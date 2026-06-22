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
                4: coeff_for_sel = -28;
                5: coeff_for_sel = -24;
                6: coeff_for_sel = 24;
                7: coeff_for_sel = 28;
                8: coeff_for_sel = -27;
                9: coeff_for_sel = -22;
                10: coeff_for_sel = 22;
                11: coeff_for_sel = 27;
                12: coeff_for_sel = -23;
                13: coeff_for_sel = -14;
                14: coeff_for_sel = 14;
                15: coeff_for_sel = 23;
                16: coeff_for_sel = -63;
                17: coeff_for_sel = -62;
                18: coeff_for_sel = 62;
                19: coeff_for_sel = 63;
                20: coeff_for_sel = -60;
                21: coeff_for_sel = -56;
                22: coeff_for_sel = 56;
                23: coeff_for_sel = 60;
                24: coeff_for_sel = -59;
                25: coeff_for_sel = -54;
                26: coeff_for_sel = 54;
                27: coeff_for_sel = 59;
                28: coeff_for_sel = -55;
                29: coeff_for_sel = -46;
                30: coeff_for_sel = 46;
                31: coeff_for_sel = 55;
                32: coeff_for_sel = -127;
                33: coeff_for_sel = -126;
                34: coeff_for_sel = 126;
                35: coeff_for_sel = 127;
                36: coeff_for_sel = -124;
                37: coeff_for_sel = -120;
                38: coeff_for_sel = 120;
                39: coeff_for_sel = 124;
                40: coeff_for_sel = -123;
                41: coeff_for_sel = -118;
                42: coeff_for_sel = 118;
                43: coeff_for_sel = 123;
                44: coeff_for_sel = -119;
                45: coeff_for_sel = -110;
                46: coeff_for_sel = 110;
                47: coeff_for_sel = 119;
                48: coeff_for_sel = -159;
                49: coeff_for_sel = -158;
                50: coeff_for_sel = 158;
                51: coeff_for_sel = 159;
                52: coeff_for_sel = -156;
                53: coeff_for_sel = -152;
                54: coeff_for_sel = 152;
                55: coeff_for_sel = 156;
                56: coeff_for_sel = -155;
                57: coeff_for_sel = -150;
                58: coeff_for_sel = 150;
                59: coeff_for_sel = 155;
                60: coeff_for_sel = -151;
                61: coeff_for_sel = -142;
                62: coeff_for_sel = 142;
                63: coeff_for_sel = 151;
                64: coeff_for_sel = 129;
                65: coeff_for_sel = 130;
                66: coeff_for_sel = -130;
                67: coeff_for_sel = -129;
                68: coeff_for_sel = 132;
                69: coeff_for_sel = 136;
                70: coeff_for_sel = -136;
                71: coeff_for_sel = -132;
                72: coeff_for_sel = 133;
                73: coeff_for_sel = 138;
                74: coeff_for_sel = -138;
                75: coeff_for_sel = -133;
                76: coeff_for_sel = 137;
                77: coeff_for_sel = 146;
                78: coeff_for_sel = -146;
                79: coeff_for_sel = -137;
                80: coeff_for_sel = 33;
                81: coeff_for_sel = 34;
                82: coeff_for_sel = -34;
                83: coeff_for_sel = -33;
                84: coeff_for_sel = 36;
                85: coeff_for_sel = 40;
                86: coeff_for_sel = -40;
                87: coeff_for_sel = -36;
                88: coeff_for_sel = 37;
                89: coeff_for_sel = 42;
                90: coeff_for_sel = -42;
                91: coeff_for_sel = -37;
                92: coeff_for_sel = 41;
                93: coeff_for_sel = 50;
                94: coeff_for_sel = -50;
                95: coeff_for_sel = -41;
                96: coeff_for_sel = 1;
                97: coeff_for_sel = 2;
                98: coeff_for_sel = -2;
                99: coeff_for_sel = -1;
                100: coeff_for_sel = 4;
                101: coeff_for_sel = 8;
                102: coeff_for_sel = -8;
                103: coeff_for_sel = -4;
                104: coeff_for_sel = 5;
                105: coeff_for_sel = 10;
                106: coeff_for_sel = -10;
                107: coeff_for_sel = -5;
                108: coeff_for_sel = 9;
                109: coeff_for_sel = 18;
                110: coeff_for_sel = -18;
                111: coeff_for_sel = -9;
                112: coeff_for_sel = -95;
                113: coeff_for_sel = -94;
                114: coeff_for_sel = 94;
                115: coeff_for_sel = 95;
                116: coeff_for_sel = -92;
                117: coeff_for_sel = -88;
                118: coeff_for_sel = 88;
                119: coeff_for_sel = 92;
                120: coeff_for_sel = -91;
                121: coeff_for_sel = -86;
                122: coeff_for_sel = 86;
                123: coeff_for_sel = 91;
                124: coeff_for_sel = -87;
                125: coeff_for_sel = -78;
                126: coeff_for_sel = 78;
                127: coeff_for_sel = 87;
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
