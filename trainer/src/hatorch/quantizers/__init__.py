from hatorch.quantizers.base import BaseQuantizer, IdentityQuantizer
from hatorch.quantizers.common.scale_approximation import ScaleApproximation
from hatorch.quantizers.common.uniform_rounding import UniformRoundingMode
from hatorch.quantizers.init.lsq_uniform import LsqUniformQuantizer
from hatorch.quantizers.init.non_uniform_sigmoid_staircase import NonUniformSigmoidStaircaseQuantizer
from hatorch.quantizers.init.step_driven import StepDrivenQuantizer

LsqQuantizer = LsqUniformQuantizer

__all__ = [
    "BaseQuantizer",
    "IdentityQuantizer",
    "LsqQuantizer",
    "LsqUniformQuantizer",
    "NonUniformSigmoidStaircaseQuantizer",
    "ScaleApproximation",
    "StepDrivenQuantizer",
    "UniformRoundingMode",
]
