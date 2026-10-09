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
                0: coeff_for_sel = 1;
                1: coeff_for_sel = 5;
                2: coeff_for_sel = -11;
                3: coeff_for_sel = -7;
                4: coeff_for_sel = 17;
                5: coeff_for_sel = 37;
                6: coeff_for_sel = -43;
                7: coeff_for_sel = -23;
                8: coeff_for_sel = 9;
                9: coeff_for_sel = 21;
                10: coeff_for_sel = -27;
                11: coeff_for_sel = -15;
                12: coeff_for_sel = 25;
                13: coeff_for_sel = 53;
                14: coeff_for_sel = -59;
                15: coeff_for_sel = -31;
                16: coeff_for_sel = 4;
                17: coeff_for_sel = 8;
                18: coeff_for_sel = -8;
                19: coeff_for_sel = -4;
                20: coeff_for_sel = 20;
                21: coeff_for_sel = 40;
                22: coeff_for_sel = -40;
                23: coeff_for_sel = -20;
                24: coeff_for_sel = 12;
                25: coeff_for_sel = 24;
                26: coeff_for_sel = -24;
                27: coeff_for_sel = -12;
                28: coeff_for_sel = 28;
                29: coeff_for_sel = 56;
                30: coeff_for_sel = -56;
                31: coeff_for_sel = -28;
                32: coeff_for_sel = 6;
                33: coeff_for_sel = 10;
                34: coeff_for_sel = -6;
                35: coeff_for_sel = -2;
                36: coeff_for_sel = 22;
                37: coeff_for_sel = 42;
                38: coeff_for_sel = -38;
                39: coeff_for_sel = -18;
                40: coeff_for_sel = 14;
                41: coeff_for_sel = 26;
                42: coeff_for_sel = -22;
                43: coeff_for_sel = -10;
                44: coeff_for_sel = 30;
                45: coeff_for_sel = 58;
                46: coeff_for_sel = -54;
                47: coeff_for_sel = -26;
                48: coeff_for_sel = 7;
                49: coeff_for_sel = 11;
                50: coeff_for_sel = -5;
                51: coeff_for_sel = -1;
                52: coeff_for_sel = 23;
                53: coeff_for_sel = 43;
                54: coeff_for_sel = -37;
                55: coeff_for_sel = -17;
                56: coeff_for_sel = 15;
                57: coeff_for_sel = 27;
                58: coeff_for_sel = -21;
                59: coeff_for_sel = -9;
                60: coeff_for_sel = 31;
                61: coeff_for_sel = 59;
                62: coeff_for_sel = -53;
                63: coeff_for_sel = -25;
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
