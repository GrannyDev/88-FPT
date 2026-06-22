"""
Model quantization utilities.

This module provides utilities for transforming standard PyTorch models
into quantized versions by replacing layers with their quantized equivalents.
"""

import copy
from contextlib import contextmanager
from time import perf_counter
from typing import Optional, Dict, Iterable
import torch
import torch.nn as nn
import torch.nn.functional as F

from hatorch.layers.quantized_conv2d import QuantConv2d
from hatorch.layers.quantized_conv2d_bn_relu import QuantConvBn2d, QuantConvBnReLU2d, QuantConvReLU2d
from hatorch.layers.quantized_linear import QuantLinear
from hatorch.layers.quantized_tensor import QuantTensor
from hatorch.layers.quantized_relu import QuantReLU
from hatorch.layers.quantized_relu6 import QuantReLU6
from hatorch.layers.quantized_maxpool2d import QuantMaxPool2d
from hatorch.layers.quantized_averagepool2d import QuantAveragePool2d
from hatorch.layers.quantized_dropout import QuantDropout
from hatorch.layers.quantized_resunit import QuantResUnit
from hatorch.layers.quantized_inverted_residual import QuantInvertedResidual
from hatorch.layers.quantize import Quantize
from hatorch.layers.dequantize import Dequantize
from hatorch.transforms.config import (
    AutosetObjective,
    LayerQuantConfig,
    ModelQuantConfig,
    QuantizerSpec,
    WeightQuantizerConfig,
    load_codebook_candidates,
)
from hatorch.quantizers.base import BaseQuantizer
from hatorch.quantizers.common._common_quantizer import BaseLearnedQuantizer
from hatorch.quantizers.common.scale_approximation import ScaleApproximation
from hatorch.quantizers.init.lsq_uniform import LsqUniformQuantizer
from hatorch.quantizers.init.non_uniform_sigmoid_staircase import NonUniformSigmoidStaircaseQuantizer
from hatorch.utils.logger import logger


def quantize_model(
    model: nn.Module,
    config: ModelQuantConfig,
    inplace: bool = False,
    add_quantize: bool = True,
    add_dequantize: bool = True,
) -> nn.Module:
    """
    Transform a model by replacing standard layers with quantized versions.
    
    Args:
        model: Original PyTorch model
        config: Quantization configuration specifying which quantizers to use
        inplace: Whether to modify the model in-place (default: False)
        add_quantize: Whether to add a Quantize layer at the beginning (default: True)
        add_dequantize: Whether to add a Dequantize layer at the end (default: True)
        
    Returns:
        Quantized model
    """
    if not inplace:
        import copy
        model = copy.deepcopy(model)

    
    # Add Quantize and Dequantize layers directly into the model structure
    if add_quantize or add_dequantize:
        _inject_quantize_dequantize_layers(model, add_quantize, add_dequantize)
    
    # First pass: identify all quantizable layers to determine which is last
    quantizable_layers = _find_quantizable_layers(model)
    
    # Recursively replace layers
    _replace_layers_recursive(model, config, "", quantizable_layers)
    _apply_architecture_activation_signedness(model)

    # In DDP mode, BatchNorm layers must synchronize running stats across ranks.
    if _should_convert_sync_batchnorm():
        model = nn.SyncBatchNorm.convert_sync_batchnorm(model)

    _assign_quantizer_debug_labels(model)
    if config.freeze_approximated_scales:
        freeze_approximated_lsq_scales(model)

    return model


def _apply_architecture_activation_signedness(model: nn.Module) -> None:
    _apply_mobilenetv2_activation_signedness(model)


def _apply_mobilenetv2_activation_signedness(model: nn.Module) -> None:
    if not any(isinstance(module, QuantInvertedResidual) for module in model.modules()):
        return
    features = getattr(model, "features", None)
    if not isinstance(features, nn.Sequential):
        return
    _apply_mobilenetv2_sequence_signedness(features, input_signed=True)


def _apply_mobilenetv2_sequence_signedness(module: nn.Module, input_signed: bool) -> bool:
    tensor_signed = input_signed
    for child in module.children():
        if isinstance(child, Quantize):
            tensor_signed = True
        elif isinstance(child, QuantInvertedResidual):
            _set_mobilenetv2_block_input_signedness(child, tensor_signed)
            tensor_signed = True
        elif _set_relu6_block_input_signedness(child, tensor_signed):
            tensor_signed = False
        elif isinstance(child, nn.Sequential):
            tensor_signed = _apply_mobilenetv2_sequence_signedness(child, tensor_signed)
    return tensor_signed


def _set_mobilenetv2_block_input_signedness(module: QuantInvertedResidual, input_signed: bool) -> None:
    conv_layers = list(module.conv.children())
    if conv_layers:
        _set_first_quantized_layer_activation_signed(conv_layers[0], input_signed)
    if len(conv_layers) > 1:
        _set_first_quantized_layer_activation_signed(conv_layers[1], False)
    if len(conv_layers) > 2:
        _set_first_quantized_layer_activation_signed(conv_layers[2], False)


def _set_relu6_block_input_signedness(module: nn.Module, input_signed: bool) -> bool:
    if not _module_ends_with_relu6(module):
        return False
    return _set_first_quantized_layer_activation_signed(module, input_signed)


def _module_ends_with_relu6(module: nn.Module) -> bool:
    children = list(module.children())
    return bool(children) and isinstance(children[-1], QuantReLU6)


def _set_first_quantized_layer_activation_signed(module: nn.Module, signed: bool) -> bool:
    if isinstance(module, (QuantConv2d, QuantConvBn2d, QuantLinear)):
        return _set_activation_quantizer_signed(module, signed)
    for child in module.children():
        if _set_first_quantized_layer_activation_signed(child, signed):
            return True
    return False


def _set_activation_quantizer_signed(module: nn.Module, signed: bool) -> bool:
    quantizer = getattr(module, "activation_quantizer", None)
    if not isinstance(quantizer, LsqUniformQuantizer):
        return False
    quantizer.signed = bool(signed)
    if signed:
        quantizer.qn = -(2 ** (quantizer.bit_width - 1))
        quantizer.qp = 2 ** (quantizer.bit_width - 1) - 1
    else:
        quantizer.qn = 0
        quantizer.qp = 2 ** quantizer.bit_width - 1
    return True


def _assign_quantizer_debug_labels(model: nn.Module) -> None:
    """Attach stable module-path labels to quantizers for debugging."""
    for name, module in model.named_modules():
        if isinstance(module, BaseQuantizer):
            module.debug_label = name


def _should_convert_sync_batchnorm() -> bool:
    """Return True when distributed training with more than one rank is active."""
    if not torch.distributed.is_available() or not torch.distributed.is_initialized():
        return False
    return torch.distributed.get_world_size() > 1


def _find_quantizable_layers(module: nn.Module, prefix: str = "") -> list:
    """
    Find all quantizable layers (Conv2d, Linear) in the model.

    Args:
        module: Module to scan
        prefix: Current module path

    Returns:
        List of tuples (full_name, layer_type) for all quantizable layers
    """
    quantizable = []
    children_list = list(module.named_children())

    for i, (name, child) in enumerate(children_list):
        full_name = f"{prefix}.{name}" if prefix else name

        if isinstance(child, nn.Conv2d):
            quantizable.append((full_name, 'Conv2d'))
        elif isinstance(child, nn.Linear):
            quantizable.append((full_name, 'Linear'))
        elif hasattr(child, 'children') and len(list(child.children())) > 0:
            quantizable.extend(_find_quantizable_layers(child, full_name))

    return quantizable


def _inject_quantize_dequantize_layers(
    module: nn.Module,
    add_quantize: bool,
    add_dequantize: bool,
) -> None:
    """
    Inject Quantize and Dequantize layers into the model structure.

    Quantize goes at the start of the first Sequential and Dequantize at the
    very end of the model. Intermediate Dequantize -> Quantize barriers are
    intentionally avoided here so quantization metadata can propagate across
    sequential blocks.

    Args:
        module: Module to modify
        add_quantize: Whether to add Quantize layer at the beginning
        add_dequantize: Whether to add Dequantize layer at the end
    """
    children = list(module.named_children())

    if not children:
        return

    # Find all Sequential containers
    sequential_containers = []
    for name, child in children:
        if isinstance(child, nn.Sequential):
            sequential_containers.append((name, child))

    if sequential_containers:
        # Add Quantize to the beginning of the FIRST Sequential
        if add_quantize:
            first_name, first_seq = sequential_containers[0]
            layers = [Quantize()]
            for layer in first_seq.children():
                layers.append(layer)
            setattr(module, first_name, nn.Sequential(*layers))

        # Ensure final output is dequantized
        if add_dequantize:
            # Refresh last child in case we modified earlier children
            last_name, _ = children[-1]
            last_child_current = getattr(module, last_name)
            if isinstance(last_child_current, nn.Sequential):
                last_layers = list(last_child_current.children())
                if not last_layers or not isinstance(last_layers[-1], Dequantize):
                    last_layers.append(Dequantize())
                    setattr(module, last_name, nn.Sequential(*last_layers))
            else:
                # Last child is not Sequential: only append the final dequantize.
                setattr(module, last_name, nn.Sequential(last_child_current, Dequantize()))
    else:
        # No Sequential found - wrap all children
        if add_quantize or add_dequantize:
            layers = []
            if add_quantize:
                layers.append(Quantize())

            children_to_wrap = []
            for name, child in children:
                children_to_wrap.append((name, child))

            for name, child in children_to_wrap:
                layers.append(child)

            if add_dequantize:
                layers.append(Dequantize())

            for name, _ in children_to_wrap:
                delattr(module, name)

            module.add_module('_quantized_sequential', nn.Sequential(*layers))


