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
                0: coeff_for_sel = -39;
                1: coeff_for_sel = -46;
                2: coeff_for_sel = 46;
                3: coeff_for_sel = 39;
                4: coeff_for_sel = -36;
                5: coeff_for_sel = -40;
                6: coeff_for_sel = 40;
                7: coeff_for_sel = 36;
                8: coeff_for_sel = -35;
                9: coeff_for_sel = -38;
                10: coeff_for_sel = 38;
                11: coeff_for_sel = 35;
                12: coeff_for_sel = -33;
                13: coeff_for_sel = -34;
                14: coeff_for_sel = 34;
                15: coeff_for_sel = 33;
                16: coeff_for_sel = -71;
                17: coeff_for_sel = -78;
                18: coeff_for_sel = 78;
                19: coeff_for_sel = 71;
                20: coeff_for_sel = -68;
                21: coeff_for_sel = -72;
                22: coeff_for_sel = 72;
                23: coeff_for_sel = 68;
                24: coeff_for_sel = -67;
                25: coeff_for_sel = -70;
                26: coeff_for_sel = 70;
                27: coeff_for_sel = 67;
                28: coeff_for_sel = -65;
                29: coeff_for_sel = -66;
                30: coeff_for_sel = 66;
                31: coeff_for_sel = 65;
                32: coeff_for_sel = -135;
                33: coeff_for_sel = -142;
                34: coeff_for_sel = 142;
                35: coeff_for_sel = 135;
                36: coeff_for_sel = -132;
                37: coeff_for_sel = -136;
                38: coeff_for_sel = 136;
                39: coeff_for_sel = 132;
                40: coeff_for_sel = -131;
                41: coeff_for_sel = -134;
                42: coeff_for_sel = 134;
                43: coeff_for_sel = 131;
                44: coeff_for_sel = -129;
                45: coeff_for_sel = -130;
                46: coeff_for_sel = 130;
                47: coeff_for_sel = 129;
                48: coeff_for_sel = -167;
                49: coeff_for_sel = -174;
                50: coeff_for_sel = 174;
                51: coeff_for_sel = 167;
                52: coeff_for_sel = -164;
                53: coeff_for_sel = -168;
                54: coeff_for_sel = 168;
                55: coeff_for_sel = 164;
                56: coeff_for_sel = -163;
                57: coeff_for_sel = -166;
                58: coeff_for_sel = 166;
                59: coeff_for_sel = 163;
                60: coeff_for_sel = -161;
                61: coeff_for_sel = -162;
                62: coeff_for_sel = 162;
                63: coeff_for_sel = 161;
                64: coeff_for_sel = 121;
                65: coeff_for_sel = 114;
                66: coeff_for_sel = -114;
                67: coeff_for_sel = -121;
                68: coeff_for_sel = 124;
                69: coeff_for_sel = 120;
                70: coeff_for_sel = -120;
                71: coeff_for_sel = -124;
                72: coeff_for_sel = 125;
                73: coeff_for_sel = 122;
                74: coeff_for_sel = -122;
                75: coeff_for_sel = -125;
                76: coeff_for_sel = 127;
                77: coeff_for_sel = 126;
                78: coeff_for_sel = -126;
                79: coeff_for_sel = -127;
                80: coeff_for_sel = 89;
                81: coeff_for_sel = 82;
                82: coeff_for_sel = -82;
                83: coeff_for_sel = -89;
                84: coeff_for_sel = 92;
                85: coeff_for_sel = 88;
                86: coeff_for_sel = -88;
                87: coeff_for_sel = -92;
                88: coeff_for_sel = 93;
                89: coeff_for_sel = 90;
                90: coeff_for_sel = -90;
                91: coeff_for_sel = -93;
                92: coeff_for_sel = 95;
                93: coeff_for_sel = 94;
                94: coeff_for_sel = -94;
                95: coeff_for_sel = -95;
                96: coeff_for_sel = -7;
                97: coeff_for_sel = -14;
                98: coeff_for_sel = 14;
                99: coeff_for_sel = 7;
                100: coeff_for_sel = -4;
                101: coeff_for_sel = -8;
                102: coeff_for_sel = 8;
                103: coeff_for_sel = 4;
                104: coeff_for_sel = -3;
                105: coeff_for_sel = -6;
                106: coeff_for_sel = 6;
                107: coeff_for_sel = 3;
                108: coeff_for_sel = -1;
                109: coeff_for_sel = -2;
                110: coeff_for_sel = 2;
                111: coeff_for_sel = 1;
                112: coeff_for_sel = -103;
                113: coeff_for_sel = -110;
                114: coeff_for_sel = 110;
                115: coeff_for_sel = 103;
                116: coeff_for_sel = -100;
                117: coeff_for_sel = -104;
                118: coeff_for_sel = 104;
                119: coeff_for_sel = 100;
                120: coeff_for_sel = -99;
                121: coeff_for_sel = -102;
                122: coeff_for_sel = 102;
                123: coeff_for_sel = 99;
                124: coeff_for_sel = -97;
                125: coeff_for_sel = -98;
                126: coeff_for_sel = 98;
                127: coeff_for_sel = 97;
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
