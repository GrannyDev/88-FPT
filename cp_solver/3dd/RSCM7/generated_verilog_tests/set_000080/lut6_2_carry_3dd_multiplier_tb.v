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
                4: coeff_for_sel = -29;
                5: coeff_for_sel = -26;
                6: coeff_for_sel = 26;
                7: coeff_for_sel = 29;
                8: coeff_for_sel = -28;
                9: coeff_for_sel = -24;
                10: coeff_for_sel = 24;
                11: coeff_for_sel = 28;
                12: coeff_for_sel = -22;
                13: coeff_for_sel = -12;
                14: coeff_for_sel = 12;
                15: coeff_for_sel = 22;
                16: coeff_for_sel = -63;
                17: coeff_for_sel = -62;
                18: coeff_for_sel = 62;
                19: coeff_for_sel = 63;
                20: coeff_for_sel = -61;
                21: coeff_for_sel = -58;
                22: coeff_for_sel = 58;
                23: coeff_for_sel = 61;
                24: coeff_for_sel = -60;
                25: coeff_for_sel = -56;
                26: coeff_for_sel = 56;
                27: coeff_for_sel = 60;
                28: coeff_for_sel = -54;
                29: coeff_for_sel = -44;
                30: coeff_for_sel = 44;
                31: coeff_for_sel = 54;
                32: coeff_for_sel = -127;
                33: coeff_for_sel = -126;
                34: coeff_for_sel = 126;
                35: coeff_for_sel = 127;
                36: coeff_for_sel = -125;
                37: coeff_for_sel = -122;
                38: coeff_for_sel = 122;
                39: coeff_for_sel = 125;
                40: coeff_for_sel = -124;
                41: coeff_for_sel = -120;
                42: coeff_for_sel = 120;
                43: coeff_for_sel = 124;
                44: coeff_for_sel = -118;
                45: coeff_for_sel = -108;
                46: coeff_for_sel = 108;
                47: coeff_for_sel = 118;
                48: coeff_for_sel = -159;
                49: coeff_for_sel = -158;
                50: coeff_for_sel = 158;
                51: coeff_for_sel = 159;
                52: coeff_for_sel = -157;
                53: coeff_for_sel = -154;
                54: coeff_for_sel = 154;
                55: coeff_for_sel = 157;
                56: coeff_for_sel = -156;
                57: coeff_for_sel = -152;
                58: coeff_for_sel = 152;
                59: coeff_for_sel = 156;
                60: coeff_for_sel = -150;
                61: coeff_for_sel = -140;
                62: coeff_for_sel = 140;
                63: coeff_for_sel = 150;
                64: coeff_for_sel = 97;
                65: coeff_for_sel = 98;
                66: coeff_for_sel = -98;
                67: coeff_for_sel = -97;
                68: coeff_for_sel = 99;
                69: coeff_for_sel = 102;
                70: coeff_for_sel = -102;
                71: coeff_for_sel = -99;
                72: coeff_for_sel = 100;
                73: coeff_for_sel = 104;
                74: coeff_for_sel = -104;
                75: coeff_for_sel = -100;
                76: coeff_for_sel = 106;
                77: coeff_for_sel = 116;
                78: coeff_for_sel = -116;
                79: coeff_for_sel = -106;
                80: coeff_for_sel = 33;
                81: coeff_for_sel = 34;
                82: coeff_for_sel = -34;
                83: coeff_for_sel = -33;
                84: coeff_for_sel = 35;
                85: coeff_for_sel = 38;
                86: coeff_for_sel = -38;
                87: coeff_for_sel = -35;
                88: coeff_for_sel = 36;
                89: coeff_for_sel = 40;
                90: coeff_for_sel = -40;
                91: coeff_for_sel = -36;
                92: coeff_for_sel = 42;
                93: coeff_for_sel = 52;
                94: coeff_for_sel = -52;
                95: coeff_for_sel = -42;
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
                108: coeff_for_sel = 10;
                109: coeff_for_sel = 20;
                110: coeff_for_sel = -20;
                111: coeff_for_sel = -10;
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
                124: coeff_for_sel = -86;
                125: coeff_for_sel = -76;
                126: coeff_for_sel = 76;
                127: coeff_for_sel = 86;
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
