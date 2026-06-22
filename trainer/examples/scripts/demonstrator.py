import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import torch.nn as nn
import torch
from matplotlib.ticker import MultipleLocator
from pathlib import Path
import sys

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "src"))

from hatorch.quantizers.autograd.non_uniform_sigmoid_staircase_quantizer import LsqNonUniformSigmoidStaircaseQuantizer
from hatorch.quantizers.autograd.lsq_uniform_quantizer import LsqUniformQuantizer
from hatorch.quantizers.autograd.lsq_step_driven_quantizer import LsqStepDrivenQuantizer
from hatorch.layers.quantized_conv2d import QuantConv2d
from hatorch.layers.quantized_tensor import QuantTensor

matplotlib.rcParams.update({
    "font.family": "serif",
    "text.usetex": False,
})

####################################################################################################
# Stolen from hustzxd's github : https://github.com/hustzxd/LSQuantization/blob/master/STE_LSQ.ipynb
####################################################################################################

nbits = 4
Qn = -2 ** (nbits - 1)
Qp = 2 ** (nbits - 1) - 1
# g = math.sqrt(weight.numel() * Qp)
g = 1

targets = torch.tensor([-10, -7, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5, 6, 8, 11], dtype=torch.float).to("cpu")

Qn_rscm = torch.min(targets).item()
Qp_rscm =torch.max(targets).item()
g = 1

ws = []
wqs_int4 = []
wqs_rscm = []
wqs_sigmoid = []
weight_grads = []
weight_grads_rscm = []
weight_grads_sigmoid = []
bias_grads = []
bias_grads_rscm = []
bias_grads_sigmoid = []
sigmoid_tau_sweep = [1.0, 4.0, 16.0]
wqs_sigmoid_by_tau = {tau: [] for tau in sigmoid_tau_sweep}
weight_grads_sigmoid_by_tau = {tau: [] for tau in sigmoid_tau_sweep}
output_dir = Path("examples_log")
output_dir.mkdir(exist_ok=True)


# Compute for uniform, step-driven, and sigmoid-staircase quantizers.
for i in range(5000):
    value = (i * 0.01) - 25
    weight = torch.tensor([value], requires_grad=True)
    bias = torch.tensor([0.0], requires_grad=True)
    alpha_int4 = torch.ones([], requires_grad=True)
    bias_int4 = torch.zeros([], requires_grad=True)

    ws.append(weight.data.item())

    # INT4 quantization
    w_q_int4 = LsqUniformQuantizer.apply(weight, alpha_int4, bias_int4, Qn, Qp) * alpha_int4 + bias_int4
    output = w_q_int4 + bias

    # Backward pass
    output.backward(retain_graph=True)
    
    # Store results
    wqs_int4.append(w_q_int4.data.item())
    weight_grads.append(weight.grad.item())
    bias_grads.append(bias_int4.grad.item())

    # Non-uniform RSCM quantization
    weight_rscm = torch.tensor([value], requires_grad=True)
    bias_rscm = torch.tensor([0.0], requires_grad=True)
    alpha_rscm = torch.ones([], requires_grad=True)

    w_q_rscm = LsqStepDrivenQuantizer.apply(weight_rscm - bias_rscm, alpha_rscm, targets, Qn_rscm, Qp_rscm)
    output_rscm = w_q_rscm * alpha_rscm + bias_rscm

    # Backward pass for RSCM
    output_rscm.backward()
    
    # Store RSCM results
    wqs_rscm.append(w_q_rscm.data.item())
    weight_grads_rscm.append(weight_rscm.grad.item())
    bias_grads_rscm.append(bias_rscm.grad.item())

    for tau in sigmoid_tau_sweep:
        weight_sigmoid = torch.tensor([value], requires_grad=True)
        alpha_sigmoid = torch.ones([], requires_grad=True)
        w_q_sigmoid = LsqNonUniformSigmoidStaircaseQuantizer.apply(
            weight_sigmoid,
            alpha_sigmoid,
            targets,
            Qn_rscm,
            Qp_rscm,
            tau=torch.tensor(tau),
            hard_forward=False,
        )
        output_sigmoid = w_q_sigmoid * alpha_sigmoid
        output_sigmoid.backward()
        wqs_sigmoid_by_tau[tau].append(w_q_sigmoid.data.item())
        weight_grads_sigmoid_by_tau[tau].append(weight_sigmoid.grad.item())


