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
                0: coeff_for_sel = -27;
                1: coeff_for_sel = -22;
                2: coeff_for_sel = 22;
                3: coeff_for_sel = 27;
                4: coeff_for_sel = -26;
                5: coeff_for_sel = -20;
                6: coeff_for_sel = 20;
                7: coeff_for_sel = 26;
                8: coeff_for_sel = -36;
                9: coeff_for_sel = -40;
                10: coeff_for_sel = 40;
                11: coeff_for_sel = 36;
                12: coeff_for_sel = -31;
                13: coeff_for_sel = -30;
                14: coeff_for_sel = 30;
                15: coeff_for_sel = 31;
                16: coeff_for_sel = -59;
                17: coeff_for_sel = -54;
                18: coeff_for_sel = 54;
                19: coeff_for_sel = 59;
                20: coeff_for_sel = -58;
                21: coeff_for_sel = -52;
                22: coeff_for_sel = 52;
                23: coeff_for_sel = 58;
                24: coeff_for_sel = -68;
                25: coeff_for_sel = -72;
                26: coeff_for_sel = 72;
                27: coeff_for_sel = 68;
                28: coeff_for_sel = -63;
                29: coeff_for_sel = -62;
                30: coeff_for_sel = 62;
                31: coeff_for_sel = 63;
                32: coeff_for_sel = -123;
                33: coeff_for_sel = -118;
                34: coeff_for_sel = 118;
                35: coeff_for_sel = 123;
                36: coeff_for_sel = -122;
                37: coeff_for_sel = -116;
                38: coeff_for_sel = 116;
                39: coeff_for_sel = 122;
                40: coeff_for_sel = -132;
                41: coeff_for_sel = -136;
                42: coeff_for_sel = 136;
                43: coeff_for_sel = 132;
                44: coeff_for_sel = -127;
                45: coeff_for_sel = -126;
                46: coeff_for_sel = 126;
                47: coeff_for_sel = 127;
                48: coeff_for_sel = -155;
                49: coeff_for_sel = -150;
                50: coeff_for_sel = 150;
                51: coeff_for_sel = 155;
                52: coeff_for_sel = -154;
                53: coeff_for_sel = -148;
                54: coeff_for_sel = 148;
                55: coeff_for_sel = 154;
                56: coeff_for_sel = -164;
                57: coeff_for_sel = -168;
                58: coeff_for_sel = 168;
                59: coeff_for_sel = 164;
                60: coeff_for_sel = -159;
                61: coeff_for_sel = -158;
                62: coeff_for_sel = 158;
                63: coeff_for_sel = 159;
                64: coeff_for_sel = 101;
                65: coeff_for_sel = 106;
                66: coeff_for_sel = -106;
                67: coeff_for_sel = -101;
                68: coeff_for_sel = 102;
                69: coeff_for_sel = 108;
                70: coeff_for_sel = -108;
                71: coeff_for_sel = -102;
                72: coeff_for_sel = 92;
                73: coeff_for_sel = 88;
                74: coeff_for_sel = -88;
                75: coeff_for_sel = -92;
                76: coeff_for_sel = 97;
                77: coeff_for_sel = 98;
                78: coeff_for_sel = -98;
                79: coeff_for_sel = -97;
                80: coeff_for_sel = 37;
                81: coeff_for_sel = 42;
                82: coeff_for_sel = -42;
                83: coeff_for_sel = -37;
                84: coeff_for_sel = 38;
                85: coeff_for_sel = 44;
                86: coeff_for_sel = -44;
                87: coeff_for_sel = -38;
                88: coeff_for_sel = 28;
                89: coeff_for_sel = 24;
                90: coeff_for_sel = -24;
                91: coeff_for_sel = -28;
                92: coeff_for_sel = 33;
                93: coeff_for_sel = 34;
                94: coeff_for_sel = -34;
                95: coeff_for_sel = -33;
                96: coeff_for_sel = 5;
                97: coeff_for_sel = 10;
                98: coeff_for_sel = -10;
                99: coeff_for_sel = -5;
                100: coeff_for_sel = 6;
                101: coeff_for_sel = 12;
                102: coeff_for_sel = -12;
                103: coeff_for_sel = -6;
                104: coeff_for_sel = -4;
                105: coeff_for_sel = -8;
                106: coeff_for_sel = 8;
                107: coeff_for_sel = 4;
                108: coeff_for_sel = 1;
                109: coeff_for_sel = 2;
                110: coeff_for_sel = -2;
                111: coeff_for_sel = -1;
                112: coeff_for_sel = -91;
                113: coeff_for_sel = -86;
                114: coeff_for_sel = 86;
                115: coeff_for_sel = 91;
                116: coeff_for_sel = -90;
                117: coeff_for_sel = -84;
                118: coeff_for_sel = 84;
                119: coeff_for_sel = 90;
                120: coeff_for_sel = -100;
                121: coeff_for_sel = -104;
                122: coeff_for_sel = 104;
                123: coeff_for_sel = 100;
                124: coeff_for_sel = -95;
                125: coeff_for_sel = -94;
                126: coeff_for_sel = 94;
                127: coeff_for_sel = 95;
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
