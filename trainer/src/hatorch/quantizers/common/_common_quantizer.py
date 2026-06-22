import math
from typing import Any, Dict, Optional

import torch
import torch.nn as nn
from torch import Tensor
from typing_extensions import override

from hatorch.layers.quantized_tensor import QuantTensor
from hatorch.quantizers.base import BaseQuantizer


class BaseLearnedQuantizer(BaseQuantizer):
    def __init__(
        self,
        is_activation: bool,
        symmetric: bool,
        per_channel: bool,
        num_channels: Optional[int],
        signed: bool,
        enabled: bool,
        qn: int | float,
        qp: int | float,
        g: Optional[float] = None,
        auto_compute_g: bool = True,
        scale_trainable: bool = True,
        with_zero_point: bool = True,
    ):
        super().__init__(
            is_activation=is_activation,
            symmetric=symmetric,
            per_channel=per_channel,
            num_channels=num_channels,
            enabled=enabled,
        )
        if is_activation and per_channel:
            raise ValueError("Per-channel quantization is not supported for activations.")
        if per_channel and num_channels is None:
            raise ValueError("num_channels must be specified when per_channel=True")

        self.signed = signed
        self.qn = qn
        self.qp = qp
        self.auto_compute_g = auto_compute_g
        self._scale_trainable = bool(scale_trainable)
        self._with_zero_point = bool(with_zero_point)

        if g is not None:
            g_value = float(g)
            g_computed = True
        elif not auto_compute_g:
            g_value = 1.0
            g_computed = True
        else:
            g_value = 1.0
            g_computed = False
        self.register_buffer("g", torch.tensor(g_value, dtype=torch.float32))
        self.register_buffer("_g_computed", torch.tensor(g_computed, dtype=torch.bool))

        if per_channel:
            initial_scale = torch.ones(num_channels)
        else:
            initial_scale = torch.tensor(1.0)
        self.scale = nn.Parameter(initial_scale)
        self.scale.requires_grad_(self._scale_trainable)

        if self._with_zero_point:
            if not symmetric:
                if per_channel:
                    self.zero_point = nn.Parameter(torch.zeros(num_channels))
                else:
                    self.zero_point = nn.Parameter(torch.tensor(0.0))
            else:
                if per_channel:
                    self.register_buffer("zero_point", torch.zeros(num_channels))
                else:
                    self.register_buffer("zero_point", torch.tensor(0.0))
        else:
            self.register_buffer("zero_point", None)

        self.register_buffer("_scale_initialized", torch.tensor(False, dtype=torch.bool))

    def current_scale(self) -> Tensor:
        return self.scale

    def _set_positive_scale(self, scale_value: Tensor) -> None:
        stored = scale_value.clamp_min(1e-8)
        self.scale.data.copy_(stored.to(self.scale.device, dtype=self.scale.dtype))
        self._scale_initialized.fill_(True)
        self.is_initialized.fill_(True)

    def _compute_g_from_tensor(self, x: Tensor) -> Tensor:
        q_positive = max(float(self.qp), 1.0)
        if self.per_channel and not self.is_activation:
            n = x[0].numel() if x.ndim > 0 else 1
            g = 1.0 / math.sqrt(float(n) * q_positive)
            return torch.full(
                (self.scale.numel(),),
                g,
                device=x.device,
                dtype=torch.float32,
            )

        n = x.numel()
        g = 1.0 / math.sqrt(float(n) * q_positive)
        return torch.tensor(g, device=x.device, dtype=torch.float32)

    def _maybe_initialize_g(self, x: Tensor) -> None:
        if bool(self._g_computed):
            return
        g_value = self._compute_g_from_tensor(x).to(device=self.scale.device, dtype=torch.float32)
        if self.g.shape != g_value.shape:
            self.g = g_value.detach().clone()
        else:
            self.g.copy_(g_value)
        self._g_computed.fill_(True)

    def _disabled_quant_tensor(self, x: Tensor) -> QuantTensor:
        return QuantTensor(
            value=x,
            scale=torch.tensor(1.0, device=x.device, dtype=x.dtype),
            zero_point=(
                None
                if self.zero_point is None
                else (self.zero_point.detach().clone() if self.per_channel else self.zero_point.detach())
            ),
            bit_width=None,
            signed=self.signed,
        )

    def _scale_repr(self) -> str:
        current_scale = self.current_scale().detach()
        if self.per_channel:
            if current_scale.numel() > 1:
                return (
                    f"scale=[min={current_scale.min().item():.6f}, "
                    f"max={current_scale.max().item():.6f}, "
                    f"mean={current_scale.mean().item():.6f}]"
                )
            return f"scale={current_scale.item():.6f}"
        return f"scale={current_scale.item():.6f}"

    def _zero_point_repr(self) -> str:
        if self.zero_point is None:
            return "zero_point=None"
        if self.per_channel:
            if self.zero_point.numel() > 1:
                return (
                    f"zero_point=[min={self.zero_point.min().item():.6f}, "
                    f"max={self.zero_point.max().item():.6f}]"
                )
            return f"zero_point={self.zero_point.item():.6f}"
        return f"zero_point={self.zero_point.item():.6f}"

    @override
    def calibration_mode_(self, mode: bool = True) -> "BaseLearnedQuantizer":
        super().calibration_mode_(mode)
        if self.is_activation:
            self.scale.requires_grad_(self._scale_trainable)
            if isinstance(self.zero_point, nn.Parameter):
                self.zero_point.requires_grad_(True)
        else:
            self.scale.requires_grad_(self._scale_trainable and not mode)
            if isinstance(self.zero_point, nn.Parameter):
                self.zero_point.requires_grad_(False)
        return self
    
    @override
    def _initialize_from_qparams(self, qparams: Dict[str, Any]) -> None:
        raise NotImplementedError("Observer-based initialization is not used by learned quantizers.")

    def _load_from_state_dict(
        self,
        state_dict,
        prefix,
        local_metadata,
        strict,
        missing_keys,
        unexpected_keys,
        error_msgs,
    ):
        g_key = prefix + "g"
        g_computed_key = prefix + "_g_computed"
        g_missing = g_key not in state_dict
        g_computed_missing = g_computed_key not in state_dict

        if g_missing:
            state_dict[g_key] = torch.tensor(1.0, dtype=torch.float32)
        if g_computed_missing:
            state_dict[g_computed_key] = torch.tensor(not self.auto_compute_g, dtype=torch.bool)

        super()._load_from_state_dict(
            state_dict,
            prefix,
            local_metadata,
            strict,
            missing_keys,
            unexpected_keys,
            error_msgs,
        )

        if g_missing and self.auto_compute_g:
            self._g_computed.fill_(False)