def _replace_layers_recursive(
    module: nn.Module,
    config: ModelQuantConfig,
    prefix: str = "",
    quantizable_layers: list = None,
    layer_index: list = None,
) -> None:
    """
    Recursively replace layers in a module with quantized versions.

    Detects and fuses common patterns:
    - Conv2d + BatchNorm2d + ReLU -> QuantConvBnReLU2d
    - Conv2d + BatchNorm2d -> QuantConvBn2d
    - Conv2d + ReLU -> QuantConvReLU2d
    - Conv2d -> QuantConv2d
    - Linear -> QuantLinear

    Args:
        module: Module to process
        config: Quantization configuration
        prefix: Current module path (for naming)
        quantizable_layers: List of all quantizable layer names (for tracking first/last)
        layer_index: Mutable list containing current index [idx]
    """
    if quantizable_layers is None:
        quantizable_layers = []
    if layer_index is None:
        layer_index = [0]

    children_list = list(module.named_children())
    skip_next = set()  # Track indices to skip due to fusion

    for i, (name, child) in enumerate(children_list):
        if i in skip_next:
            continue

        full_name = f"{prefix}.{name}" if prefix else name

        # Determine if this is first or last layer
        is_first_layer = (layer_index[0] == 0) if quantizable_layers else True
        is_last_layer = (layer_index[0] == len(quantizable_layers) - 1) if quantizable_layers else False

        # Get configuration for this layer
        layer_config = config.get_config_for_layer(full_name, is_first_layer=is_first_layer, is_last_layer=is_last_layer)

        # Try to detect ConvBlock pattern (from pytorchcv models)
        # ConvBlock structure: conv (Conv2d) + bn (BatchNorm2d) + [optional] activ (ReLU)
        if _is_convblock(child):
            # Replace ConvBlock with fused quantized layer
            quant_layer = _create_quant_from_convblock(
                child,
                layer_config,
                fold_batch_norm=config.fold_batch_norm,
            )
            setattr(module, name, quant_layer)
            layer_index[0] += 1
            continue

        # PytorchCV MobileNetV2 uses LinearBottleneck blocks with conv1/conv2/conv3
        # modules and performs the residual add in the block forward.
        if _is_ptcv_mobilenetv2_linear_bottleneck(child):
            _replace_layers_recursive(
                child,
                config,
                full_name,
                quantizable_layers,
                layer_index,
            )
            main_layers = []
            if getattr(child, "use_exp_conv", False) and hasattr(child, "conv1"):
                main_layers.append(child.conv1)
            main_layers.extend([child.conv2, child.conv3])
            quant_layer = QuantInvertedResidual(
                nn.Sequential(*main_layers),
                child.residual,
                scale_approximation=config.scale_approximation,
                fixed_point_bits=config.fixed_point_bits,
            )
            setattr(module, name, quant_layer)
            continue

        # Try to detect ResUnit pattern (from pytorchcv ResNet models)
        # ResUnit can be BasicBlock (2 convs) or Bottleneck (3 convs)
        if _is_resunit(child):
            total_layers = len(quantizable_layers) if quantizable_layers is not None else 0
            current_idx = layer_index[0]
            # Detect identity conv presence to keep layer indexing aligned
            has_identity_conv = hasattr(child, "identity_conv") and hasattr(child.identity_conv, "conv")

            # Get configs for conv layers in the ResUnit
            conv1_config = config.get_config_for_layer(
                f"{full_name}.body.conv1",
                is_first_layer=is_first_layer,
                is_last_layer=(current_idx == total_layers - 1),
            )
            conv2_config = config.get_config_for_layer(
                f"{full_name}.body.conv2",
                is_first_layer=False,
                is_last_layer=(current_idx + 1 == total_layers - 1),
            )

            # Check if it's a bottleneck (3 convs)
            conv3_config = None
            num_convs = 2
            if hasattr(child.body, 'conv3'):
                conv3_config = config.get_config_for_layer(f"{full_name}.body.conv3",
                                                            is_first_layer=False,
                                                            is_last_layer=(current_idx + 2 == total_layers - 1))
                num_convs = 3
            # Include identity conv in index accounting
            conv_count = num_convs + (1 if has_identity_conv else 0)

            # Create quantized ResUnit (or return unchanged if bottleneck)
            quant_resunit = _create_quant_resunit(
                child,
                conv1_config,
                conv2_config,
                conv3_config,
                scale_approximation=config.scale_approximation,
                fixed_point_bits=config.fixed_point_bits,
                fold_batch_norm=config.fold_batch_norm,
            )
            setattr(module, name, quant_resunit)
            # Count the number of conv layers
            layer_index[0] += conv_count
            # Don't recurse into the ResUnit - it's already been handled
            continue

        # Try to detect Conv2d fusion patterns
        if isinstance(child, nn.Conv2d):
            # Look ahead for BatchNorm2d and/or ReLU
            next_bn = None
            next_relu = None
            bn_name = None
            relu_name = None

            # Check for BatchNorm after Conv
            if i + 1 < len(children_list):
                next_name, next_child = children_list[i + 1]
                if isinstance(next_child, nn.BatchNorm2d):
                    next_bn = next_child
                    bn_name = next_name

                    # Check for ReLU after BatchNorm
                    if i + 2 < len(children_list):
                        relu_candidate_name, relu_candidate = children_list[i + 2]
                        if isinstance(relu_candidate, nn.ReLU):
                            next_relu = relu_candidate
                            relu_name = relu_candidate_name
                elif isinstance(next_child, nn.ReLU):
                    # Conv + ReLU (no BatchNorm)
                    next_relu = next_child
                    relu_name = next_name

            # Create the appropriate fused layer
            if next_bn is not None and next_relu is not None:
                # Conv + BN + ReLU fusion
                quant_layer = _create_quant_conv_bn_relu(
                    child,
                    next_bn,
                    layer_config,
                    fold_batch_norm=config.fold_batch_norm,
                )
                setattr(module, name, quant_layer)
                # Remove the BN and ReLU layers
                delattr(module, bn_name)
                delattr(module, relu_name)
                skip_next.add(i + 1)
                skip_next.add(i + 2)
                layer_index[0] += 1
            elif next_bn is not None:
                # Conv + BN fusion
                quant_layer = _create_quant_conv_bn(
                    child,
                    next_bn,
                    layer_config,
                    fold_batch_norm=config.fold_batch_norm,
                )
                setattr(module, name, quant_layer)
                # Remove the BN layer
                delattr(module, bn_name)
                skip_next.add(i + 1)
                layer_index[0] += 1
            elif next_relu is not None:
                # Conv + ReLU fusion
                quant_layer = _create_quant_conv_relu(child, layer_config)
                setattr(module, name, quant_layer)
                # Remove the ReLU layer
                delattr(module, relu_name)
                skip_next.add(i + 1)
                layer_index[0] += 1
            else:
                # Just Conv2d
                quant_layer = _create_quant_conv2d(child, layer_config)
                setattr(module, name, quant_layer)
                layer_index[0] += 1

        # Replace Linear layers
        elif isinstance(child, nn.Linear):
            quant_layer = _create_quant_linear(child, layer_config)
            setattr(module, name, quant_layer)
            layer_index[0] += 1

        # Replace standalone ReLU layers (not fused with Conv)
        elif isinstance(child, nn.ReLU):
            quant_layer = QuantReLU(inplace=child.inplace)
            setattr(module, name, quant_layer)

        elif isinstance(child, nn.ReLU6):
            quant_layer = QuantReLU6(inplace=child.inplace)
            setattr(module, name, quant_layer)

        # Replace MaxPool2d layers
        elif isinstance(child, nn.MaxPool2d):
            quant_layer = QuantMaxPool2d(
                kernel_size=child.kernel_size,
                stride=child.stride,
                padding=child.padding,
                dilation=child.dilation,
                return_indices=child.return_indices,
                ceil_mode=child.ceil_mode
            )
            setattr(module, name, quant_layer)

        elif isinstance(child, nn.AvgPool2d):
            quant_layer = QuantAveragePool2d(
                kernel_size= child.kernel_size,
                stride= child.stride,
                padding= child.padding,
                ceil_mode= child.ceil_mode,
                count_include_pad= child.count_include_pad,
                divisor_override= child.divisor_override,
                round_output=config.round_average_pool_output,
            )
            setattr(module, name, quant_layer)

        # Replace Dropout layers
        elif isinstance(child, nn.Dropout):
            quant_layer = QuantDropout(p=child.p, inplace=child.inplace)
            setattr(module, name, quant_layer)

        # Always recursively process child modules (for nested structures)
        elif hasattr(child, 'children') and len(list(child.children())) > 0:
            _replace_layers_recursive(child, config, full_name, quantizable_layers, layer_index)


