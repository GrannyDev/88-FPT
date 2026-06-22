import torch

from hatorch.layers.quantized_conv2d_bn_relu import QuantConvBn2d
from hatorch.quantizers.base import IdentityQuantizer
from hatorch.quantizers.bias.bias_quantizer import BiasQuantizer


def test_switch_to_running_stats_keeps_tracking_until_true_freeze():
    layer = QuantConvBn2d(
        in_channels=1,
        out_channels=1,
        kernel_size=1,
        weight_quantizer=IdentityQuantizer(),
        activation_quantizer=IdentityQuantizer(),
        bias_quantizer=BiasQuantizer(enabled=False),
    )
    layer.train(True)
    layer.switch_bn_to_running_stats()

    before_switch_forward = layer.bn.running_mean.clone()
    layer(torch.randn(4, 1, 3, 3))
    after_switch_forward = layer.bn.running_mean.clone()

    layer.freeze_bn_running_stats_()
    layer(torch.randn(4, 1, 3, 3))
    after_true_freeze_forward = layer.bn.running_mean.clone()

    assert layer.freeze_bn is True
    assert layer.freeze_bn_running_stats is True
    assert layer.bn.training is False
    assert not torch.equal(before_switch_forward, after_switch_forward)
    assert torch.equal(after_switch_forward, after_true_freeze_forward)
