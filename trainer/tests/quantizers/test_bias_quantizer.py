import torch

from hatorch.quantizers.bias.bias_quantizer import BiasQuantizer


def test_bias_quantizer_extra_repr_reports_last_integer_bias_range():
    quantizer = BiasQuantizer(bit_width=4)

    assert "bias_int_min=uninitialized" in repr(quantizer)
    assert "bias_int_max=uninitialized" in repr(quantizer)

    bias = torch.tensor([-1.25, 0.0, 2.5])
    quantizer(bias, torch.tensor(0.25))

    text = repr(quantizer)
    assert "bias_int_min=-5" in text
    assert "bias_int_max=7" in text


def test_bias_quantizer_reports_disabled_integer_range_when_disabled():
    quantizer = BiasQuantizer(enabled=False)
    bias = torch.tensor([-3.0, 4.0])

    result = quantizer(bias, torch.tensor(1.0))

    assert result is bias
    assert "bias_int_min=disabled" in repr(quantizer)
    assert "bias_int_max=disabled" in repr(quantizer)
