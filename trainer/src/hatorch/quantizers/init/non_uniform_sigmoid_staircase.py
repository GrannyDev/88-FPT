from typing import Optional

import torch
import torch.nn as nn
from torch import Tensor

from hatorch.layers.quantized_tensor import QuantTensor
from hatorch.quantizers.autograd.non_uniform_sigmoid_staircase_quantizer import (
    LsqNonUniformSigmoidStaircaseQuantizer,
)
from hatorch.quantizers.init.step_driven import StepDrivenQuantizer


class NonUniformSigmoidStaircaseQuantizer(StepDrivenQuantizer):
    autograd_quantizer = LsqNonUniformSigmoidStaircaseQuantizer
    _LOG_SCALE_MIN = -30.0
    _LOG_SCALE_MAX = 30.0

    def __init__(self, *args, tau: float = 1.0, learnable_thresholds: bool = False, **kwargs):
        kwargs.setdefault("auto_compute_g", False)
        super().__init__(*args, **kwargs)
        if tau <= 0:
            raise ValueError("tau must be > 0.")
        self.scale.data.zero_()
        self.register_buffer("tau", torch.tensor(float(tau), dtype=torch.float32))
        threshold_shape = self.bit_width.shape[:-1] + (max(int(self.bit_width.shape[-1]) - 1, 0),)
        self.threshold_logits = nn.Parameter(torch.zeros(threshold_shape, dtype=torch.float32))
        self.threshold_logits.requires_grad_(bool(learnable_thresholds))
        self.learnable_thresholds = bool(learnable_thresholds)
        self.hard_forward_enabled = False

    def current_scale(self) -> Tensor:
        return torch.exp(self.scale.clamp(self._LOG_SCALE_MIN, self._LOG_SCALE_MAX))

    def _set_positive_scale(self, scale_value: Tensor) -> None:
        stored = scale_value.clamp_min(1e-8).log()
        self.scale.data.copy_(stored.to(self.scale.device, dtype=self.scale.dtype))
        self._scale_initialized.fill_(True)
        self.is_initialized.fill_(True)

    def set_tau(self, tau: float) -> None:
        if tau <= 0:
            raise ValueError("tau must be > 0.")
        self.tau.fill_(float(tau))

    def set_hard_forward(self, enabled: bool) -> None:
        self.hard_forward_enabled = bool(enabled)

    def hard_forward(self, x: Tensor) -> QuantTensor:
        if not bool(self._scale_initialized):
            self.scale_initializer(x)
        effective_scale = self.current_scale()
        hard = self.autograd_quantizer.hard_forward(
            x,
            effective_scale,
            self.bit_width,
            int(self.qn),
            int(self.qp),
            self.threshold_logits,
        )
        return QuantTensor(
            value=hard,
            scale=effective_scale,
            zero_point=None,
            bit_width=None,
            signed=self.signed,
        )

    def forward(self, x: Tensor, in_scale: Optional[Tensor] = None) -> QuantTensor:
        if not self.enabled:
            return self._disabled_quant_tensor(x)
        if in_scale is not None:
            raise ValueError("NonUniformSigmoidStaircaseQuantizer is only supported for weights and does not accept input scales.")

        if not bool(self._scale_initialized):
            self.scale_initializer(x)

        effective_scale = self.current_scale()
        quant_value, export_scale = self.autograd_quantizer.apply(
            x,
            effective_scale,
            self.bit_width,
            int(self.qn),
            int(self.qp),
            self.tau.to(device=x.device, dtype=x.dtype),
            self.threshold_logits,
            self.hard_forward_enabled,
            True,
        )
        return QuantTensor(
            value=quant_value,
            scale=export_scale,
            zero_point=None,
            bit_width=None,
            signed=self.signed,
        )

    def extra_repr(self) -> str:
        return (
            f"bit_width=non_uniform_sigmoid_staircase, signed={self.signed}, symmetric={self.symmetric}, "
            f"per_channel={self.per_channel}"
            + (f", num_channels={self.num_channels}" if self.per_channel else "")
            + f", set={self._codebook_repr()}"
            + f", qn={self.qn}, qp={self.qp}, tau={float(self.tau.item()):.6f}, "
            + f"learnable_thresholds={self.learnable_thresholds}, "
            + f"hard_forward={self.hard_forward_enabled}, "
            + f"{self._scale_repr()}, enabled={self.enabled}"
        )

    def current_thresholds(self) -> Tensor:
        channels = self.num_channels if self.per_channel and self.num_channels is not None else None
        return self.autograd_quantizer.thresholds_from_logits(
            self.bit_width,
            self.threshold_logits,
            channels,
        )

    def _codebook_repr(self) -> str:
        codebook = self.bit_width.detach().cpu()
        if codebook.ndim == 1:
            return "[" + ", ".join(format_codebook_value(value) for value in codebook.tolist()) + "]"
        return f"shape={tuple(codebook.shape)}, first=[" + ", ".join(
            format_codebook_value(value) for value in codebook.reshape(-1, codebook.shape[-1])[0].tolist()
        ) + "]"


def format_codebook_value(value: float) -> str:
    return str(int(value)) if float(value).is_integer() else f"{float(value):.6g}"
