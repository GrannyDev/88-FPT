include "globals.mzn";

% -----------------------------------------------------------------------------
% 2dd affine rewrite
%
% Key differences from the original 2dd.mzn:
%   - no var set usage; shift usage is tracked with Boolean channels
%   - disabled / irrelevant operand variables are fixed to canonical defaults
%   - add2 is represented by affine transforms: coeff = alpha * add1 + beta
%   - add1 rows and add2 transforms are symmetry-broken independently
%   - final coefficient-set identity is printed as a sorted output-only array
% -----------------------------------------------------------------------------

% ------------------------------ user constants ------------------------------
int: n = 32;                         % nb coefficients
int: add1_sel_bits = 3;              % number of selection bits seen by add1
int: add2_sel_bits = 2;              % number of selection bits seen by add2
int: lut_size = 6;
bool: single_op_bit_mode = true;     % global op bit selects add vs sub/double-neg
int: input_bw = 5;                   % bitwidth of the input
int: coeff_bw = 6;                   % bitwidth for coefficients
int: add1_output_bw = 4;             % signed bitwidth allowed for add1 output coefficients

% ----------------------------- inferred constants ---------------------------
int: wire_bw = input_bw + coeff_bw;
int: max_coeff = 2^(coeff_bw - 1) - 1;
int: min_coeff = -2^(coeff_bw - 1) + 1;

int: n_add1_coeffs = 2^add1_sel_bits;
int: n_add2_coeffs = 2^add2_sel_bits;
int: n_coeffs = n_add1_coeffs * n_add2_coeffs;
set of int: ADD1_CASES = 1..n_add1_coeffs;
set of int: ADD2_CASES = 1..n_add2_coeffs;
set of int: FLAT = 1..n_coeffs;

int: min_coeff_bw = ceil(log2(int2float(n + 1)));
int: min_add1_output_bw = ceil(log2(int2float(n_add1_coeffs + 1)));

int: add1_output_bw_max = 2^(add1_output_bw - 1) - 1;
int: add1_output_bw_min = -2^(add1_output_bw - 1) + 1;

int: add1_max_card_shift_values = lut_size - add1_sel_bits;
int: add2_max_card_shift_values = lut_size - add2_sel_bits;
int: add1_half_n = n_add1_coeffs div 2;
int: add2_half_n = n_add2_coeffs div 2;

set of int: ADD1_SHIFT_IDXS = 1..add1_output_bw;
set of int: ADD2_SHIFT_IDXS = 1..coeff_bw;
array[ADD1_SHIFT_IDXS] of int: add1_shift_value = [2^(k - 1) | k in ADD1_SHIFT_IDXS];
array[ADD2_SHIFT_IDXS] of int: add2_shift_value = [2^(k - 1) | k in ADD2_SHIFT_IDXS];

int: add2_scale_abs_max = 2 * max(add2_shift_value);
int: add2_const_abs_max = 2 * max(add2_shift_value);

% static assertion
constraint
    n_coeffs = n /\
    coeff_bw >= min_coeff_bw /\
    add1_output_bw >= min_add1_output_bw /\
    add1_max_card_shift_values >= 1 /\
    add2_max_card_shift_values >= 1;

% ------------------------------ variables -----------------------------------

% Product matrix. This is still useful internally because the hardware structure
% is a product: each final coefficient is produced by one add1 case and one add2
% transform.
array[ADD1_CASES, ADD2_CASES] of var min_coeff..max_coeff: coeff;
array[FLAT] of var min_coeff..max_coeff: flat_coeff = array1d(coeff);

% Add1 low-level description: lhs is always present, rhs is optional.
array[ADD1_CASES] of var add1_output_bw_min..add1_output_bw_max: add1_output;
array[ADD1_CASES] of var {-1, 1}: add1_lhs_sign;
array[ADD1_CASES] of var {-1, 1}: add1_rhs_sign;
array[ADD1_CASES] of var ADD1_SHIFT_IDXS: add1_lhs_shift_idx;
array[ADD1_CASES] of var ADD1_SHIFT_IDXS: add1_rhs_shift_idx;
array[ADD1_CASES] of var bool: add1_rhs_enabled;
array[ADD1_SHIFT_IDXS] of var bool: add1_shift_used;

% Add2 low-level description. Each operand can use add1 output or direct input.
array[ADD2_CASES] of var {-1, 1}: add2_lhs_sign;
array[ADD2_CASES] of var {-1, 1}: add2_rhs_sign;
array[ADD2_CASES] of var ADD2_SHIFT_IDXS: add2_lhs_add1_shift_idx;
array[ADD2_CASES] of var ADD2_SHIFT_IDXS: add2_rhs_add1_shift_idx;
array[ADD2_CASES] of var ADD2_SHIFT_IDXS: add2_lhs_input_shift_idx;
array[ADD2_CASES] of var ADD2_SHIFT_IDXS: add2_rhs_input_shift_idx;
array[ADD2_CASES] of var bool: add2_rhs_enabled;
array[ADD2_CASES] of var bool: add2_lhs_uses_add1;
array[ADD2_CASES] of var bool: add2_rhs_uses_add1;

