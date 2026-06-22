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
                0: coeff_for_sel = 6;
                1: coeff_for_sel = 18;
                2: coeff_for_sel = -30;
                3: coeff_for_sel = -18;
                4: coeff_for_sel = 10;
                5: coeff_for_sel = 26;
                6: coeff_for_sel = -38;
                7: coeff_for_sel = -22;
                8: coeff_for_sel = -10;
                9: coeff_for_sel = -14;
                10: coeff_for_sel = 2;
                11: coeff_for_sel = -2;
                12: coeff_for_sel = 22;
                13: coeff_for_sel = 50;
                14: coeff_for_sel = -62;
                15: coeff_for_sel = -34;
                16: coeff_for_sel = 12;
                17: coeff_for_sel = 24;
                18: coeff_for_sel = -24;
                19: coeff_for_sel = -12;
                20: coeff_for_sel = 16;
                21: coeff_for_sel = 32;
                22: coeff_for_sel = -32;
                23: coeff_for_sel = -16;
                24: coeff_for_sel = -4;
                25: coeff_for_sel = -8;
                26: coeff_for_sel = 8;
                27: coeff_for_sel = 4;
                28: coeff_for_sel = 28;
                29: coeff_for_sel = 56;
                30: coeff_for_sel = -56;
                31: coeff_for_sel = -28;
                32: coeff_for_sel = 13;
                33: coeff_for_sel = 25;
                34: coeff_for_sel = -23;
                35: coeff_for_sel = -11;
                36: coeff_for_sel = 17;
                37: coeff_for_sel = 33;
                38: coeff_for_sel = -31;
                39: coeff_for_sel = -15;
                40: coeff_for_sel = -3;
                41: coeff_for_sel = -7;
                42: coeff_for_sel = 9;
                43: coeff_for_sel = 5;
                44: coeff_for_sel = 29;
                45: coeff_for_sel = 57;
                46: coeff_for_sel = -55;
                47: coeff_for_sel = -27;
                48: coeff_for_sel = 19;
                49: coeff_for_sel = 31;
                50: coeff_for_sel = -17;
                51: coeff_for_sel = -5;
                52: coeff_for_sel = 23;
                53: coeff_for_sel = 39;
                54: coeff_for_sel = -25;
                55: coeff_for_sel = -9;
                56: coeff_for_sel = 3;
                57: coeff_for_sel = -1;
                58: coeff_for_sel = 15;
                59: coeff_for_sel = 11;
                60: coeff_for_sel = 35;
                61: coeff_for_sel = 63;
                62: coeff_for_sel = -49;
                63: coeff_for_sel = -21;
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
