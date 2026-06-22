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
                0: coeff_for_sel = -23;
                1: coeff_for_sel = -14;
                2: coeff_for_sel = 14;
                3: coeff_for_sel = 23;
                4: coeff_for_sel = -20;
                5: coeff_for_sel = -8;
                6: coeff_for_sel = 8;
                7: coeff_for_sel = 20;
                8: coeff_for_sel = -35;
                9: coeff_for_sel = -38;
                10: coeff_for_sel = 38;
                11: coeff_for_sel = 35;
                12: coeff_for_sel = -33;
                13: coeff_for_sel = -34;
                14: coeff_for_sel = 34;
                15: coeff_for_sel = 33;
                16: coeff_for_sel = -55;
                17: coeff_for_sel = -46;
                18: coeff_for_sel = 46;
                19: coeff_for_sel = 55;
                20: coeff_for_sel = -52;
                21: coeff_for_sel = -40;
                22: coeff_for_sel = 40;
                23: coeff_for_sel = 52;
                24: coeff_for_sel = -67;
                25: coeff_for_sel = -70;
                26: coeff_for_sel = 70;
                27: coeff_for_sel = 67;
                28: coeff_for_sel = -65;
                29: coeff_for_sel = -66;
                30: coeff_for_sel = 66;
                31: coeff_for_sel = 65;
                32: coeff_for_sel = -119;
                33: coeff_for_sel = -110;
                34: coeff_for_sel = 110;
                35: coeff_for_sel = 119;
                36: coeff_for_sel = -116;
                37: coeff_for_sel = -104;
                38: coeff_for_sel = 104;
                39: coeff_for_sel = 116;
                40: coeff_for_sel = -131;
                41: coeff_for_sel = -134;
                42: coeff_for_sel = 134;
                43: coeff_for_sel = 131;
                44: coeff_for_sel = -129;
                45: coeff_for_sel = -130;
                46: coeff_for_sel = 130;
                47: coeff_for_sel = 129;
                48: coeff_for_sel = -151;
                49: coeff_for_sel = -142;
                50: coeff_for_sel = 142;
                51: coeff_for_sel = 151;
                52: coeff_for_sel = -148;
                53: coeff_for_sel = -136;
                54: coeff_for_sel = 136;
                55: coeff_for_sel = 148;
                56: coeff_for_sel = -163;
                57: coeff_for_sel = -166;
                58: coeff_for_sel = 166;
                59: coeff_for_sel = 163;
                60: coeff_for_sel = -161;
                61: coeff_for_sel = -162;
                62: coeff_for_sel = 162;
                63: coeff_for_sel = 161;
                64: coeff_for_sel = 105;
                65: coeff_for_sel = 114;
                66: coeff_for_sel = -114;
                67: coeff_for_sel = -105;
                68: coeff_for_sel = 108;
                69: coeff_for_sel = 120;
                70: coeff_for_sel = -120;
                71: coeff_for_sel = -108;
                72: coeff_for_sel = 93;
                73: coeff_for_sel = 90;
                74: coeff_for_sel = -90;
                75: coeff_for_sel = -93;
                76: coeff_for_sel = 95;
                77: coeff_for_sel = 94;
                78: coeff_for_sel = -94;
                79: coeff_for_sel = -95;
                80: coeff_for_sel = 41;
                81: coeff_for_sel = 50;
                82: coeff_for_sel = -50;
                83: coeff_for_sel = -41;
                84: coeff_for_sel = 44;
                85: coeff_for_sel = 56;
                86: coeff_for_sel = -56;
                87: coeff_for_sel = -44;
                88: coeff_for_sel = 29;
                89: coeff_for_sel = 26;
                90: coeff_for_sel = -26;
                91: coeff_for_sel = -29;
                92: coeff_for_sel = 31;
                93: coeff_for_sel = 30;
                94: coeff_for_sel = -30;
                95: coeff_for_sel = -31;
                96: coeff_for_sel = 9;
                97: coeff_for_sel = 18;
                98: coeff_for_sel = -18;
                99: coeff_for_sel = -9;
                100: coeff_for_sel = 12;
                101: coeff_for_sel = 24;
                102: coeff_for_sel = -24;
                103: coeff_for_sel = -12;
                104: coeff_for_sel = -3;
                105: coeff_for_sel = -6;
                106: coeff_for_sel = 6;
                107: coeff_for_sel = 3;
                108: coeff_for_sel = -1;
                109: coeff_for_sel = -2;
                110: coeff_for_sel = 2;
                111: coeff_for_sel = 1;
                112: coeff_for_sel = -87;
                113: coeff_for_sel = -78;
                114: coeff_for_sel = 78;
                115: coeff_for_sel = 87;
                116: coeff_for_sel = -84;
                117: coeff_for_sel = -72;
                118: coeff_for_sel = 72;
                119: coeff_for_sel = 84;
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
