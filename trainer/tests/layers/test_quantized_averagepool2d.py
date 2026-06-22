import torch

from hatorch.layers.quantized_averagepool2d import QuantAveragePool2d
from hatorch.layers.quantized_tensor import QuantTensor


def test_quant_average_pool_round_output_is_optional_and_ste():
    value = torch.tensor([[[[1.0, 2.0], [2.0, 2.0]]]], requires_grad=True)
    scale = torch.tensor([0.25])

    unrounded = QuantAveragePool2d(kernel_size=2, round_output=False)(QuantTensor(value, scale))

    assert torch.equal(unrounded.value.detach(), torch.tensor([[[[1.75]]]]))

    rounded = QuantAveragePool2d(kernel_size=2, round_output=True)(QuantTensor(value, scale))

    assert torch.equal(rounded.value.detach(), torch.tensor([[[[2.0]]]]))
    rounded.value.sum().backward()
    assert torch.allclose(value.grad, torch.full_like(value, 0.25))
