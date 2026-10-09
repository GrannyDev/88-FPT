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
                0: coeff_for_sel = 49;
                1: coeff_for_sel = 50;
                2: coeff_for_sel = -50;
                3: coeff_for_sel = -49;
                4: coeff_for_sel = 51;
                5: coeff_for_sel = 54;
                6: coeff_for_sel = -54;
                7: coeff_for_sel = -51;
                8: coeff_for_sel = 52;
                9: coeff_for_sel = 56;
                10: coeff_for_sel = -56;
                11: coeff_for_sel = -52;
                12: coeff_for_sel = 53;
                13: coeff_for_sel = 58;
                14: coeff_for_sel = -58;
                15: coeff_for_sel = -53;
                16: coeff_for_sel = 33;
                17: coeff_for_sel = 34;
                18: coeff_for_sel = -34;
                19: coeff_for_sel = -33;
                20: coeff_for_sel = 35;
                21: coeff_for_sel = 38;
                22: coeff_for_sel = -38;
                23: coeff_for_sel = -35;
                24: coeff_for_sel = 36;
                25: coeff_for_sel = 40;
                26: coeff_for_sel = -40;
                27: coeff_for_sel = -36;
                28: coeff_for_sel = 37;
                29: coeff_for_sel = 42;
                30: coeff_for_sel = -42;
                31: coeff_for_sel = -37;
                32: coeff_for_sel = 17;
                33: coeff_for_sel = 18;
                34: coeff_for_sel = -18;
                35: coeff_for_sel = -17;
                36: coeff_for_sel = 19;
                37: coeff_for_sel = 22;
                38: coeff_for_sel = -22;
                39: coeff_for_sel = -19;
                40: coeff_for_sel = 20;
                41: coeff_for_sel = 24;
                42: coeff_for_sel = -24;
                43: coeff_for_sel = -20;
                44: coeff_for_sel = 21;
                45: coeff_for_sel = 26;
                46: coeff_for_sel = -26;
                47: coeff_for_sel = -21;
                48: coeff_for_sel = 1;
                49: coeff_for_sel = 2;
                50: coeff_for_sel = -2;
                51: coeff_for_sel = -1;
                52: coeff_for_sel = 3;
                53: coeff_for_sel = 6;
                54: coeff_for_sel = -6;
                55: coeff_for_sel = -3;
                56: coeff_for_sel = 4;
                57: coeff_for_sel = 8;
                58: coeff_for_sel = -8;
                59: coeff_for_sel = -4;
                60: coeff_for_sel = 5;
                61: coeff_for_sel = 10;
                62: coeff_for_sel = -10;
                63: coeff_for_sel = -5;
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
