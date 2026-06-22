import torch
from torch import Tensor

from hatorch.quantizers.autograd.lsq_step_driven_quantizer import LsqStepDrivenQuantizer


class LsqNonUniformSigmoidStaircaseQuantizer:
    @staticmethod
    def _targets_per_channel(
        targets: Tensor,
        channels: int,
    ) -> Tensor:
        if targets.ndim == 1:
            return targets.unsqueeze(0).expand(channels, -1)
        if targets.shape[0] == 1 and channels > 1:
            return targets.expand(channels, -1)
        return targets

    @staticmethod
    def _threshold_logits_per_channel(
        threshold_logits: Tensor | None,
        channels: int,
    ) -> Tensor | None:
        if threshold_logits is None:
            return None
        if threshold_logits.ndim == 1:
            return threshold_logits.unsqueeze(0).expand(channels, -1)
        if threshold_logits.shape[0] == 1 and channels > 1:
            return threshold_logits.expand(channels, -1)
        return threshold_logits

    @staticmethod
    def thresholds_from_logits(
        targets: Tensor,
        threshold_logits: Tensor | None,
        channels: int | None = None,
    ) -> Tensor:
        if channels is None:
            channels = 1 if targets.ndim == 1 else targets.shape[0]
        targets_per_channel = LsqNonUniformSigmoidStaircaseQuantizer._targets_per_channel(targets, channels)
        sorted_targets = torch.sort(targets_per_channel, dim=-1).values
        if sorted_targets.shape[-1] <= 1:
            return sorted_targets.new_empty(*sorted_targets.shape[:-1], 0)
        deltas = sorted_targets[:, 1:] - sorted_targets[:, :-1]
        threshold_logits = LsqNonUniformSigmoidStaircaseQuantizer._threshold_logits_per_channel(
            threshold_logits,
            channels,
        )
        if threshold_logits is None:
            return sorted_targets[:, :-1] + 0.5 * deltas
        return sorted_targets[:, :-1] + torch.sigmoid(threshold_logits.to(device=sorted_targets.device, dtype=sorted_targets.dtype)) * deltas

    @staticmethod
    def _sigmoid_staircase(
        scaled: Tensor,
        targets: Tensor,
        threshold_logits: Tensor | None,
        channel_dim: int,
        tau: Tensor,
    ) -> Tensor:
        scaled_c_first = torch.movedim(scaled, channel_dim, 0)
        channels = scaled_c_first.shape[0]
        targets_per_channel = LsqNonUniformSigmoidStaircaseQuantizer._targets_per_channel(targets, channels)

        if targets_per_channel.shape[-1] == 1:
            soft_c_first = targets_per_channel[:, :1].view(
                channels,
                *([1] * (scaled_c_first.ndim - 1)),
            ).expand_as(scaled_c_first)
            return torch.movedim(soft_c_first, 0, channel_dim)

        sorted_targets = torch.sort(targets_per_channel, dim=-1).values
        thresholds = LsqNonUniformSigmoidStaircaseQuantizer.thresholds_from_logits(
            sorted_targets,
            threshold_logits,
            channels,
        )
        deltas = sorted_targets[:, 1:] - sorted_targets[:, :-1]
        flat_values = scaled_c_first.reshape(channels, -1)
        tau = tau.to(device=flat_values.device, dtype=flat_values.dtype).clamp_min(torch.finfo(flat_values.dtype).eps)

        gates = torch.sigmoid((flat_values.unsqueeze(-1) - thresholds.unsqueeze(1)) * tau)
        flat_soft = sorted_targets[:, :1] + torch.sum(deltas.unsqueeze(1) * gates, dim=-1)
        soft_c_first = flat_soft.view_as(scaled_c_first)
        return torch.movedim(soft_c_first, 0, channel_dim)

    @staticmethod
    def _round_with_thresholds(
        scaled: Tensor,
        targets: Tensor,
        threshold_logits: Tensor | None,
        channel_dim: int,
    ) -> Tensor:
        scaled_c_first = torch.movedim(scaled, channel_dim, 0)
        channels = scaled_c_first.shape[0]
        sorted_targets = torch.sort(
            LsqNonUniformSigmoidStaircaseQuantizer._targets_per_channel(targets, channels),
            dim=-1,
        ).values
        if sorted_targets.shape[-1] == 1:
            rounded_c_first = sorted_targets[:, :1].view(
                channels,
                *([1] * (scaled_c_first.ndim - 1)),
            ).expand_as(scaled_c_first)
            return torch.movedim(rounded_c_first, 0, channel_dim)

        thresholds = LsqNonUniformSigmoidStaircaseQuantizer.thresholds_from_logits(
            sorted_targets,
            threshold_logits,
            channels,
        )
        flat_values = scaled_c_first.reshape(channels, -1)
        flat_indices = torch.searchsorted(thresholds, flat_values, right=False)
        flat_rounded = torch.gather(sorted_targets, dim=1, index=flat_indices)
        rounded_c_first = flat_rounded.view_as(scaled_c_first)
        return torch.movedim(rounded_c_first, 0, channel_dim)

    @staticmethod
    def hard_forward(x: Tensor, scale: Tensor, targets: Tensor, qn: int, qp: int, threshold_logits: Tensor | None = None) -> Tensor:
        scale, channel_dim = LsqStepDrivenQuantizer._reshape_per_channel_scale(scale, x)
        scaled = (x / scale).clamp(qn, qp)
        return LsqNonUniformSigmoidStaircaseQuantizer._round_with_thresholds(scaled, targets, threshold_logits, channel_dim)

    @staticmethod
    def soft_forward(x: Tensor, scale: Tensor, targets: Tensor, qn: int, qp: int, tau: Tensor, threshold_logits: Tensor | None = None) -> Tensor:
        scale, channel_dim = LsqStepDrivenQuantizer._reshape_per_channel_scale(scale, x)
        scaled = (x / scale).clamp(qn, qp)
        return LsqNonUniformSigmoidStaircaseQuantizer._sigmoid_staircase(scaled, targets, threshold_logits, channel_dim, tau)

    @staticmethod
    def apply(
        x: Tensor,
        scale: Tensor,
        targets: Tensor,
        qn: int,
        qp: int,
        tau: float | Tensor = 1.0,
        threshold_logits: Tensor | None = None,
        hard_forward: bool = False,
        return_metadata: bool = False,
    ) -> Tensor | tuple[Tensor, Tensor]:
        scale_ste, channel_dim = LsqStepDrivenQuantizer._reshape_per_channel_scale(scale, x)
        scaled = (x / scale_ste).clamp(qn, qp)
        if hard_forward:
            hard = LsqNonUniformSigmoidStaircaseQuantizer._round_with_thresholds(
                scaled,
                targets,
                threshold_logits,
                channel_dim,
            )
            quant = LsqStepDrivenQuantizer._forward_with_real_backward(hard, scaled)
        else:
            quant = LsqNonUniformSigmoidStaircaseQuantizer._sigmoid_staircase(
                scaled,
                targets,
                threshold_logits,
                channel_dim,
                torch.as_tensor(tau, device=x.device, dtype=x.dtype),
            )
        if return_metadata:
            return quant, scale
        return quant
