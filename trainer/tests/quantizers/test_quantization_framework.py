import torch
import torch.nn as nn

from hatorch.layers.quantized_linear import QuantLinear
from hatorch.layers.quantized_tensor import QuantTensor
from hatorch.layers.quantized_conv2d import QuantConv2d
from hatorch.quantizers.base import BaseQuantizer, IdentityQuantizer
from init.lsq_uniform import LsqUniformQuantizer
from hatorch.transforms import utils as transforms_utils
from hatorch.transforms.config import LayerQuantConfig, ModelQuantConfig, QuantizerSpec, uniform_8bit_config


def test_identity_quantizer_passes_through():
    quantizer = IdentityQuantizer()
    x = torch.randn(10, 10)

    y = quantizer(x)

    assert isinstance(y, QuantTensor)
    assert torch.allclose(x, y.value)
    assert y.scale == 1.0


def test_lsq_uniform_quantizer_forward_initializes_on_first_use():
    quantizer = LsqUniformQuantizer(bit_width=8, signed=True, symmetric=True)
    x = torch.randn(10, 10)

    y = quantizer(x)

    assert isinstance(y, QuantTensor)
    assert y.value.shape == x.shape
    assert quantizer._scale_initialized.item() is True
    assert quantizer.is_initialized.item() is True


def test_quantizer_spec_creates_uniform_quantizer():
    spec = QuantizerSpec(
        quantizer_class=LsqUniformQuantizer,
        is_activation=False,
        symmetric=True,
        per_channel=False,
        kwargs={"bit_width": 8, "signed": True},
    )

    quantizer = spec.create_quantizer()

    assert isinstance(quantizer, LsqUniformQuantizer)
    assert quantizer.bit_width == 8


def test_uniform_8bit_config_uses_uniform_quantizers():
    config = uniform_8bit_config(
        quantize_weights=True,
        quantize_activations=True,
        quantize_bias=False,
    )

    assert config.weight_quantizer is not None
    assert config.activation_quantizer is not None
    assert config.weight_quantizer.quantizer_class is LsqUniformQuantizer
    assert config.activation_quantizer.quantizer_class is LsqUniformQuantizer
    assert config.bias_quantizer is None


def test_quant_conv2d_creation():
    layer = QuantConv2d(
        in_channels=3,
        out_channels=64,
        kernel_size=3,
        weight_quantizer=IdentityQuantizer(),
        activation_quantizer=IdentityQuantizer(),
    )

    assert layer.in_channels == 3
    assert layer.out_channels == 64
    assert layer.weight.shape == (64, 3, 3, 3)


def test_quant_linear_forward():
    layer = QuantLinear(
        in_features=128,
        out_features=10,
        bias=False,
        weight_quantizer=IdentityQuantizer(),
        activation_quantizer=IdentityQuantizer(),
    )

    x = torch.randn(4, 128)
    y = layer(x)

    assert y.shape == (4, 10)


def test_quantize_model_replaces_conv_and_linear_layers():
    model = nn.Sequential(
        nn.Conv2d(3, 64, kernel_size=3),
        nn.ReLU(),
        nn.Flatten(),
        nn.Linear(64 * 30 * 30, 10),
    )
    layer_config = uniform_8bit_config()
    model_config = ModelQuantConfig(default_config=layer_config)

    quant_model = transforms_utils.quantize_model(model, model_config, inplace=False)

    assert sum(isinstance(module, QuantConv2d) for module in quant_model.modules()) == 1
    assert sum(isinstance(module, QuantLinear) for module in quant_model.modules()) == 1


def test_set_quantizers_to_mode_updates_state():
    quantizer = LsqUniformQuantizer(bit_width=8)
    model = nn.Sequential(quantizer)

    transforms_utils.set_quantizers_to_mode(model, "calibration")
    assert quantizer.calibration_mode is True
    assert quantizer.enabled is True

    transforms_utils.set_quantizers_to_mode(model, "training")
    assert quantizer.calibration_mode is False
    assert quantizer.enabled is True

    transforms_utils.set_quantizers_to_mode(model, "disable")
    assert quantizer.enabled is False


def test_training_mode_keeps_lsq_activation_scales_trainable():
    activation_quantizer = LsqUniformQuantizer(
        is_activation=True,
        bit_width=3,
        signed=False,
        symmetric=False,
    )
    weight_quantizer = LsqUniformQuantizer(
        is_activation=False,
        bit_width=3,
        signed=True,
        symmetric=True,
    )
    model = nn.Sequential(activation_quantizer, weight_quantizer)

    transforms_utils.set_quantizers_to_mode(model, "calibration")
    assert activation_quantizer.scale.requires_grad is True
    assert activation_quantizer.zero_point.requires_grad is True
    assert weight_quantizer.scale.requires_grad is False

    transforms_utils.set_quantizers_to_mode(model, "training")
    assert activation_quantizer.scale.requires_grad is True
    assert activation_quantizer.zero_point.requires_grad is True
    assert weight_quantizer.scale.requires_grad is True


def test_end_to_end_quantized_model_trains_one_step():
    model = nn.Sequential(
        nn.Conv2d(3, 16, kernel_size=3, padding=1, bias=False),
        nn.Conv2d(16, 32, kernel_size=3, padding=1, bias=False),
    )
    layer_config = uniform_8bit_config()
    model_config = ModelQuantConfig(default_config=layer_config)
    quant_model = transforms_utils.quantize_model(model, model_config, inplace=False)

    test_input = torch.randn(1, 3, 32, 32)
    output = quant_model(test_input)

    assert output.shape == (1, 32, 32, 32)

    quant_model.train()
    optimizer = torch.optim.Adam(quant_model.parameters(), lr=0.001)
    criterion = nn.MSELoss()

    batch = torch.randn(2, 3, 32, 32)
    target = torch.randn(2, 32, 32, 32)

    optimizer.zero_grad()
    output = quant_model(batch)
    loss = criterion(output, target)
    loss.backward()
    optimizer.step()

    assert not torch.isnan(loss)


def test_quantize_model_exposes_quantizers_as_base_quantizer_modules():
    model = nn.Sequential(nn.Conv2d(3, 8, kernel_size=3, padding=1), nn.ReLU())
    config = ModelQuantConfig(default_config=LayerQuantConfig(weight_quantizer=uniform_8bit_config().weight_quantizer))

    quant_model = transforms_utils.quantize_model(model, config, inplace=False)

    assert any(isinstance(module, BaseQuantizer) for module in quant_model.modules())
