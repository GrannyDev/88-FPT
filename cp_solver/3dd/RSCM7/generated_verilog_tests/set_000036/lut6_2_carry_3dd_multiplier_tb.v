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
                0: coeff_for_sel = -29;
                1: coeff_for_sel = -26;
                2: coeff_for_sel = 26;
                3: coeff_for_sel = 29;
                4: coeff_for_sel = -22;
                5: coeff_for_sel = -12;
                6: coeff_for_sel = 12;
                7: coeff_for_sel = 22;
                8: coeff_for_sel = -46;
                9: coeff_for_sel = -60;
                10: coeff_for_sel = 60;
                11: coeff_for_sel = 46;
                12: coeff_for_sel = -31;
                13: coeff_for_sel = -30;
                14: coeff_for_sel = 30;
                15: coeff_for_sel = 31;
                16: coeff_for_sel = -61;
                17: coeff_for_sel = -58;
                18: coeff_for_sel = 58;
                19: coeff_for_sel = 61;
                20: coeff_for_sel = -54;
                21: coeff_for_sel = -44;
                22: coeff_for_sel = 44;
                23: coeff_for_sel = 54;
                24: coeff_for_sel = -78;
                25: coeff_for_sel = -92;
                26: coeff_for_sel = 92;
                27: coeff_for_sel = 78;
                28: coeff_for_sel = -63;
                29: coeff_for_sel = -62;
                30: coeff_for_sel = 62;
                31: coeff_for_sel = 63;
                32: coeff_for_sel = -125;
                33: coeff_for_sel = -122;
                34: coeff_for_sel = 122;
                35: coeff_for_sel = 125;
                36: coeff_for_sel = -118;
                37: coeff_for_sel = -108;
                38: coeff_for_sel = 108;
                39: coeff_for_sel = 118;
                40: coeff_for_sel = -142;
                41: coeff_for_sel = -156;
                42: coeff_for_sel = 156;
                43: coeff_for_sel = 142;
                44: coeff_for_sel = -127;
                45: coeff_for_sel = -126;
                46: coeff_for_sel = 126;
                47: coeff_for_sel = 127;
                48: coeff_for_sel = -157;
                49: coeff_for_sel = -154;
                50: coeff_for_sel = 154;
                51: coeff_for_sel = 157;
                52: coeff_for_sel = -150;
                53: coeff_for_sel = -140;
                54: coeff_for_sel = 140;
                55: coeff_for_sel = 150;
                56: coeff_for_sel = -174;
                57: coeff_for_sel = -188;
                58: coeff_for_sel = 188;
                59: coeff_for_sel = 174;
                60: coeff_for_sel = -159;
                61: coeff_for_sel = -158;
                62: coeff_for_sel = 158;
                63: coeff_for_sel = 159;
                64: coeff_for_sel = 99;
                65: coeff_for_sel = 102;
                66: coeff_for_sel = -102;
                67: coeff_for_sel = -99;
                68: coeff_for_sel = 106;
                69: coeff_for_sel = 116;
                70: coeff_for_sel = -116;
                71: coeff_for_sel = -106;
                72: coeff_for_sel = 82;
                73: coeff_for_sel = 68;
                74: coeff_for_sel = -68;
                75: coeff_for_sel = -82;
                76: coeff_for_sel = 97;
                77: coeff_for_sel = 98;
                78: coeff_for_sel = -98;
                79: coeff_for_sel = -97;
                80: coeff_for_sel = 35;
                81: coeff_for_sel = 38;
                82: coeff_for_sel = -38;
                83: coeff_for_sel = -35;
                84: coeff_for_sel = 42;
                85: coeff_for_sel = 52;
                86: coeff_for_sel = -52;
                87: coeff_for_sel = -42;
                88: coeff_for_sel = 18;
                89: coeff_for_sel = 4;
                90: coeff_for_sel = -4;
                91: coeff_for_sel = -18;
                92: coeff_for_sel = 33;
                93: coeff_for_sel = 34;
                94: coeff_for_sel = -34;
                95: coeff_for_sel = -33;
                96: coeff_for_sel = 3;
                97: coeff_for_sel = 6;
                98: coeff_for_sel = -6;
                99: coeff_for_sel = -3;
                100: coeff_for_sel = 10;
                101: coeff_for_sel = 20;
                102: coeff_for_sel = -20;
                103: coeff_for_sel = -10;
                104: coeff_for_sel = -14;
                105: coeff_for_sel = -28;
                106: coeff_for_sel = 28;
                107: coeff_for_sel = 14;
                108: coeff_for_sel = 1;
                109: coeff_for_sel = 2;
                110: coeff_for_sel = -2;
                111: coeff_for_sel = -1;
                112: coeff_for_sel = -93;
                113: coeff_for_sel = -90;
                114: coeff_for_sel = 90;
                115: coeff_for_sel = 93;
                116: coeff_for_sel = -86;
                117: coeff_for_sel = -76;
                118: coeff_for_sel = 76;
                119: coeff_for_sel = 86;
                120: coeff_for_sel = -110;
                121: coeff_for_sel = -124;
                122: coeff_for_sel = 124;
                123: coeff_for_sel = 110;
                124: coeff_for_sel = -95;
                125: coeff_for_sel = -94;
                126: coeff_for_sel = 94;
                127: coeff_for_sel = 95;
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
