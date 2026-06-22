from torch import Tensor
from torch.nn import Module

from hatorch.layers.quantized_tensor import QuantTensor


class Dequantize(Module):
    """
    Dequantization layer that extracts the tensor value from a QuantTensor.
    
    This layer is typically placed at the end of a quantized network to convert
    the output QuantTensor back to a regular PyTorch tensor.
    """
    
    def forward(self, x: QuantTensor) -> Tensor:
        """
        Extract the dequantized value from a QuantTensor.
        
        Args:
            x: QuantTensor input
            
        Returns:
            Regular PyTorch tensor (the dequantized value)
        """
        # Get the scale and value
        scale = x.scale
        value = x.value
        
        # Handle scale broadcasting for different tensor shapes
        if isinstance(scale, Tensor) and scale.numel() > 1:
            # Per-channel quantization - scale needs proper shape for broadcasting
            if value.dim() == 4:
                # Conv output: [B, C, H, W], scale should be [1, C, 1, 1]
                if scale.numel() == value.shape[1]:  # C channels
                    scale = scale.view(1, -1, 1, 1)
                else:
                    # Fallback: try to match first dimension
                    scale = scale.view(-1, 1, 1, 1)
            elif value.dim() == 2:
                # Linear output: [B, Features], scale should be [1, Features]
                if scale.numel() == value.shape[1]:  # Features dimension
                    scale = scale.view(1, -1)
                elif scale.numel() == value.shape[0]:  # Batch dimension (shouldn't happen but handle it)
                    scale = scale.view(-1, 1)
                else:
                    # Try to broadcast - reshape to match the larger dimension
                    if scale.numel() < value.shape[0]:
                        scale = scale.view(1, -1)
                    else:
                        scale = scale.view(-1, 1)
            elif value.dim() == 1:
                # 1D tensor: [Features], scale should be [Features]
                # Already correct shape, but ensure it matches
                if scale.numel() != value.numel():
                    # Try to make it work - unsqueeze if needed
                    scale = scale.view(-1)
        
        return value * scale
