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
                0: coeff_for_sel = 49;
                1: coeff_for_sel = 50;
                2: coeff_for_sel = -50;
                3: coeff_for_sel = -49;
                4: coeff_for_sel = 52;
                5: coeff_for_sel = 56;
                6: coeff_for_sel = -56;
                7: coeff_for_sel = -52;
                8: coeff_for_sel = 45;
                9: coeff_for_sel = 42;
                10: coeff_for_sel = -42;
                11: coeff_for_sel = -45;
                12: coeff_for_sel = 55;
                13: coeff_for_sel = 62;
                14: coeff_for_sel = -62;
                15: coeff_for_sel = -55;
                16: coeff_for_sel = 33;
                17: coeff_for_sel = 34;
                18: coeff_for_sel = -34;
                19: coeff_for_sel = -33;
                20: coeff_for_sel = 36;
                21: coeff_for_sel = 40;
                22: coeff_for_sel = -40;
                23: coeff_for_sel = -36;
                24: coeff_for_sel = 29;
                25: coeff_for_sel = 26;
                26: coeff_for_sel = -26;
                27: coeff_for_sel = -29;
                28: coeff_for_sel = 39;
                29: coeff_for_sel = 46;
                30: coeff_for_sel = -46;
                31: coeff_for_sel = -39;
                32: coeff_for_sel = 17;
                33: coeff_for_sel = 18;
                34: coeff_for_sel = -18;
                35: coeff_for_sel = -17;
                36: coeff_for_sel = 20;
                37: coeff_for_sel = 24;
                38: coeff_for_sel = -24;
                39: coeff_for_sel = -20;
                40: coeff_for_sel = 13;
                41: coeff_for_sel = 10;
                42: coeff_for_sel = -10;
                43: coeff_for_sel = -13;
                44: coeff_for_sel = 23;
                45: coeff_for_sel = 30;
                46: coeff_for_sel = -30;
                47: coeff_for_sel = -23;
                48: coeff_for_sel = 1;
                49: coeff_for_sel = 2;
                50: coeff_for_sel = -2;
                51: coeff_for_sel = -1;
                52: coeff_for_sel = 4;
                53: coeff_for_sel = 8;
                54: coeff_for_sel = -8;
                55: coeff_for_sel = -4;
                56: coeff_for_sel = -3;
                57: coeff_for_sel = -6;
                58: coeff_for_sel = 6;
                59: coeff_for_sel = 3;
                60: coeff_for_sel = 7;
                61: coeff_for_sel = 14;
                62: coeff_for_sel = -14;
                63: coeff_for_sel = -7;
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
