`timescale 1ns/1ps

module lut6_2_carry_3dd_multiplier_tb;
    localparam integer INPUT_BW = 7;
    localparam integer OUTPUT_BW = 15;
    localparam integer SEL_BITS = 7;
    localparam integer N_COEFFS = 128;

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
                0: coeff_for_sel = 33;
                1: coeff_for_sel = 34;
                2: coeff_for_sel = 28;
                3: coeff_for_sel = 30;
                4: coeff_for_sel = 44;
                5: coeff_for_sel = 56;
                6: coeff_for_sel = -16;
                7: coeff_for_sel = 8;
                8: coeff_for_sel = 35;
                9: coeff_for_sel = 38;
                10: coeff_for_sel = 20;
                11: coeff_for_sel = 26;
                12: coeff_for_sel = 39;
                13: coeff_for_sel = 46;
                14: coeff_for_sel = 4;
                15: coeff_for_sel = 18;
                16: coeff_for_sel = 65;
                17: coeff_for_sel = 66;
                18: coeff_for_sel = 60;
                19: coeff_for_sel = 62;
                20: coeff_for_sel = 76;
                21: coeff_for_sel = 88;
                22: coeff_for_sel = 16;
                23: coeff_for_sel = 40;
                24: coeff_for_sel = 67;
                25: coeff_for_sel = 70;
                26: coeff_for_sel = 52;
                27: coeff_for_sel = 58;
                28: coeff_for_sel = 71;
                29: coeff_for_sel = 78;
                30: coeff_for_sel = 36;
                31: coeff_for_sel = 50;
                32: coeff_for_sel = 129;
                33: coeff_for_sel = 130;
                34: coeff_for_sel = 124;
                35: coeff_for_sel = 126;
                36: coeff_for_sel = 140;
                37: coeff_for_sel = 152;
                38: coeff_for_sel = 80;
                39: coeff_for_sel = 104;
                40: coeff_for_sel = 131;
                41: coeff_for_sel = 134;
                42: coeff_for_sel = 116;
                43: coeff_for_sel = 122;
                44: coeff_for_sel = 135;
                45: coeff_for_sel = 142;
                46: coeff_for_sel = 100;
                47: coeff_for_sel = 114;
                48: coeff_for_sel = 161;
                49: coeff_for_sel = 162;
                50: coeff_for_sel = 156;
                51: coeff_for_sel = 158;
                52: coeff_for_sel = 172;
                53: coeff_for_sel = 184;
                54: coeff_for_sel = 112;
                55: coeff_for_sel = 136;
                56: coeff_for_sel = 163;
                57: coeff_for_sel = 166;
                58: coeff_for_sel = 148;
                59: coeff_for_sel = 154;
                60: coeff_for_sel = 167;
                61: coeff_for_sel = 174;
                62: coeff_for_sel = 132;
                63: coeff_for_sel = 146;
                64: coeff_for_sel = -127;
                65: coeff_for_sel = -126;
                66: coeff_for_sel = -132;
                67: coeff_for_sel = -130;
                68: coeff_for_sel = -116;
                69: coeff_for_sel = -104;
                70: coeff_for_sel = -176;
                71: coeff_for_sel = -152;
                72: coeff_for_sel = -125;
                73: coeff_for_sel = -122;
                74: coeff_for_sel = -140;
                75: coeff_for_sel = -134;
                76: coeff_for_sel = -121;
                77: coeff_for_sel = -114;
                78: coeff_for_sel = -156;
                79: coeff_for_sel = -142;
                80: coeff_for_sel = -95;
                81: coeff_for_sel = -94;
                82: coeff_for_sel = -100;
                83: coeff_for_sel = -98;
                84: coeff_for_sel = -84;
                85: coeff_for_sel = -72;
                86: coeff_for_sel = -144;
                87: coeff_for_sel = -120;
                88: coeff_for_sel = -93;
                89: coeff_for_sel = -90;
                90: coeff_for_sel = -108;
                91: coeff_for_sel = -102;
                92: coeff_for_sel = -89;
                93: coeff_for_sel = -82;
                94: coeff_for_sel = -124;
                95: coeff_for_sel = -110;
                96: coeff_for_sel = -31;
                97: coeff_for_sel = -30;
                98: coeff_for_sel = -36;
                99: coeff_for_sel = -34;
                100: coeff_for_sel = -20;
                101: coeff_for_sel = -8;
                102: coeff_for_sel = -80;
                103: coeff_for_sel = -56;
                104: coeff_for_sel = -29;
                105: coeff_for_sel = -26;
                106: coeff_for_sel = -44;
                107: coeff_for_sel = -38;
                108: coeff_for_sel = -25;
                109: coeff_for_sel = -18;
                110: coeff_for_sel = -60;
                111: coeff_for_sel = -46;
                112: coeff_for_sel = 1;
                113: coeff_for_sel = 2;
                114: coeff_for_sel = -4;
                115: coeff_for_sel = -2;
                116: coeff_for_sel = 12;
                117: coeff_for_sel = 24;
                118: coeff_for_sel = -48;
                119: coeff_for_sel = -24;
                120: coeff_for_sel = 3;
                121: coeff_for_sel = 6;
                122: coeff_for_sel = -12;
                123: coeff_for_sel = -6;
                124: coeff_for_sel = 7;
                125: coeff_for_sel = 14;
                126: coeff_for_sel = -28;
                127: coeff_for_sel = -14;
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
                end
            end
        end
        if (errors == 0) begin
            $display("SUMMARY pass=%0d fail=0 total=%0d",
                     128 * N_COEFFS, 128 * N_COEFFS);
        end else begin
            $display("SUMMARY pass=%0d fail=%0d total=%0d",
                     (128 * N_COEFFS) - errors, errors, 128 * N_COEFFS);
        end
        $finish;
    end
endmodule
