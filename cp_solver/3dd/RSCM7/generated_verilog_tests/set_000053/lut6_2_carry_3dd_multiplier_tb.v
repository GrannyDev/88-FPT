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
                0: coeff_for_sel = -27;
                1: coeff_for_sel = -22;
                2: coeff_for_sel = 22;
                3: coeff_for_sel = 27;
                4: coeff_for_sel = -12;
                5: coeff_for_sel = 8;
                6: coeff_for_sel = -8;
                7: coeff_for_sel = 12;
                8: coeff_for_sel = -33;
                9: coeff_for_sel = -34;
                10: coeff_for_sel = 34;
                11: coeff_for_sel = 33;
                12: coeff_for_sel = -29;
                13: coeff_for_sel = -26;
                14: coeff_for_sel = 26;
                15: coeff_for_sel = 29;
                16: coeff_for_sel = -59;
                17: coeff_for_sel = -54;
                18: coeff_for_sel = 54;
                19: coeff_for_sel = 59;
                20: coeff_for_sel = -44;
                21: coeff_for_sel = -24;
                22: coeff_for_sel = 24;
                23: coeff_for_sel = 44;
                24: coeff_for_sel = -65;
                25: coeff_for_sel = -66;
                26: coeff_for_sel = 66;
                27: coeff_for_sel = 65;
                28: coeff_for_sel = -61;
                29: coeff_for_sel = -58;
                30: coeff_for_sel = 58;
                31: coeff_for_sel = 61;
                32: coeff_for_sel = -123;
                33: coeff_for_sel = -118;
                34: coeff_for_sel = 118;
                35: coeff_for_sel = 123;
                36: coeff_for_sel = -108;
                37: coeff_for_sel = -88;
                38: coeff_for_sel = 88;
                39: coeff_for_sel = 108;
                40: coeff_for_sel = -129;
                41: coeff_for_sel = -130;
                42: coeff_for_sel = 130;
                43: coeff_for_sel = 129;
                44: coeff_for_sel = -125;
                45: coeff_for_sel = -122;
                46: coeff_for_sel = 122;
                47: coeff_for_sel = 125;
                48: coeff_for_sel = -155;
                49: coeff_for_sel = -150;
                50: coeff_for_sel = 150;
                51: coeff_for_sel = 155;
                52: coeff_for_sel = -140;
                53: coeff_for_sel = -120;
                54: coeff_for_sel = 120;
                55: coeff_for_sel = 140;
                56: coeff_for_sel = -161;
                57: coeff_for_sel = -162;
                58: coeff_for_sel = 162;
                59: coeff_for_sel = 161;
                60: coeff_for_sel = -157;
                61: coeff_for_sel = -154;
                62: coeff_for_sel = 154;
                63: coeff_for_sel = 157;
                64: coeff_for_sel = 133;
                65: coeff_for_sel = 138;
                66: coeff_for_sel = -138;
                67: coeff_for_sel = -133;
                68: coeff_for_sel = 148;
                69: coeff_for_sel = 168;
                70: coeff_for_sel = -168;
                71: coeff_for_sel = -148;
                72: coeff_for_sel = 127;
                73: coeff_for_sel = 126;
                74: coeff_for_sel = -126;
                75: coeff_for_sel = -127;
                76: coeff_for_sel = 131;
                77: coeff_for_sel = 134;
                78: coeff_for_sel = -134;
                79: coeff_for_sel = -131;
                80: coeff_for_sel = 37;
                81: coeff_for_sel = 42;
                82: coeff_for_sel = -42;
                83: coeff_for_sel = -37;
                84: coeff_for_sel = 52;
                85: coeff_for_sel = 72;
                86: coeff_for_sel = -72;
                87: coeff_for_sel = -52;
                88: coeff_for_sel = 31;
                89: coeff_for_sel = 30;
                90: coeff_for_sel = -30;
                91: coeff_for_sel = -31;
                92: coeff_for_sel = 35;
                93: coeff_for_sel = 38;
                94: coeff_for_sel = -38;
                95: coeff_for_sel = -35;
                96: coeff_for_sel = 5;
                97: coeff_for_sel = 10;
                98: coeff_for_sel = -10;
                99: coeff_for_sel = -5;
                100: coeff_for_sel = 20;
                101: coeff_for_sel = 40;
                102: coeff_for_sel = -40;
                103: coeff_for_sel = -20;
                104: coeff_for_sel = -1;
                105: coeff_for_sel = -2;
                106: coeff_for_sel = 2;
                107: coeff_for_sel = 1;
                108: coeff_for_sel = 3;
                109: coeff_for_sel = 6;
                110: coeff_for_sel = -6;
                111: coeff_for_sel = -3;
                112: coeff_for_sel = -91;
                113: coeff_for_sel = -86;
                114: coeff_for_sel = 86;
                115: coeff_for_sel = 91;
                116: coeff_for_sel = -76;
                117: coeff_for_sel = -56;
                118: coeff_for_sel = 56;
                119: coeff_for_sel = 76;
                120: coeff_for_sel = -97;
                121: coeff_for_sel = -98;
                122: coeff_for_sel = 98;
                123: coeff_for_sel = 97;
                124: coeff_for_sel = -93;
                125: coeff_for_sel = -90;
                126: coeff_for_sel = 90;
                127: coeff_for_sel = 93;
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
