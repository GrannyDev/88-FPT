`timescale 1ns/1ps
module lut6_2_carry_3dd_multiplier_tb;
    localparam integer INPUT_BW = 6;
    localparam integer OUTPUT_BW = 13;
    localparam integer SEL_BITS = 6;
    localparam integer N_COEFFS = 64;
    localparam integer TOTAL_TESTS = 4096;
    reg [INPUT_BW-1:0] x;
    reg [SEL_BITS-1:0] sel;
    wire signed [OUTPUT_BW-1:0] y;
    reg signed [OUTPUT_BW-1:0] expected_y;
    integer xi, si, expected, errors;
    function integer coeff_for_sel;
        input integer idx;
        begin
            case (idx)
                0: coeff_for_sel = 9;
                1: coeff_for_sel = 33;
                2: coeff_for_sel = 7;
                3: coeff_for_sel = 31;
                4: coeff_for_sel = 13;
                5: coeff_for_sel = 49;
                6: coeff_for_sel = 11;
                7: coeff_for_sel = 47;
                8: coeff_for_sel = -11;
                9: coeff_for_sel = -47;
                10: coeff_for_sel = -13;
                11: coeff_for_sel = -49;
                12: coeff_for_sel = -7;
                13: coeff_for_sel = -31;
                14: coeff_for_sel = -9;
                15: coeff_for_sel = -33;
                16: coeff_for_sel = 12;
                17: coeff_for_sel = 36;
                18: coeff_for_sel = 4;
                19: coeff_for_sel = 28;
                20: coeff_for_sel = 16;
                21: coeff_for_sel = 52;
                22: coeff_for_sel = 8;
                23: coeff_for_sel = 44;
                24: coeff_for_sel = -8;
                25: coeff_for_sel = -44;
                26: coeff_for_sel = -16;
                27: coeff_for_sel = -52;
                28: coeff_for_sel = -4;
                29: coeff_for_sel = -28;
                30: coeff_for_sel = -12;
                31: coeff_for_sel = -36;
                32: coeff_for_sel = 14;
                33: coeff_for_sel = 38;
                34: coeff_for_sel = 2;
                35: coeff_for_sel = 26;
                36: coeff_for_sel = 18;
                37: coeff_for_sel = 54;
                38: coeff_for_sel = 6;
                39: coeff_for_sel = 42;
                40: coeff_for_sel = -6;
                41: coeff_for_sel = -42;
                42: coeff_for_sel = -18;
                43: coeff_for_sel = -54;
                44: coeff_for_sel = -2;
                45: coeff_for_sel = -26;
                46: coeff_for_sel = -14;
                47: coeff_for_sel = -38;
                48: coeff_for_sel = 15;
                49: coeff_for_sel = 39;
                50: coeff_for_sel = 1;
                51: coeff_for_sel = 25;
                52: coeff_for_sel = 19;
                53: coeff_for_sel = 55;
                54: coeff_for_sel = 5;
                55: coeff_for_sel = 41;
                56: coeff_for_sel = -5;
                57: coeff_for_sel = -41;
                58: coeff_for_sel = -19;
                59: coeff_for_sel = -55;
                60: coeff_for_sel = -1;
                61: coeff_for_sel = -25;
                62: coeff_for_sel = -15;
                63: coeff_for_sel = -39;
                default: coeff_for_sel = 0;
            endcase
        end
    endfunction
    lut6_2_carry_3dd_multiplier dut (.x(x), .sel(sel), .y(y));
    initial begin
        errors = 0;
        for (xi = 0; xi <= 63; xi = xi + 1) begin
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
                end else begin
                    $display("TEST x=%0d sel=%0d coeff=%0d expected=%0d simulated=%0d PASS",
                             xi, si, coeff_for_sel(si), expected_y, $signed(y));
                end
            end
        end
        $display("SUMMARY pass=%0d fail=%0d total=%0d", TOTAL_TESTS-errors, errors, TOTAL_TESTS);
        if (errors != 0) $fatal(1, "Exhaustive test failed");
        $finish;
    end
endmodule
