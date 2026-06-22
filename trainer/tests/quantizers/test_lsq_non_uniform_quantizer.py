import torch

from hatorch.quantizers.autograd.lsq_step_driven_quantizer import LsqStepDrivenQuantizer
from hatorch.quantizers.init.non_uniform_sigmoid_staircase import NonUniformSigmoidStaircaseQuantizer
from hatorch.quantizers.init.step_driven import StepDrivenQuantizer


RSCM4_CODEBOOK = torch.tensor(
    [-20, -13, -8, -6, -5, -3, -2, -1, 0, 1, 2, 4, 5, 7, 12, 19],
    dtype=torch.float,
)


def test_step_driven_forward_uses_midpoint_threshold_lookup():
    x = torch.tensor([-4.9, -2.1, 0.4, 3.8], dtype=torch.float32)
    scale = torch.tensor(1.0, dtype=torch.float32, requires_grad=True)
    targets = torch.tensor([-5.0, -2.0, 1.0, 4.0], dtype=torch.float32)

    y = LsqStepDrivenQuantizer.apply(x, scale, targets, -8, 7)

    assert torch.equal(y, torch.tensor([-5.0, -2.0, 1.0, 4.0]))


def test_step_driven_quantizer_initializes_scale_from_fixed_codebook():
    quantizer = StepDrivenQuantizer(
        is_activation=False,
        bit_width=RSCM4_CODEBOOK,
    )
    x = torch.tensor([-0.06, -0.02, 0.01, 0.05], dtype=torch.float32)

    quantizer(x)

    assert quantizer.current_scale().item() < 0.01
    assert torch.equal(quantizer.scale, quantizer.current_scale())
    assert torch.equal(quantizer.bit_width, RSCM4_CODEBOOK)


def test_step_driven_quantizer_computes_lsq_g_normalization():
    codebook = torch.tensor([-2.0, -1.0, 0.0, 1.0, 2.0])
    quantizer = StepDrivenQuantizer(
        is_activation=False,
        bit_width=codebook,
    )
    x = torch.tensor([-1.5, -0.5, 0.5, 1.5], dtype=torch.float32)

    quantizer(x)

    expected = torch.tensor(1.0 / (x.numel() * 2) ** 0.5)
    assert quantizer.auto_compute_g is True
    assert torch.allclose(quantizer.g, expected)


def test_step_driven_quantizer_applies_lsq_g_to_scale_gradient():
    codebook = torch.tensor([-2.0, -1.0, 0.0, 1.0, 2.0])
    quantizer = StepDrivenQuantizer(
        is_activation=False,
        bit_width=codebook,
        g=0.5,
    )
    with torch.no_grad():
        quantizer.scale.fill_(1.0)
        quantizer._scale_initialized.fill_(True)
        quantizer.is_initialized.fill_(True)
    x = torch.tensor([-3.0, -0.5, 0.5, 1.5], dtype=torch.float32)

    quantized = quantizer(x)
    dequantized = quantized.value * quantized.scale
    dequantized.sum().backward()

    unscaled_step_grad = torch.tensor([-2.0, -0.5, -0.5, -0.5]).sum()
    expected = unscaled_step_grad * 0.5
    assert torch.allclose(quantizer.scale.grad, expected, atol=1e-6)


def test_sigmoid_staircase_weight_quantizer_does_not_apply_lsq_g_normalization():
    quantizer = NonUniformSigmoidStaircaseQuantizer(
        is_activation=False,
        bit_width=torch.tensor([-2.0, -1.0, 0.0, 1.0, 2.0]),
        g=0.0,
        tau=1.0,
    )
    with torch.no_grad():
        quantizer.scale.fill_(0.0)
        quantizer._scale_initialized.fill_(True)
        quantizer.is_initialized.fill_(True)
    x = torch.tensor([-1.5, -0.5, 0.5, 1.5], dtype=torch.float32)

    quantized = quantizer(x)
    dequantized = quantized.value * quantized.scale
    dequantized.sum().backward()

    assert quantizer.auto_compute_g is False
    assert torch.equal(quantizer.g, torch.tensor(0.0))
    assert quantizer.scale.grad is not None
    assert not torch.allclose(quantizer.scale.grad, torch.zeros_like(quantizer.scale.grad))
