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
                0: coeff_for_sel = 40;
                1: coeff_for_sel = 48;
                2: coeff_for_sel = 0;
                3: coeff_for_sel = 24;
                4: coeff_for_sel = 49;
                5: coeff_for_sel = 66;
                6: coeff_for_sel = -36;
                7: coeff_for_sel = 15;
                8: coeff_for_sel = 29;
                9: coeff_for_sel = 26;
                10: coeff_for_sel = 44;
                11: coeff_for_sel = 35;
                12: coeff_for_sel = 31;
                13: coeff_for_sel = 30;
                14: coeff_for_sel = 36;
                15: coeff_for_sel = 33;
                16: coeff_for_sel = 72;
                17: coeff_for_sel = 80;
                18: coeff_for_sel = 32;
                19: coeff_for_sel = 56;
                20: coeff_for_sel = 81;
                21: coeff_for_sel = 98;
                22: coeff_for_sel = -4;
                23: coeff_for_sel = 47;
                24: coeff_for_sel = 61;
                25: coeff_for_sel = 58;
                26: coeff_for_sel = 76;
                27: coeff_for_sel = 67;
                28: coeff_for_sel = 63;
                29: coeff_for_sel = 62;
                30: coeff_for_sel = 68;
                31: coeff_for_sel = 65;
                32: coeff_for_sel = 136;
                33: coeff_for_sel = 144;
                34: coeff_for_sel = 96;
                35: coeff_for_sel = 120;
                36: coeff_for_sel = 145;
                37: coeff_for_sel = 162;
                38: coeff_for_sel = 60;
                39: coeff_for_sel = 111;
                40: coeff_for_sel = 125;
                41: coeff_for_sel = 122;
                42: coeff_for_sel = 140;
                43: coeff_for_sel = 131;
                44: coeff_for_sel = 127;
                45: coeff_for_sel = 126;
                46: coeff_for_sel = 132;
                47: coeff_for_sel = 129;
                48: coeff_for_sel = 168;
                49: coeff_for_sel = 176;
                50: coeff_for_sel = 128;
                51: coeff_for_sel = 152;
                52: coeff_for_sel = 177;
                53: coeff_for_sel = 194;
                54: coeff_for_sel = 92;
                55: coeff_for_sel = 143;
                56: coeff_for_sel = 157;
                57: coeff_for_sel = 154;
                58: coeff_for_sel = 172;
                59: coeff_for_sel = 163;
                60: coeff_for_sel = 159;
                61: coeff_for_sel = 158;
                62: coeff_for_sel = 164;
                63: coeff_for_sel = 161;
                64: coeff_for_sel = -120;
                65: coeff_for_sel = -112;
                66: coeff_for_sel = -160;
                67: coeff_for_sel = -136;
                68: coeff_for_sel = -111;
                69: coeff_for_sel = -94;
                70: coeff_for_sel = -196;
                71: coeff_for_sel = -145;
                72: coeff_for_sel = -131;
                73: coeff_for_sel = -134;
                74: coeff_for_sel = -116;
                75: coeff_for_sel = -125;
                76: coeff_for_sel = -129;
                77: coeff_for_sel = -130;
                78: coeff_for_sel = -124;
                79: coeff_for_sel = -127;
                80: coeff_for_sel = -88;
                81: coeff_for_sel = -80;
                82: coeff_for_sel = -128;
                83: coeff_for_sel = -104;
                84: coeff_for_sel = -79;
                85: coeff_for_sel = -62;
                86: coeff_for_sel = -164;
                87: coeff_for_sel = -113;
                88: coeff_for_sel = -99;
                89: coeff_for_sel = -102;
                90: coeff_for_sel = -84;
                91: coeff_for_sel = -93;
                92: coeff_for_sel = -97;
                93: coeff_for_sel = -98;
                94: coeff_for_sel = -92;
                95: coeff_for_sel = -95;
                96: coeff_for_sel = -24;
                97: coeff_for_sel = -16;
                98: coeff_for_sel = -64;
                99: coeff_for_sel = -40;
                100: coeff_for_sel = -15;
                101: coeff_for_sel = 2;
                102: coeff_for_sel = -100;
                103: coeff_for_sel = -49;
                104: coeff_for_sel = -35;
                105: coeff_for_sel = -38;
                106: coeff_for_sel = -20;
                107: coeff_for_sel = -29;
                108: coeff_for_sel = -33;
                109: coeff_for_sel = -34;
                110: coeff_for_sel = -28;
                111: coeff_for_sel = -31;
                112: coeff_for_sel = 8;
                113: coeff_for_sel = 16;
                114: coeff_for_sel = -32;
                115: coeff_for_sel = -8;
                116: coeff_for_sel = 17;
                117: coeff_for_sel = 34;
                118: coeff_for_sel = -68;
                119: coeff_for_sel = -17;
                120: coeff_for_sel = -3;
                121: coeff_for_sel = -6;
                122: coeff_for_sel = 12;
                123: coeff_for_sel = 3;
                124: coeff_for_sel = -1;
                125: coeff_for_sel = -2;
                126: coeff_for_sel = 4;
                127: coeff_for_sel = 1;
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
