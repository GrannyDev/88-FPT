import torch
import torch.nn as nn

from hatorch.layers.quantized_tensor import QuantTensor, round_ste
from hatorch.quantizers.common.scale_approximation import ScaleApproximation


class QuantInvertedResidual(nn.Module):
    """
    Quantized MobileNetV2 inverted residual block.

    The internal conv sequence is already transformed into hatorch quantized
    layers. This wrapper handles the optional residual add by rescaling the
    identity path into the main path scale.
    """

    def __init__(
        self,
        conv: nn.Module,
        use_res_connect: bool,
        scale_approximation: ScaleApproximation = ScaleApproximation.NONE,
        fixed_point_bits: int = 8,
    ):
        super().__init__()
        self.conv = conv
        self.use_res_connect = bool(use_res_connect)
        self.scale_approximation = ScaleApproximation(scale_approximation)
        self.fixed_point_bits = fixed_point_bits

    def _broadcast_ratio(self, ratio: torch.Tensor, value: torch.Tensor) -> torch.Tensor:
        if ratio.dim() == 1 and value.ndim == 4:
            return ratio.view(1, -1, 1, 1)
        if ratio.dim() == 1 and value.ndim == 2:
            return ratio.view(1, -1)
        return ratio

    def _rescale_identity(self, identity: QuantTensor, main: QuantTensor) -> torch.Tensor:
        scale_ratio = self._broadcast_ratio(identity.scale / main.scale, identity.value)

        if torch.equal(scale_ratio.detach(), torch.ones_like(scale_ratio).detach()):
            return identity.value

        if self.scale_approximation == ScaleApproximation.FIXED_POINT and self.fixed_point_bits is not None:
            exact_rescaled = identity.value * scale_ratio
            scale_factor = float(1 << self.fixed_point_bits)
            int_scale = torch.round(scale_ratio * scale_factor).to(torch.int64)
            prod = (int_scale * identity.value).to(torch.int64)
            round_to_nearest = 1 << (self.fixed_point_bits - 1)
            prod_rounded = prod + torch.sign(prod.float()).to(torch.int64) * round_to_nearest
            approx_rescaled = (prod_rounded >> self.fixed_point_bits).to(identity.value.dtype)
            return exact_rescaled + (approx_rescaled - exact_rescaled).detach()

        if self.scale_approximation == ScaleApproximation.POWER_OF_TWO:
            tiny = torch.finfo(scale_ratio.dtype).tiny
            nearest_exp = torch.round(torch.log2(scale_ratio.abs().clamp_min(tiny)))
            return round_ste(identity.value * torch.pow(2, nearest_exp))

        return identity.value * scale_ratio

    def forward(self, x: QuantTensor) -> QuantTensor:
        main = self.conv(x)
        if not self.use_res_connect:
            return main
        if not isinstance(x, QuantTensor) or not isinstance(main, QuantTensor):
            raise TypeError("QuantInvertedResidual residual add requires QuantTensor inputs and outputs.")
        if x.value.shape != main.value.shape:
            raise RuntimeError(
                f"MobileNetV2 residual shape mismatch: identity {x.value.shape} vs main {main.value.shape}."
            )
        identity_rescaled = self._rescale_identity(x, main)
        return QuantTensor(main.value + identity_rescaled, main.scale, None)
