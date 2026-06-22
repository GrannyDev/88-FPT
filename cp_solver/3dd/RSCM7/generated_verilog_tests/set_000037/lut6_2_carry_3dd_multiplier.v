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
    // requested coeffs sorted = [-188, -174, -159, -158, -157, -156, -154, -150, -148, -142, -140, -138, -134, -131, -130, -129, -127, -126, -125, -124, -122, -118, -114, -110, -108, -100, -95, -94, -93, -92, -90, -86, -78, -76, -63, -62, -61, -60, -58, -54, -52, -46, -44, -42, -38, -35, -34, -33, -31, -30, -29, -28, -26, -22, -20, -18, -14, -12, -10, -6, -4, -3, -2, -1, 1, 2, 3, 4, 6, 10, 12, 14, 18, 20, 22, 26, 28, 29, 30, 31, 33, 34, 35, 38, 42, 44, 46, 52, 54, 58, 60, 61, 62, 63, 76, 78, 86, 90, 92, 93, 94, 95, 100, 108, 110, 114, 118, 122, 124, 125, 126, 127, 129, 130, 131, 134, 138, 140, 142, 148, 150, 154, 156, 157, 158, 159, 174, 188]
    // selector coeffs        = [-29, -26, 26, 29, -22, -12, 12, 22, -46, -60, 60, 46, -31, -30, 30, 31, -61, -58, 58, 61, -54, -44, 44, 54, -78, -92, 92, 78, -63, -62, 62, 63, -125, -122, 122, 125, -118, -108, 108, 118, -142, -156, 156, 142, -127, -126, 126, 127, -157, -154, 154, 157, -150, -140, 140, 150, -174, -188, 188, 174, -159, -158, 158, 159, 131, 134, -134, -131, 138, 148, -148, -138, 114, 100, -100, -114, 129, 130, -130, -129, 35, 38, -38, -35, 42, 52, -52, -42, 18, 4, -4, -18, 33, 34, -34, -33, 3, 6, -6, -3, 10, 20, -20, -10, -14, -28, 28, 14, 1, 2, -2, -1, -93, -90, 90, 93, -86, -76, 76, 86, -110, -124, 124, 110, -95, -94, 94, 95]
    // left add1 coeffs       = [1, 2, 4, 5, -4, -1, 0, 3]
    // right add1 coeffs      = [3, 10, -14, 1]

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
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4 ^ ~LUT_I3));
    localparam [63:0] LEFT_ADD1_BIT_0_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I3)) |
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
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4 ^ ~LUT_I3));
    localparam [63:0] LEFT_ADD1_BIT_1_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I3)) |
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
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4 ^ ~LUT_I3));
    localparam [63:0] LEFT_ADD1_BIT_2_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I3)) |
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
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4 ^ ~LUT_I3));
    localparam [63:0] LEFT_ADD1_BIT_3_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I3)) |
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
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4 ^ ~LUT_I3));
    localparam [63:0] LEFT_ADD1_BIT_4_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I3)) |
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
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4 ^ ~LUT_I3));
    localparam [63:0] LEFT_ADD1_BIT_5_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I3)) |
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
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4 ^ ~LUT_I3));
    localparam [63:0] LEFT_ADD1_BIT_6_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I3)) |
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
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4 ^ ~LUT_I3));
    localparam [63:0] LEFT_ADD1_BIT_7_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I3)) |
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
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4 ^ ~LUT_I3));
    localparam [63:0] LEFT_ADD1_BIT_8_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I3)) |
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
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I3 ^ 64'h0000000000000000)) |
        (LEFT_ADD1_SEL_ROW_6 & (~LUT_I3 ^ LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_7 & (LUT_I4 ^ ~LUT_I3));
    localparam [63:0] LEFT_ADD1_BIT_9_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_3 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_4 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_5 & (~LUT_I3)) |
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
    // right_add1: pack mode: direct-left
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
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I3 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I3 ^ LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I3 ^ ~LUT_I5)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I2));
    localparam [63:0] RIGHT_ADD1_BIT_0_INIT =
        RIGHT_ADD1_BIT_0_S_INIT;

    wire right_add1_unused_o5_0;
    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_0_INIT)
    ) right_add1_lut_bit_0 (
        .O6(right_add1_s[0]),
        .O5(right_add1_unused_o5_0),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[0]),
        .I3(1'b0),
        .I4(1'b0),
        .I5(1'b0)
    );
    assign right_add1_di[0] = 1'b0;

    localparam [63:0] RIGHT_ADD1_BIT_1_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I3 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I3 ^ LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I3 ^ ~LUT_I5)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I2));
    localparam [63:0] RIGHT_ADD1_BIT_1_INIT =
        RIGHT_ADD1_BIT_1_S_INIT;

    wire right_add1_unused_o5_1;
    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_1_INIT)
    ) right_add1_lut_bit_1 (
        .O6(right_add1_s[1]),
        .O5(right_add1_unused_o5_1),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[1]),
        .I3(x[0]),
        .I4(1'b0),
        .I5(1'b0)
    );
    assign right_add1_di[1] = x[0];

    localparam [63:0] RIGHT_ADD1_BIT_2_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I3 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I3 ^ LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I3 ^ ~LUT_I5)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I2));
    localparam [63:0] RIGHT_ADD1_BIT_2_INIT =
        RIGHT_ADD1_BIT_2_S_INIT;

    wire right_add1_unused_o5_2;
    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_2_INIT)
    ) right_add1_lut_bit_2 (
        .O6(right_add1_s[2]),
        .O5(right_add1_unused_o5_2),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[2]),
        .I3(x[1]),
        .I4(1'b0),
        .I5(1'b0)
    );
    assign right_add1_di[2] = x[1];

    localparam [63:0] RIGHT_ADD1_BIT_3_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I3 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I3 ^ LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I3 ^ ~LUT_I5)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I2));
    localparam [63:0] RIGHT_ADD1_BIT_3_INIT =
        RIGHT_ADD1_BIT_3_S_INIT;

    wire right_add1_unused_o5_3;
    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_3_INIT)
    ) right_add1_lut_bit_3 (
        .O6(right_add1_s[3]),
        .O5(right_add1_unused_o5_3),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[3]),
        .I3(x[2]),
        .I4(x[0]),
        .I5(1'b0)
    );
    assign right_add1_di[3] = x[2];

    localparam [63:0] RIGHT_ADD1_BIT_4_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I3 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I3 ^ LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I3 ^ ~LUT_I5)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I2));
    localparam [63:0] RIGHT_ADD1_BIT_4_INIT =
        RIGHT_ADD1_BIT_4_S_INIT;

    wire right_add1_unused_o5_4;
    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_4_INIT)
    ) right_add1_lut_bit_4 (
        .O6(right_add1_s[4]),
        .O5(right_add1_unused_o5_4),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[4]),
        .I3(x[3]),
        .I4(x[1]),
        .I5(x[0])
    );
    assign right_add1_di[4] = x[3];

    localparam [63:0] RIGHT_ADD1_BIT_5_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I3 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I3 ^ LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I3 ^ ~LUT_I5)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I2));
    localparam [63:0] RIGHT_ADD1_BIT_5_INIT =
        RIGHT_ADD1_BIT_5_S_INIT;

    wire right_add1_unused_o5_5;
    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_5_INIT)
    ) right_add1_lut_bit_5 (
        .O6(right_add1_s[5]),
        .O5(right_add1_unused_o5_5),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[5]),
        .I3(x[4]),
        .I4(x[2]),
        .I5(x[1])
    );
    assign right_add1_di[5] = x[4];

    localparam [63:0] RIGHT_ADD1_BIT_6_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I3 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I3 ^ LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I3 ^ ~LUT_I5)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I2));
    localparam [63:0] RIGHT_ADD1_BIT_6_INIT =
        RIGHT_ADD1_BIT_6_S_INIT;

    wire right_add1_unused_o5_6;
    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_6_INIT)
    ) right_add1_lut_bit_6 (
        .O6(right_add1_s[6]),
        .O5(right_add1_unused_o5_6),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[6]),
        .I3(x[5]),
        .I4(x[3]),
        .I5(x[2])
    );
    assign right_add1_di[6] = x[5];

    localparam [63:0] RIGHT_ADD1_BIT_7_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I3 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I3 ^ LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I3 ^ ~LUT_I5)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I2));
    localparam [63:0] RIGHT_ADD1_BIT_7_INIT =
        RIGHT_ADD1_BIT_7_S_INIT;

    wire right_add1_unused_o5_7;
    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_7_INIT)
    ) right_add1_lut_bit_7 (
        .O6(right_add1_s[7]),
        .O5(right_add1_unused_o5_7),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[6]),
        .I3(x[6]),
        .I4(x[4]),
        .I5(x[3])
    );
    assign right_add1_di[7] = x[6];

    localparam [63:0] RIGHT_ADD1_BIT_8_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I3 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I3 ^ LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I3 ^ ~LUT_I5)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I2));
    localparam [63:0] RIGHT_ADD1_BIT_8_INIT =
        RIGHT_ADD1_BIT_8_S_INIT;

    wire right_add1_unused_o5_8;
    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_8_INIT)
    ) right_add1_lut_bit_8 (
        .O6(right_add1_s[8]),
        .O5(right_add1_unused_o5_8),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[6]),
        .I3(x[6]),
        .I4(x[5]),
        .I5(x[4])
    );
    assign right_add1_di[8] = x[6];

    localparam [63:0] RIGHT_ADD1_BIT_9_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I3 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I3 ^ LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I3 ^ ~LUT_I5)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I2));
    localparam [63:0] RIGHT_ADD1_BIT_9_INIT =
        RIGHT_ADD1_BIT_9_S_INIT;

    wire right_add1_unused_o5_9;
    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_9_INIT)
    ) right_add1_lut_bit_9 (
        .O6(right_add1_s[9]),
        .O5(right_add1_unused_o5_9),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[6]),
        .I3(x[6]),
        .I4(x[6]),
        .I5(x[5])
    );
    assign right_add1_di[9] = x[6];

    localparam [63:0] RIGHT_ADD1_BIT_10_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I3 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I3 ^ LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I3 ^ ~LUT_I5)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I2));
    localparam [63:0] RIGHT_ADD1_BIT_10_INIT =
        RIGHT_ADD1_BIT_10_S_INIT;

    wire right_add1_unused_o5_10;
    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_10_INIT)
    ) right_add1_lut_bit_10 (
        .O6(right_add1_s[10]),
        .O5(right_add1_unused_o5_10),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[6]),
        .I3(x[6]),
        .I4(x[6]),
        .I5(x[6])
    );
    assign right_add1_di[10] = x[6];

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
    // add3: pack mode: lut-di
    // add3: correction carry-in is constant 1
    wire [15:0] add3_s;
    wire [15:0] add3_di;
    wire [15:0] add3_o;
    wire [15:0] add3_co;
    wire add3_carry_init = 1'b1;

    localparam [63:0] ADD3_SEL_ROW_0 =
        (~LUT_I0) & (~LUT_I1);
    localparam [63:0] ADD3_SEL_ROW_1 =
        (LUT_I0) & (~LUT_I1);
    localparam [63:0] ADD3_SEL_ROW_2 =
        (~LUT_I0) & (LUT_I1);
    localparam [63:0] ADD3_SEL_ROW_3 =
        (LUT_I0) & (LUT_I1);

    localparam [63:0] ADD3_BIT_0_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I3));
    localparam [63:0] ADD3_BIT_0_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD3_BIT_0_INIT =
        ((~LUT_I5) & ADD3_BIT_0_DI_INIT) | (LUT_I5 & ADD3_BIT_0_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_0_INIT)
    ) add3_lut_bit_0 (
        .O6(add3_s[0]),
        .O5(add3_di[0]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(1'b0),
        .I3(right_y[0]),
        .I4(1'b0),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_1_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I3));
    localparam [63:0] ADD3_BIT_1_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD3_BIT_1_INIT =
        ((~LUT_I5) & ADD3_BIT_1_DI_INIT) | (LUT_I5 & ADD3_BIT_1_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_1_INIT)
    ) add3_lut_bit_1 (
        .O6(add3_s[1]),
        .O5(add3_di[1]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(1'b0),
        .I3(right_y[1]),
        .I4(right_y[0]),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_2_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I3));
    localparam [63:0] ADD3_BIT_2_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD3_BIT_2_INIT =
        ((~LUT_I5) & ADD3_BIT_2_DI_INIT) | (LUT_I5 & ADD3_BIT_2_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_2_INIT)
    ) add3_lut_bit_2 (
        .O6(add3_s[2]),
        .O5(add3_di[2]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(1'b0),
        .I3(right_y[2]),
        .I4(right_y[1]),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_3_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I3));
    localparam [63:0] ADD3_BIT_3_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD3_BIT_3_INIT =
        ((~LUT_I5) & ADD3_BIT_3_DI_INIT) | (LUT_I5 & ADD3_BIT_3_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_3_INIT)
    ) add3_lut_bit_3 (
        .O6(add3_s[3]),
        .O5(add3_di[3]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(1'b0),
        .I3(right_y[3]),
        .I4(right_y[2]),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_4_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I3));
    localparam [63:0] ADD3_BIT_4_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD3_BIT_4_INIT =
        ((~LUT_I5) & ADD3_BIT_4_DI_INIT) | (LUT_I5 & ADD3_BIT_4_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_4_INIT)
    ) add3_lut_bit_4 (
        .O6(add3_s[4]),
        .O5(add3_di[4]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(1'b0),
        .I3(right_y[4]),
        .I4(right_y[3]),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_5_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I3));
    localparam [63:0] ADD3_BIT_5_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD3_BIT_5_INIT =
        ((~LUT_I5) & ADD3_BIT_5_DI_INIT) | (LUT_I5 & ADD3_BIT_5_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_5_INIT)
    ) add3_lut_bit_5 (
        .O6(add3_s[5]),
        .O5(add3_di[5]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[0]),
        .I3(right_y[5]),
        .I4(right_y[4]),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_6_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I3));
    localparam [63:0] ADD3_BIT_6_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD3_BIT_6_INIT =
        ((~LUT_I5) & ADD3_BIT_6_DI_INIT) | (LUT_I5 & ADD3_BIT_6_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_6_INIT)
    ) add3_lut_bit_6 (
        .O6(add3_s[6]),
        .O5(add3_di[6]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[1]),
        .I3(right_y[6]),
        .I4(right_y[5]),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_7_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I3));
    localparam [63:0] ADD3_BIT_7_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD3_BIT_7_INIT =
        ((~LUT_I5) & ADD3_BIT_7_DI_INIT) | (LUT_I5 & ADD3_BIT_7_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_7_INIT)
    ) add3_lut_bit_7 (
        .O6(add3_s[7]),
        .O5(add3_di[7]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[2]),
        .I3(right_y[7]),
        .I4(right_y[6]),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_8_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I3));
    localparam [63:0] ADD3_BIT_8_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD3_BIT_8_INIT =
        ((~LUT_I5) & ADD3_BIT_8_DI_INIT) | (LUT_I5 & ADD3_BIT_8_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_8_INIT)
    ) add3_lut_bit_8 (
        .O6(add3_s[8]),
        .O5(add3_di[8]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[3]),
        .I3(right_y[8]),
        .I4(right_y[7]),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_9_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I3));
    localparam [63:0] ADD3_BIT_9_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD3_BIT_9_INIT =
        ((~LUT_I5) & ADD3_BIT_9_DI_INIT) | (LUT_I5 & ADD3_BIT_9_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_9_INIT)
    ) add3_lut_bit_9 (
        .O6(add3_s[9]),
        .O5(add3_di[9]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[4]),
        .I3(right_y[9]),
        .I4(right_y[8]),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_10_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I3));
    localparam [63:0] ADD3_BIT_10_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD3_BIT_10_INIT =
        ((~LUT_I5) & ADD3_BIT_10_DI_INIT) | (LUT_I5 & ADD3_BIT_10_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_10_INIT)
    ) add3_lut_bit_10 (
        .O6(add3_s[10]),
        .O5(add3_di[10]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[5]),
        .I3(right_y[10]),
        .I4(right_y[9]),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_11_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I3));
    localparam [63:0] ADD3_BIT_11_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD3_BIT_11_INIT =
        ((~LUT_I5) & ADD3_BIT_11_DI_INIT) | (LUT_I5 & ADD3_BIT_11_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_11_INIT)
    ) add3_lut_bit_11 (
        .O6(add3_s[11]),
        .O5(add3_di[11]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[6]),
        .I3(right_y[10]),
        .I4(right_y[10]),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_12_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I3));
    localparam [63:0] ADD3_BIT_12_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD3_BIT_12_INIT =
        ((~LUT_I5) & ADD3_BIT_12_DI_INIT) | (LUT_I5 & ADD3_BIT_12_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_12_INIT)
    ) add3_lut_bit_12 (
        .O6(add3_s[12]),
        .O5(add3_di[12]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[7]),
        .I3(right_y[10]),
        .I4(right_y[10]),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_13_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I3));
    localparam [63:0] ADD3_BIT_13_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD3_BIT_13_INIT =
        ((~LUT_I5) & ADD3_BIT_13_DI_INIT) | (LUT_I5 & ADD3_BIT_13_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_13_INIT)
    ) add3_lut_bit_13 (
        .O6(add3_s[13]),
        .O5(add3_di[13]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[8]),
        .I3(right_y[10]),
        .I4(right_y[10]),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_14_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2 ^ LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I3));
    localparam [63:0] ADD3_BIT_14_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I2)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD3_BIT_14_INIT =
        ((~LUT_I5) & ADD3_BIT_14_DI_INIT) | (LUT_I5 & ADD3_BIT_14_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_14_INIT)
    ) add3_lut_bit_14 (
        .O6(add3_s[14]),
        .O5(add3_di[14]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[9]),
        .I3(right_y[10]),
        .I4(right_y[10]),
        .I5(1'b1)
    );

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
