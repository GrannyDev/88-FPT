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
                0: coeff_for_sel = 22;
                1: coeff_for_sel = 23;
                2: coeff_for_sel = -23;
                3: coeff_for_sel = -22;
                4: coeff_for_sel = 46;
                5: coeff_for_sel = 47;
                6: coeff_for_sel = -47;
                7: coeff_for_sel = -46;
                8: coeff_for_sel = -50;
                9: coeff_for_sel = -49;
                10: coeff_for_sel = 49;
                11: coeff_for_sel = 50;
                12: coeff_for_sel = -2;
                13: coeff_for_sel = -1;
                14: coeff_for_sel = 1;
                15: coeff_for_sel = 2;
                16: coeff_for_sel = 18;
                17: coeff_for_sel = 21;
                18: coeff_for_sel = -21;
                19: coeff_for_sel = -18;
                20: coeff_for_sel = 42;
                21: coeff_for_sel = 45;
                22: coeff_for_sel = -45;
                23: coeff_for_sel = -42;
                24: coeff_for_sel = -54;
                25: coeff_for_sel = -51;
                26: coeff_for_sel = 51;
                27: coeff_for_sel = 54;
                28: coeff_for_sel = -6;
                29: coeff_for_sel = -3;
                30: coeff_for_sel = 3;
                31: coeff_for_sel = 6;
                32: coeff_for_sel = 16;
                33: coeff_for_sel = 20;
                34: coeff_for_sel = -20;
                35: coeff_for_sel = -16;
                36: coeff_for_sel = 40;
                37: coeff_for_sel = 44;
                38: coeff_for_sel = -44;
                39: coeff_for_sel = -40;
                40: coeff_for_sel = -56;
                41: coeff_for_sel = -52;
                42: coeff_for_sel = 52;
                43: coeff_for_sel = 56;
                44: coeff_for_sel = -8;
                45: coeff_for_sel = -4;
                46: coeff_for_sel = 4;
                47: coeff_for_sel = 8;
                48: coeff_for_sel = 10;
                49: coeff_for_sel = 17;
                50: coeff_for_sel = -17;
                51: coeff_for_sel = -10;
                52: coeff_for_sel = 34;
                53: coeff_for_sel = 41;
                54: coeff_for_sel = -41;
                55: coeff_for_sel = -34;
                56: coeff_for_sel = -62;
                57: coeff_for_sel = -55;
                58: coeff_for_sel = 55;
                59: coeff_for_sel = 62;
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
