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
                4: coeff_for_sel = -22;
                5: coeff_for_sel = -12;
                6: coeff_for_sel = 12;
                7: coeff_for_sel = 22;
                8: coeff_for_sel = -31;
                9: coeff_for_sel = -30;
                10: coeff_for_sel = 30;
                11: coeff_for_sel = 31;
                12: coeff_for_sel = -25;
                13: coeff_for_sel = -18;
                14: coeff_for_sel = 18;
                15: coeff_for_sel = 25;
                16: coeff_for_sel = -60;
                17: coeff_for_sel = -56;
                18: coeff_for_sel = 56;
                19: coeff_for_sel = 60;
                20: coeff_for_sel = -54;
                21: coeff_for_sel = -44;
                22: coeff_for_sel = 44;
                23: coeff_for_sel = 54;
                24: coeff_for_sel = -63;
                25: coeff_for_sel = -62;
                26: coeff_for_sel = 62;
                27: coeff_for_sel = 63;
                28: coeff_for_sel = -57;
                29: coeff_for_sel = -50;
                30: coeff_for_sel = 50;
                31: coeff_for_sel = 57;
                32: coeff_for_sel = -124;
                33: coeff_for_sel = -120;
                34: coeff_for_sel = 120;
                35: coeff_for_sel = 124;
                36: coeff_for_sel = -118;
                37: coeff_for_sel = -108;
                38: coeff_for_sel = 108;
                39: coeff_for_sel = 118;
                40: coeff_for_sel = -127;
                41: coeff_for_sel = -126;
                42: coeff_for_sel = 126;
                43: coeff_for_sel = 127;
                44: coeff_for_sel = -121;
                45: coeff_for_sel = -114;
                46: coeff_for_sel = 114;
                47: coeff_for_sel = 121;
                48: coeff_for_sel = -156;
                49: coeff_for_sel = -152;
                50: coeff_for_sel = 152;
                51: coeff_for_sel = 156;
                52: coeff_for_sel = -150;
                53: coeff_for_sel = -140;
                54: coeff_for_sel = 140;
                55: coeff_for_sel = 150;
                56: coeff_for_sel = -159;
                57: coeff_for_sel = -158;
                58: coeff_for_sel = 158;
                59: coeff_for_sel = 159;
                60: coeff_for_sel = -153;
                61: coeff_for_sel = -146;
                62: coeff_for_sel = 146;
                63: coeff_for_sel = 153;
                64: coeff_for_sel = 100;
                65: coeff_for_sel = 104;
                66: coeff_for_sel = -104;
                67: coeff_for_sel = -100;
                68: coeff_for_sel = 106;
                69: coeff_for_sel = 116;
                70: coeff_for_sel = -116;
                71: coeff_for_sel = -106;
                72: coeff_for_sel = 97;
                73: coeff_for_sel = 98;
                74: coeff_for_sel = -98;
                75: coeff_for_sel = -97;
                76: coeff_for_sel = 103;
                77: coeff_for_sel = 110;
                78: coeff_for_sel = -110;
                79: coeff_for_sel = -103;
                80: coeff_for_sel = 36;
                81: coeff_for_sel = 40;
                82: coeff_for_sel = -40;
                83: coeff_for_sel = -36;
                84: coeff_for_sel = 42;
                85: coeff_for_sel = 52;
                86: coeff_for_sel = -52;
                87: coeff_for_sel = -42;
                88: coeff_for_sel = 33;
                89: coeff_for_sel = 34;
                90: coeff_for_sel = -34;
                91: coeff_for_sel = -33;
                92: coeff_for_sel = 39;
                93: coeff_for_sel = 46;
                94: coeff_for_sel = -46;
                95: coeff_for_sel = -39;
                96: coeff_for_sel = 4;
                97: coeff_for_sel = 8;
                98: coeff_for_sel = -8;
                99: coeff_for_sel = -4;
                100: coeff_for_sel = 10;
                101: coeff_for_sel = 20;
                102: coeff_for_sel = -20;
                103: coeff_for_sel = -10;
                104: coeff_for_sel = 1;
                105: coeff_for_sel = 2;
                106: coeff_for_sel = -2;
                107: coeff_for_sel = -1;
                108: coeff_for_sel = 7;
                109: coeff_for_sel = 14;
                110: coeff_for_sel = -14;
                111: coeff_for_sel = -7;
                112: coeff_for_sel = -92;
                113: coeff_for_sel = -88;
                114: coeff_for_sel = 88;
                115: coeff_for_sel = 92;
                116: coeff_for_sel = -86;
                117: coeff_for_sel = -76;
                118: coeff_for_sel = 76;
                119: coeff_for_sel = 86;
                120: coeff_for_sel = -95;
                121: coeff_for_sel = -94;
                122: coeff_for_sel = 94;
                123: coeff_for_sel = 95;
                124: coeff_for_sel = -89;
                125: coeff_for_sel = -82;
                126: coeff_for_sel = 82;
                127: coeff_for_sel = 89;
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
