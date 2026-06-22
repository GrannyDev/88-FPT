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
                0: coeff_for_sel = 35;
                1: coeff_for_sel = 44;
                2: coeff_for_sel = 26;
                3: coeff_for_sel = 29;
                4: coeff_for_sel = 37;
                5: coeff_for_sel = 52;
                6: coeff_for_sel = 22;
                7: coeff_for_sel = 27;
                8: coeff_for_sel = 17;
                9: coeff_for_sel = -28;
                10: coeff_for_sel = 62;
                11: coeff_for_sel = 47;
                12: coeff_for_sel = 31;
                13: coeff_for_sel = 28;
                14: coeff_for_sel = 34;
                15: coeff_for_sel = 33;
                16: coeff_for_sel = 67;
                17: coeff_for_sel = 76;
                18: coeff_for_sel = 58;
                19: coeff_for_sel = 61;
                20: coeff_for_sel = 69;
                21: coeff_for_sel = 84;
                22: coeff_for_sel = 54;
                23: coeff_for_sel = 59;
                24: coeff_for_sel = 49;
                25: coeff_for_sel = 4;
                26: coeff_for_sel = 94;
                27: coeff_for_sel = 79;
                28: coeff_for_sel = 63;
                29: coeff_for_sel = 60;
                30: coeff_for_sel = 66;
                31: coeff_for_sel = 65;
                32: coeff_for_sel = 131;
                33: coeff_for_sel = 140;
                34: coeff_for_sel = 122;
                35: coeff_for_sel = 125;
                36: coeff_for_sel = 133;
                37: coeff_for_sel = 148;
                38: coeff_for_sel = 118;
                39: coeff_for_sel = 123;
                40: coeff_for_sel = 113;
                41: coeff_for_sel = 68;
                42: coeff_for_sel = 158;
                43: coeff_for_sel = 143;
                44: coeff_for_sel = 127;
                45: coeff_for_sel = 124;
                46: coeff_for_sel = 130;
                47: coeff_for_sel = 129;
                48: coeff_for_sel = 163;
                49: coeff_for_sel = 172;
                50: coeff_for_sel = 154;
                51: coeff_for_sel = 157;
                52: coeff_for_sel = 165;
                53: coeff_for_sel = 180;
                54: coeff_for_sel = 150;
                55: coeff_for_sel = 155;
                56: coeff_for_sel = 145;
                57: coeff_for_sel = 100;
                58: coeff_for_sel = 190;
                59: coeff_for_sel = 175;
                60: coeff_for_sel = 159;
                61: coeff_for_sel = 156;
                62: coeff_for_sel = 162;
                63: coeff_for_sel = 161;
                64: coeff_for_sel = -125;
                65: coeff_for_sel = -116;
                66: coeff_for_sel = -134;
                67: coeff_for_sel = -131;
                68: coeff_for_sel = -123;
                69: coeff_for_sel = -108;
                70: coeff_for_sel = -138;
                71: coeff_for_sel = -133;
                72: coeff_for_sel = -143;
                73: coeff_for_sel = -188;
                74: coeff_for_sel = -98;
                75: coeff_for_sel = -113;
                76: coeff_for_sel = -129;
                77: coeff_for_sel = -132;
                78: coeff_for_sel = -126;
                79: coeff_for_sel = -127;
                80: coeff_for_sel = -93;
                81: coeff_for_sel = -84;
                82: coeff_for_sel = -102;
                83: coeff_for_sel = -99;
                84: coeff_for_sel = -91;
                85: coeff_for_sel = -76;
                86: coeff_for_sel = -106;
                87: coeff_for_sel = -101;
                88: coeff_for_sel = -111;
                89: coeff_for_sel = -156;
                90: coeff_for_sel = -66;
                91: coeff_for_sel = -81;
                92: coeff_for_sel = -97;
                93: coeff_for_sel = -100;
                94: coeff_for_sel = -94;
                95: coeff_for_sel = -95;
                96: coeff_for_sel = -29;
                97: coeff_for_sel = -20;
                98: coeff_for_sel = -38;
                99: coeff_for_sel = -35;
                100: coeff_for_sel = -27;
                101: coeff_for_sel = -12;
                102: coeff_for_sel = -42;
                103: coeff_for_sel = -37;
                104: coeff_for_sel = -47;
                105: coeff_for_sel = -92;
                106: coeff_for_sel = -2;
                107: coeff_for_sel = -17;
                108: coeff_for_sel = -33;
                109: coeff_for_sel = -36;
                110: coeff_for_sel = -30;
                111: coeff_for_sel = -31;
                112: coeff_for_sel = 3;
                113: coeff_for_sel = 12;
                114: coeff_for_sel = -6;
                115: coeff_for_sel = -3;
                116: coeff_for_sel = 5;
                117: coeff_for_sel = 20;
                118: coeff_for_sel = -10;
                119: coeff_for_sel = -5;
                120: coeff_for_sel = -15;
                121: coeff_for_sel = -60;
                122: coeff_for_sel = 30;
                123: coeff_for_sel = 15;
                124: coeff_for_sel = -1;
                125: coeff_for_sel = -4;
                126: coeff_for_sel = 2;
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
