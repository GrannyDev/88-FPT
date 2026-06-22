"""
Configuration classes for quantization.

This module provides configuration classes to specify which quantizers
should be used for different components (weights, activations, bias) in quantized layers.
"""

import inspect
import ast
from enum import Enum
from pathlib import Path
from typing import Optional, Type, Dict, Any
from dataclasses import dataclass, field
import copy

from torch import Tensor

from hatorch.utils.logger import logger
from hatorch.quantizers.common.scale_approximation import ScaleApproximation
from hatorch.quantizers.common.uniform_rounding import UniformRoundingMode
from hatorch.quantizers.init.lsq_uniform import LsqUniformQuantizer
from hatorch.quantizers.init.non_uniform_sigmoid_staircase import NonUniformSigmoidStaircaseQuantizer
from hatorch.quantizers.init.step_driven import StepDrivenQuantizer
from hatorch.quantizers.bias.bias_quantizer import BiasQuantizer


class WeightQuantizerKind(Enum):
    UNIFORM = "uniform"
    STEP_DRIVEN = "step_driven"
    NON_UNIFORM_SIGMOID_STAIRCASE = "non_uniform_sigmoid_staircase"


class AutosetObjective(Enum):
    OUTPUT_MSE = "output_mse"
    FISHER_WEIGHTED_OUTPUT_MSE = "fisher_weighted_output_mse"


@dataclass(frozen=True)
class WeightQuantizerConfig:
    kind: WeightQuantizerKind = WeightQuantizerKind.UNIFORM
    autoset: bool = False
    coefficients: int | None = None
    autoset_path: str | None = None
    autoset_batches: int = 1
    autoset_max_candidates: int | None = None
    autoset_objective: AutosetObjective = AutosetObjective.OUTPUT_MSE

    def __post_init__(self):
        object.__setattr__(self, "kind", WeightQuantizerKind(self.kind))
        object.__setattr__(self, "autoset_objective", AutosetObjective(self.autoset_objective))
        if self.autoset:
            if self.kind == WeightQuantizerKind.UNIFORM:
                raise ValueError("autoset is only valid for non-uniform weight quantizers.")
            if self.coefficients is None or self.coefficients < 2:
                raise ValueError("autoset requires coefficients >= 2.")
            if not self.autoset_path:
                raise ValueError("autoset requires autoset_path.")
            if self.autoset_batches < 1:
                raise ValueError("autoset_batches must be >= 1.")
            if self.autoset_max_candidates is not None and self.autoset_max_candidates < 1:
                raise ValueError("autoset_max_candidates must be >= 1 when provided.")


def _normalize_weight_quantizer_config(
    weight_quantizer_kind: WeightQuantizerKind | WeightQuantizerConfig,
) -> WeightQuantizerConfig:
    if isinstance(weight_quantizer_kind, WeightQuantizerConfig):
        return weight_quantizer_kind
    return WeightQuantizerConfig(kind=WeightQuantizerKind(weight_quantizer_kind))


def _resolve_codebook_path(path: str) -> Path:
    requested_path = Path(path).expanduser()
    search_paths = [requested_path]
    if not requested_path.is_absolute():
        search_paths.append(Path.cwd() / requested_path)

    repo_root = Path(__file__).resolve().parents[3]
    search_paths.extend(
        [
            repo_root / "sets" / requested_path.name,
            repo_root / "examples" / "sets" / requested_path.name,
        ]
    )

    for candidate_path in search_paths:
        if candidate_path.is_file():
            return candidate_path

    searched = ", ".join(str(candidate_path) for candidate_path in search_paths)
    raise FileNotFoundError(f"Could not find codebook candidate file {path!r}. Searched: {searched}")


def load_codebook_candidates(path: str, coefficients: int | None = None) -> list[Tensor]:
    resolved_path = _resolve_codebook_path(path)
    candidates: list[Tensor] = []
    with resolved_path.open("r", encoding="utf-8") as handle:
        for line_number, raw_line in enumerate(handle, start=1):
            line = raw_line.strip()
            if not line:
                continue
            values = ast.literal_eval(line)
            candidate = Tensor(values).float()
            if coefficients is not None and candidate.numel() != coefficients:
                raise ValueError(
                    f"{resolved_path}:{line_number}: expected {coefficients} coefficients, got {candidate.numel()}."
                )
            candidates.append(candidate)
    if not candidates:
        raise ValueError(f"No codebook candidates found in {resolved_path}.")
    return candidates


