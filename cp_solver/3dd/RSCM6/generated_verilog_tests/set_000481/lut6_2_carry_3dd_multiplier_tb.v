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
                0: coeff_for_sel = -21;
                1: coeff_for_sel = -49;
                2: coeff_for_sel = 49;
                3: coeff_for_sel = 21;
                4: coeff_for_sel = -9;
                5: coeff_for_sel = -25;
                6: coeff_for_sel = 25;
                7: coeff_for_sel = 9;
                8: coeff_for_sel = -5;
                9: coeff_for_sel = -17;
                10: coeff_for_sel = 17;
                11: coeff_for_sel = 5;
                12: coeff_for_sel = 3;
                13: coeff_for_sel = -1;
                14: coeff_for_sel = 1;
                15: coeff_for_sel = -3;
                16: coeff_for_sel = -26;
                17: coeff_for_sel = -54;
                18: coeff_for_sel = 54;
                19: coeff_for_sel = 26;
                20: coeff_for_sel = -14;
                21: coeff_for_sel = -30;
                22: coeff_for_sel = 30;
                23: coeff_for_sel = 14;
                24: coeff_for_sel = -10;
                25: coeff_for_sel = -22;
                26: coeff_for_sel = 22;
                27: coeff_for_sel = 10;
                28: coeff_for_sel = -2;
                29: coeff_for_sel = -6;
                30: coeff_for_sel = 6;
                31: coeff_for_sel = 2;
                32: coeff_for_sel = -28;
                33: coeff_for_sel = -56;
                34: coeff_for_sel = 56;
                35: coeff_for_sel = 28;
                36: coeff_for_sel = -16;
                37: coeff_for_sel = -32;
                38: coeff_for_sel = 32;
                39: coeff_for_sel = 16;
                40: coeff_for_sel = -12;
                41: coeff_for_sel = -24;
                42: coeff_for_sel = 24;
                43: coeff_for_sel = 12;
                44: coeff_for_sel = -4;
                45: coeff_for_sel = -8;
                46: coeff_for_sel = 8;
                47: coeff_for_sel = 4;
                48: coeff_for_sel = -35;
                49: coeff_for_sel = -63;
                50: coeff_for_sel = 63;
                51: coeff_for_sel = 35;
                52: coeff_for_sel = -23;
                53: coeff_for_sel = -39;
                54: coeff_for_sel = 39;
                55: coeff_for_sel = 23;
                56: coeff_for_sel = -19;
                57: coeff_for_sel = -31;
                58: coeff_for_sel = 31;
                59: coeff_for_sel = 19;
                60: coeff_for_sel = -11;
                61: coeff_for_sel = -15;
                62: coeff_for_sel = 15;
                63: coeff_for_sel = 11;
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
