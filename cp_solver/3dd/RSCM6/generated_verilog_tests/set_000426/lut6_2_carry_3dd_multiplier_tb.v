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
                0: coeff_for_sel = -23;
                1: coeff_for_sel = -11;
                2: coeff_for_sel = 11;
                3: coeff_for_sel = 23;
                4: coeff_for_sel = -21;
                5: coeff_for_sel = -9;
                6: coeff_for_sel = 9;
                7: coeff_for_sel = 21;
                8: coeff_for_sel = -26;
                9: coeff_for_sel = -14;
                10: coeff_for_sel = 14;
                11: coeff_for_sel = 26;
                12: coeff_for_sel = -24;
                13: coeff_for_sel = -12;
                14: coeff_for_sel = 12;
                15: coeff_for_sel = 24;
                16: coeff_for_sel = -31;
                17: coeff_for_sel = -15;
                18: coeff_for_sel = 15;
                19: coeff_for_sel = 31;
                20: coeff_for_sel = -29;
                21: coeff_for_sel = -13;
                22: coeff_for_sel = 13;
                23: coeff_for_sel = 29;
                24: coeff_for_sel = -34;
                25: coeff_for_sel = -18;
                26: coeff_for_sel = 18;
                27: coeff_for_sel = 34;
                28: coeff_for_sel = -32;
                29: coeff_for_sel = -16;
                30: coeff_for_sel = 16;
                31: coeff_for_sel = 32;
                32: coeff_for_sel = -7;
                33: coeff_for_sel = -3;
                34: coeff_for_sel = 3;
                35: coeff_for_sel = 7;
                36: coeff_for_sel = -5;
                37: coeff_for_sel = -1;
                38: coeff_for_sel = 1;
                39: coeff_for_sel = 5;
                40: coeff_for_sel = -10;
                41: coeff_for_sel = -6;
                42: coeff_for_sel = 6;
                43: coeff_for_sel = 10;
                44: coeff_for_sel = -8;
                45: coeff_for_sel = -4;
                46: coeff_for_sel = 4;
                47: coeff_for_sel = 8;
                48: coeff_for_sel = -55;
                49: coeff_for_sel = -27;
                50: coeff_for_sel = 27;
                51: coeff_for_sel = 55;
                52: coeff_for_sel = -53;
                53: coeff_for_sel = -25;
                54: coeff_for_sel = 25;
                55: coeff_for_sel = 53;
                56: coeff_for_sel = -58;
                57: coeff_for_sel = -30;
                58: coeff_for_sel = 30;
                59: coeff_for_sel = 58;
                60: coeff_for_sel = -56;
                61: coeff_for_sel = -28;
                62: coeff_for_sel = 28;
                63: coeff_for_sel = 56;
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