@dataclass(frozen=True)
class SigmoidStaircaseConfig:
    start_value: float = 1.0
    end_value: float = 16.0
    start_epoch: int = 1
    end_epoch: int = 1
    learnable_thresholds: bool = False

    def __post_init__(self):
        if self.start_value <= 0 or self.end_value <= 0:
            raise ValueError("Sigmoid staircase tau values must be > 0.")
        if self.start_epoch < 1 or self.end_epoch < 1:
            raise ValueError("Sigmoid staircase tau epochs must be >= 1.")
        if self.end_epoch < self.start_epoch:
            raise ValueError("sigmoid staircase tau end_epoch must be >= start_epoch.")

    def value_at_epoch(self, epoch: int) -> float:
        epoch = int(epoch)
        if epoch <= self.start_epoch:
            return float(self.start_value)
        if epoch >= self.end_epoch:
            return float(self.end_value)
        progress = (epoch - self.start_epoch) / (self.end_epoch - self.start_epoch)
        return float(self.start_value + progress * (self.end_value - self.start_value))


SigmoidStaircaseTauSchedule = SigmoidStaircaseConfig


@dataclass(frozen=True)
class WeightQuantization:
    """User-facing weight quantization intent."""
    kind: WeightQuantizerKind = WeightQuantizerKind.UNIFORM
    value: int | Tensor = 8
    per_channel: bool = False
    autoset: WeightQuantizerConfig | None = None
    sigmoid_staircase: SigmoidStaircaseConfig | None = None

    def __post_init__(self):
        object.__setattr__(self, "kind", WeightQuantizerKind(self.kind))
        if self.kind == WeightQuantizerKind.UNIFORM and isinstance(self.value, Tensor):
            raise ValueError("Uniform weight quantization requires an integer bit width.")
        if self.kind != WeightQuantizerKind.UNIFORM and not isinstance(self.value, Tensor) and self.autoset is None:
            raise ValueError("Non-uniform weight quantization requires a Tensor codebook or autoset.")
        if self.autoset is not None and self.autoset.kind != self.kind:
            raise ValueError("Weight autoset kind must match the weight quantizer kind.")
        if self.sigmoid_staircase is not None and self.kind != WeightQuantizerKind.NON_UNIFORM_SIGMOID_STAIRCASE:
            raise ValueError("sigmoid_staircase is only valid for NON_UNIFORM_SIGMOID_STAIRCASE weights.")

    @classmethod
    def uniform(cls, bits: int, per_channel: bool = False) -> "WeightQuantization":
        return cls(kind=WeightQuantizerKind.UNIFORM, value=int(bits), per_channel=per_channel)

    @classmethod
    def codebook(
        cls,
        codebook: Tensor,
        kind: WeightQuantizerKind,
        per_channel: bool = False,
        sigmoid_staircase: SigmoidStaircaseConfig | None = None,
    ) -> "WeightQuantization":
        return cls(
            kind=kind,
            value=codebook,
            per_channel=per_channel,
            sigmoid_staircase=sigmoid_staircase,
        )

    @classmethod
    def autoset_codebook(
        cls,
        path: str,
        coefficients: int,
        kind: WeightQuantizerKind,
        initial_codebook: Tensor | None = None,
        per_channel: bool = False,
        batches: int = 1,
        max_candidates: int | None = None,
        objective: AutosetObjective = AutosetObjective.OUTPUT_MSE,
        sigmoid_staircase: SigmoidStaircaseConfig | None = None,
    ) -> "WeightQuantization":
        if initial_codebook is not None and initial_codebook.numel() != coefficients:
            raise ValueError(
                "initial_codebook must contain exactly "
                f"{coefficients} coefficients, got {initial_codebook.numel()}."
            )
        return cls(
            kind=kind,
            value=initial_codebook if initial_codebook is not None else coefficients,
            per_channel=per_channel,
            autoset=WeightQuantizerConfig(
                kind=kind,
                autoset=True,
                coefficients=coefficients,
                autoset_path=path,
                autoset_batches=batches,
                autoset_max_candidates=max_candidates,
                autoset_objective=objective,
            ),
            sigmoid_staircase=sigmoid_staircase,
        )

    @property
    def quantizer_config(self) -> WeightQuantizerConfig:
        return self.autoset or WeightQuantizerConfig(kind=self.kind)


