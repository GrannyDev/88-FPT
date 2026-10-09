`timescale 1ns/1ps
module lut6_2_carry_3dd_multiplier_tb;
    localparam integer INPUT_BW = 7;
    localparam integer OUTPUT_BW = 16;
    localparam integer SEL_BITS = 7;
    localparam integer N_COEFFS = 128;
    localparam integer TOTAL_TESTS = 16384;
    reg [INPUT_BW-1:0] x;
    reg [SEL_BITS-1:0] sel;
    wire signed [OUTPUT_BW-1:0] y;
    reg signed [OUTPUT_BW-1:0] expected_y;
    integer xi, si, expected, errors;
    function integer coeff_for_sel;
        input integer idx;
        begin
            case (idx)
                0: coeff_for_sel = -28;
                1: coeff_for_sel = -24;
                2: coeff_for_sel = 24;
                3: coeff_for_sel = 28;
                4: coeff_for_sel = -27;
                5: coeff_for_sel = -22;
                6: coeff_for_sel = 22;
                7: coeff_for_sel = 27;
                8: coeff_for_sel = -33;
                9: coeff_for_sel = -34;
                10: coeff_for_sel = 34;
                11: coeff_for_sel = 33;
                12: coeff_for_sel = -25;
                13: coeff_for_sel = -18;
                14: coeff_for_sel = 18;
                15: coeff_for_sel = 25;
                16: coeff_for_sel = -60;
                17: coeff_for_sel = -56;
                18: coeff_for_sel = 56;
                19: coeff_for_sel = 60;
                20: coeff_for_sel = -59;
                21: coeff_for_sel = -54;
                22: coeff_for_sel = 54;
                23: coeff_for_sel = 59;
                24: coeff_for_sel = -65;
                25: coeff_for_sel = -66;
                26: coeff_for_sel = 66;
                27: coeff_for_sel = 65;
                28: coeff_for_sel = -57;
                29: coeff_for_sel = -50;
                30: coeff_for_sel = 50;
                31: coeff_for_sel = 57;
                32: coeff_for_sel = -156;
                33: coeff_for_sel = -152;
                34: coeff_for_sel = 152;
                35: coeff_for_sel = 156;
                36: coeff_for_sel = -155;
                37: coeff_for_sel = -150;
                38: coeff_for_sel = 150;
                39: coeff_for_sel = 155;
                40: coeff_for_sel = -161;
                41: coeff_for_sel = -162;
                42: coeff_for_sel = 162;
                43: coeff_for_sel = 161;
                44: coeff_for_sel = -153;
                45: coeff_for_sel = -146;
                46: coeff_for_sel = 146;
                47: coeff_for_sel = 153;
                48: coeff_for_sel = -252;
                49: coeff_for_sel = -248;
                50: coeff_for_sel = 248;
                51: coeff_for_sel = 252;
                52: coeff_for_sel = -251;
                53: coeff_for_sel = -246;
                54: coeff_for_sel = 246;
                55: coeff_for_sel = 251;
                56: coeff_for_sel = -257;
                57: coeff_for_sel = -258;
                58: coeff_for_sel = 258;
                59: coeff_for_sel = 257;
                60: coeff_for_sel = -249;
                61: coeff_for_sel = -242;
                62: coeff_for_sel = 242;
                63: coeff_for_sel = 249;
                64: coeff_for_sel = 132;
                65: coeff_for_sel = 136;
                66: coeff_for_sel = -136;
                67: coeff_for_sel = -132;
                68: coeff_for_sel = 133;
                69: coeff_for_sel = 138;
                70: coeff_for_sel = -138;
                71: coeff_for_sel = -133;
                72: coeff_for_sel = 127;
                73: coeff_for_sel = 126;
                74: coeff_for_sel = -126;
                75: coeff_for_sel = -127;
                76: coeff_for_sel = 135;
                77: coeff_for_sel = 142;
                78: coeff_for_sel = -142;
                79: coeff_for_sel = -135;
                80: coeff_for_sel = 36;
                81: coeff_for_sel = 40;
                82: coeff_for_sel = -40;
                83: coeff_for_sel = -36;
                84: coeff_for_sel = 37;
                85: coeff_for_sel = 42;
                86: coeff_for_sel = -42;
                87: coeff_for_sel = -37;
                88: coeff_for_sel = 31;
                89: coeff_for_sel = 30;
                90: coeff_for_sel = -30;
                91: coeff_for_sel = -31;
                92: coeff_for_sel = 39;
                93: coeff_for_sel = 46;
                94: coeff_for_sel = -46;
                95: coeff_for_sel = -39;
                96: coeff_for_sel = 4;
                97: coeff_for_sel = 8;
                98: coeff_for_sel = -8;
                99: coeff_for_sel = -4;
                100: coeff_for_sel = 5;
                101: coeff_for_sel = 10;
                102: coeff_for_sel = -10;
                103: coeff_for_sel = -5;
                104: coeff_for_sel = -1;
                105: coeff_for_sel = -2;
                106: coeff_for_sel = 2;
                107: coeff_for_sel = 1;
                108: coeff_for_sel = 7;
                109: coeff_for_sel = 14;
                110: coeff_for_sel = -14;
                111: coeff_for_sel = -7;
                112: coeff_for_sel = -92;
                113: coeff_for_sel = -88;
                114: coeff_for_sel = 88;
                115: coeff_for_sel = 92;
                116: coeff_for_sel = -91;
                117: coeff_for_sel = -86;
                118: coeff_for_sel = 86;
                119: coeff_for_sel = 91;
                120: coeff_for_sel = -97;
                121: coeff_for_sel = -98;
                122: coeff_for_sel = 98;
                123: coeff_for_sel = 97;
                124: coeff_for_sel = -89;
                125: coeff_for_sel = -82;
                126: coeff_for_sel = 82;
                127: coeff_for_sel = 89;
                default: coeff_for_sel = 0;
            endcase
        end
    endfunction
    lut6_2_carry_3dd_multiplier dut (.x(x), .sel(sel), .y(y));
    initial begin
        errors = 0;
        for (xi = 0; xi <= 127; xi = xi + 1) begin
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
                end else begin
                    $display("TEST x=%0d sel=%0d coeff=%0d expected=%0d simulated=%0d PASS",
                             xi, si, coeff_for_sel(si), expected_y, $signed(y));
                end
            end
        end
        $display("SUMMARY pass=%0d fail=%0d total=%0d", TOTAL_TESTS-errors, errors, TOTAL_TESTS);
        if (errors != 0) $fatal(1, "Exhaustive test failed");
        $finish;
    end
endmodule
