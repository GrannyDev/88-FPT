include "globals.mzn";

% -----------------------------------------------------------------------------
% 3dd strict/all-different structural model
%
% This is the reduced form that is valid when every final coefficient must be
% different.  In that case every bottom-adder case must depend on both first
% stage adders; otherwise a selector dimension is ignored and duplicates are
% inevitable.  Since the bottom adder has only two operands, this also implies:
%
%   beta[b] = 0
%   coeff[l,r,b] = alpha_left[b] * left_add1_output[l]
%                + alpha_right[b] * right_add1_output[r]
%
% Therefore this model removes all bottom-source Boolean variables and all
% direct-input bottom paths.  It searches only the realizable L/R bottom cases.
% -----------------------------------------------------------------------------

% ------------------------------ user constants ------------------------------
int: n = 128;
int: left_add1_sel_bits = 3;
int: right_add1_sel_bits = 2;
int: add3_sel_bits = 2;
int: lut_size = 6;
bool: single_op_bit_mode = true;
int: input_bw = 7;
int: coeff_bw = 9;
int: left_add1_output_bw = 5;
int: right_add1_output_bw = 6;

% ----------------------------- inferred constants ---------------------------
int: max_coeff = 2^(coeff_bw - 1) - 1;
int: min_coeff = -2^(coeff_bw - 1) + 1;

int: n_left_add1_coeffs = 2^left_add1_sel_bits;
int: n_right_add1_coeffs = 2^right_add1_sel_bits;
int: n_add3_coeffs = 2^add3_sel_bits;
int: n_coeffs = n_left_add1_coeffs * n_right_add1_coeffs * n_add3_coeffs;

set of int: LEFT_ADD1_CASES = 1..n_left_add1_coeffs;
set of int: RIGHT_ADD1_CASES = 1..n_right_add1_coeffs;
set of int: ADD3_CASES = 1..n_add3_coeffs;
set of int: FLAT = 1..n_coeffs;

int: min_coeff_bw = ceil(log2(int2float(n + 1)));
int: min_left_add1_output_bw = ceil(log2(int2float(n_left_add1_coeffs + 1)));
int: min_right_add1_output_bw = ceil(log2(int2float(n_right_add1_coeffs + 1)));

int: left_add1_output_bw_max = 2^(left_add1_output_bw - 1) - 1;
int: left_add1_output_bw_min = -2^(left_add1_output_bw - 1) + 1;
int: right_add1_output_bw_max = 2^(right_add1_output_bw - 1) - 1;
int: right_add1_output_bw_min = -2^(right_add1_output_bw - 1) + 1;

int: left_add1_max_card_shift_values = lut_size - left_add1_sel_bits;
int: right_add1_max_card_shift_values = lut_size - right_add1_sel_bits;
int: add3_max_card_shift_values = lut_size - add3_sel_bits;

int: left_add1_half_n = n_left_add1_coeffs div 2;
int: right_add1_half_n = n_right_add1_coeffs div 2;
int: add3_half_n = n_add3_coeffs div 2;

set of int: LEFT_ADD1_SHIFT_IDXS = 1..left_add1_output_bw;
set of int: RIGHT_ADD1_SHIFT_IDXS = 1..right_add1_output_bw;
set of int: ADD3_SHIFT_IDXS = 1..coeff_bw;

array[LEFT_ADD1_SHIFT_IDXS] of int: left_add1_shift_value =
    [2^(k - 1) | k in LEFT_ADD1_SHIFT_IDXS];
array[RIGHT_ADD1_SHIFT_IDXS] of int: right_add1_shift_value =
    [2^(k - 1) | k in RIGHT_ADD1_SHIFT_IDXS];
array[ADD3_SHIFT_IDXS] of int: add3_shift_value =
    [2^(k - 1) | k in ADD3_SHIFT_IDXS];

constraint
    n_coeffs = n /\
    coeff_bw >= min_coeff_bw /\
    left_add1_output_bw >= min_left_add1_output_bw /\
    right_add1_output_bw >= min_right_add1_output_bw /\
    left_add1_max_card_shift_values >= 1 /\
    right_add1_max_card_shift_values >= 1 /\
    add3_max_card_shift_values >= 2;  % strict mode needs left and right shifts

constraint
    single_op_bit_mode ->
        (n_left_add1_coeffs mod 2 = 0 /\
         n_right_add1_coeffs mod 2 = 0 /\
         n_add3_coeffs mod 2 = 0);

% -------------------------- first-stage adders -------------------------------

array[LEFT_ADD1_CASES] of var left_add1_output_bw_min..left_add1_output_bw_max: left_add1_output;
array[LEFT_ADD1_CASES] of var {-1, 1}: left_lhs_sign;
array[LEFT_ADD1_CASES] of var {-1, 1}: left_rhs_sign;
array[LEFT_ADD1_CASES] of var LEFT_ADD1_SHIFT_IDXS: left_lhs_shift_idx;
array[LEFT_ADD1_CASES] of var LEFT_ADD1_SHIFT_IDXS: left_rhs_shift_idx;
array[LEFT_ADD1_CASES] of var bool: left_rhs_enabled;
array[LEFT_ADD1_SHIFT_IDXS] of var bool: left_shift_used;

