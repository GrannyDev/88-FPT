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
                0: coeff_for_sel = -18;
                1: coeff_for_sel = -21;
                2: coeff_for_sel = 21;
                3: coeff_for_sel = 18;
                4: coeff_for_sel = 6;
                5: coeff_for_sel = 3;
                6: coeff_for_sel = -3;
                7: coeff_for_sel = -6;
                8: coeff_for_sel = 30;
                9: coeff_for_sel = 27;
                10: coeff_for_sel = -27;
                11: coeff_for_sel = -30;
                12: coeff_for_sel = 62;
                13: coeff_for_sel = 59;
                14: coeff_for_sel = -59;
                15: coeff_for_sel = -62;
                16: coeff_for_sel = -22;
                17: coeff_for_sel = -23;
                18: coeff_for_sel = 23;
                19: coeff_for_sel = 22;
                20: coeff_for_sel = 2;
                21: coeff_for_sel = 1;
                22: coeff_for_sel = -1;
                23: coeff_for_sel = -2;
                24: coeff_for_sel = 26;
                25: coeff_for_sel = 25;
                26: coeff_for_sel = -25;
                27: coeff_for_sel = -26;
                28: coeff_for_sel = 58;
                29: coeff_for_sel = 57;
                30: coeff_for_sel = -57;
                31: coeff_for_sel = -58;
                32: coeff_for_sel = -32;
                33: coeff_for_sel = -28;
                34: coeff_for_sel = 28;
                35: coeff_for_sel = 32;
                36: coeff_for_sel = -8;
                37: coeff_for_sel = -4;
                38: coeff_for_sel = 4;
                39: coeff_for_sel = 8;
                40: coeff_for_sel = 16;
                41: coeff_for_sel = 20;
                42: coeff_for_sel = -20;
                43: coeff_for_sel = -16;
                44: coeff_for_sel = 48;
                45: coeff_for_sel = 52;
                46: coeff_for_sel = -52;
                47: coeff_for_sel = -48;
                48: coeff_for_sel = -38;
                49: coeff_for_sel = -31;
                50: coeff_for_sel = 31;
                51: coeff_for_sel = 38;
                52: coeff_for_sel = -14;
                53: coeff_for_sel = -7;
                54: coeff_for_sel = 7;
                55: coeff_for_sel = 14;
                56: coeff_for_sel = 10;
                57: coeff_for_sel = 17;
                58: coeff_for_sel = -17;
                59: coeff_for_sel = -10;
                60: coeff_for_sel = 42;
                61: coeff_for_sel = 49;
                62: coeff_for_sel = -49;
                63: coeff_for_sel = -42;
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
