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
                0: coeff_for_sel = 41;
                1: coeff_for_sel = 50;
                2: coeff_for_sel = -4;
                3: coeff_for_sel = 14;
                4: coeff_for_sel = 44;
                5: coeff_for_sel = 56;
                6: coeff_for_sel = -16;
                7: coeff_for_sel = 8;
                8: coeff_for_sel = 31;
                9: coeff_for_sel = 30;
                10: coeff_for_sel = 36;
                11: coeff_for_sel = 34;
                12: coeff_for_sel = 35;
                13: coeff_for_sel = 38;
                14: coeff_for_sel = 20;
                15: coeff_for_sel = 26;
                16: coeff_for_sel = 73;
                17: coeff_for_sel = 82;
                18: coeff_for_sel = 28;
                19: coeff_for_sel = 46;
                20: coeff_for_sel = 76;
                21: coeff_for_sel = 88;
                22: coeff_for_sel = 16;
                23: coeff_for_sel = 40;
                24: coeff_for_sel = 63;
                25: coeff_for_sel = 62;
                26: coeff_for_sel = 68;
                27: coeff_for_sel = 66;
                28: coeff_for_sel = 67;
                29: coeff_for_sel = 70;
                30: coeff_for_sel = 52;
                31: coeff_for_sel = 58;
                32: coeff_for_sel = 137;
                33: coeff_for_sel = 146;
                34: coeff_for_sel = 92;
                35: coeff_for_sel = 110;
                36: coeff_for_sel = 140;
                37: coeff_for_sel = 152;
                38: coeff_for_sel = 80;
                39: coeff_for_sel = 104;
                40: coeff_for_sel = 127;
                41: coeff_for_sel = 126;
                42: coeff_for_sel = 132;
                43: coeff_for_sel = 130;
                44: coeff_for_sel = 131;
                45: coeff_for_sel = 134;
                46: coeff_for_sel = 116;
                47: coeff_for_sel = 122;
                48: coeff_for_sel = 169;
                49: coeff_for_sel = 178;
                50: coeff_for_sel = 124;
                51: coeff_for_sel = 142;
                52: coeff_for_sel = 172;
                53: coeff_for_sel = 184;
                54: coeff_for_sel = 112;
                55: coeff_for_sel = 136;
                56: coeff_for_sel = 159;
                57: coeff_for_sel = 158;
                58: coeff_for_sel = 164;
                59: coeff_for_sel = 162;
                60: coeff_for_sel = 163;
                61: coeff_for_sel = 166;
                62: coeff_for_sel = 148;
                63: coeff_for_sel = 154;
                64: coeff_for_sel = -119;
                65: coeff_for_sel = -110;
                66: coeff_for_sel = -164;
                67: coeff_for_sel = -146;
                68: coeff_for_sel = -116;
                69: coeff_for_sel = -104;
                70: coeff_for_sel = -176;
                71: coeff_for_sel = -152;
                72: coeff_for_sel = -129;
                73: coeff_for_sel = -130;
                74: coeff_for_sel = -124;
                75: coeff_for_sel = -126;
                76: coeff_for_sel = -125;
                77: coeff_for_sel = -122;
                78: coeff_for_sel = -140;
                79: coeff_for_sel = -134;
                80: coeff_for_sel = -87;
                81: coeff_for_sel = -78;
                82: coeff_for_sel = -132;
                83: coeff_for_sel = -114;
                84: coeff_for_sel = -84;
                85: coeff_for_sel = -72;
                86: coeff_for_sel = -144;
                87: coeff_for_sel = -120;
                88: coeff_for_sel = -97;
                89: coeff_for_sel = -98;
                90: coeff_for_sel = -92;
                91: coeff_for_sel = -94;
                92: coeff_for_sel = -93;
                93: coeff_for_sel = -90;
                94: coeff_for_sel = -108;
                95: coeff_for_sel = -102;
                96: coeff_for_sel = -23;
                97: coeff_for_sel = -14;
                98: coeff_for_sel = -68;
                99: coeff_for_sel = -50;
                100: coeff_for_sel = -20;
                101: coeff_for_sel = -8;
                102: coeff_for_sel = -80;
                103: coeff_for_sel = -56;
                104: coeff_for_sel = -33;
                105: coeff_for_sel = -34;
                106: coeff_for_sel = -28;
                107: coeff_for_sel = -30;
                108: coeff_for_sel = -29;
                109: coeff_for_sel = -26;
                110: coeff_for_sel = -44;
                111: coeff_for_sel = -38;
                112: coeff_for_sel = 9;
                113: coeff_for_sel = 18;
                114: coeff_for_sel = -36;
                115: coeff_for_sel = -18;
                116: coeff_for_sel = 12;
                117: coeff_for_sel = 24;
                118: coeff_for_sel = -48;
                119: coeff_for_sel = -24;
                120: coeff_for_sel = -1;
                121: coeff_for_sel = -2;
                122: coeff_for_sel = 4;
                123: coeff_for_sel = 2;
                124: coeff_for_sel = 3;
                125: coeff_for_sel = 6;
                126: coeff_for_sel = -12;
                127: coeff_for_sel = -6;
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
