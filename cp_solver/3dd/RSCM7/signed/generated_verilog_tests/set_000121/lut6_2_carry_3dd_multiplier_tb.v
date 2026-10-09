`timescale 1ns/1ps
module lut6_2_carry_3dd_multiplier_tb;
    localparam integer INPUT_BW = 7;
    localparam integer OUTPUT_BW = 15;
    localparam integer SEL_BITS = 7;
    localparam integer N_COEFFS = 128;
    localparam integer TOTAL_TESTS = 16384;
    reg signed [INPUT_BW-1:0] x;
    reg [SEL_BITS-1:0] sel;
    wire signed [OUTPUT_BW-1:0] y;
    reg signed [OUTPUT_BW-1:0] expected_y;
    integer xi, si, expected, errors;
    function integer coeff_for_sel;
        input integer idx;
        begin
            case (idx)
                0: coeff_for_sel = -63;
                1: coeff_for_sel = -62;
                2: coeff_for_sel = 62;
                3: coeff_for_sel = 63;
                4: coeff_for_sel = -61;
                5: coeff_for_sel = -58;
                6: coeff_for_sel = 58;
                7: coeff_for_sel = 61;
                8: coeff_for_sel = -60;
                9: coeff_for_sel = -56;
                10: coeff_for_sel = 56;
                11: coeff_for_sel = 60;
                12: coeff_for_sel = -59;
                13: coeff_for_sel = -54;
                14: coeff_for_sel = 54;
                15: coeff_for_sel = 59;
                16: coeff_for_sel = -127;
                17: coeff_for_sel = -126;
                18: coeff_for_sel = 126;
                19: coeff_for_sel = 127;
                20: coeff_for_sel = -125;
                21: coeff_for_sel = -122;
                22: coeff_for_sel = 122;
                23: coeff_for_sel = 125;
                24: coeff_for_sel = -124;
                25: coeff_for_sel = -120;
                26: coeff_for_sel = 120;
                27: coeff_for_sel = 124;
                28: coeff_for_sel = -123;
                29: coeff_for_sel = -118;
                30: coeff_for_sel = 118;
                31: coeff_for_sel = 123;
                32: coeff_for_sel = -159;
                33: coeff_for_sel = -158;
                34: coeff_for_sel = 158;
                35: coeff_for_sel = 159;
                36: coeff_for_sel = -157;
                37: coeff_for_sel = -154;
                38: coeff_for_sel = 154;
                39: coeff_for_sel = 157;
                40: coeff_for_sel = -156;
                41: coeff_for_sel = -152;
                42: coeff_for_sel = 152;
                43: coeff_for_sel = 156;
                44: coeff_for_sel = -155;
                45: coeff_for_sel = -150;
                46: coeff_for_sel = 150;
                47: coeff_for_sel = 155;
                48: coeff_for_sel = -255;
                49: coeff_for_sel = -254;
                50: coeff_for_sel = 254;
                51: coeff_for_sel = 255;
                52: coeff_for_sel = -253;
                53: coeff_for_sel = -250;
                54: coeff_for_sel = 250;
                55: coeff_for_sel = 253;
                56: coeff_for_sel = -252;
                57: coeff_for_sel = -248;
                58: coeff_for_sel = 248;
                59: coeff_for_sel = 252;
                60: coeff_for_sel = -251;
                61: coeff_for_sel = -246;
                62: coeff_for_sel = 246;
                63: coeff_for_sel = 251;
                64: coeff_for_sel = 129;
                65: coeff_for_sel = 130;
                66: coeff_for_sel = -130;
                67: coeff_for_sel = -129;
                68: coeff_for_sel = 131;
                69: coeff_for_sel = 134;
                70: coeff_for_sel = -134;
                71: coeff_for_sel = -131;
                72: coeff_for_sel = 132;
                73: coeff_for_sel = 136;
                74: coeff_for_sel = -136;
                75: coeff_for_sel = -132;
                76: coeff_for_sel = 133;
                77: coeff_for_sel = 138;
                78: coeff_for_sel = -138;
                79: coeff_for_sel = -133;
                80: coeff_for_sel = 97;
                81: coeff_for_sel = 98;
                82: coeff_for_sel = -98;
                83: coeff_for_sel = -97;
                84: coeff_for_sel = 99;
                85: coeff_for_sel = 102;
                86: coeff_for_sel = -102;
                87: coeff_for_sel = -99;
                88: coeff_for_sel = 100;
                89: coeff_for_sel = 104;
                90: coeff_for_sel = -104;
                91: coeff_for_sel = -100;
                92: coeff_for_sel = 101;
                93: coeff_for_sel = 106;
                94: coeff_for_sel = -106;
                95: coeff_for_sel = -101;
                96: coeff_for_sel = 1;
                97: coeff_for_sel = 2;
                98: coeff_for_sel = -2;
                99: coeff_for_sel = -1;
                100: coeff_for_sel = 3;
                101: coeff_for_sel = 6;
                102: coeff_for_sel = -6;
                103: coeff_for_sel = -3;
                104: coeff_for_sel = 4;
                105: coeff_for_sel = 8;
                106: coeff_for_sel = -8;
                107: coeff_for_sel = -4;
                108: coeff_for_sel = 5;
                109: coeff_for_sel = 10;
                110: coeff_for_sel = -10;
                111: coeff_for_sel = -5;
                112: coeff_for_sel = -95;
                113: coeff_for_sel = -94;
                114: coeff_for_sel = 94;
                115: coeff_for_sel = 95;
                116: coeff_for_sel = -93;
                117: coeff_for_sel = -90;
                118: coeff_for_sel = 90;
                119: coeff_for_sel = 93;
                120: coeff_for_sel = -92;
                121: coeff_for_sel = -88;
                122: coeff_for_sel = 88;
                123: coeff_for_sel = 92;
                124: coeff_for_sel = -91;
                125: coeff_for_sel = -86;
                126: coeff_for_sel = 86;
                127: coeff_for_sel = 91;
                default: coeff_for_sel = 0;
            endcase
        end
    endfunction
    lut6_2_carry_3dd_multiplier dut (.x(x), .sel(sel), .y(y));
    initial begin
        errors = 0;
        for (xi = -64; xi <= 63; xi = xi + 1) begin
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
