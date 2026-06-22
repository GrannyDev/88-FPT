include "globals.mzn";

% ------------------------------ user constants ------------------------------
int: n = 8; % nb coefficients
int: lut_size = 6;
bool: single_op_bit_mode = true; % global op bit selects add vs sub/double-neg
int: input_bw = 3; % bitwidth of the input
int: coeff_bw = 4; % bitwidth for coefficients

% ------------------------------ infered constants ------------------------------
int: wire_bw = input_bw + coeff_bw; % bitwidth for wires
int: max_coeff = 2^(coeff_bw-1)-1; % max allowed coefficient value
int: min_coeff = -2^(coeff_bw-1)+1; % min allowed coefficient value
int: max_card_shift_values = lut_size - ceil(log2(int2float(n))); % maximum number of different shift values allowed
int: half_n = n div 2; % number of coeffs per op-neg group (single-op mode)
array[1..coeff_bw] of int: allowed_shift_values = [2^(k-1) | k in 1..coeff_bw];

% ------------------------------ variables ------------------------------
array[1..n] of var min_coeff..max_coeff: coeffs; % raw add1/add2 product coefficients
array[1..n] of var {-1, 1}: lhs_sign; % left operand sign
array[1..n] of var {-1, 1}: rhs_sign; % right operand sign
array[1..n] of var 1..coeff_bw: lhs_shift_idx; % left operand shift index
array[1..n] of var 1..coeff_bw: rhs_shift_idx; % right operand shift index
array[1..n] of var bool: rhs_enabled; % whether the right operand is used
array[1..coeff_bw] of var bool: shift_values_used; % whether a shifted version of input is used

% ------------------------------ constraints ------------------------------
constraint
    forall(i in 1..n) (
        % Ensure that the coefficients are within the allowed range
        coeffs[i] >= min_coeff /\ coeffs[i] <= max_coeff /\
        (lhs_sign[i] = 1 \/ rhs_sign[i] = 1) /\
        coeffs[i] = allowed_shift_values[lhs_shift_idx[i]] * lhs_sign[i] + allowed_shift_values[rhs_shift_idx[i]] * rhs_sign[i] * (bool2int(rhs_enabled[i]))
    );

constraint
    % Link shift value usage to shift_values_used
    forall(i in 1..coeff_bw) (
        shift_values_used[i] <-> exists(j in 1..n)(lhs_shift_idx[j] = i \/ (rhs_shift_idx[j] = i /\ rhs_enabled[j]))
    );

constraint
    % When enabled, add1 can use all add, all subtract/negate, or a half split.
    single_op_bit_mode ->
    let {
        var int: add_neg_count =
            sum(i in 1..n)(bool2int(lhs_sign[i] = -1) + bool2int(rhs_sign[i] = -1))
    } in (
        add_neg_count = 0 \/
        add_neg_count = half_n \/
        add_neg_count = n
    );

constraint
    % Limit the union of left/right shift values
    let {
        var int: num_shift_values = sum(i in 1..coeff_bw)(bool2int(shift_values_used[i]))
    } in (
        (
            num_shift_values <= max_card_shift_values /\
            forall(i in 2..n)(lhs_shift_idx[i] = lhs_shift_idx[1]) /\
            forall(i in 1..n)(lhs_sign[i] = 1)
        ) \/
        num_shift_values <= max_card_shift_values - 1
    );

constraint
    % Ensure that the coefficients are unique
    all_different(coeffs);

constraint
    % Enforce ordering of coefficients for no duplicates (e.g., coeffs[i] <= coeffs[i+1])
    forall(i in 1..n-1) (
        coeffs[i] <= coeffs[i+1]
    );

% constraint
%     % Ensure that the number of positive and negative coefficients differ by at most 1
%     abs(sum(i in 1..n)(bool2int(coeffs[i] > 0)) - sum(i in 1..n)(bool2int(coeffs[i] < 0))) <= 1;

% constraint
%     % Ensure the spread between max and min coefficients is at most 2
%     abs(max(coeffs) + min(coeffs)) <= 1;

% ------------------------------ solve and output ------------------------------
solve satisfy;
output [
    "coeffs = " ++ show(coeffs) ++ "\n"
];
