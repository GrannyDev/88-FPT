import torch.nn as nn

from hatorch.quantizers.init.lsq_uniform import LsqUniformQuantizer
from hatorch.utils.example_utils import (
    ExampleOptimizerConfig,
    ExampleRuntimeConfig,
    run_training,
)


class _TrainerStub:
    def __init__(self):
        self.disable_calls = []
        self.train_called = False
        self.closed = False

    def disable_weight_decay_for_lsq_parameters(self, **kwargs):
        self.disable_calls.append(kwargs)
        return 1

    def train(self):
        self.train_called = True

    def close(self):
        self.closed = True


def test_run_training_disables_lsq_scale_decay_by_default():
    trainer = _TrainerStub()
    model = nn.Sequential(LsqUniformQuantizer(is_activation=False, bit_width=4))
    runtime = ExampleRuntimeConfig(
        output_dir="out",
        num_epochs=1,
        calibration_epochs=0,
        freeze_scale_during_training=False,
    )
    optimization = ExampleOptimizerConfig(lr=0.1, eta_min=0.0, calibration_lr=0.0)

    run_training(trainer, model, runtime, optimization)

    assert trainer.disable_calls == [
        {
            "include_scale": True,
            "include_zero_point": False,
            "weights_only": False,
            "activations_only": False,
        }
    ]
    assert trainer.train_called is True
    assert trainer.closed is True


def test_run_training_does_not_disable_decay_when_scales_are_frozen():
    trainer = _TrainerStub()
    model = nn.Sequential(LsqUniformQuantizer(is_activation=False, bit_width=4))
    runtime = ExampleRuntimeConfig(
        output_dir="out",
        num_epochs=1,
        calibration_epochs=0,
        freeze_scale_during_training=True,
    )
    optimization = ExampleOptimizerConfig(lr=0.1, eta_min=0.0, calibration_lr=0.0)

    run_training(trainer, model, runtime, optimization)

    assert trainer.disable_calls == []
    assert trainer.train_called is True
    assert trainer.closed is True