% Affine representation of each add2 case:
%   coeff[a,b] = alpha[b] * add1_output[a] + beta[b]
array[ADD2_CASES] of var -add2_scale_abs_max..add2_scale_abs_max: alpha;
array[ADD2_CASES] of var -add2_const_abs_max..add2_const_abs_max: beta;

% Boolean shift-use channels for add2. These replace var set unions/cards.
array[ADD2_SHIFT_IDXS] of var bool: add2_add1_shift_used;
array[ADD2_SHIFT_IDXS] of var bool: add2_input_shift_used;

% ------------------------------ add1 constraints ----------------------------

constraint
    forall(a in ADD1_CASES) (
        % Prevent double-negative adders.
        (add1_lhs_sign[a] = 1 \/ add1_rhs_sign[a] = 1) /\

        % Canonical default for disabled rhs shift. The disabled sign remains
        % free because negated zero can participate in single-op grouping.
        (not add1_rhs_enabled[a] ->
            add1_rhs_shift_idx[a] = 1
        ) /\

        add1_output[a] =
            add1_lhs_sign[a] * add1_shift_value[add1_lhs_shift_idx[a]] +
            bool2int(add1_rhs_enabled[a]) *
                add1_rhs_sign[a] * add1_shift_value[add1_rhs_shift_idx[a]]
    );

constraint
    forall(k in ADD1_SHIFT_IDXS) (
        add1_shift_used[k] <->
            exists(a in ADD1_CASES)(
                add1_lhs_shift_idx[a] = k \/
                (add1_rhs_enabled[a] /\ add1_rhs_shift_idx[a] = k)
            )
    );

constraint
    single_op_bit_mode ->
    let {
        var int: add1_neg_count =
            sum(a in ADD1_CASES)(
                bool2int(add1_lhs_sign[a] = -1) +
                bool2int(add1_rhs_sign[a] = -1)
            )
    } in (
        add1_neg_count = 0 \/
        add1_neg_count = add1_half_n \/
        add1_neg_count = n_add1_coeffs
    );

constraint
    (
        sum(k in ADD1_SHIFT_IDXS)(bool2int(add1_shift_used[k])) <= add1_max_card_shift_values /\
        forall(a in ADD1_CASES)(add1_lhs_shift_idx[a] = add1_lhs_shift_idx[1]) /\
        forall(a in ADD1_CASES)(add1_lhs_sign[a] = 1)
    ) \/
    (
        sum(k in ADD1_SHIFT_IDXS)(bool2int(add1_shift_used[k])) <= add1_max_card_shift_values - 1
    );

% Add1 row permutation symmetry. Strict is safe because duplicate add1 outputs
% would duplicate at least one final coefficient column.
constraint symmetry_breaking_constraint(
    forall(a in 1..n_add1_coeffs - 1)(add1_output[a] < add1_output[a + 1])
);

% ------------------------------ add2 constraints ----------------------------

constraint
    forall(b in ADD2_CASES) (
        % Prevent double-negative adders. Disabled operands are canonicalized
        % with positive signs below, so negative single-operand cases remain possible.
        (add2_lhs_sign[b] = 1 \/ add2_rhs_sign[b] = 1) /\

        % Canonical defaults for disabled operand sources/shifts. Disabled
        % signs remain free because negated zero can participate in op grouping.
        (not add2_rhs_enabled[b] ->
            not add2_rhs_uses_add1[b] /\
            add2_rhs_add1_shift_idx[b] = 1 /\
            add2_rhs_input_shift_idx[b] = 1
        ) /\

        % Canonical defaults for unused shift variables on enabled operands.
        (add2_lhs_uses_add1[b] -> add2_lhs_input_shift_idx[b] = 1) /\
        (not add2_lhs_uses_add1[b] -> add2_lhs_add1_shift_idx[b] = 1) /\
        (add2_rhs_enabled[b] /\ add2_rhs_uses_add1[b] -> add2_rhs_input_shift_idx[b] = 1) /\
        (add2_rhs_enabled[b] /\ not add2_rhs_uses_add1[b] -> add2_rhs_add1_shift_idx[b] = 1)
    );