array[RIGHT_ADD1_CASES] of var right_add1_output_bw_min..right_add1_output_bw_max: right_add1_output;
array[RIGHT_ADD1_CASES] of var {-1, 1}: right_lhs_sign;
array[RIGHT_ADD1_CASES] of var {-1, 1}: right_rhs_sign;
array[RIGHT_ADD1_CASES] of var RIGHT_ADD1_SHIFT_IDXS: right_lhs_shift_idx;
array[RIGHT_ADD1_CASES] of var RIGHT_ADD1_SHIFT_IDXS: right_rhs_shift_idx;
array[RIGHT_ADD1_CASES] of var bool: right_rhs_enabled;
array[RIGHT_ADD1_SHIFT_IDXS] of var bool: right_shift_used;

constraint forall(l in LEFT_ADD1_CASES) (
    (left_lhs_sign[l] = 1 \/ left_rhs_sign[l] = 1) /\
    (not left_rhs_enabled[l] -> left_rhs_sign[l] = 1 /\ left_rhs_shift_idx[l] = 1) /\
    left_add1_output[l] =
        left_lhs_sign[l] * left_add1_shift_value[left_lhs_shift_idx[l]] +
        bool2int(left_rhs_enabled[l]) * left_rhs_sign[l] * left_add1_shift_value[left_rhs_shift_idx[l]]
);

constraint forall(k in LEFT_ADD1_SHIFT_IDXS) (
    left_shift_used[k] <-> exists(l in LEFT_ADD1_CASES)(
        left_lhs_shift_idx[l] = k \/
        (left_rhs_enabled[l] /\ left_rhs_shift_idx[l] = k)
    )
);

constraint single_op_bit_mode ->
let {
    var int: neg_count = sum(l in LEFT_ADD1_CASES)(
        bool2int(left_lhs_sign[l] = -1) +
        bool2int(left_rhs_enabled[l] /\ left_rhs_sign[l] = -1)
    )
} in (neg_count = 0 \/ neg_count = left_add1_half_n \/ neg_count = n_left_add1_coeffs);

constraint
    (
        sum(k in LEFT_ADD1_SHIFT_IDXS)(bool2int(left_shift_used[k])) <= left_add1_max_card_shift_values /\
        forall(l in LEFT_ADD1_CASES)(left_lhs_shift_idx[l] = left_lhs_shift_idx[1]) /\
        forall(l in LEFT_ADD1_CASES)(left_lhs_sign[l] = 1)
    ) \/
    (
        sum(k in LEFT_ADD1_SHIFT_IDXS)(bool2int(left_shift_used[k])) <= left_add1_max_card_shift_values - 1
    );

constraint symmetry_breaking_constraint(
    forall(l in 1..n_left_add1_coeffs - 1)(left_add1_output[l] < left_add1_output[l + 1])
);

constraint forall(r in RIGHT_ADD1_CASES) (
    (right_lhs_sign[r] = 1 \/ right_rhs_sign[r] = 1) /\
    (not right_rhs_enabled[r] -> right_rhs_sign[r] = 1 /\ right_rhs_shift_idx[r] = 1) /\
    right_add1_output[r] =
        right_lhs_sign[r] * right_add1_shift_value[right_lhs_shift_idx[r]] +
        bool2int(right_rhs_enabled[r]) * right_rhs_sign[r] * right_add1_shift_value[right_rhs_shift_idx[r]]
);

constraint forall(k in RIGHT_ADD1_SHIFT_IDXS) (
    right_shift_used[k] <-> exists(r in RIGHT_ADD1_CASES)(
        right_lhs_shift_idx[r] = k \/
        (right_rhs_enabled[r] /\ right_rhs_shift_idx[r] = k)
    )
);

constraint single_op_bit_mode ->
let {
    var int: neg_count = sum(r in RIGHT_ADD1_CASES)(
        bool2int(right_lhs_sign[r] = -1) +
        bool2int(right_rhs_enabled[r] /\ right_rhs_sign[r] = -1)
    )
} in (neg_count = 0 \/ neg_count = right_add1_half_n \/ neg_count = n_right_add1_coeffs);

constraint
    (
        sum(k in RIGHT_ADD1_SHIFT_IDXS)(bool2int(right_shift_used[k])) <= right_add1_max_card_shift_values /\
        forall(r in RIGHT_ADD1_CASES)(right_lhs_shift_idx[r] = right_lhs_shift_idx[1]) /\
        forall(r in RIGHT_ADD1_CASES)(right_lhs_sign[r] = 1)
    ) \/
    (
        sum(k in RIGHT_ADD1_SHIFT_IDXS)(bool2int(right_shift_used[k])) <= right_add1_max_card_shift_values - 1
    );

