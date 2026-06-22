import pytest

from hatorch.train import TrainingArguments


def test_outpur_dir():
    args = TrainingArguments()

    assert args.output_dir == "trainer_output"


def test_dataloader_worker_defaults():
    args = TrainingArguments(output_dir="out")

    assert args.num_workers == 0
    assert args.persistent_workers is False
    assert args.pin_memory is False
    assert args.prefetch_factor is None


def test_persistent_workers_requires_workers():
    with pytest.raises(ValueError, match="persistent_workers=True requires num_workers > 0"):
        TrainingArguments(
            output_dir="out",
            num_workers=0,
            persistent_workers=True,
        )


def test_prefetch_factor_requires_workers():
    with pytest.raises(ValueError, match="prefetch_factor requires num_workers > 0"):
        TrainingArguments(
            output_dir="out",
            num_workers=0,
            prefetch_factor=2,
        )


def test_prefetch_factor_must_be_positive():
    with pytest.raises(ValueError, match="prefetch_factor must be >= 1"):
        TrainingArguments(
            output_dir="out",
            num_workers=2,
            prefetch_factor=0,
        )


def test_prefetch_factor_valid_with_workers():
    args = TrainingArguments(
        output_dir="out",
        num_workers=2,
        prefetch_factor=4,
    )
    assert args.prefetch_factor == 4