@dataclass(frozen=True)
class ActivationQuantization:
    """User-facing activation quantization intent."""
    bits: int = 8
    affine_zero_point: bool = False
    rounding: UniformRoundingMode = UniformRoundingMode.ROUND

    def __post_init__(self):
        if self.bits < 1:
            raise ValueError("Activation bit width must be >= 1.")
        object.__setattr__(self, "rounding", UniformRoundingMode(self.rounding))


@dataclass(frozen=True)
class BiasQuantization:
    """Bias quantization precision."""
    bits: int = 32

    def __post_init__(self):
        if self.bits < 1:
            raise ValueError("Bias bit width must be >= 1.")


@dataclass(frozen=True)
class BoundaryQuantization:
    """Precision overrides for input/output deployment boundaries."""
    first_weight_bits: int | None = None
    input_activation_bits: int | None = None
    last_weight_bits: int | None = None
    output_activation_bits: int | None = None


@dataclass(frozen=True)
class ScalePolicy:
    """Deployment-scale approximation and freezing policy."""
    approximation: ScaleApproximation = ScaleApproximation.NONE
    start_epoch: int = 1
    fixed_point_bits: int = 32
    freeze_approximated_scales: bool = False

    def __post_init__(self):
        object.__setattr__(self, "approximation", ScaleApproximation(self.approximation))
        if self.start_epoch < 1:
            raise ValueError("Scale approximation start_epoch must be >= 1.")
        if self.fixed_point_bits < 1:
            raise ValueError("fixed_point_bits must be >= 1.")


@dataclass(frozen=True)
class TransformPolicy:
    """Model transform options that affect quantized layer construction."""
    fold_batch_norm: bool = True
    round_average_pool_output: bool = False


@dataclass(frozen=True)
class QuantizationRecipe:
    """High-level quantization recipe that lowers to ModelQuantConfig."""
    weights: WeightQuantization = field(default_factory=WeightQuantization)
    activations: ActivationQuantization = field(default_factory=ActivationQuantization)
    bias: BiasQuantization = field(default_factory=BiasQuantization)
    boundaries: BoundaryQuantization = field(default_factory=BoundaryQuantization)
    scale: ScalePolicy = field(default_factory=ScalePolicy)
    transforms: TransformPolicy = field(default_factory=TransformPolicy)

    def build(self) -> "ModelQuantConfig":
        return create_model_config_with_edge_layers(
            default_weight_bits=self.weights.value,
            default_activation_bits=self.activations.bits,
            first_layer_weight_bits=self.boundaries.first_weight_bits,
            first_layer_activation_bits=self.boundaries.input_activation_bits,
            last_layer_weight_bits=self.boundaries.last_weight_bits,
            last_layer_activation_bits=self.boundaries.output_activation_bits,
            bias_bits=self.bias.bits,
            affine_activations=self.activations.affine_zero_point,
            per_channel_weights=self.weights.per_channel,
            scale_approximation=self.scale.approximation,
            scale_approximation_start_epoch=self.scale.start_epoch,
            freeze_approximated_scales=self.scale.freeze_approximated_scales,
            fixed_point_bits=self.scale.fixed_point_bits,
            activation_rounding_mode=self.activations.rounding,
            weight_quantizer_kind=self.weights.quantizer_config,
            sigmoid_staircase_config=self.weights.sigmoid_staircase,
            fold_batch_norm=self.transforms.fold_batch_norm,
            round_average_pool_output=self.transforms.round_average_pool_output,
        )


