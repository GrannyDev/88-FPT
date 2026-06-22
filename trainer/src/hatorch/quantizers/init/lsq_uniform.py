from typing import Optional

import torch
from torch import Tensor

from hatorch.layers.quantized_tensor import QuantTensor
from hatorch.quantizers.common._common_quantizer import BaseLearnedQuantizer
from hatorch.quantizers.autograd.lsq_uniform_quantizer import LsqUniformQuantizer as LsqUniformAutograd
from hatorch.quantizers.common.scale_approximation import ScaleApproximation
from hatorch.quantizers.common.uniform_rounding import UniformRoundingMode


class LsqUniformQuantizer(BaseLearnedQuantizer):
    def __init__(
        self,
        is_activation: bool = False,
        symmetric: bool = True,
        per_channel: bool = False,
        num_channels: Optional[int] = None,
        bit_width: int = 8,
        signed: bool = True,
        enabled: bool = True,
        g: Optional[float] = None,
        auto_compute_g: bool = True,
        scale_approximation: ScaleApproximation = ScaleApproximation.NONE,
        fixed_point_bits: int = 8,
        rounding_mode: UniformRoundingMode = UniformRoundingMode.ROUND,
    ):
        if not isinstance(bit_width, int):
            raise ValueError("LsqUniformQuantizer requires an integer bit_width.")
        if signed:
            qn = -(2 ** (bit_width - 1))
            qp = 2 ** (bit_width - 1) - 1
        else:
            qn = 0
            qp = 2 ** bit_width - 1
        super().__init__(
            is_activation=is_activation,
            symmetric=symmetric,
            per_channel=per_channel,
            num_channels=num_channels,
            signed=signed,
            enabled=enabled,
            qn=qn,
            qp=qp,
            g=g,
            auto_compute_g=auto_compute_g,
            scale_trainable=True,
        )
        self.bit_width = bit_width
        self.scale_approximation = scale_approximation
        self.fixed_point_bits = fixed_point_bits
        self.rounding_mode = UniformRoundingMode(rounding_mode)
        self.is_non_uniform_bitwidth = False

    def scale_zp_initializer(
        self,
        mean_v: Tensor,
        std_v: Tensor,
        max_v: Tensor,
        min_v: Tensor,
    ) -> None:
        with torch.no_grad():
            if not self.is_activation:
                effective_level_count = 2 ** (self.bit_width - 1)
                init_scale = torch.max(abs(mean_v - 3 * std_v), abs(mean_v + 3 * std_v)) / effective_level_count
                init_scale = init_scale.clamp_min(1e-8)
            else:
                if self.symmetric and self.signed:
                    qmax = max(abs(float(self.qn)), abs(float(self.qp)), 1.0)
                    init_scale = torch.maximum(max_v.abs(), min_v.abs()) / qmax
                else:
                    init_scale = (max_v - min_v) / (self.qp - self.qn)
                init_scale = init_scale.clamp_min(1e-8)
                if not self.symmetric:
                    init_zp = min_v - self.qn * init_scale
                    self.zero_point.copy_(init_zp.to(self.zero_point.device))
            self._set_positive_scale(init_scale.to(self.scale.device))

    def forward(self, x: Tensor, in_scale: Optional[Tensor] = None) -> QuantTensor:
        if not self.enabled:
            return self._disabled_quant_tensor(x)

        effective_scale = self.current_scale()
        effective_zero_point = self.zero_point
        fused_scales = False
        if in_scale is not None:
            detached_in_scale = in_scale.detach()
            is_identity_input_scale = detached_in_scale.numel() == 1 and float(detached_in_scale.item()) == 1.0
            if self._scale_initialized and not is_identity_input_scale:
                fused_scales = True
            else:
                if in_scale.numel() > 1:
                    if x.ndim == 4:
                        in_scale = in_scale.view(1, -1, 1, 1)
                    elif x.ndim == 2:
                        in_scale = in_scale.view(1, -1)
                x = x * in_scale

        if not bool(self._scale_initialized):
            if self.per_channel:
                dims = list(range(1, x.ndim))
                mean_v = x.mean(dim=dims, keepdim=False)
                std_v = x.std(dim=dims, keepdim=False)
                max_v = x.amax(dim=dims, keepdim=False)
                min_v = x.amin(dim=dims, keepdim=False)
            else:
                mean_v = x.mean()
                std_v = x.std()
                max_v = x.max()
                min_v = x.min()
            self.scale_zp_initializer(mean_v, std_v, max_v, min_v)
            effective_scale = self.current_scale()
            effective_zero_point = self.zero_point

        self._maybe_initialize_g(x)
        g_scale = self.g.to(device=effective_scale.device, dtype=effective_scale.dtype)
        if (not self.symmetric) and self.is_activation and isinstance(self.zero_point, torch.nn.Parameter):
            g_zp = self.g.to(device=effective_scale.device, dtype=effective_scale.dtype)
        else:
            g_zp = effective_scale.new_tensor(1.0)

        quant_value, export_scale, export_zero_point = LsqUniformAutograd.apply(
            x,
            effective_scale,
            effective_zero_point,
            self.qn,
            self.qp,
            g_scale,
            g_zp,
            fused_scales,
            self.scale_approximation,
            self.fixed_point_bits if self.scale_approximation == ScaleApproximation.FIXED_POINT else None,
            in_scale,
            self.symmetric,
            self.rounding_mode if self.is_activation else UniformRoundingMode.ROUND,
            True,
        )
        return QuantTensor(
            value=quant_value,
            scale=export_scale,
            zero_point=export_zero_point,
            bit_width=None,
            signed=self.signed,
        )

    def extra_repr(self) -> str:
        return (
            f"bit_width={self.bit_width}, signed={self.signed}, symmetric={self.symmetric}, "
            f"per_channel={self.per_channel}"
            + (f", num_channels={self.num_channels}" if self.per_channel else "")
            + f", qn={self.qn}, qp={self.qp}, {self._scale_repr()}, {self._zero_point_repr()}, "
            f"g={self.g}, rounding_mode={self.rounding_mode.value}, learnable_zp={not self.symmetric}, enabled={self.enabled}"
        )
