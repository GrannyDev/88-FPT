% Actual XilinxRSCM LUT6/LUT6_2 count: one primitive per adder output bit.
% The including model defines min_input, max_input, and max_lut_width.
function var int: output_lut_count(var int: coeff_min, var int: coeff_max) =
    let {
        var int: product_min = min([
            min_input * coeff_min, min_input * coeff_max,
            max_input * coeff_min, max_input * coeff_max
        ]),
        var int: product_max = max([
            min_input * coeff_min, min_input * coeff_max,
            max_input * coeff_min, max_input * coeff_max
        ])
    } in
    1 + sum(w in 1..max_lut_width - 1)(
        bool2int(product_min < -2^(w - 1) \/ product_max >= 2^(w - 1))
    );
