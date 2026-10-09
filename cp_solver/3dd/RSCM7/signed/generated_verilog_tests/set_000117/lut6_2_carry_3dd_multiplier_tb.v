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
                0: coeff_for_sel = -31;
                1: coeff_for_sel = -30;
                2: coeff_for_sel = 30;
                3: coeff_for_sel = 31;
                4: coeff_for_sel = -28;
                5: coeff_for_sel = -24;
                6: coeff_for_sel = 24;
                7: coeff_for_sel = 28;
                8: coeff_for_sel = -39;
                9: coeff_for_sel = -46;
                10: coeff_for_sel = 46;
                11: coeff_for_sel = 39;
                12: coeff_for_sel = -38;
                13: coeff_for_sel = -44;
                14: coeff_for_sel = 44;
                15: coeff_for_sel = 38;
                16: coeff_for_sel = -63;
                17: coeff_for_sel = -62;
                18: coeff_for_sel = 62;
                19: coeff_for_sel = 63;
                20: coeff_for_sel = -60;
                21: coeff_for_sel = -56;
                22: coeff_for_sel = 56;
                23: coeff_for_sel = 60;
                24: coeff_for_sel = -71;
                25: coeff_for_sel = -78;
                26: coeff_for_sel = 78;
                27: coeff_for_sel = 71;
                28: coeff_for_sel = -70;
                29: coeff_for_sel = -76;
                30: coeff_for_sel = 76;
                31: coeff_for_sel = 70;
                32: coeff_for_sel = -127;
                33: coeff_for_sel = -126;
                34: coeff_for_sel = 126;
                35: coeff_for_sel = 127;
                36: coeff_for_sel = -124;
                37: coeff_for_sel = -120;
                38: coeff_for_sel = 120;
                39: coeff_for_sel = 124;
                40: coeff_for_sel = -135;
                41: coeff_for_sel = -142;
                42: coeff_for_sel = 142;
                43: coeff_for_sel = 135;
                44: coeff_for_sel = -134;
                45: coeff_for_sel = -140;
                46: coeff_for_sel = 140;
                47: coeff_for_sel = 134;
                48: coeff_for_sel = -159;
                49: coeff_for_sel = -158;
                50: coeff_for_sel = 158;
                51: coeff_for_sel = 159;
                52: coeff_for_sel = -156;
                53: coeff_for_sel = -152;
                54: coeff_for_sel = 152;
                55: coeff_for_sel = 156;
                56: coeff_for_sel = -167;
                57: coeff_for_sel = -174;
                58: coeff_for_sel = 174;
                59: coeff_for_sel = 167;
                60: coeff_for_sel = -166;
                61: coeff_for_sel = -172;
                62: coeff_for_sel = 172;
                63: coeff_for_sel = 166;
                64: coeff_for_sel = 129;
                65: coeff_for_sel = 130;
                66: coeff_for_sel = -130;
                67: coeff_for_sel = -129;
                68: coeff_for_sel = 132;
                69: coeff_for_sel = 136;
                70: coeff_for_sel = -136;
                71: coeff_for_sel = -132;
                72: coeff_for_sel = 121;
                73: coeff_for_sel = 114;
                74: coeff_for_sel = -114;
                75: coeff_for_sel = -121;
                76: coeff_for_sel = 122;
                77: coeff_for_sel = 116;
                78: coeff_for_sel = -116;
                79: coeff_for_sel = -122;
                80: coeff_for_sel = 97;
                81: coeff_for_sel = 98;
                82: coeff_for_sel = -98;
                83: coeff_for_sel = -97;
                84: coeff_for_sel = 100;
                85: coeff_for_sel = 104;
                86: coeff_for_sel = -104;
                87: coeff_for_sel = -100;
                88: coeff_for_sel = 89;
                89: coeff_for_sel = 82;
                90: coeff_for_sel = -82;
                91: coeff_for_sel = -89;
                92: coeff_for_sel = 90;
                93: coeff_for_sel = 84;
                94: coeff_for_sel = -84;
                95: coeff_for_sel = -90;
                96: coeff_for_sel = 1;
                97: coeff_for_sel = 2;
                98: coeff_for_sel = -2;
                99: coeff_for_sel = -1;
                100: coeff_for_sel = 4;
                101: coeff_for_sel = 8;
                102: coeff_for_sel = -8;
                103: coeff_for_sel = -4;
                104: coeff_for_sel = -7;
                105: coeff_for_sel = -14;
                106: coeff_for_sel = 14;
                107: coeff_for_sel = 7;
                108: coeff_for_sel = -6;
                109: coeff_for_sel = -12;
                110: coeff_for_sel = 12;
                111: coeff_for_sel = 6;
                112: coeff_for_sel = -95;
                113: coeff_for_sel = -94;
                114: coeff_for_sel = 94;
                115: coeff_for_sel = 95;
                116: coeff_for_sel = -92;
                117: coeff_for_sel = -88;
                118: coeff_for_sel = 88;
                119: coeff_for_sel = 92;
                120: coeff_for_sel = -103;
                121: coeff_for_sel = -110;
                122: coeff_for_sel = 110;
                123: coeff_for_sel = 103;
                124: coeff_for_sel = -102;
                125: coeff_for_sel = -108;
                126: coeff_for_sel = 108;
                127: coeff_for_sel = 102;
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