@dataclass
class QuantizerSpec:
    """
    Specification for a quantizer instance.

    Attributes:
        quantizer_class: The quantizer class to instantiate
        is_activation: Whether this quantizer is for activations (True) or weights (False)
        symmetric: Whether to use symmetric quantization around zero
        per_channel: Whether to use per-channel quantization
        kwargs: Additional keyword arguments to pass to the quantizer constructor
    """
    quantizer_class: Type
    is_activation: bool
    symmetric: bool
    per_channel: bool
    kwargs: Dict[str, Any] = field(default_factory=dict)

    def __post_init__(self):
        """Validate the quantizer specification."""
        if self.is_activation:
            if not issubclass(self.quantizer_class, LsqUniformQuantizer):
                raise ValueError("Activations can only use LsqUniformQuantizer.")
            if self.per_channel:
                logger.warning(
                    "Per-channel quantization is unsupported for activations. This will be ignored.")
                self.per_channel = False
        else:
            if not self.symmetric:
                logger.warning(
                    "Asymmetric quantization for weights is unsupported by the lowering process. This will be ignored.")
                self.symmetric = True

    def create_quantizer(self, num_channels: Optional[int] = None):
        """
        Create an instance of the quantizer.

        Returns:
            Instantiated quantizer
        """

        # Deep copy kwargs to avoid sharing mutable objects (like observers) between quantizers
        kwargs_copy = copy.deepcopy(self.kwargs)
        signature = inspect.signature(self.quantizer_class.__init__)
        accepts_var_kwargs = any(
            parameter.kind == inspect.Parameter.VAR_KEYWORD
            for parameter in signature.parameters.values()
        )
        if not accepts_var_kwargs:
            kwargs_copy = {
                key: value
                for key, value in kwargs_copy.items()
                if key in signature.parameters
            }
        return self.quantizer_class(self.is_activation, self.symmetric, self.per_channel, num_channels, **kwargs_copy)


@dataclass
class LayerQuantConfig:
    """
    Quantization configuration for a single layer.
    
    Specifies which quantizers to use for weights, activations, and bias.
    
    Attributes:
        weight_quantizer: Specification for weight quantizer (None = no quantization)
        activation_quantizer: Specification for activation quantizer (None = no quantization)
        bias_quantizer: Specification for bias quantizer (None = no quantization)
    """
    weight_quantizer: Optional[QuantizerSpec] = None
    activation_quantizer: Optional[QuantizerSpec] = None
    bias_quantizer: Optional[BiasQuantizer] = None
    
    def __post_init__(self):
        """Validate configuration."""
        # Ensure specs are QuantizerSpec instances or None
        if self.weight_quantizer is not None and not isinstance(self.weight_quantizer, QuantizerSpec):
            raise TypeError("weight_quantizer must be a QuantizerSpec or None")
        if self.activation_quantizer is not None and not isinstance(self.activation_quantizer, QuantizerSpec):
            raise TypeError("activation_quantizer must be a QuantizerSpec or None")
        if self.bias_quantizer is not None and not isinstance(self.bias_quantizer, BiasQuantizer):
            raise TypeError("bias_quantizer must be a BiasQuantizer or None")


@dataclass
class ModelQuantConfig:
    """
    Quantization configuration for an entire model.
    
    Provides default quantization settings and per-layer overrides.
    
    Attributes:
        default_config: Default configuration for all layers
        layer_configs: Dictionary mapping layer names to specific configurations
        first_layer_config: Optional configuration specifically for the first quantized layer
        last_layer_config: Optional configuration specifically for the last quantized layer
        first_layer_symmetric_activation: Whether first layer activation should be symmetric (default: True)
        scale_approximation: Scale approximation method (NONE, POWER_OF_TWO, FIXED_POINT)
        fixed_point_bits: Number of fractional bits for fixed-point approximation
        fold_batch_norm: Whether to fold BN into conv during QAT (default: True)
        freeze_approximated_scales: Whether LSQ scales should be frozen when
            scale approximation is enabled for them.
    """
    default_config: LayerQuantConfig
    layer_configs: Dict[str, LayerQuantConfig] = field(default_factory=dict)
    first_layer_config: Optional[LayerQuantConfig] = None
    last_layer_config: Optional[LayerQuantConfig] = None
    first_layer_symmetric_activation: bool = True
    scale_approximation: ScaleApproximation = ScaleApproximation.NONE
    fixed_point_bits: int = 32
    fold_batch_norm: bool = True
    round_average_pool_output: bool = False
    target_scale_approximation: Optional[ScaleApproximation] = None
    scale_approximation_start_epoch: int = 1
    freeze_approximated_scales: bool = False
    sigmoid_staircase_config: Optional[SigmoidStaircaseConfig] = None
    weight_quantizer_config: WeightQuantizerConfig = field(default_factory=WeightQuantizerConfig)
    
    def get_config_for_layer(self, layer_name: str, is_first_layer: bool = False, is_last_layer: bool = False) -> LayerQuantConfig:
        """
        Get quantization configuration for a specific layer.
        
        Args:
            layer_name: Name/identifier of the layer
            is_first_layer: Whether this is the first quantized layer
            is_last_layer: Whether this is the last quantized layer
            
        Returns:
            LayerQuantConfig for the specified layer (falls back to default if not specified)
        """
        import copy
        
        # Priority: layer_configs > first/last_layer_config > default_config
        if layer_name in self.layer_configs:
            base_config = self.layer_configs[layer_name]
        elif is_last_layer and self.last_layer_config is not None:
            base_config = self.last_layer_config
        elif is_first_layer and self.first_layer_config is not None:
            base_config = self.first_layer_config
        else:
            base_config = self.default_config
        
        # Dataset/input quantization is an external deployment boundary:
        # keep its rounding independent from the network activation policy.
        if is_first_layer and base_config.activation_quantizer is not None:
            # Deep copy to avoid modifying the original
            config = copy.deepcopy(base_config)
            # Modify activation quantizer to be signed
            if is_first_layer and self.first_layer_symmetric_activation and 'signed' in config.activation_quantizer.kwargs:
                config.activation_quantizer.kwargs['signed'] = True
            if 'rounding_mode' in config.activation_quantizer.kwargs:
                config.activation_quantizer.kwargs['rounding_mode'] = UniformRoundingMode.ROUND
            return config
        
        return base_config