def _create_weight_quantizer(_weight: torch.Tensor, spec: Optional[QuantizerSpec], num_channels: int):
    """Create weight quantizer from specification."""
    if spec is None:
        return None
    return spec.create_quantizer(num_channels)


def _create_bias_quantizer(config: LayerQuantConfig):
    """Clone the configured bias quantizer so every layer owns its debug state."""
    if config.bias_quantizer is None:
        return None
    return copy.deepcopy(config.bias_quantizer)


def _create_quant_conv2d(
    conv: nn.Conv2d,
    config: LayerQuantConfig,
) -> QuantConv2d:
    """
    Create a QuantConv2d from a Conv2d layer with specified configuration.

    Args:
        conv: Original Conv2d layer
        config: Layer quantization configuration

    Returns:
        QuantConv2d layer
    """
    # Create quantizers from config
    weight_quantizer = _create_weight_quantizer(conv.weight, config.weight_quantizer, conv.out_channels)

    activation_quantizer = None
    if config.activation_quantizer is not None:
        activation_quantizer = config.activation_quantizer.create_quantizer()

    bias_quantizer = _create_bias_quantizer(config)

    # Create quantized layer
    return QuantConv2d.from_conv2d(
        conv,
        weight_quantizer=weight_quantizer,
        activation_quantizer=activation_quantizer,
        bias_quantizer=bias_quantizer,
    )


def _create_quant_conv_bn(
    conv: nn.Conv2d,
    bn: nn.BatchNorm2d,
    config: LayerQuantConfig,
    fold_batch_norm: bool = True,
) -> QuantConvBn2d:
    """
    Create a QuantConvBn2d from Conv2d and BatchNorm2d layers.

    Args:
        conv: Original Conv2d layer
        bn: Original BatchNorm2d layer
        config: Layer quantization configuration

    Returns:
        QuantConvBn2d layer
    """
    # Create quantizers from config
    weight_quantizer = _create_weight_quantizer(conv.weight, config.weight_quantizer, conv.out_channels)

    activation_quantizer = None
    if config.activation_quantizer is not None:
        activation_quantizer = config.activation_quantizer.create_quantizer()

    bias_quantizer = _create_bias_quantizer(config)

    # Create fused quantized layer
    return QuantConvBn2d.from_conv_bn(
        conv,
        bn,
        weight_quantizer=weight_quantizer,
        activation_quantizer=activation_quantizer,
        bias_quantizer=bias_quantizer,
        freeze_bn=False,
        fold_batch_norm=fold_batch_norm,
    )


def _create_quant_conv_bn_relu(
    conv: nn.Conv2d,
    bn: nn.BatchNorm2d,
    config: LayerQuantConfig,
    fold_batch_norm: bool = True,
) -> QuantConvBnReLU2d:
    """
    Create a QuantConvBnReLU2d from Conv2d, BatchNorm2d, and ReLU layers.

    Args:
        conv: Original Conv2d layer
        bn: Original BatchNorm2d layer
        config: Layer quantization configuration

    Returns:
        QuantConvBnReLU2d layer
    """
    # Create quantizers from config
    weight_quantizer = _create_weight_quantizer(conv.weight, config.weight_quantizer, conv.out_channels)

    activation_quantizer = None
    if config.activation_quantizer is not None:
        activation_quantizer = config.activation_quantizer.create_quantizer()

    bias_quantizer = _create_bias_quantizer(config)

    # Create fused quantized layer
    return QuantConvBnReLU2d.from_conv_bn(
        conv,
        bn,
        weight_quantizer=weight_quantizer,
        activation_quantizer=activation_quantizer,
        bias_quantizer=bias_quantizer,
        freeze_bn=False,
        fold_batch_norm=fold_batch_norm,
    )


def _create_quant_conv_relu(
    conv: nn.Conv2d,
    config: LayerQuantConfig,
) -> QuantConvReLU2d:
    """
    Create a QuantConvReLU2d from Conv2d and ReLU layers.

    Args:
        conv: Original Conv2d layer
        config: Layer quantization configuration

    Returns:
        QuantConvReLU2d layer
    """
    # Create quantizers from config
    weight_quantizer = _create_weight_quantizer(conv.weight, config.weight_quantizer, conv.out_channels)

    activation_quantizer = None
    if config.activation_quantizer is not None:
        activation_quantizer = config.activation_quantizer.create_quantizer()

    bias_quantizer = _create_bias_quantizer(config)

    # Create fused quantized layer
    return QuantConvReLU2d.from_conv(
        conv,
        weight_quantizer=weight_quantizer,
        activation_quantizer=activation_quantizer,
        bias_quantizer=bias_quantizer,
    )


def _is_convblock(module: nn.Module) -> bool:
    """
    Check if a module is a ConvBlock from pytorchcv.

    ConvBlock structure:
        - conv: Conv2d
        - bn: BatchNorm2d
        - [optional] activ: ReLU

    Args:
        module: Module to check

    Returns:
        True if module is a ConvBlock
    """
    # Check for the characteristic structure
    if not (hasattr(module, 'conv') and hasattr(module, 'bn')):
        return False

    # Check types
    if not isinstance(module.conv, nn.Conv2d) or not isinstance(module.bn, nn.BatchNorm2d):
        return False

    return True


def _create_quant_from_convblock(
    convblock: nn.Module,
    config: LayerQuantConfig,
    fold_batch_norm: bool = True,
) -> nn.Module:
    """
    Create a quantized layer from a ConvBlock module.

    Args:
        convblock: Original ConvBlock module
        config: Layer quantization configuration

    Returns:
        Quantized layer (QuantConvBnReLU2d or QuantConvBn2d)
    """
    conv = convblock.conv
    bn = convblock.bn
    activation = getattr(convblock, "activ", None)
    has_relu = isinstance(activation, nn.ReLU)
    has_relu6 = isinstance(activation, nn.ReLU6)

    # Create quantizers from config
    weight_quantizer = _create_weight_quantizer(conv.weight, config.weight_quantizer, conv.out_channels)

    activation_quantizer = None
    if config.activation_quantizer is not None:
        activation_quantizer = config.activation_quantizer.create_quantizer()

    bias_quantizer = _create_bias_quantizer(config)

    # Create appropriate fused quantized layer
    if has_relu:
        return QuantConvBnReLU2d.from_conv_bn(
            conv,
            bn,
            weight_quantizer=weight_quantizer,
            activation_quantizer=activation_quantizer,
            bias_quantizer=bias_quantizer,
            freeze_bn=False,
            fold_batch_norm=fold_batch_norm,
        )
    elif has_relu6:
        return nn.Sequential(
            QuantConvBn2d.from_conv_bn(
                conv,
                bn,
                weight_quantizer=weight_quantizer,
                activation_quantizer=activation_quantizer,
                bias_quantizer=bias_quantizer,
                freeze_bn=False,
                fold_batch_norm=fold_batch_norm,
            ),
            QuantReLU6(inplace=activation.inplace),
        )
    else:
        return QuantConvBn2d.from_conv_bn(
            conv,
            bn,
            weight_quantizer=weight_quantizer,
            activation_quantizer=activation_quantizer,
            bias_quantizer=bias_quantizer,
            freeze_bn=False,
            fold_batch_norm=fold_batch_norm,
        )


def _is_ptcv_mobilenetv2_linear_bottleneck(module: nn.Module) -> bool:
    """
    Check for pytorchcv MobileNetV2 LinearBottleneck blocks.
    """
    return (
        type(module).__name__ == "LinearBottleneck"
        and hasattr(module, "conv2")
        and hasattr(module, "conv3")
        and hasattr(module, "residual")
    )


