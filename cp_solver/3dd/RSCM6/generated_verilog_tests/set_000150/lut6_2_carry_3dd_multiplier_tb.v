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
                0: coeff_for_sel = 10;
                1: coeff_for_sel = 12;
                2: coeff_for_sel = -6;
                3: coeff_for_sel = 6;
                4: coeff_for_sel = 13;
                5: coeff_for_sel = 18;
                6: coeff_for_sel = -3;
                7: coeff_for_sel = 3;
                8: coeff_for_sel = 5;
                9: coeff_for_sel = 2;
                10: coeff_for_sel = -11;
                11: coeff_for_sel = 11;
                12: coeff_for_sel = 15;
                13: coeff_for_sel = 22;
                14: coeff_for_sel = -1;
                15: coeff_for_sel = 1;
                16: coeff_for_sel = 42;
                17: coeff_for_sel = 44;
                18: coeff_for_sel = -38;
                19: coeff_for_sel = 38;
                20: coeff_for_sel = 45;
                21: coeff_for_sel = 50;
                22: coeff_for_sel = -35;
                23: coeff_for_sel = 35;
                24: coeff_for_sel = 37;
                25: coeff_for_sel = 34;
                26: coeff_for_sel = -43;
                27: coeff_for_sel = 43;
                28: coeff_for_sel = 47;
                29: coeff_for_sel = 54;
                30: coeff_for_sel = -33;
                31: coeff_for_sel = 33;
                32: coeff_for_sel = -54;
                33: coeff_for_sel = -52;
                34: coeff_for_sel = 58;
                35: coeff_for_sel = -58;
                36: coeff_for_sel = -51;
                37: coeff_for_sel = -46;
                38: coeff_for_sel = 61;
                39: coeff_for_sel = -61;
                40: coeff_for_sel = -59;
                41: coeff_for_sel = -62;
                42: coeff_for_sel = 53;
                43: coeff_for_sel = -53;
                44: coeff_for_sel = -49;
                45: coeff_for_sel = -42;
                46: coeff_for_sel = 63;
                47: coeff_for_sel = -63;
                48: coeff_for_sel = -22;
                49: coeff_for_sel = -20;
                50: coeff_for_sel = 26;
                51: coeff_for_sel = -26;
                52: coeff_for_sel = -19;
                53: coeff_for_sel = -14;
                54: coeff_for_sel = 29;
                55: coeff_for_sel = -29;
                56: coeff_for_sel = -27;
                57: coeff_for_sel = -30;
                58: coeff_for_sel = 21;
                59: coeff_for_sel = -21;
                60: coeff_for_sel = -17;
                61: coeff_for_sel = -10;
                62: coeff_for_sel = 31;
                63: coeff_for_sel = -31;
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
