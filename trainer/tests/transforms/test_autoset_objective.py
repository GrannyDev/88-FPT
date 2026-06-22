import pytest
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, TensorDataset

from hatorch.layers.quantized_tensor import QuantTensor
from hatorch.transforms import utils as transforms_utils
from hatorch.transforms.config import (
    ActivationQuantization,
    AutosetObjective,
    QuantizationRecipe,
    WeightQuantization,
    WeightQuantizerKind,
)


class _PerChannelActivationQuantizer(nn.Module):
    def forward(self, x):
        scale = torch.tensor([10.0, 20.0, 30.0], device=x.device, dtype=x.dtype)
        zero_point = torch.tensor([100.0, 200.0, 300.0], device=x.device, dtype=x.dtype)
        return QuantTensor(x, scale, zero_point)


class _LayerWithPerChannelActivation(nn.Module):
    def __init__(self):
        super().__init__()
        self.activation_quantizer = _PerChannelActivationQuantizer()


def _candidate_file(tmp_path):
    path = tmp_path / "sets.txt"
    path.write_text("[-3, -1, 0, 1, 3]\n[-4, -2, 0, 2, 4]\n", encoding="utf-8")
    return str(path)


def _quantized_linear_autoset_model(tmp_path, objective):
    model = nn.Sequential(nn.Linear(4, 3))
    config = QuantizationRecipe(
        weights=WeightQuantization.autoset_codebook(
            path=_candidate_file(tmp_path),
            coefficients=5,
            kind=WeightQuantizerKind.STEP_DRIVEN,
            batches=1,
            objective=objective,
        ),
        activations=ActivationQuantization(bits=4),
    ).build()
    transforms_utils.quantize_model(model, config, inplace=True)
    return model, config


def test_fisher_weighted_autoset_selects_codebook(tmp_path):
    model, config = _quantized_linear_autoset_model(tmp_path, AutosetObjective.FISHER_WEIGHTED_OUTPUT_MSE)
    loader = DataLoader(
        TensorDataset(torch.randn(8, 4), torch.randint(0, 3, (8,))),
        batch_size=4,
    )

    selected = transforms_utils.apply_autoset_weight_codebooks(
        model,
        loader,
        torch.device("cpu"),
        config.weight_quantizer_config,
    )

    assert len(selected) == 1
    assert next(iter(selected.values())) in (
        [-3.0, -1.0, 0.0, 1.0, 3.0],
        [-4.0, -2.0, 0.0, 2.0, 4.0],
    )


def test_fisher_weighted_autoset_requires_labels(tmp_path):
    model, config = _quantized_linear_autoset_model(tmp_path, AutosetObjective.FISHER_WEIGHTED_OUTPUT_MSE)
    loader = DataLoader(torch.randn(8, 4), batch_size=4)

    with pytest.raises(ValueError, match="requires dataloader batches with labels"):
        transforms_utils.apply_autoset_weight_codebooks(
            model,
            loader,
            torch.device("cpu"),
            config.weight_quantizer_config,
        )


def test_distributed_nonzero_rank_receives_autoset_selection(tmp_path, monkeypatch):
    model, config = _quantized_linear_autoset_model(tmp_path, AutosetObjective.OUTPUT_MSE)
    layer_name, quantized_layer = transforms_utils._autoset_layers(model)[0]
    selected = {layer_name: [-4.0, -2.0, 0.0, 2.0, 4.0]}

    monkeypatch.setattr(torch.distributed, "is_available", lambda: True)
    monkeypatch.setattr(torch.distributed, "is_initialized", lambda: True)
    monkeypatch.setattr(torch.distributed, "get_rank", lambda: 1)
    monkeypatch.setattr(torch.distributed, "get_world_size", lambda: 2)

    def fake_broadcast_object_list(payload, src):
        assert src == 0
        payload[0] = selected

    monkeypatch.setattr(torch.distributed, "broadcast_object_list", fake_broadcast_object_list)
    monkeypatch.setattr(torch.distributed, "all_reduce", lambda tensor, op=None: tensor)

    returned = transforms_utils.apply_autoset_weight_codebooks(
        model,
        DataLoader(torch.randn(8, 4), batch_size=4),
        torch.device("cpu"),
        config.weight_quantizer_config,
    )

    assert returned == selected
    assert quantized_layer.weight_quantizer.bit_width.detach().cpu().tolist() == selected[layer_name]


def test_autoset_quantized_activation_broadcasts_quant_tensor_zero_point():
    layer_input = QuantTensor(
        torch.ones(1, 3, 2, 2),
        torch.tensor([1.0, 2.0, 3.0]),
        torch.tensor([0.5, 1.5, 2.5]),
    )

    activation = transforms_utils._autoset_quantized_activation(
        _LayerWithPerChannelActivation(),
        layer_input,
    )

    expected = torch.tensor([115.0, 270.0, 465.0]).view(1, 3, 1, 1).expand(1, 3, 2, 2)
    assert torch.equal(activation, expected)