def _is_resunit(module: nn.Module) -> bool:
    """
    Check if a module is a ResUnit from pytorchcv.

    ResUnit can have two structures:
    1. BasicBlock (2 convs):
        - body: ResBlock
            - conv1: ConvBlock (Conv2d + BatchNorm2d + ReLU)
            - conv2: ConvBlock (Conv2d + BatchNorm2d)
        - activ: ReLU

    2. Bottleneck (3 convs):
        - body: ResBottleneck
            - conv1: ConvBlock (1x1 Conv2d + BatchNorm2d + ReLU)
            - conv2: ConvBlock (3x3 Conv2d + BatchNorm2d + ReLU)
            - conv3: ConvBlock (1x1 Conv2d + BatchNorm2d)
        - activ: ReLU
        - [often has] identity_conv: for dimension matching

    Args:
        module: Module to check

    Returns:
        True if module is a ResUnit (either BasicBlock or Bottleneck)
    """
    # Check for the characteristic structure
    if not hasattr(module, 'body') or not hasattr(module, 'activ'):
        return False

    body = module.body
    # Must have at least conv1 and conv2
    if not hasattr(body, 'conv1') or not hasattr(body, 'conv2'):
        return False

    # Check conv1 has conv, bn, activ
    conv1 = body.conv1
    if not (hasattr(conv1, 'conv') and hasattr(conv1, 'bn') and hasattr(conv1, 'activ')):
        return False

    # Check conv2 - it should have conv, bn, and may or may not have activ
    conv2 = body.conv2
    if not (hasattr(conv2, 'conv') and hasattr(conv2, 'bn')):
        return False

    # Check types for conv1 and conv2
    if not isinstance(conv1.conv, nn.Conv2d) or not isinstance(conv1.bn, nn.BatchNorm2d):
        return False
    if not isinstance(conv2.conv, nn.Conv2d) or not isinstance(conv2.bn, nn.BatchNorm2d):
        return False

    # If conv3 exists (bottleneck), validate it too
    if hasattr(body, 'conv3'):
        conv3 = body.conv3
        if not (hasattr(conv3, 'conv') and hasattr(conv3, 'bn')):
            return False
        if not isinstance(conv3.conv, nn.Conv2d) or not isinstance(conv3.bn, nn.BatchNorm2d):
            return False

    if not isinstance(module.activ, nn.ReLU):
        return False

    return True


def _create_quant_resunit(
    resunit: nn.Module,
    conv1_config: LayerQuantConfig,
    conv2_config: LayerQuantConfig,
    conv3_config: Optional[LayerQuantConfig] = None,
    scale_approximation: ScaleApproximation = ScaleApproximation.NONE,
    fixed_point_bits: int = 8,
    fold_batch_norm: bool = True,
) -> QuantResUnit:
    """
    Create a QuantResUnit from a ResUnit module.

    Handles both BasicBlock (2 convs) and Bottleneck (3 convs) structures.

    Args:
        resunit: Original ResUnit module
        conv1_config: Configuration for first conv layer
        conv2_config: Configuration for second conv layer
        conv3_config: Configuration for third conv layer (bottleneck only)

    Returns:
        QuantResUnit with quantized convolutions
    """
    # Note: Current QuantResUnit only supports 2-conv BasicBlock structure
    # For bottleneck (3 convs), we fall back to leaving it unquantized for now
    # TODO: Implement QuantResUnitBottleneck for 3-conv case

    body = resunit.body
    has_conv3 = hasattr(body, 'conv3')

    if has_conv3:
        # Bottleneck structure (3 convs) - not yet supported
        # Return the original resunit unchanged
        # User can implement QuantResUnitBottleneck separately
        return resunit

    # BasicBlock structure (2 convs) - proceed with quantization
    # Create quantizers for conv1
    conv1_weight_quantizer = None
    if conv1_config.weight_quantizer is not None:
        # Get out_channels from conv1
        out_channels = resunit.body.conv1.conv.out_channels
        conv1_weight_quantizer = _create_weight_quantizer(
            resunit.body.conv1.conv.weight,
            conv1_config.weight_quantizer,
            out_channels,
        )

    conv1_activation_quantizer = None
    if conv1_config.activation_quantizer is not None:
        conv1_activation_quantizer = conv1_config.activation_quantizer.create_quantizer()

    conv1_bias_quantizer = _create_bias_quantizer(conv1_config)

    # Create quantizers for conv2
    conv2_weight_quantizer = None
    if conv2_config.weight_quantizer is not None:
        # Get out_channels from conv2
        out_channels = resunit.body.conv2.conv.out_channels
        conv2_weight_quantizer = _create_weight_quantizer(
            resunit.body.conv2.conv.weight,
            conv2_config.weight_quantizer,
            out_channels,
        )

    conv2_activation_quantizer = None
    if conv2_config.activation_quantizer is not None:
        conv2_activation_quantizer = conv2_config.activation_quantizer.create_quantizer()

    conv2_bias_quantizer = _create_bias_quantizer(conv2_config)

    # Create QuantResUnit using factory method, pass conv2_config for identity
    return QuantResUnit.from_resunit(
        resunit,
        conv1_weight_quantizer=conv1_weight_quantizer,
        conv1_activation_quantizer=conv1_activation_quantizer,
        conv1_bias_quantizer=conv1_bias_quantizer,
        conv2_weight_quantizer=conv2_weight_quantizer,
        conv2_activation_quantizer=conv2_activation_quantizer,
        conv2_bias_quantizer=conv2_bias_quantizer,
        freeze_bn=False,
        identity_config=copy.deepcopy(conv2_config),  # Use conv2_config for identity path
        scale_approximation=scale_approximation,
        fixed_point_bits=fixed_point_bits,
        fold_batch_norm=fold_batch_norm,
    )


def _create_quant_linear(
    linear: nn.Linear,
    config: LayerQuantConfig,
) -> QuantLinear:
    """
    Create a QuantLinear from a Linear layer with specified configuration.

    Args:
        linear: Original Linear layer
        config: Layer quantization configuration

    Returns:
        QuantLinear layer
    """
    # Create quantizers from config
    weight_quantizer = _create_weight_quantizer(linear.weight, config.weight_quantizer, linear.out_features)

    activation_quantizer = None
    if config.activation_quantizer is not None:
        activation_quantizer = config.activation_quantizer.create_quantizer()

    bias_quantizer = _create_bias_quantizer(config)

    # Create quantized layer
    return QuantLinear.from_linear(
        linear,
        weight_quantizer=weight_quantizer,
        activation_quantizer=activation_quantizer,
        bias_quantizer=bias_quantizer,
    )


def set_quantizers_to_mode(
    model: nn.Module,
    mode: str,
) -> None:
    """
    Set all quantizers in a model to a specific mode.

    Args:
        model: Model containing quantizers
        mode: Mode to set ('calibration', 'training', 'eval', 'disable', 'enable')
    """
    for module in model.modules():
        if isinstance(module, BaseQuantizer):
            if mode == 'calibration':
                module.calibration_mode_(True)
                module.enable()
            elif mode == 'training':
                module.calibration_mode_(False)
                module.enable()
                module.train()
            elif mode == 'eval':
                module.calibration_mode_(False)
                module.enable()
                module.eval()
            elif mode == 'disable':
                module.disable()
            elif mode == 'enable':
                module.enable()
            else:
                raise ValueError(f"Unknown mode: {mode}")

def freeze_model_parameters(model: nn.Module) -> Dict[int, bool]:
    # start by storing the requires_grad state of each parameter in a dict
    param_states = {id(p): p.requires_grad for p in model.parameters()}

    # then set requires_grad to False for all parameters
    for param in model.parameters():
        param.requires_grad = False

    return param_states

def unfreeze_model_parameters(model: nn.Module, param_states: Dict[int, bool]) -> None:
    # restore the requires_grad state of each parameter from the provided dict
    for param in model.parameters():
        if id(param) in param_states:
            param.requires_grad = param_states[id(param)]

def freeze_quantizer_parameters(model: nn.Module) -> None:
    """
    Freeze all quantizer parameters (e.g., scales) in a model.

    Useful for fine-tuning only the weights while keeping quantization fixed.

    Args:
        model: Model containing quantizers
    """
    for module in model.modules():
        if isinstance(module, BaseQuantizer):
            for param in module.parameters():
                param.requires_grad = False


def unfreeze_quantizer_parameters(model: nn.Module) -> None:
    """
    Unfreeze all quantizer parameters in a model.

    Args:
        model: Model containing quantizers
    """
    for module in model.modules():
        if isinstance(module, BaseQuantizer):
            for param in module.parameters():
                param.requires_grad = True


