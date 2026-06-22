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
                0: coeff_for_sel = 5;
                1: coeff_for_sel = 9;
                2: coeff_for_sel = -7;
                3: coeff_for_sel = -3;
                4: coeff_for_sel = 17;
                5: coeff_for_sel = 33;
                6: coeff_for_sel = -31;
                7: coeff_for_sel = -15;
                8: coeff_for_sel = 25;
                9: coeff_for_sel = 49;
                10: coeff_for_sel = -47;
                11: coeff_for_sel = -23;
                12: coeff_for_sel = 29;
                13: coeff_for_sel = 57;
                14: coeff_for_sel = -55;
                15: coeff_for_sel = -27;
                16: coeff_for_sel = 8;
                17: coeff_for_sel = 12;
                18: coeff_for_sel = -4;
                19: coeff_for_sel = 0;
                20: coeff_for_sel = 20;
                21: coeff_for_sel = 36;
                22: coeff_for_sel = -28;
                23: coeff_for_sel = -12;
                24: coeff_for_sel = 28;
                25: coeff_for_sel = 52;
                26: coeff_for_sel = -44;
                27: coeff_for_sel = -20;
                28: coeff_for_sel = 32;
                29: coeff_for_sel = 60;
                30: coeff_for_sel = -52;
                31: coeff_for_sel = -24;
                32: coeff_for_sel = -2;
                33: coeff_for_sel = 2;
                34: coeff_for_sel = -14;
                35: coeff_for_sel = -10;
                36: coeff_for_sel = 10;
                37: coeff_for_sel = 26;
                38: coeff_for_sel = -38;
                39: coeff_for_sel = -22;
                40: coeff_for_sel = 18;
                41: coeff_for_sel = 42;
                42: coeff_for_sel = -54;
                43: coeff_for_sel = -30;
                44: coeff_for_sel = 22;
                45: coeff_for_sel = 50;
                46: coeff_for_sel = -62;
                47: coeff_for_sel = -34;
                48: coeff_for_sel = 11;
                49: coeff_for_sel = 15;
                50: coeff_for_sel = -1;
                51: coeff_for_sel = 3;
                52: coeff_for_sel = 23;
                53: coeff_for_sel = 39;
                54: coeff_for_sel = -25;
                55: coeff_for_sel = -9;
                56: coeff_for_sel = 31;
                57: coeff_for_sel = 55;
                58: coeff_for_sel = -41;
                59: coeff_for_sel = -17;
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