# Convenience functions for common configurations

def uniform_8bit_config(
    quantize_weights: bool = True,
    quantize_activations: bool = True,
    quantize_bias: bool = False,
    affine_activations: bool = True,
    per_channel_weights: bool = False,
) -> LayerQuantConfig:
    """
    Create a configuration for uniform 8-bit quantization.
    
    Args:
        quantize_weights: Whether to quantize weights
        quantize_activations: Whether to quantize activations
        quantize_bias: Whether to quantize bias
        affine_activations: Whether activations are affine (affects symmetry)
        per_channel_weights: Whether to use per-channel quantization for weights
        
    Returns:
        LayerQuantConfig with 8-bit LSQ quantizers
    """

    weight_spec = None
    if quantize_weights:
        weight_spec = QuantizerSpec(
            quantizer_class=LsqUniformQuantizer,
            is_activation=False,
            symmetric=True,
            per_channel=per_channel_weights,
            kwargs={
                'bit_width': 8,
                'signed': True,
            }
        )

    activation_spec = None
    if quantize_activations:
        activation_spec = QuantizerSpec(
            quantizer_class=LsqUniformQuantizer,
            is_activation=True,
            symmetric=not affine_activations,
            per_channel=False,
            kwargs={
                'bit_width': 8,
                'signed': False,
            }
        )

    bias_spec = None
    if quantize_bias:
        bias_spec = BiasQuantizer(bit_width=32, signed=True, enabled=True)

    return LayerQuantConfig(
        weight_quantizer=weight_spec,
        activation_quantizer=activation_spec,
        bias_quantizer=bias_spec,
    )


