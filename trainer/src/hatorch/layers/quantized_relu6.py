import torch
from torch import nn

from hatorch.layers.quantized_tensor import QuantTensor


class QuantReLU6(nn.Module):
    """
    Quantized version of nn.ReLU6.

    QuantTensor.value is stored in the quantized integer domain. ReLU6 clips the
    represented real value to [0, 6], so the integer-domain upper bound is
    6 / scale.
    """

    def __init__(self, inplace: bool = False):
        super().__init__()
        self.inplace = inplace

    def _broadcast_scale(self, scale: torch.Tensor, value: torch.Tensor) -> torch.Tensor:
        if scale.numel() == 1:
            return scale
        if value.ndim == 4 and scale.numel() == value.shape[1]:
            return scale.view(1, -1, 1, 1)
        if value.ndim == 2 and scale.numel() == value.shape[1]:
            return scale.view(1, -1)
        return scale

    def forward(self, x: QuantTensor) -> QuantTensor:
        scale = self._broadcast_scale(x.scale, x.value).clamp_min(torch.finfo(x.value.dtype).tiny)
        value = torch.minimum(x.value.clamp_min(0), 6.0 / scale)
        if self.inplace:
            x.value = value
            return x
        return QuantTensor(value, x.scale, x.zero_point, x.bit_width, x.signed)
