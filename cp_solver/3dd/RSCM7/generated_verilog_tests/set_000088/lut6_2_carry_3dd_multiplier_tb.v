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
                0: coeff_for_sel = -31;
                1: coeff_for_sel = -30;
                2: coeff_for_sel = 30;
                3: coeff_for_sel = 31;
                4: coeff_for_sel = -23;
                5: coeff_for_sel = -14;
                6: coeff_for_sel = 14;
                7: coeff_for_sel = 23;
                8: coeff_for_sel = -36;
                9: coeff_for_sel = -40;
                10: coeff_for_sel = 40;
                11: coeff_for_sel = 36;
                12: coeff_for_sel = -35;
                13: coeff_for_sel = -38;
                14: coeff_for_sel = 38;
                15: coeff_for_sel = 35;
                16: coeff_for_sel = -63;
                17: coeff_for_sel = -62;
                18: coeff_for_sel = 62;
                19: coeff_for_sel = 63;
                20: coeff_for_sel = -55;
                21: coeff_for_sel = -46;
                22: coeff_for_sel = 46;
                23: coeff_for_sel = 55;
                24: coeff_for_sel = -68;
                25: coeff_for_sel = -72;
                26: coeff_for_sel = 72;
                27: coeff_for_sel = 68;
                28: coeff_for_sel = -67;
                29: coeff_for_sel = -70;
                30: coeff_for_sel = 70;
                31: coeff_for_sel = 67;
                32: coeff_for_sel = -127;
                33: coeff_for_sel = -126;
                34: coeff_for_sel = 126;
                35: coeff_for_sel = 127;
                36: coeff_for_sel = -119;
                37: coeff_for_sel = -110;
                38: coeff_for_sel = 110;
                39: coeff_for_sel = 119;
                40: coeff_for_sel = -132;
                41: coeff_for_sel = -136;
                42: coeff_for_sel = 136;
                43: coeff_for_sel = 132;
                44: coeff_for_sel = -131;
                45: coeff_for_sel = -134;
                46: coeff_for_sel = 134;
                47: coeff_for_sel = 131;
                48: coeff_for_sel = -159;
                49: coeff_for_sel = -158;
                50: coeff_for_sel = 158;
                51: coeff_for_sel = 159;
                52: coeff_for_sel = -151;
                53: coeff_for_sel = -142;
                54: coeff_for_sel = 142;
                55: coeff_for_sel = 151;
                56: coeff_for_sel = -164;
                57: coeff_for_sel = -168;
                58: coeff_for_sel = 168;
                59: coeff_for_sel = 164;
                60: coeff_for_sel = -163;
                61: coeff_for_sel = -166;
                62: coeff_for_sel = 166;
                63: coeff_for_sel = 163;
                64: coeff_for_sel = 97;
                65: coeff_for_sel = 98;
                66: coeff_for_sel = -98;
                67: coeff_for_sel = -97;
                68: coeff_for_sel = 105;
                69: coeff_for_sel = 114;
                70: coeff_for_sel = -114;
                71: coeff_for_sel = -105;
                72: coeff_for_sel = 92;
                73: coeff_for_sel = 88;
                74: coeff_for_sel = -88;
                75: coeff_for_sel = -92;
                76: coeff_for_sel = 93;
                77: coeff_for_sel = 90;
                78: coeff_for_sel = -90;
                79: coeff_for_sel = -93;
                80: coeff_for_sel = 33;
                81: coeff_for_sel = 34;
                82: coeff_for_sel = -34;
                83: coeff_for_sel = -33;
                84: coeff_for_sel = 41;
                85: coeff_for_sel = 50;
                86: coeff_for_sel = -50;
                87: coeff_for_sel = -41;
                88: coeff_for_sel = 28;
                89: coeff_for_sel = 24;
                90: coeff_for_sel = -24;
                91: coeff_for_sel = -28;
                92: coeff_for_sel = 29;
                93: coeff_for_sel = 26;
                94: coeff_for_sel = -26;
                95: coeff_for_sel = -29;
                96: coeff_for_sel = 1;
                97: coeff_for_sel = 2;
                98: coeff_for_sel = -2;
                99: coeff_for_sel = -1;
                100: coeff_for_sel = 9;
                101: coeff_for_sel = 18;
                102: coeff_for_sel = -18;
                103: coeff_for_sel = -9;
                104: coeff_for_sel = -4;
                105: coeff_for_sel = -8;
                106: coeff_for_sel = 8;
                107: coeff_for_sel = 4;
                108: coeff_for_sel = -3;
                109: coeff_for_sel = -6;
                110: coeff_for_sel = 6;
                111: coeff_for_sel = 3;
                112: coeff_for_sel = -95;
                113: coeff_for_sel = -94;
                114: coeff_for_sel = 94;
                115: coeff_for_sel = 95;
                116: coeff_for_sel = -87;
                117: coeff_for_sel = -78;
                118: coeff_for_sel = 78;
                119: coeff_for_sel = 87;
                120: coeff_for_sel = -100;
                121: coeff_for_sel = -104;
                122: coeff_for_sel = 104;
                123: coeff_for_sel = 100;
                124: coeff_for_sel = -99;
                125: coeff_for_sel = -102;
                126: coeff_for_sel = 102;
                127: coeff_for_sel = 99;
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
