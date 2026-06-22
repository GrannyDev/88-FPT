`timescale 1ns/1ps

module lut6_2_carry_3dd_multiplier_tb;
    localparam integer INPUT_BW = 6;
    localparam integer OUTPUT_BW = 12;
    localparam integer SEL_BITS = 6;
    localparam integer N_COEFFS = 64;

    reg signed [INPUT_BW-1:0] x;
    reg [SEL_BITS-1:0] sel;
    wire signed [OUTPUT_BW-1:0] y;
    reg signed [OUTPUT_BW-1:0] expected_y;
    integer xi;
    integer si;
    integer expected;
    integer errors;

    function integer coeff_for_sel;
        input integer idx;
        begin
            case (idx)
                0: coeff_for_sel = 4;
                1: coeff_for_sel = 8;
                2: coeff_for_sel = -8;
                3: coeff_for_sel = -4;
                4: coeff_for_sel = 20;
                5: coeff_for_sel = 40;
                6: coeff_for_sel = -40;
                7: coeff_for_sel = -20;
                8: coeff_for_sel = -28;
                9: coeff_for_sel = -56;
                10: coeff_for_sel = 56;
                11: coeff_for_sel = 28;
                12: coeff_for_sel = 12;
                13: coeff_for_sel = 24;
                14: coeff_for_sel = -24;
                15: coeff_for_sel = -12;
                16: coeff_for_sel = 3;
                17: coeff_for_sel = 7;
                18: coeff_for_sel = -7;
                19: coeff_for_sel = -3;
                20: coeff_for_sel = 19;
                21: coeff_for_sel = 39;
                22: coeff_for_sel = -39;
                23: coeff_for_sel = -19;
                24: coeff_for_sel = -29;
                25: coeff_for_sel = -57;
                26: coeff_for_sel = 57;
                27: coeff_for_sel = 29;
                28: coeff_for_sel = 11;
                29: coeff_for_sel = 23;
                30: coeff_for_sel = -23;
                31: coeff_for_sel = -11;
                32: coeff_for_sel = 2;
                33: coeff_for_sel = 6;
                34: coeff_for_sel = -6;
                35: coeff_for_sel = -2;
                36: coeff_for_sel = 18;
                37: coeff_for_sel = 38;
                38: coeff_for_sel = -38;
                39: coeff_for_sel = -18;
                40: coeff_for_sel = -30;
                41: coeff_for_sel = -58;
                42: coeff_for_sel = 58;
                43: coeff_for_sel = 30;
                44: coeff_for_sel = 10;
                45: coeff_for_sel = 22;
                46: coeff_for_sel = -22;
                47: coeff_for_sel = -10;
                48: coeff_for_sel = 1;
                49: coeff_for_sel = 5;
                50: coeff_for_sel = -5;
                51: coeff_for_sel = -1;
                52: coeff_for_sel = 17;
                53: coeff_for_sel = 37;
                54: coeff_for_sel = -37;
                55: coeff_for_sel = -17;
                56: coeff_for_sel = -31;
                57: coeff_for_sel = -59;
                58: coeff_for_sel = 59;
                59: coeff_for_sel = 31;
                60: coeff_for_sel = 9;
                61: coeff_for_sel = 21;
                62: coeff_for_sel = -21;
                63: coeff_for_sel = -9;
                default: coeff_for_sel = 0;
            endcase
        end
    endfunction

    lut6_2_carry_3dd_multiplier dut (
        .x(x),
        .sel(sel),
        .y(y)
    );

    initial begin
        errors = 0;
        for (xi = -32; xi <= 31; xi = xi + 1) begin
            for (si = 0; si < N_COEFFS; si = si + 1) begin
                x = xi[INPUT_BW-1:0];
                sel = si[SEL_BITS-1:0];
                #1;
                expected = xi * coeff_for_sel(si);
                expected_y = expected;
                if ($signed(y) !== expected_y) begin
                    $display("TEST x=%0d sel=%0d coeff=%0d expected=%0d simulated=%0d FAIL",
                             xi, si, coeff_for_sel(si), expected_y, $signed(y));
                    errors = errors + 1;
                end
            end
        end
        if (errors == 0) begin
            $display("SUMMARY pass=%0d fail=0 total=%0d",
                     64 * N_COEFFS, 64 * N_COEFFS);
        end else begin
            $display("SUMMARY pass=%0d fail=%0d total=%0d",
                     (64 * N_COEFFS) - errors, errors, 64 * N_COEFFS);
        end
        $finish;
    end
endmodule