constraint symmetry_breaking_constraint(
    forall(r in 1..n_right_add1_coeffs - 1)(right_add1_output[r] < right_add1_output[r + 1])
);

% ----------------------------- strict bottom adder ---------------------------

% Canonical orientation: final lhs uses left 1dd, final rhs uses right 1dd.
% Since the bottom adder is commutative and beta is impossible in strict mode,
% this removes the left/right operand-source symmetry at the bottom.
array[ADD3_CASES] of var {-1, 1}: add3_left_sign;
array[ADD3_CASES] of var {-1, 1}: add3_right_sign;
array[ADD3_CASES] of var ADD3_SHIFT_IDXS: add3_left_shift_idx;
array[ADD3_CASES] of var ADD3_SHIFT_IDXS: add3_right_shift_idx;
array[ADD3_CASES] of var -max(add3_shift_value)..max(add3_shift_value): alpha_left;
array[ADD3_CASES] of var -max(add3_shift_value)..max(add3_shift_value): alpha_right;
array[ADD3_SHIFT_IDXS] of var bool: add3_left_shift_used;
array[ADD3_SHIFT_IDXS] of var bool: add3_right_shift_used;

constraint forall(b in ADD3_CASES) (
    (add3_left_sign[b] = 1 \/ add3_right_sign[b] = 1) /\
    alpha_left[b] = add3_left_sign[b] * add3_shift_value[add3_left_shift_idx[b]] /\
    alpha_right[b] = add3_right_sign[b] * add3_shift_value[add3_right_shift_idx[b]]
);

constraint forall(k in ADD3_SHIFT_IDXS) (
    (add3_left_shift_used[k] <-> exists(b in ADD3_CASES)(add3_left_shift_idx[b] = k)) /\
    (add3_right_shift_used[k] <-> exists(b in ADD3_CASES)(add3_right_shift_idx[b] = k))
);

constraint single_op_bit_mode ->
let {
    var int: neg_count = sum(b in ADD3_CASES)(
        bool2int(add3_left_sign[b] = -1) + bool2int(add3_right_sign[b] = -1)
    )
} in (neg_count = 0 \/ neg_count = add3_half_n \/ neg_count = n_add3_coeffs);

constraint
    (
        sum(k in ADD3_SHIFT_IDXS)(bool2int(add3_left_shift_used[k])) +
        sum(k in ADD3_SHIFT_IDXS)(bool2int(add3_right_shift_used[k])) <= add3_max_card_shift_values /\
        forall(b in ADD3_CASES)(add3_left_sign[b] = 1) /\
        forall(b in ADD3_CASES)(add3_left_shift_idx[b] = add3_left_shift_idx[1])
    ) \/
    (
        sum(k in ADD3_SHIFT_IDXS)(bool2int(add3_left_shift_used[k])) +
        sum(k in ADD3_SHIFT_IDXS)(bool2int(add3_right_shift_used[k])) <= add3_max_card_shift_values - 1
    );

% Bottom case permutation symmetry.
constraint symmetry_breaking_constraint(
    forall(b in 1..n_add3_coeffs - 1)(
        alpha_left[b] < alpha_left[b + 1] \/
        (alpha_left[b] = alpha_left[b + 1] /\ alpha_right[b] < alpha_right[b + 1])
    )
);

% ----------------------------- product and set -------------------------------

array[LEFT_ADD1_CASES, RIGHT_ADD1_CASES, ADD3_CASES] of var min_coeff..max_coeff: coeff;
array[FLAT] of var min_coeff..max_coeff: flat_coeff = array1d(coeff);

constraint forall(l in LEFT_ADD1_CASES, r in RIGHT_ADD1_CASES, b in ADD3_CASES) (
    coeff[l, r, b] = alpha_left[b] * left_add1_output[l] + alpha_right[b] * right_add1_output[r]
);

constraint all_different(flat_coeff);

% ------------------------------ optional filters -----------------------------

% constraint
%     abs(sum(i in FLAT)(bool2int(flat_coeff[i] > 0)) -
%         sum(i in FLAT)(bool2int(flat_coeff[i] < 0))) <= 5;

% constraint
%     abs(max(flat_coeff) + min(flat_coeff)) <= 3;

% constraint
%     % either 0 or 1 or -1 in the set
%     (exists(i in FLAT)(flat_coeff[i] = 0)) \/
%     (exists(i in FLAT)(flat_coeff[i] = 1)) \/
%     (exists(i in FLAT)(flat_coeff[i] = -1));

% ------------------------------ solve / output -------------------------------

% Let the solver use its own activity/search first.  For Chuffed, try -f.
solve satisfy;

array[FLAT] of int: coeffs_out :: output_only = sort([fix(flat_coeff[i]) | i in FLAT]);

output [
    "coeffs = " ++ show(coeffs_out) ++ "\n"
];
