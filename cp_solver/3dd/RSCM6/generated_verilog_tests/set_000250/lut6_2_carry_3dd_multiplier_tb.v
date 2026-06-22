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
                0: coeff_for_sel = 32;
                1: coeff_for_sel = 28;
                2: coeff_for_sel = -28;
                3: coeff_for_sel = -32;
                4: coeff_for_sel = 56;
                5: coeff_for_sel = 52;
                6: coeff_for_sel = -52;
                7: coeff_for_sel = -56;
                8: coeff_for_sel = -16;
                9: coeff_for_sel = -20;
                10: coeff_for_sel = 20;
                11: coeff_for_sel = 16;
                12: coeff_for_sel = 8;
                13: coeff_for_sel = 4;
                14: coeff_for_sel = -4;
                15: coeff_for_sel = -8;
                16: coeff_for_sel = 30;
                17: coeff_for_sel = 27;
                18: coeff_for_sel = -27;
                19: coeff_for_sel = -30;
                20: coeff_for_sel = 54;
                21: coeff_for_sel = 51;
                22: coeff_for_sel = -51;
                23: coeff_for_sel = -54;
                24: coeff_for_sel = -18;
                25: coeff_for_sel = -21;
                26: coeff_for_sel = 21;
                27: coeff_for_sel = 18;
                28: coeff_for_sel = 6;
                29: coeff_for_sel = 3;
                30: coeff_for_sel = -3;
                31: coeff_for_sel = -6;
                32: coeff_for_sel = 26;
                33: coeff_for_sel = 25;
                34: coeff_for_sel = -25;
                35: coeff_for_sel = -26;
                36: coeff_for_sel = 50;
                37: coeff_for_sel = 49;
                38: coeff_for_sel = -49;
                39: coeff_for_sel = -50;
                40: coeff_for_sel = -22;
                41: coeff_for_sel = -23;
                42: coeff_for_sel = 23;
                43: coeff_for_sel = 22;
                44: coeff_for_sel = 2;
                45: coeff_for_sel = 1;
                46: coeff_for_sel = -1;
                47: coeff_for_sel = -2;
                48: coeff_for_sel = 10;
                49: coeff_for_sel = 17;
                50: coeff_for_sel = -17;
                51: coeff_for_sel = -10;
                52: coeff_for_sel = 34;
                53: coeff_for_sel = 41;
                54: coeff_for_sel = -41;
                55: coeff_for_sel = -34;
                56: coeff_for_sel = -38;
                57: coeff_for_sel = -31;
                58: coeff_for_sel = 31;
                59: coeff_for_sel = 38;
                60: coeff_for_sel = -14;
                61: coeff_for_sel = -7;
                62: coeff_for_sel = 7;
                63: coeff_for_sel = 14;
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
