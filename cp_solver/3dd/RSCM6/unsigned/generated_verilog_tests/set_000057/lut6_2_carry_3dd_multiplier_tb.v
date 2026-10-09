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
                0: coeff_for_sel = 13;
                1: coeff_for_sel = 29;
                2: coeff_for_sel = -35;
                3: coeff_for_sel = -19;
                4: coeff_for_sel = 17;
                5: coeff_for_sel = 37;
                6: coeff_for_sel = -43;
                7: coeff_for_sel = -23;
                8: coeff_for_sel = -7;
                9: coeff_for_sel = -11;
                10: coeff_for_sel = 5;
                11: coeff_for_sel = 1;
                12: coeff_for_sel = 9;
                13: coeff_for_sel = 21;
                14: coeff_for_sel = -27;
                15: coeff_for_sel = -15;
                16: coeff_for_sel = 14;
                17: coeff_for_sel = 30;
                18: coeff_for_sel = -34;
                19: coeff_for_sel = -18;
                20: coeff_for_sel = 18;
                21: coeff_for_sel = 38;
                22: coeff_for_sel = -42;
                23: coeff_for_sel = -22;
                24: coeff_for_sel = -6;
                25: coeff_for_sel = -10;
                26: coeff_for_sel = 6;
                27: coeff_for_sel = 2;
                28: coeff_for_sel = 10;
                29: coeff_for_sel = 22;
                30: coeff_for_sel = -26;
                31: coeff_for_sel = -14;
                32: coeff_for_sel = 16;
                33: coeff_for_sel = 32;
                34: coeff_for_sel = -32;
                35: coeff_for_sel = -16;
                36: coeff_for_sel = 20;
                37: coeff_for_sel = 40;
                38: coeff_for_sel = -40;
                39: coeff_for_sel = -20;
                40: coeff_for_sel = -4;
                41: coeff_for_sel = -8;
                42: coeff_for_sel = 8;
                43: coeff_for_sel = 4;
                44: coeff_for_sel = 12;
                45: coeff_for_sel = 24;
                46: coeff_for_sel = -24;
                47: coeff_for_sel = -12;
                48: coeff_for_sel = 19;
                49: coeff_for_sel = 35;
                50: coeff_for_sel = -29;
                51: coeff_for_sel = -13;
                52: coeff_for_sel = 23;
                53: coeff_for_sel = 43;
                54: coeff_for_sel = -37;
                55: coeff_for_sel = -17;
                56: coeff_for_sel = -1;
                57: coeff_for_sel = -5;
                58: coeff_for_sel = 11;
                59: coeff_for_sel = 7;
                60: coeff_for_sel = 15;
                61: coeff_for_sel = 27;
                62: coeff_for_sel = -21;
                63: coeff_for_sel = -9;
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