def get_lsq_learnable_parameters(
    model: nn.Module,
    include_scale: bool = True,
    include_zero_point: bool = False,
    weights_only: bool = False,
    activations_only: bool = False,
) -> list[nn.Parameter]:
    """
    Collect learnable LSQ quantizer parameters from a model.

    Args:
        model: Model containing LSQ quantizers.
        include_scale: Include learnable LSQ scales.
        include_zero_point: Include learnable LSQ zero-points.
        weights_only: Only include weight quantizers.
        activations_only: Only include activation quantizers.

    Returns:
        List of unique parameters matching the requested filter.
    """
    if weights_only and activations_only:
        raise ValueError("Cannot specify both weights_only and activations_only")

    params: list[nn.Parameter] = []
    seen: set[int] = set()

    for module in model.modules():
        if not isinstance(module, BaseLearnedQuantizer):
            continue
        if weights_only and module.is_activation:
            continue
        if activations_only and not module.is_activation:
            continue

        candidates: list[nn.Parameter] = []
        if include_scale and isinstance(module.scale, nn.Parameter):
            if module.scale.requires_grad:
                candidates.append(module.scale)

        if include_zero_point and isinstance(module.zero_point, nn.Parameter):
            if module.zero_point.requires_grad:
                candidates.append(module.zero_point)

        for param in candidates:
            if id(param) not in seen:
                seen.add(id(param))
                params.append(param)

    return params


def set_optimizer_weight_decay_for_parameters(
    optimizer: torch.optim.Optimizer,
    parameters: Iterable[nn.Parameter],
    weight_decay: float = 0.0,
) -> int:
    """
    Move a subset of parameters into optimizer groups with a specific weight decay.

    Args:
        optimizer: Optimizer to update in-place.
        parameters: Parameters to move into dedicated groups.
        weight_decay: Weight decay to set for the moved parameters.

    Returns:
        Number of parameters moved.
    """
    target_ids = {id(param) for param in parameters}
    if not target_ids:
        return 0

    moved_total = 0
    new_groups = []

    for group in list(optimizer.param_groups):
        group_params = list(group["params"])
        selected = [param for param in group_params if id(param) in target_ids]
        if not selected:
            continue

        group["params"] = [param for param in group_params if id(param) not in target_ids]

        new_group = {key: value for key, value in group.items() if key != "params"}
        new_group["params"] = selected
        new_group["weight_decay"] = weight_decay
        new_groups.append(new_group)
        moved_total += len(selected)

    for new_group in new_groups:
        optimizer.add_param_group(new_group)

    optimizer.param_groups[:] = [group for group in optimizer.param_groups if group["params"]]
    return moved_total


def count_quantized_layers(model: nn.Module) -> Dict[str, int]:
    """
    Count the number of quantized layers in a model.
    
    Args:
        model: Model to analyze
        
    Returns:
        Dictionary with counts of different quantized layer types
    """
    counts = {
        'QuantConv2d': 0,
        'QuantConvBn2d': 0,
        'QuantConvReLU2d': 0,
        'QuantConvBnReLU2d': 0,
        'QuantLinear': 0,
        'QuantReLU': 0,
        'QuantReLU6': 0,
        'QuantMaxPool2d': 0,
        'QuantAveragePool2d': 0,
        'QuantDropout': 0,
        'QuantInvertedResidual': 0,
        'Quantize': 0,
        'Dequantize': 0,
        'Quantizers': 0,
    }
    
    for module in model.modules():
        if isinstance(module, QuantConvBnReLU2d):
            counts['QuantConvBnReLU2d'] += 1
        elif isinstance(module, QuantConvBn2d):
            counts['QuantConvBn2d'] += 1
        elif isinstance(module, QuantConvReLU2d):
            counts['QuantConvReLU2d'] += 1
        elif isinstance(module, QuantConv2d):
            counts['QuantConv2d'] += 1
        elif isinstance(module, QuantLinear):
            counts['QuantLinear'] += 1
        elif isinstance(module, QuantReLU6):
            counts['QuantReLU6'] += 1
        elif isinstance(module, QuantReLU):
            counts['QuantReLU'] += 1
        elif isinstance(module, QuantMaxPool2d):
            counts['QuantMaxPool2d'] += 1
        elif isinstance(module, QuantAveragePool2d):
            counts['QuantAveragePool2d'] += 1
        elif isinstance(module, QuantDropout):
            counts['QuantDropout'] += 1
        elif isinstance(module, QuantInvertedResidual):
            counts['QuantInvertedResidual'] += 1
        elif isinstance(module, Quantize):
            counts['Quantize'] += 1
        elif isinstance(module, Dequantize):
            counts['Dequantize'] += 1
        elif isinstance(module, BaseQuantizer):
            counts['Quantizers'] += 1
    
    return counts


def print_quantization_summary(model: nn.Module) -> None:
    """
    Print a summary of quantization configuration in a model.
    
    Args:
        model: Model to summarize
    """
    print("=" * 80)
    print("Quantization Summary")
    print("=" * 80)
    
    counts = count_quantized_layers(model)
    print(f"\nQuantized Layers:")
    for layer_type, count in counts.items():
        print(f"  {layer_type}: {count}")
    
    print(f"\nQuantizer Details:")
    print("-" * 80)
    
    for name, module in model.named_modules():
        if isinstance(module, (QuantConv2d, QuantConvBn2d, QuantConvReLU2d, QuantConvBnReLU2d, QuantLinear)):
            print(f"\n{name} ({type(module).__name__}):")
            print(f"  Weight quantizer: {type(module.weight_quantizer).__name__}")
            print(f"  Activation quantizer: {type(module.activation_quantizer).__name__}")
            print(f"  Bias quantizer: {type(module.bias_quantizer).__name__}")
    
    print("=" * 80)


def set_scale_approximation(
    model: nn.Module,
    approximation: ScaleApproximation,
    fixed_point_bits: Optional[int] = None,
    weights_only: bool = False,
    activations_only: bool = False,
    skip_first_activation: bool = True,
    skip_output_scale: bool = True,
) -> int:
    """
    Dynamically change the scale approximation method for all LSQ quantizers in a model.
    
    This is useful for switching between training (no approximation) and inference
    (power-of-two or fixed-point approximation) modes.
    
    Args:
        model: Model containing LSQ quantizers
        approximation: Scale approximation method to set
        fixed_point_bits: Number of fractional bits (only used for FIXED_POINT)
        weights_only: Only update weight quantizers (default: False)
        activations_only: Only update activation quantizers (default: False)
        skip_first_activation: Keep the first activation quantizer exact. Use this
            when input/dataset quantization is an external deployment boundary.
        skip_output_scale: Keep the last layer's weight quantizer exact.
            The last layer activation quantizer is the classifier input and
            remains an internal rescale.
        
    Example:
        >>> # Train with exact scales
        >>> set_scale_approximation(model, ScaleApproximation.NONE)
        >>> trainer.train()
        >>> 
        >>> # Evaluate with power-of-two approximation
        >>> set_scale_approximation(model, ScaleApproximation.POWER_OF_TWO)
        >>> trainer.evaluate()
        >>> 
        >>> # Deploy with fixed-point approximation (8 fractional bits)
        >>> set_scale_approximation(model, ScaleApproximation.FIXED_POINT, fixed_point_bits=8)
    """
    if weights_only and activations_only:
        raise ValueError("Cannot specify both weights_only and activations_only")
    
    updated = 0
    first_activation = _first_lsq_activation_quantizer(model) if skip_first_activation else None
    output_scale_quantizers = (
        {
            quantizer
            for quantizer in (_last_scale_approx_weight_quantizer(model),)
            if quantizer is not None
        }
        if skip_output_scale
        else set()
    )
    for module in model.modules():
        if isinstance(module, BaseLearnedQuantizer) and hasattr(module, "scale_approximation"):
            # Filter based on quantizer type
            if weights_only and module.is_activation:
                continue
            if activations_only and not module.is_activation:
                continue
            if module is first_activation or module in output_scale_quantizers:
                module.scale_approximation = ScaleApproximation.NONE
                continue
            
            # Update approximation settings
            module.scale_approximation = approximation
            if fixed_point_bits is not None:
                module.fixed_point_bits = fixed_point_bits
            updated += 1
        elif isinstance(module, (QuantResUnit, QuantInvertedResidual)) and not (weights_only or activations_only):
            module.scale_approximation = approximation
            if fixed_point_bits is not None:
                module.fixed_point_bits = fixed_point_bits
            updated += 1
    return updated


def freeze_approximated_lsq_scales(
    model: nn.Module,
    weights_only: bool = False,
    activations_only: bool = False,
) -> int:
    """
    Freeze LSQ scale parameters only for quantizers with active scale approximation.

    This intentionally leaves exact-scale boundary quantizers trainable, such as
    the first input/dataset activation scale when it is kept at NONE.
    """
    if weights_only and activations_only:
        raise ValueError("Cannot specify both weights_only and activations_only")

    frozen = 0
    for module in model.modules():
        if not isinstance(module, BaseLearnedQuantizer) or not hasattr(module, "scale_approximation"):
            continue
        if weights_only and module.is_activation:
            continue
        if activations_only and not module.is_activation:
            continue
        if module.scale_approximation == ScaleApproximation.NONE:
            continue
        if not isinstance(module.scale, nn.Parameter):
            continue

        module.scale.requires_grad_(False)
        frozen += 1
    return frozen


