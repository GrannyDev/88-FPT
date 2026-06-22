import torch
from torch import Tensor
from torch.nn import Module

from hatorch.layers.quantized_tensor import QuantTensor


class Quantize(Module):
    """
    Quantization layer that converts a regular PyTorch tensor to a QuantTensor.
    
    This layer is typically placed at the beginning of a quantized network to convert
    the input tensor into a QuantTensor with identity quantization (scale=1, zero_point=0).
    This allows the network to properly propagate quantization information through
    subsequent layers.
    
    Args:
        bit_width: Bit width for the quantized representation (default: 8)
        signed: Whether the quantization is signed (default: True)
    """
    
    def __init__(self, bit_width: int = 8, signed: bool = True):
        super().__init__()
        self.bit_width = bit_width
        self.signed = signed
    
    def forward(self, x: Tensor) -> QuantTensor:
        """
        Convert a regular tensor to a QuantTensor with identity quantization.
        
        Args:
            x: Regular PyTorch tensor input
            
        Returns:
            QuantTensor with scale=1 and zero_point=0 (identity quantization)
        """
        return QuantTensor(
            value=x,
            scale=torch.ones(1, device=x.device, dtype=x.dtype),
            zero_point=torch.zeros(1, device=x.device, dtype=x.dtype),
            bit_width=self.bit_width,
            signed=self.signed,
        )
