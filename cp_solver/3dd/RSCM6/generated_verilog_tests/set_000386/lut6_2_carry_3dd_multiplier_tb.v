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
                0: coeff_for_sel = -15;
                1: coeff_for_sel = -7;
                2: coeff_for_sel = 7;
                3: coeff_for_sel = 15;
                4: coeff_for_sel = -14;
                5: coeff_for_sel = -6;
                6: coeff_for_sel = 6;
                7: coeff_for_sel = 14;
                8: coeff_for_sel = -16;
                9: coeff_for_sel = -8;
                10: coeff_for_sel = 8;
                11: coeff_for_sel = 16;
                12: coeff_for_sel = -9;
                13: coeff_for_sel = -1;
                14: coeff_for_sel = 1;
                15: coeff_for_sel = 9;
                16: coeff_for_sel = -39;
                17: coeff_for_sel = -19;
                18: coeff_for_sel = 19;
                19: coeff_for_sel = 39;
                20: coeff_for_sel = -38;
                21: coeff_for_sel = -18;
                22: coeff_for_sel = 18;
                23: coeff_for_sel = 38;
                24: coeff_for_sel = -40;
                25: coeff_for_sel = -20;
                26: coeff_for_sel = 20;
                27: coeff_for_sel = 40;
                28: coeff_for_sel = -33;
                29: coeff_for_sel = -13;
                30: coeff_for_sel = 13;
                31: coeff_for_sel = 33;
                32: coeff_for_sel = 57;
                33: coeff_for_sel = 29;
                34: coeff_for_sel = -29;
                35: coeff_for_sel = -57;
                36: coeff_for_sel = 58;
                37: coeff_for_sel = 30;
                38: coeff_for_sel = -30;
                39: coeff_for_sel = -58;
                40: coeff_for_sel = 56;
                41: coeff_for_sel = 28;
                42: coeff_for_sel = -28;
                43: coeff_for_sel = -56;
                44: coeff_for_sel = 63;
                45: coeff_for_sel = 35;
                46: coeff_for_sel = -35;
                47: coeff_for_sel = -63;
                48: coeff_for_sel = -23;
                49: coeff_for_sel = -11;
                50: coeff_for_sel = 11;
                51: coeff_for_sel = 23;
                52: coeff_for_sel = -22;
                53: coeff_for_sel = -10;
                54: coeff_for_sel = 10;
                55: coeff_for_sel = 22;
                56: coeff_for_sel = -24;
                57: coeff_for_sel = -12;
                58: coeff_for_sel = 12;
                59: coeff_for_sel = 24;
                60: coeff_for_sel = -17;
                61: coeff_for_sel = -5;
                62: coeff_for_sel = 5;
                63: coeff_for_sel = 17;
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
