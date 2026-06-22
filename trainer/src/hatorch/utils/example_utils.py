from __future__ import annotations

import atexit
import logging
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

import torch
import torch.nn as nn
from torch.optim.lr_scheduler import CosineAnnealingLR, LambdaLR, LRScheduler

from hatorch.quantizers.common._common_quantizer import BaseLearnedQuantizer
from hatorch.quantizers.common.scale_approximation import ScaleApproximation
from hatorch.train import SaveStrategy, Trainer, TrainingArguments
from hatorch.train.codebook_plots import summarize_and_plot_codebook_usage
from hatorch.transforms import utils as transforms_utils
from hatorch.transforms.config import ModelQuantConfig
from hatorch.utils.logger import logger


_DEFAULT_NUM_WORKERS = 8
_DEFAULT_PERSISTENT_WORKERS = True
_DEFAULT_PIN_MEMORY = True
_DEFAULT_PREFETCH_FACTOR = 8
_DEFAULT_MOMENTUM = 0.9
_DEFAULT_WEIGHT_DECAY = 1e-4
_DEFAULT_TQDM_STEPS = 50
_RUN_LOG_STATE: dict[str, object] = {}


class _Tee:
    def __init__(self, *streams):
        self.streams = streams
        self.encoding = getattr(streams[0], "encoding", None) if streams else None

    def write(self, data):
        for stream in self.streams:
            stream.write(data)
        return len(data)

    def flush(self):
        for stream in self.streams:
            stream.flush()

    def isatty(self):
        return any(getattr(stream, "isatty", lambda: False)() for stream in self.streams)


def _install_run_log(output_dir: str, rank: int = 0) -> None:
    if int(rank) != 0 or _RUN_LOG_STATE.get("installed"):
        return

    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    log_file = (output_path / "run.log").open("w", encoding="utf-8", buffering=1)
    original_stdout = sys.stdout
    original_stderr = sys.stderr
    sys.stdout = _Tee(original_stdout, log_file)
    sys.stderr = _Tee(original_stderr, log_file)

    formatter = None
    for handler in logger.handlers:
        formatter = handler.formatter
        if formatter is not None:
            break
    if formatter is None:
        formatter = logging.Formatter("%(message)s")

    file_handler = logging.StreamHandler(log_file)
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    _RUN_LOG_STATE.update(
        installed=True,
        log_file=log_file,
        original_stdout=original_stdout,
        original_stderr=original_stderr,
        file_handler=file_handler,
    )

    def _restore_run_log() -> None:
        if not _RUN_LOG_STATE.get("installed"):
            return
        sys.stdout = _RUN_LOG_STATE["original_stdout"]
        sys.stderr = _RUN_LOG_STATE["original_stderr"]
        logger.removeHandler(_RUN_LOG_STATE["file_handler"])
        _RUN_LOG_STATE["file_handler"].close()
        _RUN_LOG_STATE["log_file"].close()
        _RUN_LOG_STATE.clear()

    atexit.register(_restore_run_log)


def _is_running_example_script() -> bool:
    argv0 = sys.argv[0] if sys.argv else ""
    if not argv0:
        return False
    return "examples" in Path(argv0).parts


@dataclass(frozen=True)
class ExampleRuntimeConfig:
    output_dir: str
    num_epochs: int
    extra_epochs: Optional[int] = None
    calibration_epochs: int = 1
    switch_bn_to_running_stats_epoch: Optional[int] = None
    freeze_bn_running_stats_epoch: Optional[int] = None
    freeze_bn_epoch: Optional[int] = None
    device: str = "cuda"
    use_ddp: bool = False
    freeze_scale_during_training: bool = True
    save_strategy: SaveStrategy = SaveStrategy.NO
    amp: bool = False
    tqdm_steps: int = _DEFAULT_TQDM_STEPS
    eval_hard_non_uniform_sigmoid_staircase: bool = True

    def __post_init__(self) -> None:
        if not self.use_ddp and _is_running_example_script():
            _install_run_log(self.output_dir, rank=0)


@dataclass(frozen=True)
class ExampleOptimizerConfig:
    lr: float
    eta_min: float
    calibration_lr: float
    momentum: float = _DEFAULT_MOMENTUM
    weight_decay: float = _DEFAULT_WEIGHT_DECAY


def dataloader_kwargs() -> dict[str, int | bool]:
    return {
        "num_workers": _DEFAULT_NUM_WORKERS,
        "persistent_workers": _DEFAULT_PERSISTENT_WORKERS,
        "pin_memory": _DEFAULT_PIN_MEMORY,
        "prefetch_factor": _DEFAULT_PREFETCH_FACTOR,
    }