constraint
    forall(b in ADD2_CASES) (
        alpha[b] =
            (if add2_lhs_uses_add1[b]
             then add2_lhs_sign[b] * add2_shift_value[add2_lhs_add1_shift_idx[b]]
             else 0 endif) +
            (if add2_rhs_enabled[b] /\ add2_rhs_uses_add1[b]
             then add2_rhs_sign[b] * add2_shift_value[add2_rhs_add1_shift_idx[b]]
             else 0 endif) /\
        beta[b] =
            (if not add2_lhs_uses_add1[b]
             then add2_lhs_sign[b] * add2_shift_value[add2_lhs_input_shift_idx[b]]
             else 0 endif) +
            (if add2_rhs_enabled[b] /\ not add2_rhs_uses_add1[b]
             then add2_rhs_sign[b] * add2_shift_value[add2_rhs_input_shift_idx[b]]
             else 0 endif)
    );

constraint
    forall(k in ADD2_SHIFT_IDXS) (
        (add2_add1_shift_used[k] <->
            exists(b in ADD2_CASES)(
                (add2_lhs_uses_add1[b] /\ add2_lhs_add1_shift_idx[b] = k) \/
                (add2_rhs_enabled[b] /\ add2_rhs_uses_add1[b] /\ add2_rhs_add1_shift_idx[b] = k)
            )) /\
        (add2_input_shift_used[k] <->
            exists(b in ADD2_CASES)(
                (not add2_lhs_uses_add1[b] /\ add2_lhs_input_shift_idx[b] = k) \/
                (add2_rhs_enabled[b] /\ not add2_rhs_uses_add1[b] /\ add2_rhs_input_shift_idx[b] = k)
            ))
    );

constraint
    single_op_bit_mode ->
    let {
        var int: add2_neg_count =
            sum(b in ADD2_CASES)(
                bool2int(add2_lhs_sign[b] = -1) +
                bool2int(add2_rhs_sign[b] = -1)
            )
    } in (
        add2_neg_count = 0 \/
        add2_neg_count = add2_half_n \/
        add2_neg_count = n_add2_coeffs
    );

constraint
    single_op_bit_mode -> (n_add1_coeffs mod 2 = 0 /\ n_add2_coeffs mod 2 = 0);

constraint
    (
        sum(k in ADD2_SHIFT_IDXS)(bool2int(add2_input_shift_used[k])) +
        sum(k in ADD2_SHIFT_IDXS)(bool2int(add2_add1_shift_used[k]))
            <= add2_max_card_shift_values /\
        forall(b in ADD2_CASES)(add2_lhs_sign[b] = 1) /\
        sum(k in ADD2_SHIFT_IDXS)(
            bool2int(exists(b in ADD2_CASES)(
                add2_lhs_uses_add1[b] /\
                add2_lhs_add1_shift_idx[b] = k
            ))
        ) +
        sum(k in ADD2_SHIFT_IDXS)(
            bool2int(exists(b in ADD2_CASES)(
                not add2_lhs_uses_add1[b] /\
                add2_lhs_input_shift_idx[b] = k
            ))
        ) = 1
    ) \/
    (
        sum(k in ADD2_SHIFT_IDXS)(bool2int(add2_input_shift_used[k])) +
        sum(k in ADD2_SHIFT_IDXS)(bool2int(add2_add1_shift_used[k]))
            <= add2_max_card_shift_values - 1
    );

% Reject one-adder degeneracy. alpha != 0 is stronger than "some source uses add1":
% it also rejects add1/add1 cancellation cases that are physically present but
% coefficient-independent.
constraint exists(b in ADD2_CASES)(alpha[b] != 0);

% Add2 case permutation symmetry, independent of add1 row values.
constraint symmetry_breaking_constraint(
    forall(b in 1..n_add2_coeffs - 1)(
        alpha[b] < alpha[b + 1] \/
        (alpha[b] = alpha[b + 1] /\ beta[b] < beta[b + 1])
    )
);

% ----------------------------- product / projection -------------------------

constraint
    forall(a in ADD1_CASES, b in ADD2_CASES) (
        coeff[a, b] = alpha[b] * add1_output[a] + beta[b]
    );

constraint all_different(flat_coeff);

% ------------------------------ optional filters -----------------------------

% constraint
%     abs(sum(i in FLAT)(bool2int(flat_coeff[i] > 0)) -
%         sum(i in FLAT)(bool2int(flat_coeff[i] < 0))) <= 5;

% constraint
%     abs(max(flat_coeff) + min(flat_coeff)) <= 2;

% ------------------------------ solve / output -------------------------------

solve satisfy;

array[FLAT] of int: coeffs_out :: output_only = sort([fix(flat_coeff[i]) | i in FLAT]);

output [
    "coeffs = " ++ show(coeffs_out) ++ "\n",
];
