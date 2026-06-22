"""
Quantized Tensor implementation inspired by Brevitas.

This module provides a QuantTensor class that encapsulates a quantized tensor
along with its quantization parameters (scale and zero-point).
"""

from typing import Optional, Tuple, Union
import torch
from torch import Tensor


def round_ste(value: Tensor) -> Tensor:
    rounded = torch.round(value)
    return value + (rounded - value).detach()


class QuantTensor:
    """
    A Brevitas-style quantized tensor that holds the quantized values along with
    scale and zero-point quantization parameters.
    
    Attributes:
        value (Tensor): The quantized tensor values (typically int representation).
        scale (Tensor): The scaling factor(s) for dequantization.
        zero_point (Tensor): The zero-point offset(s) for dequantization.
        bit_width (Optional[Tensor]): The bit width used for quantization.
        signed (bool): Whether the quantized values are signed.
    """
    
    def __init__(
        self,
        value: Tensor,
        scale: Tensor,
        zero_point: Optional[Tensor] = None,
        bit_width: Optional[int] = None,
        signed: bool = True,
    ):
        """
        Initialize a QuantTensor.
        
        Args:
            value: The quantized tensor values.
            scale: The scaling factor for dequantization.
            zero_point: The zero-point offset (default: None, treated as 0).
            bit_width: The bit width used for quantization (default: None).
            signed: Whether the quantization is signed (default: True).
        """
        self.value = value
        self.scale = scale
        self.zero_point = zero_point if zero_point is not None else torch.zeros_like(scale)
        self.bit_width = bit_width
        self.signed = signed
    
    def detach(self) -> 'QuantTensor':
        """
        Detach all tensors from the computation graph.
        
        Returns:
            A new QuantTensor with detached tensors.
        """
        return QuantTensor(
            value=self.value.detach(),
            scale=self.scale.detach(),
            zero_point=self.zero_point.detach() if self.zero_point is not None else None,
            bit_width=self.bit_width.detach() if self.bit_width is not None else None,
            signed=self.signed,
        )
    
    def clone(self) -> 'QuantTensor':
        """
        Create a deep copy of this QuantTensor.
        
        Returns:
            A new QuantTensor with cloned tensors.
        """
        return QuantTensor(
            value=self.value.clone(),
            scale=self.scale.clone(),
            zero_point=self.zero_point.clone() if self.zero_point is not None else None,
            bit_width=self.bit_width.clone() if self.bit_width is not None else None,
            signed=self.signed,
        )
    
    def to(self, *args, **kwargs) -> 'QuantTensor':
        """
        Move and/or cast the tensors to a specified device or dtype.
        
        Returns:
            A new QuantTensor with converted tensors.
        """
        return QuantTensor(
            value=self.value.to(*args, **kwargs),
            scale=self.scale.to(*args, **kwargs),
            zero_point=self.zero_point.to(*args, **kwargs) if self.zero_point is not None else None,
            bit_width=self.bit_width.to(*args, **kwargs) if self.bit_width is not None else None,
            signed=self.signed,
        )
    
    def cpu(self) -> 'QuantTensor':
        """Move all tensors to CPU."""
        return self.to('cpu')
    
    def cuda(self, device: Optional[Union[int, str]] = None) -> 'QuantTensor':
        """Move all tensors to CUDA."""
        return self.to('cuda' if device is None else f'cuda:{device}')
    
    @property
    def device(self) -> torch.device:
        """Return the device of the value tensor."""
        return self.value.device
    
    @property
    def dtype(self) -> torch.dtype:
        """Return the dtype of the value tensor."""
        return self.value.dtype
    
    @property
    def shape(self) -> torch.Size:
        """Return the shape of the value tensor."""
        return self.value.shape

    def size(self, dim: Optional[int] = None) -> torch.Size | int:
        """Mirror Tensor.size() on the wrapped value tensor."""
        return self.value.size() if dim is None else self.value.size(dim)

    def view(self, *shape) -> 'QuantTensor':
        """Return a view of the wrapped value tensor while preserving quantization metadata."""
        return QuantTensor(
            value=self.value.view(*shape),
            scale=self.scale,
            zero_point=self.zero_point,
            bit_width=self.bit_width,
            signed=self.signed,
        )

    def reshape(self, *shape) -> 'QuantTensor':
        """Return a reshaped wrapped value tensor while preserving quantization metadata."""
        return QuantTensor(
            value=self.value.reshape(*shape),
            scale=self.scale,
            zero_point=self.zero_point,
            bit_width=self.bit_width,
            signed=self.signed,
        )

    @property
    def requires_grad(self) -> bool:
        """Check if any tensor requires gradients."""
        return (self.value.requires_grad or 
                self.scale.requires_grad or 
                (self.zero_point is not None and self.zero_point.requires_grad))
    
    def __repr__(self) -> str:
        """Return a string representation of the QuantTensor."""
        return (f"QuantTensor(value={self.value.shape}, "
                f"scale={self.scale.shape}, "
                f"zero_point={self.zero_point.shape if self.zero_point is not None else None}, "
                f"bit_width={self.bit_width.item() if self.bit_width is not None and self.bit_width.numel() == 1 else self.bit_width}, "
                f"signed={self.signed}, "
                f"device={self.device})")
    
    def __str__(self) -> str:
        """Return a string representation of the QuantTensor."""
        return self.__repr__()