def select_device(requested_device: str) -> tuple[torch.device, str]:
    device = torch.device(requested_device if requested_device == "cpu" else ("cuda" if torch.cuda.is_available() else "cpu"))
    return device, device.type


def _total_training_epochs(runtime: ExampleRuntimeConfig) -> int:
    return int(runtime.num_epochs or 0) + int(runtime.extra_epochs or 0)


def _build_epoch_calls(
    model_module: torch.nn.Module,
    runtime: ExampleRuntimeConfig,
    quantization_config: Optional[ModelQuantConfig] = None,
) -> Optional[dict[int, list]]:
    epoch_calls: dict[int, list] = {}

    switch_epoch = runtime.switch_bn_to_running_stats_epoch
    if switch_epoch is None:
        switch_epoch = runtime.freeze_bn_epoch
    if switch_epoch is not None:
        switch_epoch = int(switch_epoch)
        if switch_epoch < 1:
            raise ValueError("switch_bn_to_running_stats_epoch must be >= 1.")

        def _switch_folded_bn_to_running_stats() -> None:
            switched = transforms_utils.switch_folded_batch_norm_to_running_stats(model_module)
            logger.info(
                "Switched folded BatchNorm forward to running stats for %d module(s) at epoch %d.",
                switched,
                switch_epoch,
            )

        epoch_calls.setdefault(switch_epoch, []).append(_switch_folded_bn_to_running_stats)

    if runtime.freeze_bn_running_stats_epoch is not None:
        freeze_stats_epoch = int(runtime.freeze_bn_running_stats_epoch)
        if freeze_stats_epoch < 1:
            raise ValueError("freeze_bn_running_stats_epoch must be >= 1.")

        def _freeze_folded_bn_running_stats() -> None:
            frozen = transforms_utils.freeze_folded_batch_norm_running_stats(model_module)
            logger.info(
                "Froze folded BatchNorm running-stat updates for %d module(s) at epoch %d.",
                frozen,
                freeze_stats_epoch,
            )

        epoch_calls.setdefault(freeze_stats_epoch, []).append(_freeze_folded_bn_running_stats)

    if quantization_config is not None:
        sigmoid_config = quantization_config.sigmoid_staircase_config
        if sigmoid_config is not None:
            for tau_epoch in range(sigmoid_config.start_epoch, sigmoid_config.end_epoch + 1):
                tau_value = sigmoid_config.value_at_epoch(tau_epoch)

                def _set_sigmoid_staircase_tau(value: float = tau_value, epoch: int = tau_epoch) -> None:
                    updated = transforms_utils.set_non_uniform_sigmoid_staircase_tau(model_module, value)
                    logger.info(
                        "Set non-uniform sigmoid staircase tau to %.6g for %d quantizer(s) at epoch %d.",
                        value,
                        updated,
                        epoch,
                    )

                epoch_calls.setdefault(tau_epoch, []).append(_set_sigmoid_staircase_tau)

        target_approximation = (
            quantization_config.target_scale_approximation
            if quantization_config.target_scale_approximation is not None
            else quantization_config.scale_approximation
        )
        start_epoch = int(quantization_config.scale_approximation_start_epoch)
        if target_approximation != ScaleApproximation.NONE and start_epoch > 1:

            def _enable_scale_approximation() -> None:
                updated = transforms_utils.set_scale_approximation(
                    model_module,
                    target_approximation,
                    fixed_point_bits=quantization_config.fixed_point_bits,
                    skip_first_activation=True,
                )
                logger.info(
                    "Enabled %s scale approximation for %d module(s) at epoch %d.",
                    target_approximation.value,
                    updated,
                    start_epoch,
                )
                if quantization_config.freeze_approximated_scales:
                    frozen = transforms_utils.freeze_approximated_lsq_scales(model_module)
                    logger.info(
                        "Froze %d approximated LSQ scale parameter(s) at epoch %d.",
                        frozen,
                        start_epoch,
                    )

            epoch_calls.setdefault(start_epoch, []).append(_enable_scale_approximation)

    return epoch_calls or None


def build_training_arguments(
    model_module: torch.nn.Module,
    runtime: ExampleRuntimeConfig,
    num_epochs: Optional[int] = None,
    include_epoch_calls: bool = True,
    quantization_config: Optional[ModelQuantConfig] = None,
) -> TrainingArguments:
    epoch_calls = None
    if include_epoch_calls:
        epoch_calls = _build_epoch_calls(model_module, runtime, quantization_config)

    return TrainingArguments(
        output_dir=runtime.output_dir,
        num_epochs=_total_training_epochs(runtime) if num_epochs is None else int(num_epochs),
        save_strategy=runtime.save_strategy,
        overwrite_output_dir=False,
        amp=runtime.amp,
        tqdm_steps=runtime.tqdm_steps,
        num_workers=_DEFAULT_NUM_WORKERS,
        persistent_workers=_DEFAULT_PERSISTENT_WORKERS,
        pin_memory=_DEFAULT_PIN_MEMORY,
        prefetch_factor=_DEFAULT_PREFETCH_FACTOR,
        epoch_calls=epoch_calls,
        eval_hard_non_uniform_sigmoid_staircase=runtime.eval_hard_non_uniform_sigmoid_staircase,
    )


