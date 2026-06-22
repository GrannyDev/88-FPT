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
                8: coeff_for_sel = -23;
                9: coeff_for_sel = -14;
                10: coeff_for_sel = 14;
                11: coeff_for_sel = 23;
                12: coeff_for_sel = -22;
                13: coeff_for_sel = -12;
                14: coeff_for_sel = 12;
                15: coeff_for_sel = 22;
                16: coeff_for_sel = -63;
                17: coeff_for_sel = -62;
                18: coeff_for_sel = 62;
                19: coeff_for_sel = 63;
                20: coeff_for_sel = -60;
                21: coeff_for_sel = -56;
                22: coeff_for_sel = 56;
                23: coeff_for_sel = 60;
                24: coeff_for_sel = -55;
                25: coeff_for_sel = -46;
                26: coeff_for_sel = 46;
                27: coeff_for_sel = 55;
                28: coeff_for_sel = -54;
                29: coeff_for_sel = -44;
                30: coeff_for_sel = 44;
                31: coeff_for_sel = 54;
                32: coeff_for_sel = -127;
                33: coeff_for_sel = -126;
                34: coeff_for_sel = 126;
                35: coeff_for_sel = 127;
                36: coeff_for_sel = -124;
                37: coeff_for_sel = -120;
                38: coeff_for_sel = 120;
                39: coeff_for_sel = 124;
                40: coeff_for_sel = -119;
                41: coeff_for_sel = -110;
                42: coeff_for_sel = 110;
                43: coeff_for_sel = 119;
                44: coeff_for_sel = -118;
                45: coeff_for_sel = -108;
                46: coeff_for_sel = 108;
                47: coeff_for_sel = 118;
                48: coeff_for_sel = -159;
                49: coeff_for_sel = -158;
                50: coeff_for_sel = 158;
                51: coeff_for_sel = 159;
                52: coeff_for_sel = -156;
                53: coeff_for_sel = -152;
                54: coeff_for_sel = 152;
                55: coeff_for_sel = 156;
                56: coeff_for_sel = -151;
                57: coeff_for_sel = -142;
                58: coeff_for_sel = 142;
                59: coeff_for_sel = 151;
                60: coeff_for_sel = -150;
                61: coeff_for_sel = -140;
                62: coeff_for_sel = 140;
                63: coeff_for_sel = 150;
                64: coeff_for_sel = 129;
                65: coeff_for_sel = 130;
                66: coeff_for_sel = -130;
                67: coeff_for_sel = -129;
                68: coeff_for_sel = 132;
                69: coeff_for_sel = 136;
                70: coeff_for_sel = -136;
                71: coeff_for_sel = -132;
                72: coeff_for_sel = 137;
                73: coeff_for_sel = 146;
                74: coeff_for_sel = -146;
                75: coeff_for_sel = -137;
                76: coeff_for_sel = 138;
                77: coeff_for_sel = 148;
                78: coeff_for_sel = -148;
                79: coeff_for_sel = -138;
                80: coeff_for_sel = 97;
                81: coeff_for_sel = 98;
                82: coeff_for_sel = -98;
                83: coeff_for_sel = -97;
                84: coeff_for_sel = 100;
                85: coeff_for_sel = 104;
                86: coeff_for_sel = -104;
                87: coeff_for_sel = -100;
                88: coeff_for_sel = 105;
                89: coeff_for_sel = 114;
                90: coeff_for_sel = -114;
                91: coeff_for_sel = -105;
                92: coeff_for_sel = 106;
                93: coeff_for_sel = 116;
                94: coeff_for_sel = -116;
                95: coeff_for_sel = -106;
                96: coeff_for_sel = 33;
                97: coeff_for_sel = 34;
                98: coeff_for_sel = -34;
                99: coeff_for_sel = -33;
                100: coeff_for_sel = 36;
                101: coeff_for_sel = 40;
                102: coeff_for_sel = -40;
                103: coeff_for_sel = -36;
                104: coeff_for_sel = 41;
                105: coeff_for_sel = 50;
                106: coeff_for_sel = -50;
                107: coeff_for_sel = -41;
                108: coeff_for_sel = 42;
                109: coeff_for_sel = 52;
                110: coeff_for_sel = -52;
                111: coeff_for_sel = -42;
                112: coeff_for_sel = 1;
                113: coeff_for_sel = 2;
                114: coeff_for_sel = -2;
                115: coeff_for_sel = -1;
                116: coeff_for_sel = 4;
                117: coeff_for_sel = 8;
                118: coeff_for_sel = -8;
                119: coeff_for_sel = -4;
                120: coeff_for_sel = 9;
                121: coeff_for_sel = 18;
                122: coeff_for_sel = -18;
                123: coeff_for_sel = -9;
                124: coeff_for_sel = 10;
                125: coeff_for_sel = 20;
                126: coeff_for_sel = -20;
                127: coeff_for_sel = -10;
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