def initialize_uniform_ptq_scales(
    model: nn.Module,
    data_loader,
    device: torch.device | str,
    num_batches: int = 16,
    calibration_passes: int = 3,
    initialize_weights: bool = True,
    initialize_activations: bool = True,
) -> dict[str, int]:
    """
    Initialize uniform LSQ scales for post-training quantization.

    This avoids relying on the first evaluation batch to initialize activation
    scales and avoids clipping pretrained folded weights with the historical
    LSQ training initializer.
    """
    if num_batches < 1:
        raise ValueError("num_batches must be >= 1.")
    if calibration_passes < 1:
        raise ValueError("calibration_passes must be >= 1.")

    initialized_weights = (
        _initialize_uniform_weight_scales_max_abs(model) if initialize_weights else 0
    )
    initialized_activations = 0
    if initialize_activations:
        for _ in range(calibration_passes):
            initialized_activations = _initialize_uniform_activation_scales_from_data(
                model,
                data_loader,
                device,
                num_batches,
            )
    logger.info(
        "Initialized PTQ scales for %d weight quantizer(s) and %d activation quantizer(s) over %d pass(es).",
        initialized_weights,
        initialized_activations,
        calibration_passes if initialize_activations else 0,
    )
    return {"weights": initialized_weights, "activations": initialized_activations}


def _initialize_uniform_weight_scales_max_abs(model: nn.Module) -> int:
    initialized = 0
    for module in model.modules():
        quantizer = getattr(module, "weight_quantizer", None)
        if not isinstance(quantizer, LsqUniformQuantizer) or quantizer.is_activation:
            continue
        weight = _autoset_effective_weight(module).detach()
        qmax = max(abs(float(quantizer.qn)), abs(float(quantizer.qp)), 1.0)
        if quantizer.per_channel:
            dims = list(range(1, weight.ndim))
            scale = weight.abs().amax(dim=dims) / qmax
        else:
            scale = weight.abs().amax() / qmax
        quantizer._set_positive_scale(
            scale.to(device=quantizer.scale.device, dtype=quantizer.scale.dtype).clamp_min(1e-8)
        )
        initialized += 1
    return initialized


def _initialize_uniform_activation_scales_from_data(
    model: nn.Module,
    data_loader,
    device: torch.device | str,
    num_batches: int,
) -> int:
    stats: dict[LsqUniformQuantizer, list[torch.Tensor]] = {}
    handles = []
    activation_quantizers: list[LsqUniformQuantizer] = []

    def _activation_pre_hook(quantizer: LsqUniformQuantizer, inputs) -> None:
        if not inputs or not isinstance(inputs[0], torch.Tensor):
            return
        x = inputs[0]
        if len(inputs) > 1 and isinstance(inputs[1], torch.Tensor):
            x = x * _broadcast_scale_like(inputs[1].to(device=x.device, dtype=x.dtype), x)
        x = x.detach()
        min_v = x.amin()
        max_v = x.amax()
        if quantizer not in stats:
            stats[quantizer] = [min_v, max_v]
        else:
            stats[quantizer][0] = torch.minimum(stats[quantizer][0], min_v)
            stats[quantizer][1] = torch.maximum(stats[quantizer][1], max_v)

    for module in model.modules():
        if isinstance(module, LsqUniformQuantizer) and module.is_activation:
            activation_quantizers.append(module)
            handles.append(module.register_forward_pre_hook(_activation_pre_hook))

    was_training = model.training
    model.eval()
    try:
        with torch.no_grad():
            for batch_index, batch in enumerate(data_loader):
                if batch_index >= num_batches:
                    break
                inputs = batch[0] if isinstance(batch, (tuple, list)) else batch
                model(inputs.to(device))
    finally:
        for handle in handles:
            handle.remove()
        model.train(was_training)

    if not activation_quantizers:
        return 0

    stat_device = torch.device(device)
    local_mins = []
    local_maxs = []
    for quantizer in activation_quantizers:
        if quantizer in stats:
            min_v, max_v = stats[quantizer]
            local_mins.append(min_v.detach().to(device=stat_device, dtype=torch.float32))
            local_maxs.append(max_v.detach().to(device=stat_device, dtype=torch.float32))
        else:
            local_mins.append(torch.tensor(float("inf"), device=stat_device))
            local_maxs.append(torch.tensor(float("-inf"), device=stat_device))

    min_values = torch.stack(local_mins)
    max_values = torch.stack(local_maxs)
    if torch.distributed.is_available() and torch.distributed.is_initialized():
        torch.distributed.all_reduce(min_values, op=torch.distributed.ReduceOp.MIN)
        torch.distributed.all_reduce(max_values, op=torch.distributed.ReduceOp.MAX)

    initialized = 0
    for quantizer, min_v, max_v in zip(activation_quantizers, min_values, max_values):
        if not torch.isfinite(min_v) or not torch.isfinite(max_v):
            continue
        if quantizer.symmetric and quantizer.signed:
            qmax = max(abs(float(quantizer.qn)), abs(float(quantizer.qp)), 1.0)
            scale = torch.maximum(max_v.abs(), min_v.abs()) / qmax
        else:
            scale = (max_v - min_v) / (quantizer.qp - quantizer.qn)
            if not quantizer.symmetric:
                init_zp = min_v - quantizer.qn * scale
                quantizer.zero_point.data.copy_(
                    init_zp.to(device=quantizer.zero_point.device, dtype=quantizer.zero_point.dtype)
                )
        quantizer._set_positive_scale(
            scale.to(device=quantizer.scale.device, dtype=quantizer.scale.dtype).clamp_min(1e-8)
        )
        initialized += 1

    return initialized


def _broadcast_scale_like(scale: torch.Tensor, value: torch.Tensor) -> torch.Tensor:
    if scale.numel() == 1:
        return scale
    if value.ndim == 4 and scale.numel() == value.shape[1]:
        return scale.view(1, -1, 1, 1)
    if value.ndim == 2 and scale.numel() == value.shape[1]:
        return scale.view(1, -1)
    return scale


def _dequantize_quant_tensor_value(quant_tensor: QuantTensor) -> torch.Tensor:
    value = quant_tensor.value
    scale = _broadcast_scale_like(quant_tensor.scale, value)
    zero_point = _broadcast_scale_like(quant_tensor.zero_point, value)
    return value * scale + zero_point


def set_non_uniform_sigmoid_staircase_tau(model: nn.Module, tau: float) -> int:
    updated = 0
    for module in model.modules():
        if isinstance(module, NonUniformSigmoidStaircaseQuantizer):
            module.set_tau(float(tau))
            updated += 1
    return updated


def set_non_uniform_sigmoid_staircase_hard_forward(model: nn.Module, enabled: bool) -> dict[str, bool]:
    previous_modes = {}
    for name, module in model.named_modules():
        if not isinstance(module, NonUniformSigmoidStaircaseQuantizer):
            continue
        previous_modes[name] = module.hard_forward_enabled
        module.set_hard_forward(enabled)
    return previous_modes


def restore_non_uniform_sigmoid_staircase_hard_forward(model: nn.Module, modes: dict[str, bool]) -> None:
    modules = dict(model.named_modules())
    for name, enabled in modes.items():
        module = modules.get(name)
        if isinstance(module, NonUniformSigmoidStaircaseQuantizer):
            module.set_hard_forward(enabled)


def has_non_uniform_sigmoid_staircase_quantizer(model: nn.Module) -> bool:
    return any(isinstance(module, NonUniformSigmoidStaircaseQuantizer) for module in model.modules())


@contextmanager
def non_uniform_sigmoid_staircase_hard_forward(model: nn.Module, enabled: bool):
    modes = set_non_uniform_sigmoid_staircase_hard_forward(model, enabled)
    try:
        yield
    finally:
        restore_non_uniform_sigmoid_staircase_hard_forward(model, modes)