def save_figure(fig, stem: str) -> None:
    png_path = output_dir / f"{stem}.png"
    pdf_path = output_dir / f"{stem}.pdf"
    pgf_path = output_dir / f"{stem}.pgf"
    fig.savefig(png_path, dpi=150, bbox_inches='tight')
    fig.savefig(pdf_path, format='pdf', bbox_inches='tight')
    fig.savefig(pgf_path, format='pgf', bbox_inches='tight')
    print(f"Saved {png_path}")
    print(f"Saved {pdf_path}")
    print(f"Saved {pgf_path}")


def finish_axis(ax) -> None:
    ax.set_xlabel('v', fontsize=15)
    ax.set_xlim(-12, 12)
    ax.legend()
    ax.grid(True, alpha=0.3)
    ax.xaxis.set_major_locator(MultipleLocator(2))
    ax.xaxis.set_minor_locator(MultipleLocator(1))

# Tau comparison: show how the sigmoid staircase approaches the hard step-driven path.
fig_tau, ax_tau = plt.subplots(1, 1, figsize=(10, 5))
ax_tau.plot(ws, wqs_rscm, label='Hard step-driven', color='#c85257', linewidth=2.0, linestyle='--')
for tau, values in wqs_sigmoid_by_tau.items():
    ax_tau.plot(ws, values, label=f'tau={tau:g}', linewidth=1.8, alpha=0.85)
ax_tau.set_ylabel('vhat', fontsize=15)
finish_axis(ax_tau)
plt.tight_layout()
save_figure(fig_tau, "lsq_demonstrator_sigmoid_tau")
plt.close(fig_tau)

# Weight-gradient comparison: hard step-driven STE vs sigmoid staircase.
fig_grad, ax_grad = plt.subplots(1, 1, figsize=(10, 5))
ax_grad.plot(ws, weight_grads_rscm, label='Hard step-driven', color='#c85257', linewidth=2.0, linestyle='--')
for tau, values in weight_grads_sigmoid_by_tau.items():
    ax_grad.plot(ws, values, label=f'tau={tau:g}', linewidth=1.8, alpha=0.85)
ax_grad.set_ylabel('dL/dw', fontsize=15)
finish_axis(ax_grad)
plt.tight_layout()
save_figure(fig_grad, "lsq_demonstrator_sigmoid_weight_gradient")
plt.close(fig_grad)

####################################################################################################
# Realistic convolution operation with gradient statistics
####################################################################################################

