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
                0: coeff_for_sel = 49;
                1: coeff_for_sel = 50;
                2: coeff_for_sel = -50;
                3: coeff_for_sel = -49;
                4: coeff_for_sel = 52;
                5: coeff_for_sel = 56;
                6: coeff_for_sel = -56;
                7: coeff_for_sel = -52;
                8: coeff_for_sel = 45;
                9: coeff_for_sel = 42;
                10: coeff_for_sel = -42;
                11: coeff_for_sel = -45;
                12: coeff_for_sel = 55;
                13: coeff_for_sel = 62;
                14: coeff_for_sel = -62;
                15: coeff_for_sel = -55;
                16: coeff_for_sel = 33;
                17: coeff_for_sel = 34;
                18: coeff_for_sel = -34;
                19: coeff_for_sel = -33;
                20: coeff_for_sel = 36;
                21: coeff_for_sel = 40;
                22: coeff_for_sel = -40;
                23: coeff_for_sel = -36;
                24: coeff_for_sel = 29;
                25: coeff_for_sel = 26;
                26: coeff_for_sel = -26;
                27: coeff_for_sel = -29;
                28: coeff_for_sel = 39;
                29: coeff_for_sel = 46;
                30: coeff_for_sel = -46;
                31: coeff_for_sel = -39;
                32: coeff_for_sel = 1;
                33: coeff_for_sel = 2;
                34: coeff_for_sel = -2;
                35: coeff_for_sel = -1;
                36: coeff_for_sel = 4;
                37: coeff_for_sel = 8;
                38: coeff_for_sel = -8;
                39: coeff_for_sel = -4;
                40: coeff_for_sel = -3;
                41: coeff_for_sel = -6;
                42: coeff_for_sel = 6;
                43: coeff_for_sel = 3;
                44: coeff_for_sel = 7;
                45: coeff_for_sel = 14;
                46: coeff_for_sel = -14;
                47: coeff_for_sel = -7;
                48: coeff_for_sel = -31;
                49: coeff_for_sel = -30;
                50: coeff_for_sel = 30;
                51: coeff_for_sel = 31;
                52: coeff_for_sel = -28;
                53: coeff_for_sel = -24;
                54: coeff_for_sel = 24;
                55: coeff_for_sel = 28;
                56: coeff_for_sel = -35;
                57: coeff_for_sel = -38;
                58: coeff_for_sel = 38;
                59: coeff_for_sel = 35;
                60: coeff_for_sel = -25;
                61: coeff_for_sel = -18;
                62: coeff_for_sel = 18;
                63: coeff_for_sel = 25;
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