def apply_autoset_weight_codebooks(
    model: nn.Module,
    data_loader,
    device: torch.device | str,
    config: WeightQuantizerConfig,
) -> dict[str, list[float]]:
    if not config.autoset:
        return {}

    distributed = torch.distributed.is_available() and torch.distributed.is_initialized()
    rank = torch.distributed.get_rank() if distributed else 0
    if distributed and rank != 0:
        payload = [None]
        torch.distributed.broadcast_object_list(payload, src=0)
        selected = payload[0] or {}
        _apply_autoset_codebook_selection(model, selected)
        _initialize_uniform_activation_scales_from_data(
            model,
            data_loader,
            device,
            int(config.autoset_batches),
        )
        logger.info(
            "Autoset codebook selection received from rank 0 for %d layer(s).",
            len(selected),
        )
        return selected

    candidates = load_codebook_candidates(config.autoset_path, config.coefficients)
    if config.autoset_max_candidates is not None:
        candidates = candidates[: config.autoset_max_candidates]
    candidate_tensor = torch.stack(candidates, dim=0).to(device=device, dtype=torch.float32)
    layers = _autoset_layers(model)
    selected: dict[str, list[float]] = {}
    total_layers = len(layers)
    autoset_batches = int(config.autoset_batches)

    logger.info(
        "Autoset codebook selection: %d layer(s), %d candidate(s), %d batch(es), objective=%s%s.",
        total_layers,
        candidate_tensor.shape[0],
        autoset_batches,
        config.autoset_objective.value,
        " (rank 0 only)" if distributed else "",
    )

    was_training = model.training
    model.eval()
    try:
        total_start = perf_counter()
        for layer_index, (layer_name, layer) in enumerate(layers, start=1):
            layer_start = perf_counter()
            logger.info(
                "Autoset [%d/%d] scoring layer %s.",
                layer_index,
                total_layers,
                layer_name,
            )
            scores = torch.zeros(candidate_tensor.shape[0], device=device, dtype=torch.float64)

            if config.autoset_objective == AutosetObjective.OUTPUT_MSE:
                _autoset_score_layer_mse(
                    model,
                    layer,
                    layer_name,
                    data_loader,
                    device,
                    candidate_tensor,
                    scores,
                    layer_index,
                    total_layers,
                    autoset_batches,
                )
            elif config.autoset_objective == AutosetObjective.FISHER_WEIGHTED_OUTPUT_MSE:
                _autoset_score_layer_fisher(
                    model,
                    layer,
                    layer_name,
                    data_loader,
                    device,
                    candidate_tensor,
                    scores,
                    layer_index,
                    total_layers,
                    autoset_batches,
                )
            else:
                raise ValueError(f"Unsupported autoset objective: {config.autoset_objective}")

            best_index = int(torch.argmin(scores).item())
            best_codebook = candidate_tensor[best_index].detach().to(device=layer.weight.device, dtype=layer.weight.dtype)
            _set_layer_codebook(layer, best_codebook)
            selected[layer_name] = best_codebook.detach().cpu().tolist()
            logger.info(
                "Autoset [%d/%d] selected candidate %d for %s in %.1fs.",
                layer_index,
                total_layers,
                best_index,
                layer_name,
                perf_counter() - layer_start,
            )
        logger.info("Autoset codebook selection completed in %.1fs.", perf_counter() - total_start)
    finally:
        model.train(was_training)

    if distributed:
        torch.distributed.broadcast_object_list([selected], src=0)
        initialized_activations = _initialize_uniform_activation_scales_from_data(
            model,
            data_loader,
            device,
            autoset_batches,
        )
        logger.info(
            "Autoset synchronized activation scale initialization for %d quantizer(s).",
            initialized_activations,
        )

    return selected


def _autoset_score_layer_mse(
    model: nn.Module,
    layer: nn.Module,
    layer_name: str,
    data_loader,
    device: torch.device | str,
    candidate_tensor: torch.Tensor,
    scores: torch.Tensor,
    layer_index: int,
    total_layers: int,
    autoset_batches: int,
) -> None:
    def _hook(_module, inputs):
        if not inputs:
            return
        scores.add_(
            _autoset_candidate_scores(
                layer,
                inputs[0],
                candidate_tensor,
            )
        )

    handle = layer.register_forward_pre_hook(_hook)
    try:
        with torch.no_grad():
            for batch_index, batch in enumerate(data_loader):
                if batch_index >= autoset_batches:
                    break
                _log_autoset_batch(layer_index, total_layers, layer_name, batch_index, autoset_batches)
                inputs, _ = _autoset_batch_inputs_labels(batch, device, require_labels=False)
                model(inputs)
    finally:
        handle.remove()


def _autoset_score_layer_fisher(
    model: nn.Module,
    layer: nn.Module,
    layer_name: str,
    data_loader,
    device: torch.device | str,
    candidate_tensor: torch.Tensor,
    scores: torch.Tensor,
    layer_index: int,
    total_layers: int,
    autoset_batches: int,
) -> None:
    captured = {}

    def _pre_hook(_module, inputs):
        if inputs:
            captured["input"] = inputs[0]

    def _forward_hook(_module, _inputs, output):
        output_tensor = _autoset_output_tensor(output)
        if not output_tensor.requires_grad:
            raise RuntimeError(f"Autoset Fisher objective could not track gradients for layer {layer_name}.")
        output_tensor.retain_grad()
        captured["output"] = output_tensor

    pre_handle = layer.register_forward_pre_hook(_pre_hook)
    forward_handle = layer.register_forward_hook(_forward_hook)
    try:
        for batch_index, batch in enumerate(data_loader):
            if batch_index >= autoset_batches:
                break
            _log_autoset_batch(layer_index, total_layers, layer_name, batch_index, autoset_batches)
            inputs, labels = _autoset_batch_inputs_labels(batch, device, require_labels=True)
            captured.clear()
            model.zero_grad(set_to_none=True)
            output = model(inputs)
            loss = F.cross_entropy(_autoset_output_tensor(output), labels)
            loss.backward()
            layer_input = captured.get("input")
            layer_output = captured.get("output")
            if layer_input is None or layer_output is None or layer_output.grad is None:
                raise RuntimeError(f"Autoset Fisher objective did not capture input/gradient for layer {layer_name}.")
            with torch.no_grad():
                scores.add_(
                    _autoset_candidate_scores(
                        layer,
                        layer_input,
                        candidate_tensor,
                        output_grad=layer_output.grad.detach(),
                    )
                )
            model.zero_grad(set_to_none=True)
    finally:
        pre_handle.remove()
        forward_handle.remove()
        model.zero_grad(set_to_none=True)


def _log_autoset_batch(
    layer_index: int,
    total_layers: int,
    layer_name: str,
    batch_index: int,
    autoset_batches: int,
) -> None:
    logger.info(
        "Autoset [%d/%d] layer %s, batch %d/%d.",
        layer_index,
        total_layers,
        layer_name,
        batch_index + 1,
        autoset_batches,
    )


def _autoset_batch_inputs_labels(
    batch,
    device: torch.device | str,
    require_labels: bool,
) -> tuple[torch.Tensor, torch.Tensor | None]:
    if isinstance(batch, (tuple, list)):
        inputs = batch[0]
        labels = batch[1] if len(batch) > 1 else None
    else:
        inputs = batch
        labels = None
    if require_labels and labels is None:
        raise ValueError("Fisher-weighted autoset objective requires dataloader batches with labels.")
    inputs = inputs.to(device)
    labels = labels.to(device) if labels is not None else None
    return inputs, labels


def _autoset_output_tensor(output) -> torch.Tensor:
    return output.value if isinstance(output, QuantTensor) else output


def _autoset_layers(model: nn.Module) -> list[tuple[str, nn.Module]]:
    supported = (QuantConv2d, QuantConvBn2d, QuantConvBnReLU2d, QuantConvReLU2d, QuantLinear)
    layers = []
    for name, module in model.named_modules():
        if not isinstance(module, supported):
            continue
        weight_quantizer = getattr(module, "weight_quantizer", None)
        if not hasattr(weight_quantizer, "bit_width"):
            continue
        if not getattr(weight_quantizer, "is_non_uniform_bitwidth", False):
            continue
        layers.append((name, module))
    return layers


def _autoset_candidate_scores(
    layer: nn.Module,
    layer_input,
    candidates: torch.Tensor,
    output_grad: torch.Tensor | None = None,
) -> torch.Tensor:
    activation = _autoset_quantized_activation(layer, layer_input)
    effective_weight = _autoset_effective_weight(layer)
    scores = []
    grad_weight = output_grad.detach().float().pow(2) if output_grad is not None else None
    for candidate in candidates.to(device=effective_weight.device, dtype=effective_weight.dtype):
        quantized_weight = _autoset_quantize_weight_candidate(
            effective_weight,
            candidate,
            bool(getattr(layer.weight_quantizer, "per_channel", False)),
        )
        error_weight = effective_weight - quantized_weight
        error_output = _autoset_apply_layer_op(layer, activation, error_weight)
        error = error_output.detach().float().pow(2)
        if grad_weight is not None:
            error = error * grad_weight.to(device=error.device, dtype=error.dtype)
        scores.append(error.mean().to(device=candidates.device, dtype=torch.float64))
    return torch.stack(scores)


