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
                0: coeff_for_sel = -6;
                1: coeff_for_sel = -2;
                2: coeff_for_sel = 2;
                3: coeff_for_sel = 6;
                4: coeff_for_sel = -3;
                5: coeff_for_sel = 1;
                6: coeff_for_sel = -1;
                7: coeff_for_sel = 3;
                8: coeff_for_sel = -9;
                9: coeff_for_sel = -5;
                10: coeff_for_sel = 5;
                11: coeff_for_sel = 9;
                12: coeff_for_sel = -8;
                13: coeff_for_sel = -4;
                14: coeff_for_sel = 4;
                15: coeff_for_sel = 8;
                16: coeff_for_sel = -38;
                17: coeff_for_sel = -18;
                18: coeff_for_sel = 18;
                19: coeff_for_sel = 38;
                20: coeff_for_sel = -35;
                21: coeff_for_sel = -15;
                22: coeff_for_sel = 15;
                23: coeff_for_sel = 35;
                24: coeff_for_sel = -41;
                25: coeff_for_sel = -21;
                26: coeff_for_sel = 21;
                27: coeff_for_sel = 41;
                28: coeff_for_sel = -40;
                29: coeff_for_sel = -20;
                30: coeff_for_sel = 20;
                31: coeff_for_sel = 40;
                32: coeff_for_sel = 58;
                33: coeff_for_sel = 30;
                34: coeff_for_sel = -30;
                35: coeff_for_sel = -58;
                36: coeff_for_sel = 61;
                37: coeff_for_sel = 33;
                38: coeff_for_sel = -33;
                39: coeff_for_sel = -61;
                40: coeff_for_sel = 55;
                41: coeff_for_sel = 27;
                42: coeff_for_sel = -27;
                43: coeff_for_sel = -55;
                44: coeff_for_sel = 56;
                45: coeff_for_sel = 28;
                46: coeff_for_sel = -28;
                47: coeff_for_sel = -56;
                48: coeff_for_sel = -22;
                49: coeff_for_sel = -10;
                50: coeff_for_sel = 10;
                51: coeff_for_sel = 22;
                52: coeff_for_sel = -19;
                53: coeff_for_sel = -7;
                54: coeff_for_sel = 7;
                55: coeff_for_sel = 19;
                56: coeff_for_sel = -25;
                57: coeff_for_sel = -13;
                58: coeff_for_sel = 13;
                59: coeff_for_sel = 25;
                60: coeff_for_sel = -24;
                61: coeff_for_sel = -12;
                62: coeff_for_sel = 12;
                63: coeff_for_sel = 24;
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
