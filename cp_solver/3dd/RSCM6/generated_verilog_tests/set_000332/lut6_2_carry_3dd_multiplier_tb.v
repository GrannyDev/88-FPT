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
                16: coeff_for_sel = -22;
                17: coeff_for_sel = -10;
                18: coeff_for_sel = 10;
                19: coeff_for_sel = 22;
                20: coeff_for_sel = -19;
                21: coeff_for_sel = -7;
                22: coeff_for_sel = 7;
                23: coeff_for_sel = 19;
                24: coeff_for_sel = -25;
                25: coeff_for_sel = -13;
                26: coeff_for_sel = 13;
                27: coeff_for_sel = 25;
                28: coeff_for_sel = -24;
                29: coeff_for_sel = -12;
                30: coeff_for_sel = 12;
                31: coeff_for_sel = 24;
                32: coeff_for_sel = -38;
                33: coeff_for_sel = -18;
                34: coeff_for_sel = 18;
                35: coeff_for_sel = 38;
                36: coeff_for_sel = -35;
                37: coeff_for_sel = -15;
                38: coeff_for_sel = 15;
                39: coeff_for_sel = 35;
                40: coeff_for_sel = -41;
                41: coeff_for_sel = -21;
                42: coeff_for_sel = 21;
                43: coeff_for_sel = 41;
                44: coeff_for_sel = -40;
                45: coeff_for_sel = -20;
                46: coeff_for_sel = 20;
                47: coeff_for_sel = 40;
                48: coeff_for_sel = -54;
                49: coeff_for_sel = -26;
                50: coeff_for_sel = 26;
                51: coeff_for_sel = 54;
                52: coeff_for_sel = -51;
                53: coeff_for_sel = -23;
                54: coeff_for_sel = 23;
                55: coeff_for_sel = 51;
                56: coeff_for_sel = -57;
                57: coeff_for_sel = -29;
                58: coeff_for_sel = 29;
                59: coeff_for_sel = 57;
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