def _autoset_quantized_activation(layer: nn.Module, layer_input) -> torch.Tensor:
    if isinstance(layer_input, QuantTensor):
        activation_fp = _dequantize_quant_tensor_value(layer_input)
    else:
        activation_fp = layer_input
    quantized = layer.activation_quantizer(activation_fp)
    return _dequantize_quant_tensor_value(quantized)


def _autoset_effective_weight(layer: nn.Module) -> torch.Tensor:
    weight = layer.weight.detach()
    if (
        getattr(layer, "fold_batch_norm", False)
        and hasattr(layer, "bn")
        and hasattr(layer.bn, "running_var")
        and hasattr(layer.bn, "weight")
    ):
        running_std = torch.sqrt(layer.bn.running_var + layer.bn.eps)
        fold_scale = layer.bn.weight / running_std
        weight_shape = [weight.shape[0]] + [1] * (weight.ndim - 1)
        return weight * fold_scale.reshape(weight_shape)
    return weight


def _autoset_quantize_weight_candidate(
    weight: torch.Tensor,
    candidate: torch.Tensor,
    per_channel: bool,
) -> torch.Tensor:
    sorted_candidate = torch.sort(candidate.reshape(-1)).values
    max_abs_code = sorted_candidate.abs().amax().clamp_min(1.0)
    if per_channel:
        dims = list(range(1, weight.ndim))
        mean_v = weight.mean(dim=dims, keepdim=False)
        std_v = weight.std(dim=dims, keepdim=False)
        scale = torch.maximum((mean_v - 3 * std_v).abs(), (mean_v + 3 * std_v).abs())
        scale = (scale / max_abs_code).clamp_min(1e-8).view([weight.shape[0]] + [1] * (weight.ndim - 1))
    else:
        mean_v = weight.mean()
        std_v = weight.std()
        scale = (torch.maximum((mean_v - 3 * std_v).abs(), (mean_v + 3 * std_v).abs()) / max_abs_code).clamp_min(1e-8)

    scaled = (weight / scale).clamp(float(sorted_candidate.min()), float(sorted_candidate.max()))
    indices = torch.argmin(torch.abs(scaled.reshape(-1, 1) - sorted_candidate.reshape(1, -1)), dim=1)
    quantized_codes = sorted_candidate[indices].view_as(weight)
    return quantized_codes * scale


def _autoset_apply_layer_op(layer: nn.Module, activation: torch.Tensor, weight: torch.Tensor) -> torch.Tensor:
    if isinstance(layer, QuantLinear):
        return F.linear(activation, weight, None)
    if isinstance(layer, (QuantConv2d, QuantConvBn2d, QuantConvBnReLU2d, QuantConvReLU2d)):
        if getattr(layer, "padding_mode", "zeros") != "zeros":
            activation = F.pad(
                activation,
                layer.reversed_padding_repeated_twice,
                mode=layer.padding_mode,
            )
            padding = (0, 0)
        else:
            padding = layer.padding
        return F.conv2d(
            activation,
            weight,
            None,
            stride=layer.stride,
            padding=padding,
            dilation=layer.dilation,
            groups=layer.groups,
        )
    raise TypeError(f"Unsupported autoset layer type: {type(layer).__name__}")


def _set_layer_codebook(layer: nn.Module, codebook: torch.Tensor) -> None:
    weight_quantizer = layer.weight_quantizer
    weight_quantizer.bit_width.data.copy_(codebook.to(device=weight_quantizer.bit_width.device, dtype=weight_quantizer.bit_width.dtype))
    weight_quantizer.qn = int(codebook.min().item())
    weight_quantizer.qp = int(codebook.max().item())
    if hasattr(weight_quantizer, "threshold_logits"):
        weight_quantizer.threshold_logits.data.zero_()
    effective_weight = _autoset_effective_weight(layer)
    weight_quantizer.scale_initializer(effective_weight)


def _apply_autoset_codebook_selection(model: nn.Module, selected: dict[str, list[float]]) -> None:
    if not selected:
        return
    layers_by_name = dict(_autoset_layers(model))
    for layer_name, codebook_values in selected.items():
        layer = layers_by_name.get(layer_name)
        if layer is None:
            raise RuntimeError(f"Autoset broadcast selected unknown layer {layer_name!r}.")
        codebook = torch.tensor(codebook_values, device=layer.weight.device, dtype=layer.weight.dtype)
        _set_layer_codebook(layer, codebook)


def _first_lsq_activation_quantizer(model: nn.Module) -> Optional[LsqUniformQuantizer]:
    for module in model.modules():
        if isinstance(module, LsqUniformQuantizer) and module.is_activation:
            return module
    return None


def _last_scale_approx_weight_quantizer(model: nn.Module) -> Optional[BaseLearnedQuantizer]:
    last = None
    for module in model.modules():
        if isinstance(module, BaseLearnedQuantizer) and hasattr(module, "scale_approximation") and not module.is_activation:
            last = module
    return last


def _last_scale_approx_activation_quantizer(model: nn.Module) -> Optional[BaseLearnedQuantizer]:
    last = None
    for module in model.modules():
        if isinstance(module, BaseLearnedQuantizer) and hasattr(module, "scale_approximation") and module.is_activation:
            last = module
    return last


def freeze_lsq_scales_and_set_power_of_two(
    model: nn.Module,
    weights_only: bool = False,
    activations_only: bool = False,
    skip_first_activation: bool = True,
    skip_output_scale: bool = True,
) -> None:
    """
    Freeze LSQ scale parameters and switch scale approximation to power-of-two.

    Args:
        model: Model containing LSQ quantizers.
        weights_only: Only update weight quantizers (default: False).
        activations_only: Only update activation quantizers (default: False).
        skip_first_activation: Keep the first activation quantizer exact.
        skip_output_scale: Keep the last layer's weight quantizer exact.
            The last layer activation quantizer is the classifier input and
            remains an internal rescale.
    """
    if weights_only and activations_only:
        raise ValueError("Cannot specify both weights_only and activations_only")

    first_activation = _first_lsq_activation_quantizer(model) if skip_first_activation else None
    output_scale_quantizers = (
        {
            quantizer
            for quantizer in (_last_scale_approx_weight_quantizer(model),)
            if quantizer is not None
        }
        if skip_output_scale
        else set()
    )
    for module in model.modules():
        if not isinstance(module, BaseLearnedQuantizer) or not hasattr(module, "scale_approximation"):
            continue
        if weights_only and module.is_activation:
            continue
        if activations_only and not module.is_activation:
            continue
        if module is first_activation or module in output_scale_quantizers:
            module.scale_approximation = ScaleApproximation.NONE
            continue

        module.scale.requires_grad_(False)
        module.scale_approximation = ScaleApproximation.POWER_OF_TWO

    for module in model.modules():
        if isinstance(module, (QuantResUnit, QuantInvertedResidual)):
            module.scale_approximation = ScaleApproximation.POWER_OF_TWO


def freeze_batch_norm_stats(model: nn.Module) -> None:
    """
    Freeze BatchNorm running statistics for modules in a model.
    """
    for module in model.modules():
        if hasattr(module, "freeze_bn_stats") and callable(module.freeze_bn_stats):
            module.freeze_bn_stats()
        elif isinstance(
            module,
            (nn.BatchNorm1d, nn.BatchNorm2d, nn.BatchNorm3d, nn.SyncBatchNorm),
        ):
            module.eval()


def switch_folded_batch_norm_to_running_stats(model: nn.Module) -> int:
    """
    Switch folded Conv+BN modules to running-stat folded forward.

    This intentionally keeps their BN running statistics updating during
    training until ``freeze_folded_batch_norm_running_stats`` is called.
    """
    switched = 0
    for module in model.modules():
        if (
            bool(getattr(module, "fold_batch_norm", False))
            and hasattr(module, "switch_bn_to_running_stats")
            and callable(module.switch_bn_to_running_stats)
        ):
            module.switch_bn_to_running_stats()
            switched += 1
    return switched


def freeze_folded_batch_norm_stats(model: nn.Module) -> int:
    return freeze_folded_batch_norm_running_stats(model)


def freeze_folded_batch_norm_running_stats(model: nn.Module) -> int:
    """
    Freeze running-stat updates only for fused Conv+BN modules with BN folding enabled.

    This leaves standalone/non-folded BatchNorm modules under normal train/eval
    control. Use ``switch_folded_batch_norm_to_running_stats`` separately to
    switch folded QAT paths away from batch-stat correction.
    """
    frozen = 0
    for module in model.modules():
        if (
            bool(getattr(module, "fold_batch_norm", False))
            and hasattr(module, "freeze_bn_running_stats_")
            and callable(module.freeze_bn_running_stats_)
        ):
            module.freeze_bn_running_stats_()
            frozen += 1
    return frozen
