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
                4: coeff_for_sel = -20;
                5: coeff_for_sel = -8;
                6: coeff_for_sel = 8;
                7: coeff_for_sel = 20;
                8: coeff_for_sel = -35;
                9: coeff_for_sel = -38;
                10: coeff_for_sel = 38;
                11: coeff_for_sel = 35;
                12: coeff_for_sel = -25;
                13: coeff_for_sel = -18;
                14: coeff_for_sel = 18;
                15: coeff_for_sel = 25;
                16: coeff_for_sel = -63;
                17: coeff_for_sel = -62;
                18: coeff_for_sel = 62;
                19: coeff_for_sel = 63;
                20: coeff_for_sel = -52;
                21: coeff_for_sel = -40;
                22: coeff_for_sel = 40;
                23: coeff_for_sel = 52;
                24: coeff_for_sel = -67;
                25: coeff_for_sel = -70;
                26: coeff_for_sel = 70;
                27: coeff_for_sel = 67;
                28: coeff_for_sel = -57;
                29: coeff_for_sel = -50;
                30: coeff_for_sel = 50;
                31: coeff_for_sel = 57;
                32: coeff_for_sel = -127;
                33: coeff_for_sel = -126;
                34: coeff_for_sel = 126;
                35: coeff_for_sel = 127;
                36: coeff_for_sel = -116;
                37: coeff_for_sel = -104;
                38: coeff_for_sel = 104;
                39: coeff_for_sel = 116;
                40: coeff_for_sel = -131;
                41: coeff_for_sel = -134;
                42: coeff_for_sel = 134;
                43: coeff_for_sel = 131;
                44: coeff_for_sel = -121;
                45: coeff_for_sel = -114;
                46: coeff_for_sel = 114;
                47: coeff_for_sel = 121;
                48: coeff_for_sel = -159;
                49: coeff_for_sel = -158;
                50: coeff_for_sel = 158;
                51: coeff_for_sel = 159;
                52: coeff_for_sel = -148;
                53: coeff_for_sel = -136;
                54: coeff_for_sel = 136;
                55: coeff_for_sel = 148;
                56: coeff_for_sel = -163;
                57: coeff_for_sel = -166;
                58: coeff_for_sel = 166;
                59: coeff_for_sel = 163;
                60: coeff_for_sel = -153;
                61: coeff_for_sel = -146;
                62: coeff_for_sel = 146;
                63: coeff_for_sel = 153;
                64: coeff_for_sel = 97;
                65: coeff_for_sel = 98;
                66: coeff_for_sel = -98;
                67: coeff_for_sel = -97;
                68: coeff_for_sel = 108;
                69: coeff_for_sel = 120;
                70: coeff_for_sel = -120;
                71: coeff_for_sel = -108;
                72: coeff_for_sel = 93;
                73: coeff_for_sel = 90;
                74: coeff_for_sel = -90;
                75: coeff_for_sel = -93;
                76: coeff_for_sel = 103;
                77: coeff_for_sel = 110;
                78: coeff_for_sel = -110;
                79: coeff_for_sel = -103;
                80: coeff_for_sel = 33;
                81: coeff_for_sel = 34;
                82: coeff_for_sel = -34;
                83: coeff_for_sel = -33;
                84: coeff_for_sel = 44;
                85: coeff_for_sel = 56;
                86: coeff_for_sel = -56;
                87: coeff_for_sel = -44;
                88: coeff_for_sel = 29;
                89: coeff_for_sel = 26;
                90: coeff_for_sel = -26;
                91: coeff_for_sel = -29;
                92: coeff_for_sel = 39;
                93: coeff_for_sel = 46;
                94: coeff_for_sel = -46;
                95: coeff_for_sel = -39;
                96: coeff_for_sel = 1;
                97: coeff_for_sel = 2;
                98: coeff_for_sel = -2;
                99: coeff_for_sel = -1;
                100: coeff_for_sel = 12;
                101: coeff_for_sel = 24;
                102: coeff_for_sel = -24;
                103: coeff_for_sel = -12;
                104: coeff_for_sel = -3;
                105: coeff_for_sel = -6;
                106: coeff_for_sel = 6;
                107: coeff_for_sel = 3;
                108: coeff_for_sel = 7;
                109: coeff_for_sel = 14;
                110: coeff_for_sel = -14;
                111: coeff_for_sel = -7;
                112: coeff_for_sel = -95;
                113: coeff_for_sel = -94;
                114: coeff_for_sel = 94;
                115: coeff_for_sel = 95;
                116: coeff_for_sel = -84;
                117: coeff_for_sel = -72;
                118: coeff_for_sel = 72;
                119: coeff_for_sel = 84;
                120: coeff_for_sel = -99;
                121: coeff_for_sel = -102;
                122: coeff_for_sel = 102;
                123: coeff_for_sel = 99;
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