def mixed_precision_config(
    weight_bits: int | Tensor = 8,
    activation_bits: int = 8,
    bias_bits: int = 32,
    affine_activations: bool = True,
    per_channel_weights: bool = False,
    scale_approximation: ScaleApproximation = ScaleApproximation.NONE,
    fixed_point_bits: int = 8,
    activation_rounding_mode: UniformRoundingMode = UniformRoundingMode.ROUND,
    weight_quantizer_kind: WeightQuantizerKind | WeightQuantizerConfig = WeightQuantizerKind.UNIFORM,
    sigmoid_staircase_tau: float = 1.0,
    sigmoid_staircase_learnable_thresholds: bool = False,
) -> LayerQuantConfig:
    """
    Create a mixed-precision quantization configuration.
    
    Args:
        weight_bits: Integer bit width for uniform quantization, or tensor codebook
            targets for step-driven non-uniform quantization.
        activation_bits: Bit width for activations
        bias_bits: Bit width for bias
        affine_activations: Whether activations are affine (affects symmetry)
        per_channel_weights: Whether to use per-channel quantization for weights
        scale_approximation: Scale approximation method (NONE, POWER_OF_TWO, FIXED_POINT)
        fixed_point_bits: Number of fractional bits for fixed-point approximation
        activation_rounding_mode: Uniform activation rounding used during training
        weight_quantizer_kind: Which weight quantizer implementation to instantiate
        sigmoid_staircase_tau: Initial tau for NON_UNIFORM_SIGMOID_STAIRCASE
        sigmoid_staircase_learnable_thresholds: Whether sigmoid staircase bin
            thresholds are trainable.

    Returns:
        LayerQuantConfig with specified bit widths
    """
    weight_quantizer_config = _normalize_weight_quantizer_config(weight_quantizer_kind)
    weight_quantizer_kind = weight_quantizer_config.kind
    if weight_quantizer_config.autoset and not isinstance(weight_bits, Tensor):
        weight_bits = load_codebook_candidates(
            weight_quantizer_config.autoset_path,
            weight_quantizer_config.coefficients,
        )[0]
    uses_tensor_codebook = isinstance(weight_bits, Tensor)

    if weight_quantizer_kind == WeightQuantizerKind.UNIFORM:
        if uses_tensor_codebook:
            raise ValueError("WeightQuantizerKind.UNIFORM requires integer weight_bits, not a Tensor codebook.")
        weight_quantizer_class = LsqUniformQuantizer
        weight_kwargs = {
            'bit_width': int(weight_bits),
            'signed': True,
            'scale_approximation': scale_approximation,
            'fixed_point_bits': fixed_point_bits,
        }
    elif weight_quantizer_kind == WeightQuantizerKind.STEP_DRIVEN:
        if not uses_tensor_codebook:
            raise ValueError("WeightQuantizerKind.STEP_DRIVEN requires weight_bits to be a Tensor codebook.")
        weight_quantizer_class = StepDrivenQuantizer
        weight_kwargs = {
            'bit_width': weight_bits,
            'signed': True,
            'scale_approximation': scale_approximation,
            'fixed_point_bits': fixed_point_bits,
        }
    elif weight_quantizer_kind == WeightQuantizerKind.NON_UNIFORM_SIGMOID_STAIRCASE:
        if not uses_tensor_codebook:
            raise ValueError("WeightQuantizerKind.NON_UNIFORM_SIGMOID_STAIRCASE requires weight_bits to be a Tensor codebook.")
        weight_quantizer_class = NonUniformSigmoidStaircaseQuantizer
        weight_kwargs = {
            'bit_width': weight_bits,
            'signed': True,
            'scale_approximation': scale_approximation,
            'fixed_point_bits': fixed_point_bits,
            'tau': sigmoid_staircase_tau,
            'learnable_thresholds': sigmoid_staircase_learnable_thresholds,
        }
    else:
        raise ValueError(f"Unsupported weight_quantizer_kind: {weight_quantizer_kind}")

    weight_spec = QuantizerSpec(
        quantizer_class=weight_quantizer_class,
        is_activation=False,
        symmetric=True,
        per_channel=per_channel_weights,
        kwargs=weight_kwargs
    )
    
    activation_spec = QuantizerSpec(
        quantizer_class=LsqUniformQuantizer,
        is_activation=True,
        symmetric=not affine_activations,
        per_channel=False,
        kwargs={
            'bit_width': activation_bits,
            'signed': False,
            'scale_approximation': scale_approximation,
            'fixed_point_bits': fixed_point_bits,
            'rounding_mode': activation_rounding_mode,
        }
    )
    
    bias_quantizer = BiasQuantizer(bit_width=bias_bits, signed=True, enabled=True)
    
    return LayerQuantConfig(
        weight_quantizer=weight_spec,
        activation_quantizer=activation_spec,
        bias_quantizer=bias_quantizer,
    )


