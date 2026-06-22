import torch

from hatorch.quantizers.autograd.lsq_uniform_quantizer import LsqUniformQuantizer
from hatorch.quantizers.init.lsq_uniform import LsqUniformQuantizer as LearnedLsqUniformQuantizer


def test_lsq_uniform_forward_rounds_and_clips():
    x = torch.tensor([-9.0, -1.2, 0.2, 6.6], dtype=torch.float32)
    scale = torch.tensor(1.0, dtype=torch.float32, requires_grad=True)
    zp = torch.tensor(0.0, dtype=torch.float32, requires_grad=True)

    y = LsqUniformQuantizer.apply(x, scale, zp, -4, 3)

    assert torch.equal(y, torch.tensor([-4.0, -1.0, 0.0, 3.0]))


def test_lsq_uniform_backward_uses_identity_path_inside_clipping_range():
    x = torch.tensor([-1.0, 0.0, 1.0], dtype=torch.float32, requires_grad=True)
    scale = torch.tensor(2.0, dtype=torch.float32, requires_grad=True)
    zp = torch.tensor(0.0, dtype=torch.float32, requires_grad=True)

    y = LsqUniformQuantizer.apply(x, scale, zp, -8, 7)
    y.sum().backward()

    assert torch.allclose(x.grad, torch.full((3,), 0.5, dtype=torch.float32), atol=1e-6)


def test_lsq_uniform_weight_g_uses_lsq_positive_bound_without_changing_initializer():
    quantizer = LearnedLsqUniformQuantizer(bit_width=3, signed=True, symmetric=True)
    x = torch.linspace(-1.0, 1.0, steps=4 * 3 * 3 * 3).reshape(4, 3, 3, 3)

    quantizer(x)

    expected_g = torch.tensor(1.0 / (x.numel() * 3) ** 0.5)
    old_initializer_scale = torch.max(abs(x.mean() - 3 * x.std()), abs(x.mean() + 3 * x.std())) / 4
    assert torch.allclose(quantizer.g, expected_g)
    assert torch.allclose(quantizer.scale, old_initializer_scale)


def test_lsq_uniform_activation_g_counts_all_features_without_changing_initializer():
    quantizer = LearnedLsqUniformQuantizer(
        is_activation=True,
        bit_width=3,
        signed=False,
        symmetric=False,
    )
    x = torch.linspace(0.0, 1.0, steps=2 * 3 * 4 * 5).reshape(2, 3, 4, 5)

    quantizer(x)

    expected_g = torch.tensor(1.0 / (x.numel() * 7) ** 0.5)
    old_initializer_scale = (x.max() - x.min()) / 7
    assert torch.allclose(quantizer.g, expected_g)
    assert torch.allclose(quantizer.scale, old_initializer_scale)


def test_lsq_uniform_per_channel_weight_g_counts_weights_per_scale():
    quantizer = LearnedLsqUniformQuantizer(
        bit_width=3,
        signed=True,
        symmetric=True,
        per_channel=True,
        num_channels=4,
    )
    x = torch.linspace(-1.0, 1.0, steps=4 * 3 * 3 * 3).reshape(4, 3, 3, 3)

    quantizer(x)

    expected = torch.full((4,), 1.0 / (3 * 3 * 3 * 3) ** 0.5)
    assert torch.allclose(quantizer.g, expected)


def test_lsq_uniform_dequantized_scale_gradient_matches_lsq_g_scaling():
    quantizer = LearnedLsqUniformQuantizer(
        bit_width=3,
        signed=True,
        symmetric=True,
        g=0.5,
    )
    with torch.no_grad():
        quantizer.scale.fill_(1.0)
        quantizer._scale_initialized.fill_(True)
        quantizer.is_initialized.fill_(True)
    x = torch.tensor([-5.0, -1.2, 0.2, 3.6, 5.0], dtype=torch.float32)

    quantized = quantizer(x)
    dequantized = quantized.value * quantized.scale
    dequantized.sum().backward()

    unscaled_lsq_grad = torch.tensor([-4.0, 0.2, -0.2, 3.0, 3.0]).sum()
    expected = unscaled_lsq_grad * 0.5
    assert torch.allclose(quantizer.scale.grad, expected, atol=1e-6)


def test_lsq_uniform_activation_scale_learns_in_training_mode():
    quantizer = LearnedLsqUniformQuantizer(
        is_activation=True,
        bit_width=3,
        signed=False,
        symmetric=False,
    )
    with torch.no_grad():
        quantizer.scale.fill_(1.0)
        quantizer.zero_point.zero_()
        quantizer._scale_initialized.fill_(True)
        quantizer.is_initialized.fill_(True)
    quantizer.calibration_mode_(False)
    optimizer = torch.optim.SGD([quantizer.scale, quantizer.zero_point], lr=0.1)
    x = torch.tensor([-2.0, -0.4, 0.4, 2.0], dtype=torch.float32)
    scale_before = quantizer.scale.detach().clone()

    quantized = quantizer(x)
    loss = (quantized.value * quantized.scale).sum()
    loss.backward()
    optimizer.step()

    assert quantizer.scale.requires_grad is True
    assert quantizer.zero_point.requires_grad is True
    assert quantizer.scale.grad is not None
    assert not torch.allclose(quantizer.scale.grad, torch.zeros_like(quantizer.scale.grad))
    assert not torch.allclose(quantizer.scale.detach(), scale_before)
