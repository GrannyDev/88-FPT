`timescale 1ns/1ps
module lut6_2_carry_3dd_multiplier_tb;
    localparam integer INPUT_BW = 6;
    localparam integer OUTPUT_BW = 12;
    localparam integer SEL_BITS = 6;
    localparam integer N_COEFFS = 64;
    localparam integer TOTAL_TESTS = 4096;
    reg signed [INPUT_BW-1:0] x;
    reg [SEL_BITS-1:0] sel;
    wire signed [OUTPUT_BW-1:0] y;
    reg signed [OUTPUT_BW-1:0] expected_y;
    integer xi, si, expected, errors;
    function integer coeff_for_sel;
        input integer idx;
        begin
            case (idx)
                0: coeff_for_sel = -39;
                1: coeff_for_sel = -46;
                2: coeff_for_sel = 46;
                3: coeff_for_sel = 39;
                4: coeff_for_sel = -36;
                5: coeff_for_sel = -40;
                6: coeff_for_sel = 40;
                7: coeff_for_sel = 36;
                8: coeff_for_sel = -33;
                9: coeff_for_sel = -34;
                10: coeff_for_sel = 34;
                11: coeff_for_sel = 33;
                12: coeff_for_sel = -29;
                13: coeff_for_sel = -26;
                14: coeff_for_sel = 26;
                15: coeff_for_sel = 29;
                16: coeff_for_sel = -55;
                17: coeff_for_sel = -62;
                18: coeff_for_sel = 62;
                19: coeff_for_sel = 55;
                20: coeff_for_sel = -52;
                21: coeff_for_sel = -56;
                22: coeff_for_sel = 56;
                23: coeff_for_sel = 52;
                24: coeff_for_sel = -49;
                25: coeff_for_sel = -50;
                26: coeff_for_sel = 50;
                27: coeff_for_sel = 49;
                28: coeff_for_sel = -45;
                29: coeff_for_sel = -42;
                30: coeff_for_sel = 42;
                31: coeff_for_sel = 45;
                32: coeff_for_sel = 25;
                33: coeff_for_sel = 18;
                34: coeff_for_sel = -18;
                35: coeff_for_sel = -25;
                36: coeff_for_sel = 28;
                37: coeff_for_sel = 24;
                38: coeff_for_sel = -24;
                39: coeff_for_sel = -28;
                40: coeff_for_sel = 31;
                41: coeff_for_sel = 30;
                42: coeff_for_sel = -30;
                43: coeff_for_sel = -31;
                44: coeff_for_sel = 35;
                45: coeff_for_sel = 38;
                46: coeff_for_sel = -38;
                47: coeff_for_sel = -35;
                48: coeff_for_sel = -7;
                49: coeff_for_sel = -14;
                50: coeff_for_sel = 14;
                51: coeff_for_sel = 7;
                52: coeff_for_sel = -4;
                53: coeff_for_sel = -8;
                54: coeff_for_sel = 8;
                55: coeff_for_sel = 4;
                56: coeff_for_sel = -1;
                57: coeff_for_sel = -2;
                58: coeff_for_sel = 2;
                59: coeff_for_sel = 1;
                60: coeff_for_sel = 3;
                61: coeff_for_sel = 6;
                62: coeff_for_sel = -6;
                63: coeff_for_sel = -3;
                default: coeff_for_sel = 0;
            endcase
        end
    endfunction
    lut6_2_carry_3dd_multiplier dut (.x(x), .sel(sel), .y(y));
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
