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
                0: coeff_for_sel = -28;
                1: coeff_for_sel = -24;
                2: coeff_for_sel = 24;
                3: coeff_for_sel = 28;
                4: coeff_for_sel = -27;
                5: coeff_for_sel = -22;
                6: coeff_for_sel = 22;
                7: coeff_for_sel = 27;
                8: coeff_for_sel = -35;
                9: coeff_for_sel = -38;
                10: coeff_for_sel = 38;
                11: coeff_for_sel = 35;
                12: coeff_for_sel = -1;
                13: coeff_for_sel = 30;
                14: coeff_for_sel = -30;
                15: coeff_for_sel = 1;
                16: coeff_for_sel = -60;
                17: coeff_for_sel = -56;
                18: coeff_for_sel = 56;
                19: coeff_for_sel = 60;
                20: coeff_for_sel = -59;
                21: coeff_for_sel = -54;
                22: coeff_for_sel = 54;
                23: coeff_for_sel = 59;
                24: coeff_for_sel = -67;
                25: coeff_for_sel = -70;
                26: coeff_for_sel = 70;
                27: coeff_for_sel = 67;
                28: coeff_for_sel = -33;
                29: coeff_for_sel = -2;
                30: coeff_for_sel = 2;
                31: coeff_for_sel = 33;
                32: coeff_for_sel = -124;
                33: coeff_for_sel = -120;
                34: coeff_for_sel = 120;
                35: coeff_for_sel = 124;
                36: coeff_for_sel = -123;
                37: coeff_for_sel = -118;
                38: coeff_for_sel = 118;
                39: coeff_for_sel = 123;
                40: coeff_for_sel = -131;
                41: coeff_for_sel = -134;
                42: coeff_for_sel = 134;
                43: coeff_for_sel = 131;
                44: coeff_for_sel = -97;
                45: coeff_for_sel = -66;
                46: coeff_for_sel = 66;
                47: coeff_for_sel = 97;
                48: coeff_for_sel = -156;
                49: coeff_for_sel = -152;
                50: coeff_for_sel = 152;
                51: coeff_for_sel = 156;
                52: coeff_for_sel = -155;
                53: coeff_for_sel = -150;
                54: coeff_for_sel = 150;
                55: coeff_for_sel = 155;
                56: coeff_for_sel = -163;
                57: coeff_for_sel = -166;
                58: coeff_for_sel = 166;
                59: coeff_for_sel = 163;
                60: coeff_for_sel = -129;
                61: coeff_for_sel = -98;
                62: coeff_for_sel = 98;
                63: coeff_for_sel = 129;
                64: coeff_for_sel = 132;
                65: coeff_for_sel = 136;
                66: coeff_for_sel = -136;
                67: coeff_for_sel = -132;
                68: coeff_for_sel = 133;
                69: coeff_for_sel = 138;
                70: coeff_for_sel = -138;
                71: coeff_for_sel = -133;
                72: coeff_for_sel = 125;
                73: coeff_for_sel = 122;
                74: coeff_for_sel = -122;
                75: coeff_for_sel = -125;
                76: coeff_for_sel = 159;
                77: coeff_for_sel = 190;
                78: coeff_for_sel = -190;
                79: coeff_for_sel = -159;
                80: coeff_for_sel = 36;
                81: coeff_for_sel = 40;
                82: coeff_for_sel = -40;
                83: coeff_for_sel = -36;
                84: coeff_for_sel = 37;
                85: coeff_for_sel = 42;
                86: coeff_for_sel = -42;
                87: coeff_for_sel = -37;
                88: coeff_for_sel = 29;
                89: coeff_for_sel = 26;
                90: coeff_for_sel = -26;
                91: coeff_for_sel = -29;
                92: coeff_for_sel = 63;
                93: coeff_for_sel = 94;
                94: coeff_for_sel = -94;
                95: coeff_for_sel = -63;
                96: coeff_for_sel = 4;
                97: coeff_for_sel = 8;
                98: coeff_for_sel = -8;
                99: coeff_for_sel = -4;
                100: coeff_for_sel = 5;
                101: coeff_for_sel = 10;
                102: coeff_for_sel = -10;
                103: coeff_for_sel = -5;
                104: coeff_for_sel = -3;
                105: coeff_for_sel = -6;
                106: coeff_for_sel = 6;
                107: coeff_for_sel = 3;
                108: coeff_for_sel = 31;
                109: coeff_for_sel = 62;
                110: coeff_for_sel = -62;
                111: coeff_for_sel = -31;
                112: coeff_for_sel = -92;
                113: coeff_for_sel = -88;
                114: coeff_for_sel = 88;
                115: coeff_for_sel = 92;
                116: coeff_for_sel = -91;
                117: coeff_for_sel = -86;
                118: coeff_for_sel = 86;
                119: coeff_for_sel = 91;
                120: coeff_for_sel = -99;
                121: coeff_for_sel = -102;
                122: coeff_for_sel = 102;
                123: coeff_for_sel = 99;
                124: coeff_for_sel = -65;
                125: coeff_for_sel = -34;
                126: coeff_for_sel = 34;
                127: coeff_for_sel = 65;
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
