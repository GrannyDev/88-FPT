# FPT Submission 88: FPGA-Aware Co-Design of Quantized DNNs with Reconfigurable Single Constant Multipliers

## Section III: FPGA-AWARE RSCM CO-DESIGN

Minizinc models are available under:
```
cp_solver/xdd/RSCMx/model.mzn
```

Our recorded output is saved as minizinc_out.txt in the same folder.
The corresponding verilog implementations and their testbenches are available under the generated_verilog_tests/ subfolder.

To run a model, minizinc and chuffed must be installed, then:

```
minizinc model.mzn --solver chuffed --statistics -a
```

## Section V: EVALUATION

The training framework is available under the trainer/ folder.

To reproduce an entry from the result tables, simply run
```
python trainer/examples/dataset/network/quant_type/network_quant_type.py
```

Our runs logs are also provided in the same folder.

The recommended way to install the framework is to create a python virtual environment:

```
python -m venv myvenv
source myvenv/bin/activate

pip install torch torchvision
pip install -e trainer/
```