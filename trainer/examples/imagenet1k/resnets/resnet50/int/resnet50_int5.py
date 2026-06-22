import torch
import torch.multiprocessing as mp
from pathlib import Path
from torch.distributed import destroy_process_group

from hatorch.utils.example_utils import (
    ExampleOptimizerConfig,
    ExampleRuntimeConfig,
    build_optimizers,
    build_trainer,
    dataloader_kwargs,
    run_training,
)

from hatorch.datasets import DatasetName
from hatorch.models import ResNet50
from hatorch.quantizers.common.scale_approximation import ScaleApproximation
from hatorch.quantizers.common.uniform_rounding import UniformRoundingMode
from hatorch.transforms import utils as transforms_utils
from hatorch.transforms.config import (
    ActivationQuantization,
    BiasQuantization,
    BoundaryQuantization,
    QuantizationRecipe,
    ScalePolicy,
    SigmoidStaircaseConfig,
    TransformPolicy,
    WeightQuantization,
)
from hatorch.utils.device import ddp_setup

torch.backends.cudnn.benchmark = False


OUTPUT_DIR = "results/RESNET50_INT5/"
FINAL_MODEL_PATH = str(Path(OUTPUT_DIR) / "resnet50_int5_final.pt")
DEVICE = "cuda"
BATCH_SIZE = 256
PLOT_CODEBOOK_USAGE = False
USE_DPP = True
MASTER_ADDR = "localhost"
MASTER_PORT = "12355"

EPOCHS = 30
EXTRA_EPOCHS = 0
CALIBRATION_EPOCHS = 1
SWITCH_BN_TO_RUNNING_STATS_EPOCH = 5
FREEZE_BN_RUNNING_STATS_EPOCH = 5
FREEZE_SCALE_DURING_TRAINING = False
SCALE_APPROXIMATION = ScaleApproximation.NONE
SCALE_APPROXIMATION_START_EPOCH = 1
FREEZE_APPROXIMATED_SCALES = False
ACTIVATION_ROUNDING_MODE = UniformRoundingMode.ROUND

SIGMOID_STAIRCASE_CONFIG: SigmoidStaircaseConfig | None = None

EVAL_HARD_NON_UNIFORM_SIGMOID_STAIRCASE = True

LR = 0.001
ETA_MIN = 0.000001
CALIBRATION_LR = 0.00001

ACTIVATION_BITS = 5
WEIGHTS_BITS = 5
FIRST_LAYER_WEIGHT_BITS = 8
FIRST_LAYER_ACTIVATION_BITS = 8
LAST_LAYER_WEIGHT_BITS = 8
LAST_LAYER_ACTIVATION_BITS = 8
PER_CHANNEL_WEIGHTS = False
WEIGHT_QUANTIZATION = WeightQuantization.uniform(
    bits=WEIGHTS_BITS,
    per_channel=PER_CHANNEL_WEIGHTS,
)


def create_quantization_parameters():
    return QuantizationRecipe(
        weights=WEIGHT_QUANTIZATION,
        activations=ActivationQuantization(
            bits=ACTIVATION_BITS,
            affine_zero_point=True,
            rounding=ACTIVATION_ROUNDING_MODE,
        ),
        bias=BiasQuantization(bits=32),
        boundaries=BoundaryQuantization(
            first_weight_bits=FIRST_LAYER_WEIGHT_BITS,
            input_activation_bits=FIRST_LAYER_ACTIVATION_BITS,
            last_weight_bits=LAST_LAYER_WEIGHT_BITS,
            output_activation_bits=LAST_LAYER_ACTIVATION_BITS,
        ),
        scale=ScalePolicy(
            approximation=SCALE_APPROXIMATION,
            start_epoch=SCALE_APPROXIMATION_START_EPOCH,
            fixed_point_bits=32,
            freeze_approximated_scales=FREEZE_APPROXIMATED_SCALES,
        ),
        transforms=TransformPolicy(fold_batch_norm=True),
    ).build()


