import torch
import torch.nn as nn
import pytest

from hatorch.quantizers.common.uniform_rounding import UniformRoundingMode
from hatorch.quantizers.init.lsq_uniform import LsqUniformQuantizer
from hatorch.quantizers.init.non_uniform_sigmoid_staircase import NonUniformSigmoidStaircaseQuantizer
from hatorch.quantizers.init.step_driven import StepDrivenQuantizer
from hatorch.quantizers.common.scale_approximation import ScaleApproximation
from hatorch.transforms.config import (
    ActivationQuantization,
    BoundaryQuantization,
    QuantizationRecipe,
    ScalePolicy,
    TransformPolicy,
    WeightQuantization,
    WeightQuantizerKind,
    load_codebook_candidates,
)
from hatorch.layers.quantized_averagepool2d import QuantAveragePool2d
from hatorch.transforms import utils as transforms_utils


def test_scalar_weight_bits_select_uniform_quantizer():
    config = QuantizationRecipe(
        weights=WeightQuantization.uniform(bits=4),
        activations=ActivationQuantization(bits=8),
    ).build()

    weight_quantizer = config.default_config.weight_quantizer
    assert weight_quantizer.quantizer_class is LsqUniformQuantizer
    assert weight_quantizer.kwargs["bit_width"] == 4


def test_vector_weight_bits_select_step_driven_quantizer():
    codebook = torch.tensor([-8, -4, -1, 0, 1, 4, 7], dtype=torch.float)
    config = QuantizationRecipe(
        weights=WeightQuantization.codebook(
            codebook=codebook,
            kind=WeightQuantizerKind.STEP_DRIVEN,
        ),
        activations=ActivationQuantization(bits=8),
    ).build()

    weight_quantizer = config.default_config.weight_quantizer
    assert weight_quantizer.quantizer_class is StepDrivenQuantizer
    assert torch.equal(weight_quantizer.kwargs["bit_width"], codebook)


def test_autoset_initial_codebook_must_match_coefficients(tmp_path):
    path = tmp_path / "sets.txt"
    path.write_text("[-4, -3, 0, 1, 2, 3, 4, 5]\n", encoding="utf-8")

    with pytest.raises(ValueError, match="initial_codebook must contain exactly 8 coefficients"):
        WeightQuantization.autoset_codebook(
            path=str(path),
            coefficients=8,
            kind=WeightQuantizerKind.NON_UNIFORM_SIGMOID_STAIRCASE,
            initial_codebook=torch.tensor([-2, -1, 0, 1], dtype=torch.float),
        )


def test_codebook_loader_falls_back_to_repo_sets_for_stale_absolute_path():
    candidates = load_codebook_candidates("/stale/machine/path/sets/RSCM4.txt", coefficients=16)

    assert candidates
    assert candidates[0].numel() == 16


def test_step_driven_weights_keep_lsq_g_normalization():
    codebook = torch.tensor([-2, -1, 0, 1, 2], dtype=torch.float)
    config = QuantizationRecipe(
        weights=WeightQuantization.codebook(
            codebook=codebook,
            kind=WeightQuantizerKind.STEP_DRIVEN,
        ),
        activations=ActivationQuantization(bits=3, affine_zero_point=True),
    ).build()
    weight_quantizer = config.default_config.weight_quantizer.create_quantizer()
    weights = torch.tensor([-0.2, -0.1, 0.1, 0.2])

    weight_quantizer(weights)

    assert isinstance(weight_quantizer, StepDrivenQuantizer)
    assert weight_quantizer.auto_compute_g is True
    expected_g = torch.tensor(1.0 / (weights.numel() * 2) ** 0.5)
    assert torch.allclose(weight_quantizer.g, expected_g)


def test_sigmoid_weights_do_not_disable_uniform_activation_lsq_g():
    codebook = torch.tensor([-2, -1, 0, 1, 2], dtype=torch.float)
    config = QuantizationRecipe(
        weights=WeightQuantization.codebook(
            codebook=codebook,
            kind=WeightQuantizerKind.NON_UNIFORM_SIGMOID_STAIRCASE,
        ),
        activations=ActivationQuantization(bits=3, affine_zero_point=True),
    ).build()
    weight_quantizer = config.default_config.weight_quantizer.create_quantizer()
    activation_quantizer = config.default_config.activation_quantizer.create_quantizer()
    activation = torch.linspace(0.0, 1.0, steps=2 * 3 * 4 * 5).reshape(2, 3, 4, 5)

    weight_quantizer(torch.tensor([-0.2, -0.1, 0.1, 0.2]))
    activation_quantizer(activation)

    assert isinstance(weight_quantizer, NonUniformSigmoidStaircaseQuantizer)
    assert weight_quantizer.auto_compute_g is False
    assert torch.equal(weight_quantizer.g, torch.tensor(1.0))
    assert isinstance(activation_quantizer, LsqUniformQuantizer)
    assert activation_quantizer.auto_compute_g is True
    expected_activation_g = torch.tensor(1.0 / (activation.numel() * 7) ** 0.5)
    assert torch.allclose(activation_quantizer.g, expected_activation_g)


