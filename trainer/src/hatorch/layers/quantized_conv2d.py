"""
Quantized 2D convolution layer.

This module provides a quantized version of PyTorch's Conv2d layer,
using QuantTensor for proper quantization flow and configurable quantizers.
"""

import math
from typing import Optional, Union, Literal
import torch
import torch.nn as nn
import torch.nn.functional as F

from hatorch.layers.quantized_tensor import QuantTensor
from hatorch.quantizers.base import BaseQuantizer, IdentityQuantizer


class QuantConv2d(nn.Module):
    """
    Quantized 2D convolution layer.
    
    Applies quantization to weights, activations, and optionally bias.
    Supports different quantizers for each component.
    
    Args:
        in_channels: Number of input channels
        out_channels: Number of output channels
        kernel_size: Size of the convolution kernel
        stride: Stride of the convolution (default: 1)
        padding: Padding added to input (default: 0)
        dilation: Spacing between kernel elements (default: 1)
        groups: Number of blocked connections (default: 1)
        bias: Whether to include bias term (default: True)
        weight_quantizer: Quantizer for weights (default: IdentityQuantizer)
        activation_quantizer: Quantizer for activations (default: IdentityQuantizer)
        bias_quantizer: Quantizer for bias (default: IdentityQuantizer)
    """
    
    def __init__(
        self,
        in_channels: int,
        out_channels: int,
        kernel_size: Union[int, tuple],
        stride: Union[int, tuple] = 1,
        padding: Union[int, tuple] = 0,
        dilation: Union[int, tuple] = 1,
        groups: int = 1,
        bias: bool = True,
        padding_mode: Literal["zeros", "reflect", "replicate", "circular"] = "zeros",
        reversed_padding_repeated_twice: list[int] = None,
        weight_quantizer: Optional[BaseQuantizer] = None,
        activation_quantizer: Optional[BaseQuantizer] = None,
        bias_quantizer: Optional[BaseQuantizer] = None,
    ):
        super().__init__()
        
        self.in_channels = in_channels
        self.out_channels = out_channels
        self.kernel_size = kernel_size if isinstance(kernel_size, tuple) else (kernel_size, kernel_size)
        self.stride = stride if isinstance(stride, tuple) else (stride, stride)
        self.padding = padding if isinstance(padding, tuple) else (padding, padding)
        self.dilation = dilation if isinstance(dilation, tuple) else (dilation, dilation)
        self.padding_mode = padding_mode
        self.reversed_padding_repeated_twice = reversed_padding_repeated_twice
        self.groups = groups

        # Initialize weight and bias
        self.weight = nn.Parameter(torch.empty(out_channels, in_channels // groups, *self.kernel_size))
        if bias:
            self.bias = nn.Parameter(torch.empty(out_channels))
        else:
            self.register_parameter('bias', None)
        
        self.reset_parameters()
        
        # Set up quantizers
        self.weight_quantizer = weight_quantizer if weight_quantizer is not None else IdentityQuantizer()
        self.activation_quantizer = activation_quantizer if activation_quantizer is not None else IdentityQuantizer()
        self.bias_quantizer = bias_quantizer if bias_quantizer is not None else IdentityQuantizer()
    
    def reset_parameters(self) -> None:
        """Initialize parameters using Kaiming initialization."""
        nn.init.kaiming_uniform_(self.weight, a=math.sqrt(5))
        if self.bias is not None:
            fan_in, _ = nn.init._calculate_fan_in_and_fan_out(self.weight)
            bound = 1 / math.sqrt(fan_in)
            nn.init.uniform_(self.bias, -bound, bound)
    
    def forward(self, x: QuantTensor) -> QuantTensor:
        """
        Forward pass with quantization.
        
        Args:
            x: QuantTensor
            
        Returns:
            QuantTensor
        """
        if isinstance(x, QuantTensor) and isinstance(self.activation_quantizer, IdentityQuantizer):
            quant_input_qt = x
        elif isinstance(x, QuantTensor):
            quant_input_qt = self.activation_quantizer(x.value, x.scale)
        else:
            quant_input_qt = self.activation_quantizer(x)
        
        # Quantize weight (returns QuantTensor)
        quant_weight_qt = self.weight_quantizer(self.weight)

        # zero-point fusing into bias ----------------------------
        conv_bias = self.bias
        if not self.activation_quantizer.symmetric:
            ones_like_input = torch.ones(
                1,
                self.in_channels,
                1,
                1,
                device=self.weight.device,
                dtype=self.weight.dtype,
            )
            z = self.activation_quantizer.zero_point.clone()
            sw = self.weight_quantizer.current_scale()
            if sw.numel() > 1:
                scaled_weight_for_zp = sw.view(self.out_channels, 1, 1, 1) * self.weight
            else:
                scaled_weight_for_zp = sw * self.weight
            weight_sum = F.conv2d(
                ones_like_input,
                scaled_weight_for_zp,
                bias=None,
                stride=self.stride,
                padding=(0, 0) if self.padding_mode != "zeros" else self.padding,
                dilation=self.dilation,
                groups=self.groups,
            )
            zero_point_contribution = weight_sum * z
            fused_zero_point_bias = zero_point_contribution.reshape(-1)
            conv_bias = fused_zero_point_bias if conv_bias is None else conv_bias + fused_zero_point_bias
        # end zero-point fusing into bias ------------------------

        # Quantize bias if present (returns QuantTensor)
        bias_scale = quant_input_qt.scale.squeeze() * quant_weight_qt.scale.squeeze()
        if conv_bias is not None:
            # bias scale = input_scale * weight_scale
            # Handle per-channel weight scales: both should be [out_channels] or scalar
            quant_bias = self.bias_quantizer(conv_bias, bias_scale)
        else:
            quant_bias = None
        
        # Perform convolution with quantized values (extract .value from QuantTensors)
        if self.padding_mode != "zeros":
            conv_input = F.pad(
                quant_input_qt.value,
                self.reversed_padding_repeated_twice,
                mode=self.padding_mode,
            )
            padding = (0, 0)
        else:
            conv_input = quant_input_qt.value
            padding = self.padding

        output = F.conv2d(
            conv_input,
            quant_weight_qt.value,
            quant_bias,
            stride=self.stride,
            padding=padding,
            dilation=self.dilation,
            groups=self.groups,
        )

        # Compute output scale: weight_scale * input_scale
        # This is the proper scale for the output of convolution
        output_scale = bias_scale

        return QuantTensor(
            value=output,
            scale=output_scale,
            zero_point=None,
            bit_width=quant_input_qt.bit_width,  # Use input bit width for output
            signed=True,
        )
    
    def extra_repr(self) -> str:
        """Return string representation of layer parameters."""
        s = (f"{self.in_channels}, {self.out_channels}, kernel_size={self.kernel_size}, "
             f"stride={self.stride}")
        if self.padding != (0, 0):
            s += f", padding={self.padding}"
        if self.dilation != (1, 1):
            s += f", dilation={self.dilation}"
        if self.groups != 1:
            s += f", groups={self.groups}"
        if self.bias is None:
            s += ", bias=False"
        return s
    
    @classmethod
    def from_conv2d(
        cls,
        conv: nn.Conv2d,
        weight_quantizer: Optional[BaseQuantizer] = None,
        activation_quantizer: Optional[BaseQuantizer] = None,
        bias_quantizer: Optional[BaseQuantizer] = None,
    ) -> 'QuantConv2d':
        """
        Create a QuantConv2d from an existing Conv2d layer.
        
        Copies weights and configuration from the original layer.
        
        Args:
            conv: Original Conv2d layer
            weight_quantizer: Quantizer for weights
            activation_quantizer: Quantizer for activations
            bias_quantizer: Quantizer for bias

        Returns:
            QuantConv2d layer with copied parameters
        """
        quant_conv = cls(
            in_channels=conv.in_channels,
            out_channels=conv.out_channels,
            kernel_size=conv.kernel_size,
            stride=conv.stride,
            padding=conv.padding,
            dilation=conv.dilation,
            groups=conv.groups,
            bias=conv.bias is not None,
            padding_mode=conv.padding_mode,
            reversed_padding_repeated_twice=conv._reversed_padding_repeated_twice, # No idea why this is private
            weight_quantizer=weight_quantizer,
            activation_quantizer=activation_quantizer,
            bias_quantizer=bias_quantizer,
        )
        
        # Copy weights
        with torch.no_grad():
            quant_conv.weight.copy_(conv.weight)
            if conv.bias is not None:
                quant_conv.bias.copy_(conv.bias)
        
        return quant_conv
