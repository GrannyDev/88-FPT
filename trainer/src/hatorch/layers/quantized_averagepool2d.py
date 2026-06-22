from torch.nn import AvgPool2d

from hatorch.layers.quantized_tensor import QuantTensor, round_ste


class QuantAveragePool2d(AvgPool2d):
    """
    Quantized version of nn.AvgPool2d.
    Handles QuantTensor inputs and outputs while performing average pooling.
    """
    def __init__(self, *args, round_output: bool = False, **kwargs):
        super().__init__(*args, **kwargs)
        self.round_output = bool(round_output)

    def forward(self, x: QuantTensor) -> QuantTensor:
        value = super().forward(x.value)
        x.value = round_ste(value) if self.round_output else value
        return x