def main(rank: int = 0, world_size: int = 1) -> None:

    runtime = ExampleRuntimeConfig(
        output_dir=OUTPUT_DIR,
        num_epochs=EPOCHS,
        extra_epochs=EXTRA_EPOCHS,
        calibration_epochs=CALIBRATION_EPOCHS,
        switch_bn_to_running_stats_epoch=SWITCH_BN_TO_RUNNING_STATS_EPOCH,
        freeze_bn_running_stats_epoch=FREEZE_BN_RUNNING_STATS_EPOCH,
        device=DEVICE,
        use_ddp=USE_DPP,
        freeze_scale_during_training=FREEZE_SCALE_DURING_TRAINING,
        eval_hard_non_uniform_sigmoid_staircase=EVAL_HARD_NON_UNIFORM_SIGMOID_STAIRCASE,
    )

    if runtime.use_ddp:
        ddp_setup(rank, world_size, MASTER_ADDR, MASTER_PORT)
    elif DEVICE == "cuda" and torch.cuda.is_available():
        torch.cuda.set_device(0)

    device = torch.device(
        f"cuda:{rank}" if DEVICE == "cuda" and torch.cuda.is_available() else "cpu"
    )
    trainer_device = device.type

    model = ResNet50(
        gpu_id=rank if device.type == "cuda" else 0,
        dataset_name=DatasetName.IMAGENET1K,
        batch_size=BATCH_SIZE,
        padding=0,
        pretrained=True,
        **dataloader_kwargs(),
    )

    quantization_parameters = create_quantization_parameters()

    transforms_utils.quantize_model(model.model, quantization_parameters, inplace=True)
    model.to_device(device)

    train_loader, valid_loader = model.dataloader.get_train_valid_loader()
    autoset_selection = transforms_utils.apply_autoset_weight_codebooks(
        model.model,
        train_loader,
        device,
        quantization_parameters.weight_quantizer_config,
    )
    if rank == 0 and autoset_selection:
        print(f"Selected autoset codebooks for {len(autoset_selection)} layer(s).")
    loss_fn = torch.nn.CrossEntropyLoss()

    optimization = ExampleOptimizerConfig(
        lr=LR,
        eta_min=ETA_MIN,
        calibration_lr=CALIBRATION_LR,
    )

    optimizer, lr_scheduler = build_optimizers(
        model.model,
        runtime,
        optimization,
    )
    trainer = build_trainer(
        model=model,
        trainer_device=trainer_device,
        train_loader=train_loader,
        valid_loader=valid_loader,
        loss_fn=loss_fn,
        optimizer=optimizer,
        lr_scheduler=lr_scheduler,
        runtime=runtime,
        quantization_config=quantization_parameters,
        rank=rank,
    )

    try:
        run_training(
            trainer=trainer,
            model_module=model.model,
            runtime=runtime,
            optimization=optimization,
            quantization_config=quantization_parameters,
            plot_codebook_usage=PLOT_CODEBOOK_USAGE,
            rank=rank,
        )
        if rank == 0:
            final_model_path = trainer.save_network(path=FINAL_MODEL_PATH)
            print(f"Saved final trained model to {final_model_path}")
            print(model.model)
    finally:
        if runtime.use_ddp and torch.distributed.is_initialized():
            destroy_process_group()


if __name__ == "__main__":
    if USE_DPP:
        world_size = torch.cuda.device_count()
        print(f"DDP: {world_size} GPUs")
        print(f"Batch size per GPU: {BATCH_SIZE}")
        print(f"Total effective batch size: {BATCH_SIZE * world_size}")
        if world_size < 2:
            raise RuntimeError("USE_DPP=True requires at least 2 CUDA devices.")
        mp.spawn(main, args=(world_size,), nprocs=world_size)
    else:
        main()
