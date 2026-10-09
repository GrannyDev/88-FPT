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
                4: coeff_for_sel = -60;
                5: coeff_for_sel = -56;
                6: coeff_for_sel = 56;
                7: coeff_for_sel = 60;
                8: coeff_for_sel = -59;
                9: coeff_for_sel = -54;
                10: coeff_for_sel = 54;
                11: coeff_for_sel = 59;
                12: coeff_for_sel = -58;
                13: coeff_for_sel = -52;
                14: coeff_for_sel = 52;
                15: coeff_for_sel = 58;
                16: coeff_for_sel = -127;
                17: coeff_for_sel = -126;
                18: coeff_for_sel = 126;
                19: coeff_for_sel = 127;
                20: coeff_for_sel = -124;
                21: coeff_for_sel = -120;
                22: coeff_for_sel = 120;
                23: coeff_for_sel = 124;
                24: coeff_for_sel = -123;
                25: coeff_for_sel = -118;
                26: coeff_for_sel = 118;
                27: coeff_for_sel = 123;
                28: coeff_for_sel = -122;
                29: coeff_for_sel = -116;
                30: coeff_for_sel = 116;
                31: coeff_for_sel = 122;
                32: coeff_for_sel = -159;
                33: coeff_for_sel = -158;
                34: coeff_for_sel = 158;
                35: coeff_for_sel = 159;
                36: coeff_for_sel = -156;
                37: coeff_for_sel = -152;
                38: coeff_for_sel = 152;
                39: coeff_for_sel = 156;
                40: coeff_for_sel = -155;
                41: coeff_for_sel = -150;
                42: coeff_for_sel = 150;
                43: coeff_for_sel = 155;
                44: coeff_for_sel = -154;
                45: coeff_for_sel = -148;
                46: coeff_for_sel = 148;
                47: coeff_for_sel = 154;
                48: coeff_for_sel = -255;
                49: coeff_for_sel = -254;
                50: coeff_for_sel = 254;
                51: coeff_for_sel = 255;
                52: coeff_for_sel = -252;
                53: coeff_for_sel = -248;
                54: coeff_for_sel = 248;
                55: coeff_for_sel = 252;
                56: coeff_for_sel = -251;
                57: coeff_for_sel = -246;
                58: coeff_for_sel = 246;
                59: coeff_for_sel = 251;
                60: coeff_for_sel = -250;
                61: coeff_for_sel = -244;
                62: coeff_for_sel = 244;
                63: coeff_for_sel = 250;
                64: coeff_for_sel = 129;
                65: coeff_for_sel = 130;
                66: coeff_for_sel = -130;
                67: coeff_for_sel = -129;
                68: coeff_for_sel = 132;
                69: coeff_for_sel = 136;
                70: coeff_for_sel = -136;
                71: coeff_for_sel = -132;
                72: coeff_for_sel = 133;
                73: coeff_for_sel = 138;
                74: coeff_for_sel = -138;
                75: coeff_for_sel = -133;
                76: coeff_for_sel = 134;
                77: coeff_for_sel = 140;
                78: coeff_for_sel = -140;
                79: coeff_for_sel = -134;
                80: coeff_for_sel = 97;
                81: coeff_for_sel = 98;
                82: coeff_for_sel = -98;
                83: coeff_for_sel = -97;
                84: coeff_for_sel = 100;
                85: coeff_for_sel = 104;
                86: coeff_for_sel = -104;
                87: coeff_for_sel = -100;
                88: coeff_for_sel = 101;
                89: coeff_for_sel = 106;
                90: coeff_for_sel = -106;
                91: coeff_for_sel = -101;
                92: coeff_for_sel = 102;
                93: coeff_for_sel = 108;
                94: coeff_for_sel = -108;
                95: coeff_for_sel = -102;
                96: coeff_for_sel = 1;
                97: coeff_for_sel = 2;
                98: coeff_for_sel = -2;
                99: coeff_for_sel = -1;
                100: coeff_for_sel = 4;
                101: coeff_for_sel = 8;
                102: coeff_for_sel = -8;
                103: coeff_for_sel = -4;
                104: coeff_for_sel = 5;
                105: coeff_for_sel = 10;
                106: coeff_for_sel = -10;
                107: coeff_for_sel = -5;
                108: coeff_for_sel = 6;
                109: coeff_for_sel = 12;
                110: coeff_for_sel = -12;
                111: coeff_for_sel = -6;
                112: coeff_for_sel = -95;
                113: coeff_for_sel = -94;
                114: coeff_for_sel = 94;
                115: coeff_for_sel = 95;
                116: coeff_for_sel = -92;
                117: coeff_for_sel = -88;
                118: coeff_for_sel = 88;
                119: coeff_for_sel = 92;
                120: coeff_for_sel = -91;
                121: coeff_for_sel = -86;
                122: coeff_for_sel = 86;
                123: coeff_for_sel = 91;
                124: coeff_for_sel = -90;
                125: coeff_for_sel = -84;
                126: coeff_for_sel = 84;
                127: coeff_for_sel = 90;
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
