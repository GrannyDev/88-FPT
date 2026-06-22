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
                1: coeff_for_sel = 10;
                2: coeff_for_sel = -6;
                3: coeff_for_sel = -2;
                4: coeff_for_sel = 9;
                5: coeff_for_sel = 13;
                6: coeff_for_sel = -3;
                7: coeff_for_sel = 1;
                8: coeff_for_sel = 0;
                9: coeff_for_sel = 4;
                10: coeff_for_sel = -12;
                11: coeff_for_sel = -8;
                12: coeff_for_sel = 3;
                13: coeff_for_sel = 7;
                14: coeff_for_sel = -9;
                15: coeff_for_sel = -5;
                16: coeff_for_sel = 18;
                17: coeff_for_sel = 34;
                18: coeff_for_sel = -30;
                19: coeff_for_sel = -14;
                20: coeff_for_sel = 21;
                21: coeff_for_sel = 37;
                22: coeff_for_sel = -27;
                23: coeff_for_sel = -11;
                24: coeff_for_sel = 12;
                25: coeff_for_sel = 28;
                26: coeff_for_sel = -36;
                27: coeff_for_sel = -20;
                28: coeff_for_sel = 15;
                29: coeff_for_sel = 31;
                30: coeff_for_sel = -33;
                31: coeff_for_sel = -17;
                32: coeff_for_sel = 26;
                33: coeff_for_sel = 50;
                34: coeff_for_sel = -46;
                35: coeff_for_sel = -22;
                36: coeff_for_sel = 29;
                37: coeff_for_sel = 53;
                38: coeff_for_sel = -43;
                39: coeff_for_sel = -19;
                40: coeff_for_sel = 20;
                41: coeff_for_sel = 44;
                42: coeff_for_sel = -52;
                43: coeff_for_sel = -28;
                44: coeff_for_sel = 23;
                45: coeff_for_sel = 47;
                46: coeff_for_sel = -49;
                47: coeff_for_sel = -25;
                48: coeff_for_sel = 30;
                49: coeff_for_sel = 58;
                50: coeff_for_sel = -54;
                51: coeff_for_sel = -26;
                52: coeff_for_sel = 33;
                53: coeff_for_sel = 61;
                54: coeff_for_sel = -51;
                55: coeff_for_sel = -23;
                56: coeff_for_sel = 24;
                57: coeff_for_sel = 52;
                58: coeff_for_sel = -60;
                59: coeff_for_sel = -32;
                60: coeff_for_sel = 27;
                61: coeff_for_sel = 55;
                62: coeff_for_sel = -57;
                63: coeff_for_sel = -29;
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
