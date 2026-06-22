import torch

from hatorch.layers.quantized_conv2d_bn_relu import QuantConvBn2d
from hatorch.quantizers.bias.bias_quantizer import BiasQuantizer


def test_bn_running_stat_blend_uses_bias_free_running_mean_in_fused_bias():
    layer = QuantConvBn2d(
        in_channels=1,
        out_channels=1,
        kernel_size=1,
        bias=True,
        bias_quantizer=BiasQuantizer(enabled=False),
        fold_batch_norm=True,
    )
    layer.train(True)
    layer.set_bn_running_stat_blend(0.5)

    with torch.no_grad():
        layer.weight.zero_()
        layer.bias.fill_(10.0)
        layer.bn.weight.fill_(1.0)
        layer.bn.bias.zero_()
        layer.bn.running_mean.fill_(10.0)
        layer.bn.running_var.fill_(0.0)

    x = torch.zeros(2, 1, 1, 1)
    out = layer(x)

    # With zero weights and a conv bias exactly matched by BN running_mean,
    # the fused output should stay at zero during blended training as well.
    assert torch.allclose(out.value, torch.zeros_like(out.value), atol=1e-5)