def test_scalar_first_layer_override_selects_uniform_quantizer():
    codebook = torch.tensor([-8, -4, -1, 0, 1, 4, 7], dtype=torch.float)
    config = QuantizationRecipe(
        weights=WeightQuantization.codebook(
            codebook=codebook,
            kind=WeightQuantizerKind.STEP_DRIVEN,
        ),
        activations=ActivationQuantization(bits=8),
        boundaries=BoundaryQuantization(first_weight_bits=8),
    ).build()

    default_weight_quantizer = config.default_config.weight_quantizer
    first_weight_quantizer = config.first_layer_config.weight_quantizer

    assert default_weight_quantizer.quantizer_class is StepDrivenQuantizer
    assert first_weight_quantizer.quantizer_class is LsqUniformQuantizer
    assert first_weight_quantizer.kwargs["bit_width"] == 8


def test_input_activation_quantizer_always_uses_rounding():
    config = QuantizationRecipe(
        weights=WeightQuantization.uniform(bits=4),
        activations=ActivationQuantization(bits=4, rounding=UniformRoundingMode.TRUNC),
        boundaries=BoundaryQuantization(input_activation_bits=8, output_activation_bits=8),
    ).build()

    first_config = config.get_config_for_layer("first", is_first_layer=True)
    last_config = config.get_config_for_layer("last", is_last_layer=True)
    default_config = config.get_config_for_layer("middle")

    assert first_config.activation_quantizer.kwargs["rounding_mode"] == UniformRoundingMode.ROUND
    assert last_config.activation_quantizer.kwargs["rounding_mode"] == UniformRoundingMode.TRUNC
    assert default_config.activation_quantizer.kwargs["rounding_mode"] == UniformRoundingMode.TRUNC


def test_last_layer_activation_scale_approximation_is_internal():
    config = QuantizationRecipe(
        weights=WeightQuantization.uniform(bits=4),
        activations=ActivationQuantization(bits=4),
        boundaries=BoundaryQuantization(last_weight_bits=8, output_activation_bits=8),
        scale=ScalePolicy(approximation=ScaleApproximation.POWER_OF_TWO),
    ).build()

    last_config = config.get_config_for_layer("last", is_last_layer=True)

    assert last_config.activation_quantizer.kwargs["scale_approximation"] == ScaleApproximation.POWER_OF_TWO
    assert last_config.weight_quantizer.kwargs["scale_approximation"] == ScaleApproximation.NONE


def test_quantize_model_creates_distinct_bias_quantizers_per_layer():
    model = nn.Sequential(
        nn.Linear(4, 3),
        nn.ReLU(),
        nn.Linear(3, 2),
    )
    config = QuantizationRecipe(
        weights=WeightQuantization.uniform(bits=4),
        activations=ActivationQuantization(bits=4),
    ).build()

    transforms_utils.quantize_model(model, config, inplace=True)

    bias_quantizers = [
        module.bias_quantizer
        for module in model.modules()
        if getattr(module, "bias_quantizer", None) is not None
    ]

    assert len(bias_quantizers) == 2
    assert len({id(quantizer) for quantizer in bias_quantizers}) == len(bias_quantizers)
    assert all(quantizer is not config.default_config.bias_quantizer for quantizer in bias_quantizers)


def test_transform_policy_controls_average_pool_rounding():
    model = nn.Sequential(nn.AvgPool2d(kernel_size=2))
    config = QuantizationRecipe(
        transforms=TransformPolicy(round_average_pool_output=True),
    ).build()

    transforms_utils.quantize_model(model, config, inplace=True)

    average_pools = [module for module in model.modules() if isinstance(module, QuantAveragePool2d)]

    assert len(average_pools) == 1
    assert average_pools[0].round_output is True
