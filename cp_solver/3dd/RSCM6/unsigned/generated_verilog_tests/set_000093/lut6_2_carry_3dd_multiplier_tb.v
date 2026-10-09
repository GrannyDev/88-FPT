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
                0: coeff_for_sel = -50;
                1: coeff_for_sel = -49;
                2: coeff_for_sel = 49;
                3: coeff_for_sel = 50;
                4: coeff_for_sel = -18;
                5: coeff_for_sel = -17;
                6: coeff_for_sel = 17;
                7: coeff_for_sel = 18;
                8: coeff_for_sel = -2;
                9: coeff_for_sel = -1;
                10: coeff_for_sel = 1;
                11: coeff_for_sel = 2;
                12: coeff_for_sel = 46;
                13: coeff_for_sel = 47;
                14: coeff_for_sel = -47;
                15: coeff_for_sel = -46;
                16: coeff_for_sel = -54;
                17: coeff_for_sel = -51;
                18: coeff_for_sel = 51;
                19: coeff_for_sel = 54;
                20: coeff_for_sel = -22;
                21: coeff_for_sel = -19;
                22: coeff_for_sel = 19;
                23: coeff_for_sel = 22;
                24: coeff_for_sel = -6;
                25: coeff_for_sel = -3;
                26: coeff_for_sel = 3;
                27: coeff_for_sel = 6;
                28: coeff_for_sel = 42;
                29: coeff_for_sel = 45;
                30: coeff_for_sel = -45;
                31: coeff_for_sel = -42;
                32: coeff_for_sel = -56;
                33: coeff_for_sel = -52;
                34: coeff_for_sel = 52;
                35: coeff_for_sel = 56;
                36: coeff_for_sel = -24;
                37: coeff_for_sel = -20;
                38: coeff_for_sel = 20;
                39: coeff_for_sel = 24;
                40: coeff_for_sel = -8;
                41: coeff_for_sel = -4;
                42: coeff_for_sel = 4;
                43: coeff_for_sel = 8;
                44: coeff_for_sel = 40;
                45: coeff_for_sel = 44;
                46: coeff_for_sel = -44;
                47: coeff_for_sel = -40;
                48: coeff_for_sel = -58;
                49: coeff_for_sel = -53;
                50: coeff_for_sel = 53;
                51: coeff_for_sel = 58;
                52: coeff_for_sel = -26;
                53: coeff_for_sel = -21;
                54: coeff_for_sel = 21;
                55: coeff_for_sel = 26;
                56: coeff_for_sel = -10;
                57: coeff_for_sel = -5;
                58: coeff_for_sel = 5;
                59: coeff_for_sel = 10;
                60: coeff_for_sel = 38;
                61: coeff_for_sel = 43;
                62: coeff_for_sel = -43;
                63: coeff_for_sel = -38;
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