# print("\n" + "="*80)
# print("Realistic Convolution Operation with LSQ Quantization")
# print("="*80)
#
# # Create a simple input and convolution layer
# torch.manual_seed(42)
# input_tensor = torch.randn(1, 3, 32, 32, requires_grad=True)  # Batch=1, Channels=3, 32x32 image
# target = torch.randn(1, 16, 32, 32)  # Target output
#
# # Create quantizers for weight and activation
# weight_quantizer = LsqUniformQuantizer(
#     bit_width=nbits,
#     signed=True,
#     symmetric=True,
#     per_channel=False,
#     is_activation=False,
#     auto_compute_g=True,
# )
#
# activation_quantizer = LsqUniformQuantizer(
#     bit_width=nbits,
#     signed=False,
#     symmetric=False,
#     per_channel=False,
#     is_activation=True,
#     auto_compute_g=True,
# )
#
# bias_quantizer = None  # No quantization for bias in this example
#
# # Create quantized conv layer
# conv = QuantConv2d(
#     in_channels=3,
#     out_channels=16,
#     kernel_size=3,
#     stride=1,
#     padding=1,
#     bias=True,
#     weight_quantizer=weight_quantizer,
#     activation_quantizer=activation_quantizer,
#     bias_quantizer=bias_quantizer,
# )
#
# qt_tensor = QuantTensor(
#     value=input_tensor,
#     scale=torch.tensor(1.0),
#     zero_point=torch.tensor(0.0),
#     bit_width=nbits,
#     signed=False,
# )
#
# # Forward pass
# output = conv(qt_tensor)
#
# # Compute loss
# loss = nn.MSELoss()(output, target)
#
# # Backward pass
# loss.backward()
#
# # Collect gradient statistics
# print("\nGradient Statistics:")
# print("-" * 80)
#
# # Scale gradients (from weight quantizer)
# if conv.weight_quantizer.scale.grad is not None:
#     scale_grad = conv.weight_quantizer.scale.grad
#     print(f"Weight Scale Gradient:")
#     print(f"  Max:  {scale_grad.max().item():.6e}")
#     print(f"  Mean: {scale_grad.mean().item():.6e}")
#     print(f"  Min:  {scale_grad.min().item():.6e}")
# else:
#     print("Weight Scale Gradient: None")
#
# # Weight gradients
# if conv.weight.grad is not None:
#     weight_grad = conv.weight.grad
#     print(f"\nWeight Gradient:")
#     print(f"  Max:  {weight_grad.max().item():.6e}")
#     print(f"  Mean: {weight_grad.mean().item():.6e}")
#     print(f"  Min:  {weight_grad.min().item():.6e}")
# else:
#     print("\nWeight Gradient: None")
#
# # Bias gradients
# if conv.bias is not None and conv.bias.grad is not None:
#     bias_grad = conv.bias.grad
#     print(f"\nBias Gradient:")
#     print(f"  Max:  {bias_grad.max().item():.6e}")
#     print(f"  Mean: {bias_grad.mean().item():.6e}")
#     print(f"  Min:  {bias_grad.min().item():.6e}")
# else:
#     print("\nBias Gradient: None")
#
# # Bias scale gradients (from bias quantizer)
# if bias_quantizer:
#     if conv.bias_quantizer.scale.grad is not None:
#         bias_scale_grad = conv.bias_quantizer.scale.grad
#         print(f"\nBias Scale Gradient:")
#         print(f"  Max:  {bias_scale_grad.max().item():.6e}")
#         print(f"  Mean: {bias_scale_grad.mean().item():.6e}")
#         print(f"  Min:  {bias_scale_grad.min().item():.6e}")
#     else:
#         print("\nBias Scale Gradient: None")
#
# # Activation scale gradients
# if conv.activation_quantizer.scale.grad is not None:
#     act_scale_grad = conv.activation_quantizer.scale.grad
#     print(f"\nActivation Scale Gradient:")
#     print(f"  Max:  {act_scale_grad.max().item():.6e}")
#     print(f"  Mean: {act_scale_grad.mean().item():.6e}")
#     print(f"  Min:  {act_scale_grad.min().item():.6e}")
# else:
#     print("\nActivation Scale Gradient: None")
#
# # Activation zero-point gradients
# if conv.activation_quantizer.zero_point is not None and conv.activation_quantizer.zero_point.grad is not None:
#     act_zp_grad = conv.activation_quantizer.zero_point.grad
#     print(f"\nActivation Zero-Point Gradient:")
#     print(f"  Max:  {act_zp_grad.max().item():.6e}")
#     print(f"  Mean: {act_zp_grad.mean().item():.6e}")
#     print(f"  Min:  {act_zp_grad.min().item():.6e}")
# else:
#     print("\nActivation Zero-Point Gradient: None")
#
# print("\n" + "="*80)
