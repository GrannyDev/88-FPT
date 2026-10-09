`timescale 1ns/1ps
module lut6_2_carry_2dd_multiplier_tb;
    localparam integer INPUT_BW = 5;
    localparam integer OUTPUT_BW = 10;
    localparam integer SEL_BITS = 5;
    localparam integer N_COEFFS = 32;
    localparam integer TOTAL_TESTS = 1024;
    reg signed [INPUT_BW-1:0] x;
    reg [SEL_BITS-1:0] sel;
    wire signed [OUTPUT_BW-1:0] y;
    reg signed [OUTPUT_BW-1:0] expected_y;
    integer xi, si, expected, errors;
    function integer coeff_for_sel;
        input integer idx;
        begin
            case (idx)
                0: coeff_for_sel = -7;
                1: coeff_for_sel = -6;
                2: coeff_for_sel = 7;
                3: coeff_for_sel = 8;
                4: coeff_for_sel = -15;
                5: coeff_for_sel = -14;
                6: coeff_for_sel = 15;
                7: coeff_for_sel = 16;
                8: coeff_for_sel = -19;
                9: coeff_for_sel = -18;
                10: coeff_for_sel = 19;
                11: coeff_for_sel = 20;
                12: coeff_for_sel = -31;
                13: coeff_for_sel = -30;
                14: coeff_for_sel = 31;
                15: coeff_for_sel = 32;
                16: coeff_for_sel = 13;
                17: coeff_for_sel = 14;
                18: coeff_for_sel = -13;
                19: coeff_for_sel = -12;
                20: coeff_for_sel = 5;
                21: coeff_for_sel = 6;
                22: coeff_for_sel = -5;
                23: coeff_for_sel = -4;
                24: coeff_for_sel = 1;
                25: coeff_for_sel = 2;
                26: coeff_for_sel = -1;
                27: coeff_for_sel = 0;
                28: coeff_for_sel = -11;
                29: coeff_for_sel = -10;
                30: coeff_for_sel = 11;
                31: coeff_for_sel = 12;
                default: coeff_for_sel = 0;
            endcase
        end
    endfunction
    lut6_2_carry_2dd_multiplier dut (.x(x), .sel(sel), .y(y));
    initial begin
        errors = 0;
        for (xi = -16; xi <= 15; xi = xi + 1) begin
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