def _set_weight_scale_training_policy(
    model_module: torch.nn.Module,
    freeze_scale_during_training: bool,
) -> int:
    updated = 0
    for module in model_module.modules():
        if not isinstance(module, BaseLearnedQuantizer):
            continue
        if module.is_activation:
            continue
        scale = getattr(module, "scale", None)
        if not isinstance(scale, nn.Parameter):
            continue
        scale.requires_grad_(not freeze_scale_during_training)
        updated += 1
    return updated


def build_optimizers(
    model_module: torch.nn.Module,
    runtime: ExampleRuntimeConfig,
    optimization: ExampleOptimizerConfig,
) -> tuple[torch.optim.Optimizer, LRScheduler]:
    params = [param for param in model_module.parameters() if param.requires_grad]
    optimizer = torch.optim.SGD(
        params,
        lr=optimization.lr,
        momentum=optimization.momentum,
        weight_decay=optimization.weight_decay,
    )

    total_epochs = _total_training_epochs(runtime)
    if total_epochs <= 1:
        scheduler: LRScheduler = LambdaLR(optimizer, lr_lambda=lambda epoch: 1.0)
    else:
        scheduler = CosineAnnealingLR(
            optimizer,
            T_max=total_epochs,
            eta_min=optimization.eta_min,
        )

    return optimizer, scheduler


def build_trainer(
    model,
    trainer_device: str,
    train_loader,
    valid_loader,
    loss_fn,
    optimizer: torch.optim.Optimizer,
    lr_scheduler,
    runtime: ExampleRuntimeConfig,
    quantization_config: Optional[ModelQuantConfig] = None,
    rank: int = 0,
) -> Trainer:
    _install_run_log(runtime.output_dir, rank)
    args = build_training_arguments(
        model.model,
        runtime,
        quantization_config=quantization_config,
    )
    trainer = Trainer(
        model,
        trainer_device,
        train_loader,
        valid_loader,
        optimizer,
        loss_fn,
        rank=rank,
        lr_scheduler=lr_scheduler,
        args=args,
        callbacks=[],
    )
    return trainer


def run_training(
    trainer: Trainer,
    model_module: torch.nn.Module,
    runtime: ExampleRuntimeConfig,
    optimization: ExampleOptimizerConfig,
    quantization_config: Optional[ModelQuantConfig] = None,
    plot_codebook_usage: bool = False,
    rank: int = 0,
) -> None:
    calibration_epochs = int(runtime.calibration_epochs or 0)
    calibration_params = [param for param in model_module.parameters() if param.requires_grad]

    try:
        if calibration_epochs > 0 and calibration_params:
            calibration_optimizer = torch.optim.SGD(
                calibration_params,
                lr=optimization.calibration_lr,
                momentum=optimization.momentum,
                weight_decay=optimization.weight_decay,
            )
            trainer.calibrate(
                calibration_optimizer,
                num_epochs=calibration_epochs,
                tqdm_steps=runtime.tqdm_steps,
            )
            trainer.evaluate(log_prefix="PostCalibrationEvaluation")

        if (
            quantization_config is not None
            and quantization_config.freeze_approximated_scales
            and quantization_config.scale_approximation != ScaleApproximation.NONE
        ):
            frozen = transforms_utils.freeze_approximated_lsq_scales(model_module)
            logger.info("Froze %d approximated LSQ scale parameter(s) for training.", frozen)

        if runtime.freeze_scale_during_training:
            num_scales = _set_weight_scale_training_policy(model_module, freeze_scale_during_training=True)
            logger.info("Froze %d weight quantizer scale parameter(s) for training.", num_scales)
        else:
            moved = trainer.disable_weight_decay_for_lsq_parameters(
                include_scale=True,
                include_zero_point=False,
                weights_only=False,
                activations_only=False,
            )
            logger.info("Disabled weight decay for %d quantizer scale parameter(s).", moved)

        trainer.train()

        if plot_codebook_usage and (not runtime.use_ddp or rank == 0):
            chart_paths = summarize_and_plot_codebook_usage(model_module, runtime.output_dir)
            logger.info("Saved %d codebook usage chart(s).", len(chart_paths))
    finally:
        trainer.close()
