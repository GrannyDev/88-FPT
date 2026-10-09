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
                0: coeff_for_sel = 5;
                1: coeff_for_sel = 9;
                2: coeff_for_sel = -7;
                3: coeff_for_sel = -3;
                4: coeff_for_sel = 21;
                5: coeff_for_sel = 41;
                6: coeff_for_sel = -39;
                7: coeff_for_sel = -19;
                8: coeff_for_sel = 17;
                9: coeff_for_sel = 33;
                10: coeff_for_sel = -31;
                11: coeff_for_sel = -15;
                12: coeff_for_sel = 29;
                13: coeff_for_sel = 57;
                14: coeff_for_sel = -55;
                15: coeff_for_sel = -27;
                16: coeff_for_sel = 7;
                17: coeff_for_sel = 11;
                18: coeff_for_sel = -5;
                19: coeff_for_sel = -1;
                20: coeff_for_sel = 23;
                21: coeff_for_sel = 43;
                22: coeff_for_sel = -37;
                23: coeff_for_sel = -17;
                24: coeff_for_sel = 19;
                25: coeff_for_sel = 35;
                26: coeff_for_sel = -29;
                27: coeff_for_sel = -13;
                28: coeff_for_sel = 31;
                29: coeff_for_sel = 59;
                30: coeff_for_sel = -53;
                31: coeff_for_sel = -25;
                32: coeff_for_sel = 0;
                33: coeff_for_sel = 4;
                34: coeff_for_sel = -12;
                35: coeff_for_sel = -8;
                36: coeff_for_sel = 16;
                37: coeff_for_sel = 36;
                38: coeff_for_sel = -44;
                39: coeff_for_sel = -24;
                40: coeff_for_sel = 12;
                41: coeff_for_sel = 28;
                42: coeff_for_sel = -36;
                43: coeff_for_sel = -20;
                44: coeff_for_sel = 24;
                45: coeff_for_sel = 52;
                46: coeff_for_sel = -60;
                47: coeff_for_sel = -32;
                48: coeff_for_sel = 6;
                49: coeff_for_sel = 10;
                50: coeff_for_sel = -6;
                51: coeff_for_sel = -2;
                52: coeff_for_sel = 22;
                53: coeff_for_sel = 42;
                54: coeff_for_sel = -38;
                55: coeff_for_sel = -18;
                56: coeff_for_sel = 18;
                57: coeff_for_sel = 34;
                58: coeff_for_sel = -30;
                59: coeff_for_sel = -14;
                60: coeff_for_sel = 30;
                61: coeff_for_sel = 58;
                62: coeff_for_sel = -54;
                63: coeff_for_sel = -26;
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
