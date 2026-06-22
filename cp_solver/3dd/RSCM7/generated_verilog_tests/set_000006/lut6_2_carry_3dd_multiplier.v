`timescale 1ns/1ps

module lut6_2_carry_3dd_multiplier (
    input wire signed [6:0] x,
    input wire [6:0] sel,
    output wire signed [14:0] y
);
    localparam integer INPUT_BW = 7;
    localparam integer COEFF_BW = 9;
    localparam integer LEFT_Y_BW = 10;
    localparam integer RIGHT_Y_BW = 11;
    localparam integer OUTPUT_BW = 15;
    localparam integer LEFT_ADD1_SEL_BITS = 3;
    localparam integer RIGHT_ADD1_SEL_BITS = 2;
    localparam integer ADD3_SEL_BITS = 2;
    localparam integer N_COEFFS = 128;
    // requested coeffs sorted = [-176, -164, -152, -146, -144, -140, -134, -132, -130, -129, -126, -125, -124, -122, -120, -119, -116, -114, -110, -108, -104, -102, -98, -97, -94, -93, -92, -90, -87, -84, -80, -78, -72, -68, -56, -50, -48, -44, -38, -36, -34, -33, -30, -29, -28, -26, -24, -23, -20, -18, -16, -14, -12, -8, -6, -4, -2, -1, 2, 3, 4, 6, 8, 9, 12, 14, 16, 18, 20, 24, 26, 28, 30, 31, 34, 35, 36, 38, 40, 41, 44, 46, 50, 52, 56, 58, 62, 63, 66, 67, 68, 70, 73, 76, 80, 82, 88, 92, 104, 110, 112, 116, 122, 124, 126, 127, 130, 131, 132, 134, 136, 137, 140, 142, 146, 148, 152, 154, 158, 159, 162, 163, 164, 166, 169, 172, 178, 184]
    // selector coeffs        = [41, 50, -4, 14, 44, 56, -16, 8, 31, 30, 36, 34, 35, 38, 20, 26, 73, 82, 28, 46, 76, 88, 16, 40, 63, 62, 68, 66, 67, 70, 52, 58, 137, 146, 92, 110, 140, 152, 80, 104, 127, 126, 132, 130, 131, 134, 116, 122, 169, 178, 124, 142, 172, 184, 112, 136, 159, 158, 164, 162, 163, 166, 148, 154, -119, -110, -164, -146, -116, -104, -176, -152, -129, -130, -124, -126, -125, -122, -140, -134, -87, -78, -132, -114, -84, -72, -144, -120, -97, -98, -92, -94, -93, -90, -108, -102, -23, -14, -68, -50, -20, -8, -80, -56, -33, -34, -28, -30, -29, -26, -44, -38, 9, 18, -36, -18, 12, 24, -48, -24, -1, -2, 4, 2, 3, 6, -12, -6]
    // left add1 coeffs       = [1, 2, 4, 5, -4, -3, -1, 0]
    // right add1 coeffs      = [9, 12, -1, 3]

    localparam [63:0] LUT_I0 = 64'hAAAAAAAAAAAAAAAA;
    localparam [63:0] LUT_I1 = 64'hCCCCCCCCCCCCCCCC;
    localparam [63:0] LUT_I2 = 64'hF0F0F0F0F0F0F0F0;
    localparam [63:0] LUT_I3 = 64'hFF00FF00FF00FF00;
    localparam [63:0] LUT_I4 = 64'hFFFF0000FFFF0000;
    localparam [63:0] LUT_I5 = 64'hFFFFFFFF00000000;

    wire [1:0] add3_sel = sel[1:0];
    wire [1:0] right_sel = sel[3:2];
    wire [2:0] left_sel = sel[6:4];
    wire signed [9:0] left_y;
    wire signed [10:0] right_y;

    // left_add1: rows reordered for op select bit: false
    // left_add1: pack mode: lut-di
    // left_add1: correction carry-in is left_sel[2]
    wire [11:0] left_add1_s;
    wire [11:0] left_add1_di;
    wire [11:0] left_add1_o;
    wire [11:0] left_add1_co;
    wire left_add1_carry_init = left_sel[2];

    localparam [63:0] LEFT_ADD1_SEL_ROW_0 =
        (~LUT_I0) & (~LUT_I1) & (~LUT_I2);
    localparam [63:0] LEFT_ADD1_SEL_ROW_1 =
        (LUT_I0) & (~LUT_I1) & (~LUT_I2);
    localparam [63:0] LEFT_ADD1_SEL_ROW_2 =
        (~LUT_I0) & (LUT_I1) & (~LUT_I2);
    localparam [63:0] LEFT_ADD1_SEL_ROW_3 =
        (LUT_I0) & (LUT_I1) & (~LUT_I2);
    localparam [63:0] LEFT_ADD1_SEL_ROW_4 =
        (~LUT_I0) & (~LUT_I1) & (LUT_I2);
    localparam [63:0] LEFT_ADD1_SEL_ROW_5 =
        (LUT_I0) & (~LUT_I1) & (LUT_I2);
    localparam [63:0] LEFT_ADD1_SEL_ROW_6 =
        (~LUT_I0) & (LUT_I1) & (LUT_I2);
    localparam [63:0] LEFT_ADD1_SEL_ROW_7 =
        (LUT_I0) & (LUT_I1) & (LUT_I2);

    localparam [63:0] LEFT_ADD1_BIT_0_S_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3 ^ LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I4 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4 ^ ~LUT_I4));
    localparam [63:0] LEFT_ADD1_BIT_0_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4));
    localparam [63:0] LEFT_ADD1_BIT_0_INIT =
        ((~LUT_I5) & LEFT_ADD1_BIT_0_DI_INIT) | (LUT_I5 & LEFT_ADD1_BIT_0_S_INIT);

    LUT6_2 #(
        .INIT(LEFT_ADD1_BIT_0_INIT)
    ) left_add1_lut_bit_0 (
        .O6(left_add1_s[0]),
        .O5(left_add1_di[0]),
        .I0(left_sel[0]),
        .I1(left_sel[1]),
        .I2(left_sel[2]),
        .I3(x[0]),
        .I4(1'b0),
        .I5(1'b1)
    );

    localparam [63:0] LEFT_ADD1_BIT_1_S_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3 ^ LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I4 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4 ^ ~LUT_I4));
    localparam [63:0] LEFT_ADD1_BIT_1_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4));
    localparam [63:0] LEFT_ADD1_BIT_1_INIT =
        ((~LUT_I5) & LEFT_ADD1_BIT_1_DI_INIT) | (LUT_I5 & LEFT_ADD1_BIT_1_S_INIT);

    LUT6_2 #(
        .INIT(LEFT_ADD1_BIT_1_INIT)
    ) left_add1_lut_bit_1 (
        .O6(left_add1_s[1]),
        .O5(left_add1_di[1]),
        .I0(left_sel[0]),
        .I1(left_sel[1]),
        .I2(left_sel[2]),
        .I3(x[1]),
        .I4(1'b0),
        .I5(1'b1)
    );

    localparam [63:0] LEFT_ADD1_BIT_2_S_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3 ^ LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I4 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4 ^ ~LUT_I4));
    localparam [63:0] LEFT_ADD1_BIT_2_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4));
    localparam [63:0] LEFT_ADD1_BIT_2_INIT =
        ((~LUT_I5) & LEFT_ADD1_BIT_2_DI_INIT) | (LUT_I5 & LEFT_ADD1_BIT_2_S_INIT);

    LUT6_2 #(
        .INIT(LEFT_ADD1_BIT_2_INIT)
    ) left_add1_lut_bit_2 (
        .O6(left_add1_s[2]),
        .O5(left_add1_di[2]),
        .I0(left_sel[0]),
        .I1(left_sel[1]),
        .I2(left_sel[2]),
        .I3(x[2]),
        .I4(x[0]),
        .I5(1'b1)
    );

    localparam [63:0] LEFT_ADD1_BIT_3_S_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3 ^ LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I4 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4 ^ ~LUT_I4));
    localparam [63:0] LEFT_ADD1_BIT_3_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4));
    localparam [63:0] LEFT_ADD1_BIT_3_INIT =
        ((~LUT_I5) & LEFT_ADD1_BIT_3_DI_INIT) | (LUT_I5 & LEFT_ADD1_BIT_3_S_INIT);

    LUT6_2 #(
        .INIT(LEFT_ADD1_BIT_3_INIT)
    ) left_add1_lut_bit_3 (
        .O6(left_add1_s[3]),
        .O5(left_add1_di[3]),
        .I0(left_sel[0]),
        .I1(left_sel[1]),
        .I2(left_sel[2]),
        .I3(x[3]),
        .I4(x[1]),
        .I5(1'b1)
    );

    localparam [63:0] LEFT_ADD1_BIT_4_S_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3 ^ LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I4 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4 ^ ~LUT_I4));
    localparam [63:0] LEFT_ADD1_BIT_4_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4));
    localparam [63:0] LEFT_ADD1_BIT_4_INIT =
        ((~LUT_I5) & LEFT_ADD1_BIT_4_DI_INIT) | (LUT_I5 & LEFT_ADD1_BIT_4_S_INIT);

    LUT6_2 #(
        .INIT(LEFT_ADD1_BIT_4_INIT)
    ) left_add1_lut_bit_4 (
        .O6(left_add1_s[4]),
        .O5(left_add1_di[4]),
        .I0(left_sel[0]),
        .I1(left_sel[1]),
        .I2(left_sel[2]),
        .I3(x[4]),
        .I4(x[2]),
        .I5(1'b1)
    );

    localparam [63:0] LEFT_ADD1_BIT_5_S_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3 ^ LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I4 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4 ^ ~LUT_I4));
    localparam [63:0] LEFT_ADD1_BIT_5_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4));
    localparam [63:0] LEFT_ADD1_BIT_5_INIT =
        ((~LUT_I5) & LEFT_ADD1_BIT_5_DI_INIT) | (LUT_I5 & LEFT_ADD1_BIT_5_S_INIT);

    LUT6_2 #(
        .INIT(LEFT_ADD1_BIT_5_INIT)
    ) left_add1_lut_bit_5 (
        .O6(left_add1_s[5]),
        .O5(left_add1_di[5]),
        .I0(left_sel[0]),
        .I1(left_sel[1]),
        .I2(left_sel[2]),
        .I3(x[5]),
        .I4(x[3]),
        .I5(1'b1)
    );

    localparam [63:0] LEFT_ADD1_BIT_6_S_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3 ^ LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I4 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4 ^ ~LUT_I4));
    localparam [63:0] LEFT_ADD1_BIT_6_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4));
    localparam [63:0] LEFT_ADD1_BIT_6_INIT =
        ((~LUT_I5) & LEFT_ADD1_BIT_6_DI_INIT) | (LUT_I5 & LEFT_ADD1_BIT_6_S_INIT);

    LUT6_2 #(
        .INIT(LEFT_ADD1_BIT_6_INIT)
    ) left_add1_lut_bit_6 (
        .O6(left_add1_s[6]),
        .O5(left_add1_di[6]),
        .I0(left_sel[0]),
        .I1(left_sel[1]),
        .I2(left_sel[2]),
        .I3(x[6]),
        .I4(x[4]),
        .I5(1'b1)
    );

    localparam [63:0] LEFT_ADD1_BIT_7_S_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3 ^ LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I4 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4 ^ ~LUT_I4));
    localparam [63:0] LEFT_ADD1_BIT_7_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4));
    localparam [63:0] LEFT_ADD1_BIT_7_INIT =
        ((~LUT_I5) & LEFT_ADD1_BIT_7_DI_INIT) | (LUT_I5 & LEFT_ADD1_BIT_7_S_INIT);

    LUT6_2 #(
        .INIT(LEFT_ADD1_BIT_7_INIT)
    ) left_add1_lut_bit_7 (
        .O6(left_add1_s[7]),
        .O5(left_add1_di[7]),
        .I0(left_sel[0]),
        .I1(left_sel[1]),
        .I2(left_sel[2]),
        .I3(x[6]),
        .I4(x[5]),
        .I5(1'b1)
    );

    localparam [63:0] LEFT_ADD1_BIT_8_S_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3 ^ LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I4 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4 ^ ~LUT_I4));
    localparam [63:0] LEFT_ADD1_BIT_8_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4));
    localparam [63:0] LEFT_ADD1_BIT_8_INIT =
        ((~LUT_I5) & LEFT_ADD1_BIT_8_DI_INIT) | (LUT_I5 & LEFT_ADD1_BIT_8_S_INIT);

    LUT6_2 #(
        .INIT(LEFT_ADD1_BIT_8_INIT)
    ) left_add1_lut_bit_8 (
        .O6(left_add1_s[8]),
        .O5(left_add1_di[8]),
        .I0(left_sel[0]),
        .I1(left_sel[1]),
        .I2(left_sel[2]),
        .I3(x[6]),
        .I4(x[6]),
        .I5(1'b1)
    );

    localparam [63:0] LEFT_ADD1_BIT_9_S_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3 ^ LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I4 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4 ^ ~LUT_I4));
    localparam [63:0] LEFT_ADD1_BIT_9_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4));
    localparam [63:0] LEFT_ADD1_BIT_9_INIT =
        ((~LUT_I5) & LEFT_ADD1_BIT_9_DI_INIT) | (LUT_I5 & LEFT_ADD1_BIT_9_S_INIT);

    LUT6_2 #(
        .INIT(LEFT_ADD1_BIT_9_INIT)
    ) left_add1_lut_bit_9 (
        .O6(left_add1_s[9]),
        .O5(left_add1_di[9]),
        .I0(left_sel[0]),
        .I1(left_sel[1]),
        .I2(left_sel[2]),
        .I3(x[6]),
        .I4(x[6]),
        .I5(1'b1)
    );

    assign left_add1_s[10] = 1'b0;
    assign left_add1_di[10] = 1'b0;
    assign left_add1_s[11] = 1'b0;
    assign left_add1_di[11] = 1'b0;

    CARRY4 left_add1_carry_0 (
        .CO(left_add1_co[3:0]),
        .O(left_add1_o[3:0]),
        .CI(1'b0),
        .CYINIT(left_add1_carry_init),
        .DI(left_add1_di[3:0]),
        .S(left_add1_s[3:0])
    );

    CARRY4 left_add1_carry_1 (
        .CO(left_add1_co[7:4]),
        .O(left_add1_o[7:4]),
        .CI(left_add1_co[3]),
        .CYINIT(1'b0),
        .DI(left_add1_di[7:4]),
        .S(left_add1_s[7:4])
    );

    CARRY4 left_add1_carry_2 (
        .CO(left_add1_co[11:8]),
        .O(left_add1_o[11:8]),
        .CI(left_add1_co[7]),
        .CYINIT(1'b0),
        .DI(left_add1_di[11:8]),
        .S(left_add1_s[11:8])
    );

    assign left_y = left_add1_o[9:0];

    // right_add1: rows reordered for op select bit: false
    // right_add1: pack mode: lut-di
    // right_add1: correction carry-in is right_sel[1]
    wire [11:0] right_add1_s;
    wire [11:0] right_add1_di;
    wire [11:0] right_add1_o;
    wire [11:0] right_add1_co;
    wire right_add1_carry_init = right_sel[1];

    localparam [63:0] RIGHT_ADD1_SEL_ROW_0 =
        (~LUT_I0) & (~LUT_I1);
    localparam [63:0] RIGHT_ADD1_SEL_ROW_1 =
        (LUT_I0) & (~LUT_I1);
    localparam [63:0] RIGHT_ADD1_SEL_ROW_2 =
        (~LUT_I0) & (LUT_I1);
    localparam [63:0] RIGHT_ADD1_SEL_ROW_3 =
        (LUT_I0) & (LUT_I1);

    localparam [63:0] RIGHT_ADD1_BIT_0_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I4 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4 ^ LUT_I3)) |
        (RIGHT_ADD1_SEL_ROW_2 & (~LUT_I2 ^ 64'h0000000000000000)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I2));
    localparam [63:0] RIGHT_ADD1_BIT_0_DI_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (~LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] RIGHT_ADD1_BIT_0_INIT =
        ((~LUT_I5) & RIGHT_ADD1_BIT_0_DI_INIT) | (LUT_I5 & RIGHT_ADD1_BIT_0_S_INIT);

    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_0_INIT)
    ) right_add1_lut_bit_0 (
        .O6(right_add1_s[0]),
        .O5(right_add1_di[0]),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[0]),
        .I3(1'b0),
        .I4(1'b0),
        .I5(1'b1)
    );

    localparam [63:0] RIGHT_ADD1_BIT_1_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I4 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4 ^ LUT_I3)) |
        (RIGHT_ADD1_SEL_ROW_2 & (~LUT_I2 ^ 64'h0000000000000000)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I2));
    localparam [63:0] RIGHT_ADD1_BIT_1_DI_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (~LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] RIGHT_ADD1_BIT_1_INIT =
        ((~LUT_I5) & RIGHT_ADD1_BIT_1_DI_INIT) | (LUT_I5 & RIGHT_ADD1_BIT_1_S_INIT);

    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_1_INIT)
    ) right_add1_lut_bit_1 (
        .O6(right_add1_s[1]),
        .O5(right_add1_di[1]),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[1]),
        .I3(1'b0),
        .I4(1'b0),
        .I5(1'b1)
    );

    localparam [63:0] RIGHT_ADD1_BIT_2_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I4 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4 ^ LUT_I3)) |
        (RIGHT_ADD1_SEL_ROW_2 & (~LUT_I2 ^ 64'h0000000000000000)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I2));
    localparam [63:0] RIGHT_ADD1_BIT_2_DI_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (~LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] RIGHT_ADD1_BIT_2_INIT =
        ((~LUT_I5) & RIGHT_ADD1_BIT_2_DI_INIT) | (LUT_I5 & RIGHT_ADD1_BIT_2_S_INIT);

    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_2_INIT)
    ) right_add1_lut_bit_2 (
        .O6(right_add1_s[2]),
        .O5(right_add1_di[2]),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[2]),
        .I3(x[0]),
        .I4(1'b0),
        .I5(1'b1)
    );

    localparam [63:0] RIGHT_ADD1_BIT_3_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I4 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4 ^ LUT_I3)) |
        (RIGHT_ADD1_SEL_ROW_2 & (~LUT_I2 ^ 64'h0000000000000000)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I2));
    localparam [63:0] RIGHT_ADD1_BIT_3_DI_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (~LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] RIGHT_ADD1_BIT_3_INIT =
        ((~LUT_I5) & RIGHT_ADD1_BIT_3_DI_INIT) | (LUT_I5 & RIGHT_ADD1_BIT_3_S_INIT);

    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_3_INIT)
    ) right_add1_lut_bit_3 (
        .O6(right_add1_s[3]),
        .O5(right_add1_di[3]),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[3]),
        .I3(x[1]),
        .I4(x[0]),
        .I5(1'b1)
    );

    localparam [63:0] RIGHT_ADD1_BIT_4_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I4 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4 ^ LUT_I3)) |
        (RIGHT_ADD1_SEL_ROW_2 & (~LUT_I2 ^ 64'h0000000000000000)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I2));
    localparam [63:0] RIGHT_ADD1_BIT_4_DI_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (~LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] RIGHT_ADD1_BIT_4_INIT =
        ((~LUT_I5) & RIGHT_ADD1_BIT_4_DI_INIT) | (LUT_I5 & RIGHT_ADD1_BIT_4_S_INIT);

    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_4_INIT)
    ) right_add1_lut_bit_4 (
        .O6(right_add1_s[4]),
        .O5(right_add1_di[4]),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[4]),
        .I3(x[2]),
        .I4(x[1]),
        .I5(1'b1)
    );

    localparam [63:0] RIGHT_ADD1_BIT_5_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I4 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4 ^ LUT_I3)) |
        (RIGHT_ADD1_SEL_ROW_2 & (~LUT_I2 ^ 64'h0000000000000000)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I2));
    localparam [63:0] RIGHT_ADD1_BIT_5_DI_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (~LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] RIGHT_ADD1_BIT_5_INIT =
        ((~LUT_I5) & RIGHT_ADD1_BIT_5_DI_INIT) | (LUT_I5 & RIGHT_ADD1_BIT_5_S_INIT);

    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_5_INIT)
    ) right_add1_lut_bit_5 (
        .O6(right_add1_s[5]),
        .O5(right_add1_di[5]),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[5]),
        .I3(x[3]),
        .I4(x[2]),
        .I5(1'b1)
    );

    localparam [63:0] RIGHT_ADD1_BIT_6_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I4 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4 ^ LUT_I3)) |
        (RIGHT_ADD1_SEL_ROW_2 & (~LUT_I2 ^ 64'h0000000000000000)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I2));
    localparam [63:0] RIGHT_ADD1_BIT_6_DI_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (~LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] RIGHT_ADD1_BIT_6_INIT =
        ((~LUT_I5) & RIGHT_ADD1_BIT_6_DI_INIT) | (LUT_I5 & RIGHT_ADD1_BIT_6_S_INIT);

    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_6_INIT)
    ) right_add1_lut_bit_6 (
        .O6(right_add1_s[6]),
        .O5(right_add1_di[6]),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[6]),
        .I3(x[4]),
        .I4(x[3]),
        .I5(1'b1)
    );

    localparam [63:0] RIGHT_ADD1_BIT_7_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I4 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4 ^ LUT_I3)) |
        (RIGHT_ADD1_SEL_ROW_2 & (~LUT_I2 ^ 64'h0000000000000000)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I2));
    localparam [63:0] RIGHT_ADD1_BIT_7_DI_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (~LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] RIGHT_ADD1_BIT_7_INIT =
        ((~LUT_I5) & RIGHT_ADD1_BIT_7_DI_INIT) | (LUT_I5 & RIGHT_ADD1_BIT_7_S_INIT);

    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_7_INIT)
    ) right_add1_lut_bit_7 (
        .O6(right_add1_s[7]),
        .O5(right_add1_di[7]),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[6]),
        .I3(x[5]),
        .I4(x[4]),
        .I5(1'b1)
    );

    localparam [63:0] RIGHT_ADD1_BIT_8_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I4 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4 ^ LUT_I3)) |
        (RIGHT_ADD1_SEL_ROW_2 & (~LUT_I2 ^ 64'h0000000000000000)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I2));
    localparam [63:0] RIGHT_ADD1_BIT_8_DI_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (~LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] RIGHT_ADD1_BIT_8_INIT =
        ((~LUT_I5) & RIGHT_ADD1_BIT_8_DI_INIT) | (LUT_I5 & RIGHT_ADD1_BIT_8_S_INIT);

    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_8_INIT)
    ) right_add1_lut_bit_8 (
        .O6(right_add1_s[8]),
        .O5(right_add1_di[8]),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[6]),
        .I3(x[6]),
        .I4(x[5]),
        .I5(1'b1)
    );

    localparam [63:0] RIGHT_ADD1_BIT_9_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I4 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4 ^ LUT_I3)) |
        (RIGHT_ADD1_SEL_ROW_2 & (~LUT_I2 ^ 64'h0000000000000000)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I2));
    localparam [63:0] RIGHT_ADD1_BIT_9_DI_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (~LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] RIGHT_ADD1_BIT_9_INIT =
        ((~LUT_I5) & RIGHT_ADD1_BIT_9_DI_INIT) | (LUT_I5 & RIGHT_ADD1_BIT_9_S_INIT);

    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_9_INIT)
    ) right_add1_lut_bit_9 (
        .O6(right_add1_s[9]),
        .O5(right_add1_di[9]),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[6]),
        .I3(x[6]),
        .I4(x[6]),
        .I5(1'b1)
    );

    localparam [63:0] RIGHT_ADD1_BIT_10_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I4 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4 ^ LUT_I3)) |
        (RIGHT_ADD1_SEL_ROW_2 & (~LUT_I2 ^ 64'h0000000000000000)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I2));
    localparam [63:0] RIGHT_ADD1_BIT_10_DI_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (~LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] RIGHT_ADD1_BIT_10_INIT =
        ((~LUT_I5) & RIGHT_ADD1_BIT_10_DI_INIT) | (LUT_I5 & RIGHT_ADD1_BIT_10_S_INIT);

    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_10_INIT)
    ) right_add1_lut_bit_10 (
        .O6(right_add1_s[10]),
        .O5(right_add1_di[10]),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[6]),
        .I3(x[6]),
        .I4(x[6]),
        .I5(1'b1)
    );

    assign right_add1_s[11] = 1'b0;
    assign right_add1_di[11] = 1'b0;

    CARRY4 right_add1_carry_0 (
        .CO(right_add1_co[3:0]),
        .O(right_add1_o[3:0]),
        .CI(1'b0),
        .CYINIT(right_add1_carry_init),
        .DI(right_add1_di[3:0]),
        .S(right_add1_s[3:0])
    );

    CARRY4 right_add1_carry_1 (
        .CO(right_add1_co[7:4]),
        .O(right_add1_o[7:4]),
        .CI(right_add1_co[3]),
        .CYINIT(1'b0),
        .DI(right_add1_di[7:4]),
        .S(right_add1_s[7:4])
    );

    CARRY4 right_add1_carry_2 (
        .CO(right_add1_co[11:8]),
        .O(right_add1_o[11:8]),
        .CI(right_add1_co[7]),
        .CYINIT(1'b0),
        .DI(right_add1_di[11:8]),
        .S(right_add1_s[11:8])
    );

    assign right_y = right_add1_o[10:0];

    // add3: rows reordered for op select bit: false
    // add3: pack mode: direct-left
    // add3: correction carry-in is add3_sel[1]
    wire [15:0] add3_s;
    wire [15:0] add3_di;
    wire [15:0] add3_o;
    wire [15:0] add3_co;
    wire add3_carry_init = add3_sel[1];

    localparam [63:0] ADD3_SEL_ROW_0 =
        (~LUT_I0) & (~LUT_I1);
    localparam [63:0] ADD3_SEL_ROW_1 =
        (LUT_I0) & (~LUT_I1);
    localparam [63:0] ADD3_SEL_ROW_2 =
        (~LUT_I0) & (LUT_I1);
    localparam [63:0] ADD3_SEL_ROW_3 =
        (LUT_I0) & (LUT_I1);

    localparam [63:0] ADD3_BIT_0_S_INIT =
        (ADD3_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I5)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_0_INIT =
        ADD3_BIT_0_S_INIT;

    wire add3_unused_o5_0;
    LUT6_2 #(
        .INIT(ADD3_BIT_0_INIT)
    ) add3_lut_bit_0 (
        .O6(add3_s[0]),
        .O5(add3_unused_o5_0),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(1'b0),
        .I3(right_y[0]),
        .I4(1'b0),
        .I5(1'b0)
    );
    assign add3_di[0] = 1'b0;

    localparam [63:0] ADD3_BIT_1_S_INIT =
        (ADD3_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I5)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_1_INIT =
        ADD3_BIT_1_S_INIT;

    wire add3_unused_o5_1;
    LUT6_2 #(
        .INIT(ADD3_BIT_1_INIT)
    ) add3_lut_bit_1 (
        .O6(add3_s[1]),
        .O5(add3_unused_o5_1),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(1'b0),
        .I3(right_y[1]),
        .I4(right_y[0]),
        .I5(1'b0)
    );
    assign add3_di[1] = 1'b0;

    localparam [63:0] ADD3_BIT_2_S_INIT =
        (ADD3_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I5)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_2_INIT =
        ADD3_BIT_2_S_INIT;

    wire add3_unused_o5_2;
    LUT6_2 #(
        .INIT(ADD3_BIT_2_INIT)
    ) add3_lut_bit_2 (
        .O6(add3_s[2]),
        .O5(add3_unused_o5_2),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(1'b0),
        .I3(right_y[2]),
        .I4(right_y[1]),
        .I5(right_y[0])
    );
    assign add3_di[2] = 1'b0;

    localparam [63:0] ADD3_BIT_3_S_INIT =
        (ADD3_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I5)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_3_INIT =
        ADD3_BIT_3_S_INIT;

    wire add3_unused_o5_3;
    LUT6_2 #(
        .INIT(ADD3_BIT_3_INIT)
    ) add3_lut_bit_3 (
        .O6(add3_s[3]),
        .O5(add3_unused_o5_3),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(1'b0),
        .I3(right_y[3]),
        .I4(right_y[2]),
        .I5(right_y[1])
    );
    assign add3_di[3] = 1'b0;

    localparam [63:0] ADD3_BIT_4_S_INIT =
        (ADD3_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I5)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_4_INIT =
        ADD3_BIT_4_S_INIT;

    wire add3_unused_o5_4;
    LUT6_2 #(
        .INIT(ADD3_BIT_4_INIT)
    ) add3_lut_bit_4 (
        .O6(add3_s[4]),
        .O5(add3_unused_o5_4),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(1'b0),
        .I3(right_y[4]),
        .I4(right_y[3]),
        .I5(right_y[2])
    );
    assign add3_di[4] = 1'b0;

    localparam [63:0] ADD3_BIT_5_S_INIT =
        (ADD3_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I5)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_5_INIT =
        ADD3_BIT_5_S_INIT;

    wire add3_unused_o5_5;
    LUT6_2 #(
        .INIT(ADD3_BIT_5_INIT)
    ) add3_lut_bit_5 (
        .O6(add3_s[5]),
        .O5(add3_unused_o5_5),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[0]),
        .I3(right_y[5]),
        .I4(right_y[4]),
        .I5(right_y[3])
    );
    assign add3_di[5] = left_y[0];

    localparam [63:0] ADD3_BIT_6_S_INIT =
        (ADD3_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I5)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_6_INIT =
        ADD3_BIT_6_S_INIT;

    wire add3_unused_o5_6;
    LUT6_2 #(
        .INIT(ADD3_BIT_6_INIT)
    ) add3_lut_bit_6 (
        .O6(add3_s[6]),
        .O5(add3_unused_o5_6),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[1]),
        .I3(right_y[6]),
        .I4(right_y[5]),
        .I5(right_y[4])
    );
    assign add3_di[6] = left_y[1];

    localparam [63:0] ADD3_BIT_7_S_INIT =
        (ADD3_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I5)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_7_INIT =
        ADD3_BIT_7_S_INIT;

    wire add3_unused_o5_7;
    LUT6_2 #(
        .INIT(ADD3_BIT_7_INIT)
    ) add3_lut_bit_7 (
        .O6(add3_s[7]),
        .O5(add3_unused_o5_7),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[2]),
        .I3(right_y[7]),
        .I4(right_y[6]),
        .I5(right_y[5])
    );
    assign add3_di[7] = left_y[2];

    localparam [63:0] ADD3_BIT_8_S_INIT =
        (ADD3_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I5)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_8_INIT =
        ADD3_BIT_8_S_INIT;

    wire add3_unused_o5_8;
    LUT6_2 #(
        .INIT(ADD3_BIT_8_INIT)
    ) add3_lut_bit_8 (
        .O6(add3_s[8]),
        .O5(add3_unused_o5_8),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[3]),
        .I3(right_y[8]),
        .I4(right_y[7]),
        .I5(right_y[6])
    );
    assign add3_di[8] = left_y[3];

    localparam [63:0] ADD3_BIT_9_S_INIT =
        (ADD3_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I5)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_9_INIT =
        ADD3_BIT_9_S_INIT;

    wire add3_unused_o5_9;
    LUT6_2 #(
        .INIT(ADD3_BIT_9_INIT)
    ) add3_lut_bit_9 (
        .O6(add3_s[9]),
        .O5(add3_unused_o5_9),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[4]),
        .I3(right_y[9]),
        .I4(right_y[8]),
        .I5(right_y[7])
    );
    assign add3_di[9] = left_y[4];

    localparam [63:0] ADD3_BIT_10_S_INIT =
        (ADD3_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I5)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_10_INIT =
        ADD3_BIT_10_S_INIT;

    wire add3_unused_o5_10;
    LUT6_2 #(
        .INIT(ADD3_BIT_10_INIT)
    ) add3_lut_bit_10 (
        .O6(add3_s[10]),
        .O5(add3_unused_o5_10),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[5]),
        .I3(right_y[10]),
        .I4(right_y[9]),
        .I5(right_y[8])
    );
    assign add3_di[10] = left_y[5];

    localparam [63:0] ADD3_BIT_11_S_INIT =
        (ADD3_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I5)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_11_INIT =
        ADD3_BIT_11_S_INIT;

    wire add3_unused_o5_11;
    LUT6_2 #(
        .INIT(ADD3_BIT_11_INIT)
    ) add3_lut_bit_11 (
        .O6(add3_s[11]),
        .O5(add3_unused_o5_11),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[6]),
        .I3(right_y[10]),
        .I4(right_y[10]),
        .I5(right_y[9])
    );
    assign add3_di[11] = left_y[6];

    localparam [63:0] ADD3_BIT_12_S_INIT =
        (ADD3_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I5)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_12_INIT =
        ADD3_BIT_12_S_INIT;

    wire add3_unused_o5_12;
    LUT6_2 #(
        .INIT(ADD3_BIT_12_INIT)
    ) add3_lut_bit_12 (
        .O6(add3_s[12]),
        .O5(add3_unused_o5_12),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[7]),
        .I3(right_y[10]),
        .I4(right_y[10]),
        .I5(right_y[10])
    );
    assign add3_di[12] = left_y[7];

    localparam [63:0] ADD3_BIT_13_S_INIT =
        (ADD3_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I5)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_13_INIT =
        ADD3_BIT_13_S_INIT;

    wire add3_unused_o5_13;
    LUT6_2 #(
        .INIT(ADD3_BIT_13_INIT)
    ) add3_lut_bit_13 (
        .O6(add3_s[13]),
        .O5(add3_unused_o5_13),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[8]),
        .I3(right_y[10]),
        .I4(right_y[10]),
        .I5(right_y[10])
    );
    assign add3_di[13] = left_y[8];

    localparam [63:0] ADD3_BIT_14_S_INIT =
        (ADD3_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I5)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_14_INIT =
        ADD3_BIT_14_S_INIT;

    wire add3_unused_o5_14;
    LUT6_2 #(
        .INIT(ADD3_BIT_14_INIT)
    ) add3_lut_bit_14 (
        .O6(add3_s[14]),
        .O5(add3_unused_o5_14),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[9]),
        .I3(right_y[10]),
        .I4(right_y[10]),
        .I5(right_y[10])
    );
    assign add3_di[14] = left_y[9];

    assign add3_s[15] = 1'b0;
    assign add3_di[15] = 1'b0;

    CARRY4 add3_carry_0 (
        .CO(add3_co[3:0]),
        .O(add3_o[3:0]),
        .CI(1'b0),
        .CYINIT(add3_carry_init),
        .DI(add3_di[3:0]),
        .S(add3_s[3:0])
    );

    CARRY4 add3_carry_1 (
        .CO(add3_co[7:4]),
        .O(add3_o[7:4]),
        .CI(add3_co[3]),
        .CYINIT(1'b0),
        .DI(add3_di[7:4]),
        .S(add3_s[7:4])
    );

    CARRY4 add3_carry_2 (
        .CO(add3_co[11:8]),
        .O(add3_o[11:8]),
        .CI(add3_co[7]),
        .CYINIT(1'b0),
        .DI(add3_di[11:8]),
        .S(add3_s[11:8])
    );

    CARRY4 add3_carry_3 (
        .CO(add3_co[15:12]),
        .O(add3_o[15:12]),
        .CI(add3_co[11]),
        .CYINIT(1'b0),
        .DI(add3_di[15:12]),
        .S(add3_s[15:12])
    );

    assign y = add3_o[14:0];

endmodule