def create_model_config_with_edge_layers(
    default_weight_bits: int | Tensor = 8,
    default_activation_bits: int | Tensor = 8,
    first_layer_weight_bits: int | Tensor | None = None,
    first_layer_activation_bits: int = None,
    last_layer_weight_bits: int | Tensor | None = None,
    last_layer_activation_bits: int = None,
    bias_bits: int = 32,
    affine_activations: bool = True,
    per_channel_weights: bool = False,
    scale_approximation: ScaleApproximation = ScaleApproximation.NONE,
    scale_approximation_start_epoch: int = 1,
    freeze_approximated_scales: bool = False,
    fixed_point_bits: int = 8,
    activation_rounding_mode: UniformRoundingMode = UniformRoundingMode.ROUND,
    weight_quantizer_kind: WeightQuantizerKind | WeightQuantizerConfig = WeightQuantizerKind.UNIFORM,
    sigmoid_staircase_config: SigmoidStaircaseConfig | None = None,
    fold_batch_norm: bool = True,
    round_average_pool_output: bool = False,
) -> ModelQuantConfig:
    """
    Create a ModelQuantConfig with separate bit widths for first and last layers.
    
    This is a convenience function to easily configure different quantization
    bit widths for the first layer (typically higher precision for input features)
    and last layer (typically higher precision for classification logits).
    
    Args:
        default_weight_bits: Integer bit width for uniform quantization, or tensor
            codebook targets for step-driven non-uniform quantization.
        default_activation_bits: Bit width for activations in middle layers
        first_layer_weight_bits: Uniform weight bit width for first layer (None = use default)
        first_layer_activation_bits: Bit width for first layer activations (None = use default)
        last_layer_weight_bits: Uniform weight bit width for last layer (None = use default)
        last_layer_activation_bits: Bit width for last layer activations (None = use default)
        bias_bits: Bit width for bias terms (typically high precision)
        affine_activations: Whether activations are affine (affects symmetry)
        per_channel_weights: Whether to use per-channel quantization for weights
        scale_approximation: Scale approximation method (NONE, POWER_OF_TWO, FIXED_POINT)
        scale_approximation_start_epoch: 1-based epoch where scale approximation is enabled.
            Use 1 to enable it from the start. Values greater than 1 instantiate the
            model with exact scales and rely on training epoch callbacks to enable it.
        freeze_approximated_scales: Freeze only LSQ scales that use scale approximation,
            at the same time the approximation is enabled.
        fixed_point_bits: Number of fractional bits for fixed-point approximation
        activation_rounding_mode: ROUND or TRUNC for uniform activation quantizers
        weight_quantizer_kind: Weight quantizer family or WeightQuantizerConfig.
            UNIFORM requires integer weight settings; STEP_DRIVEN and
            NON_UNIFORM_SIGMOID_STAIRCASE require tensor codebook weight settings
            unless WeightQuantizerConfig.autoset provides an autoset file.
        sigmoid_staircase_config: Tau annealing and threshold-learning settings
            for NON_UNIFORM_SIGMOID_STAIRCASE. If omitted, tau stays at 1.0 and
            thresholds stay fixed at midpoint initialization. Tau is a hardness
            multiplier, so larger values are closer to the hard staircase.
        fold_batch_norm: Whether to fold BN into conv during QAT
        round_average_pool_output: Round quantized average-pool outputs to the
            nearest integer-domain value with STE.

    Returns:
        ModelQuantConfig with separate configurations for first, middle, and last layers
        
    Example:
        >>> # 8-bit for most layers, but 6-bit for first layer activations and 4-bit weights elsewhere
        >>> config = create_model_config_with_edge_layers(
        ...     default_weight_bits=4,
        ...     default_activation_bits=8,
        ...     first_layer_activation_bits=6,
        ...     last_layer_weight_bits=8,
        ... )
    """
    if scale_approximation_start_epoch < 1:
        raise ValueError("scale_approximation_start_epoch must be >= 1.")
    weight_quantizer_config = _normalize_weight_quantizer_config(weight_quantizer_kind)
    weight_quantizer_kind = weight_quantizer_config.kind
    if sigmoid_staircase_config is not None and weight_quantizer_kind != WeightQuantizerKind.NON_UNIFORM_SIGMOID_STAIRCASE:
        raise ValueError("sigmoid_staircase_config is only valid with WeightQuantizerKind.NON_UNIFORM_SIGMOID_STAIRCASE.")
    if weight_quantizer_kind == WeightQuantizerKind.NON_UNIFORM_SIGMOID_STAIRCASE and sigmoid_staircase_config is None:
        sigmoid_staircase_config = SigmoidStaircaseConfig(start_value=2.0, end_value=1.0, start_epoch=1, end_epoch=1)
    initial_sigmoid_staircase_tau = (
        sigmoid_staircase_config.value_at_epoch(1)
        if sigmoid_staircase_config is not None
        else 1.0
    )
    sigmoid_staircase_learnable_thresholds = (
        bool(sigmoid_staircase_config.learnable_thresholds)
        if sigmoid_staircase_config is not None
        else False
    )

    initial_scale_approximation = (
        scale_approximation
        if scale_approximation == ScaleApproximation.NONE or scale_approximation_start_epoch == 1
        else ScaleApproximation.NONE
    )

    # Create default config for middle layers
    default_config = mixed_precision_config(
        weight_bits=default_weight_bits,
        activation_bits=default_activation_bits,
        bias_bits=bias_bits,
        affine_activations=affine_activations,
        per_channel_weights=per_channel_weights,
        scale_approximation=initial_scale_approximation,
        fixed_point_bits=fixed_point_bits,
        activation_rounding_mode=activation_rounding_mode,
        weight_quantizer_kind=weight_quantizer_config,
        sigmoid_staircase_tau=initial_sigmoid_staircase_tau,
        sigmoid_staircase_learnable_thresholds=sigmoid_staircase_learnable_thresholds,
    )
    
    def edge_weight_bits_or_default(edge_weight_bits: int | Tensor | None, edge_name: str) -> int | Tensor:
        if isinstance(edge_weight_bits, Tensor):
            raise ValueError(
                f"{edge_name}_layer_weight_bits must be an integer bit width; "
                "edge layer weights are always uniform."
            )
        if edge_weight_bits is not None:
            return edge_weight_bits
        if isinstance(default_weight_bits, Tensor):
            raise ValueError(
                f"{edge_name}_layer_weight_bits must be an integer bit width when "
                "default_weight_bits is a Tensor codebook; edge layer weights are always uniform."
            )
        return default_weight_bits

    # Create first layer config if any edge parameter is specified, or when
    # scale approximation is enabled so the dataset/input scale can stay exact.
    first_layer_config = None
    if (
        first_layer_weight_bits is not None
        or first_layer_activation_bits is not None
        or scale_approximation != ScaleApproximation.NONE
    ):
        first_weight_bits = edge_weight_bits_or_default(first_layer_weight_bits, "first")
        first_layer_config = mixed_precision_config(
            weight_bits=first_weight_bits,
            activation_bits=first_layer_activation_bits if first_layer_activation_bits is not None else default_activation_bits,
            bias_bits=bias_bits,
            affine_activations=affine_activations,
            per_channel_weights=per_channel_weights,
            scale_approximation=initial_scale_approximation,
            fixed_point_bits=fixed_point_bits,
            activation_rounding_mode=activation_rounding_mode,
            weight_quantizer_kind=WeightQuantizerKind.UNIFORM,
        )
        _set_quantizer_spec_scale_approximation(
            first_layer_config.activation_quantizer,
            ScaleApproximation.NONE,
        )
    
    # Create last layer config if any edge parameter is specified, or when
    # scale approximation is enabled so the final output weight scale can stay exact.
    last_layer_config = None
    if (
        last_layer_weight_bits is not None
        or last_layer_activation_bits is not None
        or scale_approximation != ScaleApproximation.NONE
    ):
        last_weight_bits = edge_weight_bits_or_default(last_layer_weight_bits, "last")
        last_layer_config = mixed_precision_config(
            weight_bits=last_weight_bits,
            activation_bits=last_layer_activation_bits if last_layer_activation_bits is not None else default_activation_bits,
            bias_bits=bias_bits,
            affine_activations=affine_activations,
            per_channel_weights=per_channel_weights,
            scale_approximation=initial_scale_approximation,
            fixed_point_bits=fixed_point_bits,
            activation_rounding_mode=activation_rounding_mode,
            weight_quantizer_kind=WeightQuantizerKind.UNIFORM,
        )
        _set_quantizer_spec_scale_approximation(
            last_layer_config.weight_quantizer,
            ScaleApproximation.NONE,
        )
    
    return ModelQuantConfig(
        default_config=default_config,
        first_layer_config=first_layer_config,
        last_layer_config=last_layer_config,
        scale_approximation=initial_scale_approximation,
        fixed_point_bits=fixed_point_bits,
        fold_batch_norm=fold_batch_norm,
        round_average_pool_output=round_average_pool_output,
        target_scale_approximation=scale_approximation,
        scale_approximation_start_epoch=scale_approximation_start_epoch,
        freeze_approximated_scales=freeze_approximated_scales,
        sigmoid_staircase_config=sigmoid_staircase_config,
        weight_quantizer_config=weight_quantizer_config,
    )


def _set_quantizer_spec_scale_approximation(
    spec: Optional[QuantizerSpec],
    scale_approximation: ScaleApproximation,
) -> None:
    if spec is not None and "scale_approximation" in spec.kwargs:
        spec.kwargs["scale_approximation"] = scale_approximation
