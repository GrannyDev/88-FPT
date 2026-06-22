`timescale 1ns/1ps

module lut6_2_carry_3dd_multiplier (
    input wire signed [5:0] x,
    input wire [5:0] sel,
    output wire signed [11:0] y
);
    localparam integer INPUT_BW = 6;
    localparam integer COEFF_BW = 7;
    localparam integer LEFT_Y_BW = 9;
    localparam integer RIGHT_Y_BW = 9;
    localparam integer OUTPUT_BW = 12;
    localparam integer LEFT_ADD1_SEL_BITS = 2;
    localparam integer RIGHT_ADD1_SEL_BITS = 2;
    localparam integer ADD3_SEL_BITS = 2;
    localparam integer N_COEFFS = 64;
    // requested coeffs sorted = [-54, -48, -47, -46, -44, -43, -42, -41, -38, -32, -31, -30, -28, -27, -26, -25, -23, -22, -21, -20, -18, -17, -16, -14, -10, -8, -7, -6, -4, -3, -2, -1, 1, 2, 3, 4, 6, 7, 8, 10, 14, 16, 17, 18, 20, 21, 22, 23, 25, 26, 27, 28, 30, 31, 32, 38, 41, 42, 43, 44, 46, 47, 48, 54]
    // selector coeffs        = [38, 31, -31, -38, 54, 47, -47, -54, -10, -17, 17, 10, 14, 7, -7, -14, 32, 28, -28, -32, 48, 44, -44, -48, -16, -20, 20, 16, 8, 4, -4, -8, 30, 27, -27, -30, 46, 43, -43, -46, -18, -21, 21, 18, 6, 3, -3, -6, 26, 25, -25, -26, 42, 41, -41, -42, -22, -23, 23, 22, 2, 1, -1, -2]
    // left add1 coeffs       = [-7, -4, -3, -1]
    // right add1 coeffs      = [3, 5, -3, 0]

    localparam [63:0] LUT_I0 = 64'hAAAAAAAAAAAAAAAA;
    localparam [63:0] LUT_I1 = 64'hCCCCCCCCCCCCCCCC;
    localparam [63:0] LUT_I2 = 64'hF0F0F0F0F0F0F0F0;
    localparam [63:0] LUT_I3 = 64'hFF00FF00FF00FF00;
    localparam [63:0] LUT_I4 = 64'hFFFF0000FFFF0000;
    localparam [63:0] LUT_I5 = 64'hFFFFFFFF00000000;

    wire [1:0] add3_sel = sel[1:0];
    wire [1:0] right_sel = sel[3:2];
    wire [1:0] left_sel = sel[5:4];
    wire signed [8:0] left_y;
    wire signed [8:0] right_y;

    // left_add1: rows reordered for op select bit: false
    // left_add1: pack mode: lut-di
    // left_add1: correction carry-in is constant 1
    wire [11:0] left_add1_s;
    wire [11:0] left_add1_di;
    wire [11:0] left_add1_o;
    wire [11:0] left_add1_co;
    wire left_add1_carry_init = 1'b1;

    localparam [63:0] LEFT_ADD1_SEL_ROW_0 =
        (~LUT_I0) & (~LUT_I1);
    localparam [63:0] LEFT_ADD1_SEL_ROW_1 =
        (LUT_I0) & (~LUT_I1);
    localparam [63:0] LEFT_ADD1_SEL_ROW_2 =
        (~LUT_I0) & (LUT_I1);
    localparam [63:0] LEFT_ADD1_SEL_ROW_3 =
        (LUT_I0) & (LUT_I1);

    localparam [63:0] LEFT_ADD1_BIT_0_S_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (~LUT_I4 ^ LUT_I2)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3 ^ ~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_2 & (~LUT_I3 ^ LUT_I2)) |
        (LEFT_ADD1_SEL_ROW_3 & (~LUT_I2 ^ 64'h0000000000000000));
    localparam [63:0] LEFT_ADD1_BIT_0_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (~LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_3 & (~LUT_I2));
    localparam [63:0] LEFT_ADD1_BIT_0_INIT =
        ((~LUT_I5) & LEFT_ADD1_BIT_0_DI_INIT) | (LUT_I5 & LEFT_ADD1_BIT_0_S_INIT);

    LUT6_2 #(
        .INIT(LEFT_ADD1_BIT_0_INIT)
    ) left_add1_lut_bit_0 (
        .O6(left_add1_s[0]),
        .O5(left_add1_di[0]),
        .I0(left_sel[0]),
        .I1(left_sel[1]),
        .I2(x[0]),
        .I3(1'b0),
        .I4(1'b0),
        .I5(1'b1)
    );

    localparam [63:0] LEFT_ADD1_BIT_1_S_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (~LUT_I4 ^ LUT_I2)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3 ^ ~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_2 & (~LUT_I3 ^ LUT_I2)) |
        (LEFT_ADD1_SEL_ROW_3 & (~LUT_I2 ^ 64'h0000000000000000));
    localparam [63:0] LEFT_ADD1_BIT_1_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (~LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_3 & (~LUT_I2));
    localparam [63:0] LEFT_ADD1_BIT_1_INIT =
        ((~LUT_I5) & LEFT_ADD1_BIT_1_DI_INIT) | (LUT_I5 & LEFT_ADD1_BIT_1_S_INIT);

    LUT6_2 #(
        .INIT(LEFT_ADD1_BIT_1_INIT)
    ) left_add1_lut_bit_1 (
        .O6(left_add1_s[1]),
        .O5(left_add1_di[1]),
        .I0(left_sel[0]),
        .I1(left_sel[1]),
        .I2(x[1]),
        .I3(1'b0),
        .I4(1'b0),
        .I5(1'b1)
    );

    localparam [63:0] LEFT_ADD1_BIT_2_S_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (~LUT_I4 ^ LUT_I2)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3 ^ ~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_2 & (~LUT_I3 ^ LUT_I2)) |
        (LEFT_ADD1_SEL_ROW_3 & (~LUT_I2 ^ 64'h0000000000000000));
    localparam [63:0] LEFT_ADD1_BIT_2_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (~LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_3 & (~LUT_I2));
    localparam [63:0] LEFT_ADD1_BIT_2_INIT =
        ((~LUT_I5) & LEFT_ADD1_BIT_2_DI_INIT) | (LUT_I5 & LEFT_ADD1_BIT_2_S_INIT);

    LUT6_2 #(
        .INIT(LEFT_ADD1_BIT_2_INIT)
    ) left_add1_lut_bit_2 (
        .O6(left_add1_s[2]),
        .O5(left_add1_di[2]),
        .I0(left_sel[0]),
        .I1(left_sel[1]),
        .I2(x[2]),
        .I3(x[0]),
        .I4(1'b0),
        .I5(1'b1)
    );

    localparam [63:0] LEFT_ADD1_BIT_3_S_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (~LUT_I4 ^ LUT_I2)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3 ^ ~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_2 & (~LUT_I3 ^ LUT_I2)) |
        (LEFT_ADD1_SEL_ROW_3 & (~LUT_I2 ^ 64'h0000000000000000));
    localparam [63:0] LEFT_ADD1_BIT_3_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (~LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_3 & (~LUT_I2));
    localparam [63:0] LEFT_ADD1_BIT_3_INIT =
        ((~LUT_I5) & LEFT_ADD1_BIT_3_DI_INIT) | (LUT_I5 & LEFT_ADD1_BIT_3_S_INIT);

    LUT6_2 #(
        .INIT(LEFT_ADD1_BIT_3_INIT)
    ) left_add1_lut_bit_3 (
        .O6(left_add1_s[3]),
        .O5(left_add1_di[3]),
        .I0(left_sel[0]),
        .I1(left_sel[1]),
        .I2(x[3]),
        .I3(x[1]),
        .I4(x[0]),
        .I5(1'b1)
    );

    localparam [63:0] LEFT_ADD1_BIT_4_S_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (~LUT_I4 ^ LUT_I2)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3 ^ ~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_2 & (~LUT_I3 ^ LUT_I2)) |
        (LEFT_ADD1_SEL_ROW_3 & (~LUT_I2 ^ 64'h0000000000000000));
    localparam [63:0] LEFT_ADD1_BIT_4_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (~LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_3 & (~LUT_I2));
    localparam [63:0] LEFT_ADD1_BIT_4_INIT =
        ((~LUT_I5) & LEFT_ADD1_BIT_4_DI_INIT) | (LUT_I5 & LEFT_ADD1_BIT_4_S_INIT);

    LUT6_2 #(
        .INIT(LEFT_ADD1_BIT_4_INIT)
    ) left_add1_lut_bit_4 (
        .O6(left_add1_s[4]),
        .O5(left_add1_di[4]),
        .I0(left_sel[0]),
        .I1(left_sel[1]),
        .I2(x[4]),
        .I3(x[2]),
        .I4(x[1]),
        .I5(1'b1)
    );

    localparam [63:0] LEFT_ADD1_BIT_5_S_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (~LUT_I4 ^ LUT_I2)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3 ^ ~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_2 & (~LUT_I3 ^ LUT_I2)) |
        (LEFT_ADD1_SEL_ROW_3 & (~LUT_I2 ^ 64'h0000000000000000));
    localparam [63:0] LEFT_ADD1_BIT_5_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (~LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_3 & (~LUT_I2));
    localparam [63:0] LEFT_ADD1_BIT_5_INIT =
        ((~LUT_I5) & LEFT_ADD1_BIT_5_DI_INIT) | (LUT_I5 & LEFT_ADD1_BIT_5_S_INIT);

    LUT6_2 #(
        .INIT(LEFT_ADD1_BIT_5_INIT)
    ) left_add1_lut_bit_5 (
        .O6(left_add1_s[5]),
        .O5(left_add1_di[5]),
        .I0(left_sel[0]),
        .I1(left_sel[1]),
        .I2(x[5]),
        .I3(x[3]),
        .I4(x[2]),
        .I5(1'b1)
    );

    localparam [63:0] LEFT_ADD1_BIT_6_S_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (~LUT_I4 ^ LUT_I2)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3 ^ ~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_2 & (~LUT_I3 ^ LUT_I2)) |
        (LEFT_ADD1_SEL_ROW_3 & (~LUT_I2 ^ 64'h0000000000000000));
    localparam [63:0] LEFT_ADD1_BIT_6_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (~LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_3 & (~LUT_I2));
    localparam [63:0] LEFT_ADD1_BIT_6_INIT =
        ((~LUT_I5) & LEFT_ADD1_BIT_6_DI_INIT) | (LUT_I5 & LEFT_ADD1_BIT_6_S_INIT);

    LUT6_2 #(
        .INIT(LEFT_ADD1_BIT_6_INIT)
    ) left_add1_lut_bit_6 (
        .O6(left_add1_s[6]),
        .O5(left_add1_di[6]),
        .I0(left_sel[0]),
        .I1(left_sel[1]),
        .I2(x[5]),
        .I3(x[4]),
        .I4(x[3]),
        .I5(1'b1)
    );

    localparam [63:0] LEFT_ADD1_BIT_7_S_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (~LUT_I4 ^ LUT_I2)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3 ^ ~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_2 & (~LUT_I3 ^ LUT_I2)) |
        (LEFT_ADD1_SEL_ROW_3 & (~LUT_I2 ^ 64'h0000000000000000));
    localparam [63:0] LEFT_ADD1_BIT_7_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (~LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_3 & (~LUT_I2));
    localparam [63:0] LEFT_ADD1_BIT_7_INIT =
        ((~LUT_I5) & LEFT_ADD1_BIT_7_DI_INIT) | (LUT_I5 & LEFT_ADD1_BIT_7_S_INIT);

    LUT6_2 #(
        .INIT(LEFT_ADD1_BIT_7_INIT)
    ) left_add1_lut_bit_7 (
        .O6(left_add1_s[7]),
        .O5(left_add1_di[7]),
        .I0(left_sel[0]),
        .I1(left_sel[1]),
        .I2(x[5]),
        .I3(x[5]),
        .I4(x[4]),
        .I5(1'b1)
    );

    localparam [63:0] LEFT_ADD1_BIT_8_S_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (~LUT_I4 ^ LUT_I2)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3 ^ ~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_2 & (~LUT_I3 ^ LUT_I2)) |
        (LEFT_ADD1_SEL_ROW_3 & (~LUT_I2 ^ 64'h0000000000000000));
    localparam [63:0] LEFT_ADD1_BIT_8_DI_INIT =
        (LEFT_ADD1_SEL_ROW_0 & (~LUT_I4)) |
        (LEFT_ADD1_SEL_ROW_1 & (LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_2 & (~LUT_I3)) |
        (LEFT_ADD1_SEL_ROW_3 & (~LUT_I2));
    localparam [63:0] LEFT_ADD1_BIT_8_INIT =
        ((~LUT_I5) & LEFT_ADD1_BIT_8_DI_INIT) | (LUT_I5 & LEFT_ADD1_BIT_8_S_INIT);

    LUT6_2 #(
        .INIT(LEFT_ADD1_BIT_8_INIT)
    ) left_add1_lut_bit_8 (
        .O6(left_add1_s[8]),
        .O5(left_add1_di[8]),
        .I0(left_sel[0]),
        .I1(left_sel[1]),
        .I2(x[5]),
        .I3(x[5]),
        .I4(x[5]),
        .I5(1'b1)
    );

    assign left_add1_s[9] = 1'b0;
    assign left_add1_di[9] = 1'b0;
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

    assign left_y = left_add1_o[8:0];

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
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I4 ^ ~LUT_I4));
    localparam [63:0] RIGHT_ADD1_BIT_0_DI_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I4));
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
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I4 ^ ~LUT_I4));
    localparam [63:0] RIGHT_ADD1_BIT_1_DI_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I4));
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
        .I3(x[0]),
        .I4(1'b0),
        .I5(1'b1)
    );

    localparam [63:0] RIGHT_ADD1_BIT_2_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I4 ^ ~LUT_I4));
    localparam [63:0] RIGHT_ADD1_BIT_2_DI_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I4));
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
        .I3(x[1]),
        .I4(x[0]),
        .I5(1'b1)
    );

    localparam [63:0] RIGHT_ADD1_BIT_3_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I4 ^ ~LUT_I4));
    localparam [63:0] RIGHT_ADD1_BIT_3_DI_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I4));
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
        .I3(x[2]),
        .I4(x[1]),
        .I5(1'b1)
    );

    localparam [63:0] RIGHT_ADD1_BIT_4_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I4 ^ ~LUT_I4));
    localparam [63:0] RIGHT_ADD1_BIT_4_DI_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I4));
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
        .I3(x[3]),
        .I4(x[2]),
        .I5(1'b1)
    );

    localparam [63:0] RIGHT_ADD1_BIT_5_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I4 ^ ~LUT_I4));
    localparam [63:0] RIGHT_ADD1_BIT_5_DI_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I4));
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
        .I3(x[4]),
        .I4(x[3]),
        .I5(1'b1)
    );

    localparam [63:0] RIGHT_ADD1_BIT_6_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I4 ^ ~LUT_I4));
    localparam [63:0] RIGHT_ADD1_BIT_6_DI_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I4));
    localparam [63:0] RIGHT_ADD1_BIT_6_INIT =
        ((~LUT_I5) & RIGHT_ADD1_BIT_6_DI_INIT) | (LUT_I5 & RIGHT_ADD1_BIT_6_S_INIT);

    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_6_INIT)
    ) right_add1_lut_bit_6 (
        .O6(right_add1_s[6]),
        .O5(right_add1_di[6]),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[5]),
        .I3(x[5]),
        .I4(x[4]),
        .I5(1'b1)
    );

    localparam [63:0] RIGHT_ADD1_BIT_7_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I4 ^ ~LUT_I4));
    localparam [63:0] RIGHT_ADD1_BIT_7_DI_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I4));
    localparam [63:0] RIGHT_ADD1_BIT_7_INIT =
        ((~LUT_I5) & RIGHT_ADD1_BIT_7_DI_INIT) | (LUT_I5 & RIGHT_ADD1_BIT_7_S_INIT);

    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_7_INIT)
    ) right_add1_lut_bit_7 (
        .O6(right_add1_s[7]),
        .O5(right_add1_di[7]),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[5]),
        .I3(x[5]),
        .I4(x[5]),
        .I5(1'b1)
    );

    localparam [63:0] RIGHT_ADD1_BIT_8_S_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I2 ^ LUT_I3)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4 ^ LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I4 ^ ~LUT_I4));
    localparam [63:0] RIGHT_ADD1_BIT_8_DI_INIT =
        (RIGHT_ADD1_SEL_ROW_0 & (LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_1 & (LUT_I4)) |
        (RIGHT_ADD1_SEL_ROW_2 & (LUT_I2)) |
        (RIGHT_ADD1_SEL_ROW_3 & (LUT_I4));
    localparam [63:0] RIGHT_ADD1_BIT_8_INIT =
        ((~LUT_I5) & RIGHT_ADD1_BIT_8_DI_INIT) | (LUT_I5 & RIGHT_ADD1_BIT_8_S_INIT);

    LUT6_2 #(
        .INIT(RIGHT_ADD1_BIT_8_INIT)
    ) right_add1_lut_bit_8 (
        .O6(right_add1_s[8]),
        .O5(right_add1_di[8]),
        .I0(right_sel[0]),
        .I1(right_sel[1]),
        .I2(x[5]),
        .I3(x[5]),
        .I4(x[5]),
        .I5(1'b1)
    );

    assign right_add1_s[9] = 1'b0;
    assign right_add1_di[9] = 1'b0;
    assign right_add1_s[10] = 1'b0;
    assign right_add1_di[10] = 1'b0;
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

    assign right_y = right_add1_o[8:0];

    // add3: rows reordered for op select bit: false
    // add3: pack mode: lut-di
    // add3: correction carry-in is constant 1
    wire [11:0] add3_s;
    wire [11:0] add3_di;
    wire [11:0] add3_o;
    wire [11:0] add3_co;
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
        (ADD3_SEL_ROW_0 & (~LUT_I3 ^ LUT_I4)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_0_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] ADD3_BIT_0_INIT =
        ((~LUT_I5) & ADD3_BIT_0_DI_INIT) | (LUT_I5 & ADD3_BIT_0_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_0_INIT)
    ) add3_lut_bit_0 (
        .O6(add3_s[0]),
        .O5(add3_di[0]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[0]),
        .I3(1'b0),
        .I4(1'b0),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_1_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3 ^ LUT_I4)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_1_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] ADD3_BIT_1_INIT =
        ((~LUT_I5) & ADD3_BIT_1_DI_INIT) | (LUT_I5 & ADD3_BIT_1_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_1_INIT)
    ) add3_lut_bit_1 (
        .O6(add3_s[1]),
        .O5(add3_di[1]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[1]),
        .I3(left_y[0]),
        .I4(1'b0),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_2_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3 ^ LUT_I4)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_2_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] ADD3_BIT_2_INIT =
        ((~LUT_I5) & ADD3_BIT_2_DI_INIT) | (LUT_I5 & ADD3_BIT_2_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_2_INIT)
    ) add3_lut_bit_2 (
        .O6(add3_s[2]),
        .O5(add3_di[2]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[2]),
        .I3(left_y[1]),
        .I4(1'b0),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_3_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3 ^ LUT_I4)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_3_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] ADD3_BIT_3_INIT =
        ((~LUT_I5) & ADD3_BIT_3_DI_INIT) | (LUT_I5 & ADD3_BIT_3_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_3_INIT)
    ) add3_lut_bit_3 (
        .O6(add3_s[3]),
        .O5(add3_di[3]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[3]),
        .I3(left_y[2]),
        .I4(right_y[0]),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_4_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3 ^ LUT_I4)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_4_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] ADD3_BIT_4_INIT =
        ((~LUT_I5) & ADD3_BIT_4_DI_INIT) | (LUT_I5 & ADD3_BIT_4_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_4_INIT)
    ) add3_lut_bit_4 (
        .O6(add3_s[4]),
        .O5(add3_di[4]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[4]),
        .I3(left_y[3]),
        .I4(right_y[1]),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_5_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3 ^ LUT_I4)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_5_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] ADD3_BIT_5_INIT =
        ((~LUT_I5) & ADD3_BIT_5_DI_INIT) | (LUT_I5 & ADD3_BIT_5_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_5_INIT)
    ) add3_lut_bit_5 (
        .O6(add3_s[5]),
        .O5(add3_di[5]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[5]),
        .I3(left_y[4]),
        .I4(right_y[2]),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_6_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3 ^ LUT_I4)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_6_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] ADD3_BIT_6_INIT =
        ((~LUT_I5) & ADD3_BIT_6_DI_INIT) | (LUT_I5 & ADD3_BIT_6_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_6_INIT)
    ) add3_lut_bit_6 (
        .O6(add3_s[6]),
        .O5(add3_di[6]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[6]),
        .I3(left_y[5]),
        .I4(right_y[3]),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_7_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3 ^ LUT_I4)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_7_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] ADD3_BIT_7_INIT =
        ((~LUT_I5) & ADD3_BIT_7_DI_INIT) | (LUT_I5 & ADD3_BIT_7_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_7_INIT)
    ) add3_lut_bit_7 (
        .O6(add3_s[7]),
        .O5(add3_di[7]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[7]),
        .I3(left_y[6]),
        .I4(right_y[4]),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_8_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3 ^ LUT_I4)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_8_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] ADD3_BIT_8_INIT =
        ((~LUT_I5) & ADD3_BIT_8_DI_INIT) | (LUT_I5 & ADD3_BIT_8_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_8_INIT)
    ) add3_lut_bit_8 (
        .O6(add3_s[8]),
        .O5(add3_di[8]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[8]),
        .I3(left_y[7]),
        .I4(right_y[5]),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_9_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3 ^ LUT_I4)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_9_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] ADD3_BIT_9_INIT =
        ((~LUT_I5) & ADD3_BIT_9_DI_INIT) | (LUT_I5 & ADD3_BIT_9_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_9_INIT)
    ) add3_lut_bit_9 (
        .O6(add3_s[9]),
        .O5(add3_di[9]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[8]),
        .I3(left_y[8]),
        .I4(right_y[6]),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_10_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3 ^ LUT_I4)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_10_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] ADD3_BIT_10_INIT =
        ((~LUT_I5) & ADD3_BIT_10_DI_INIT) | (LUT_I5 & ADD3_BIT_10_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_10_INIT)
    ) add3_lut_bit_10 (
        .O6(add3_s[10]),
        .O5(add3_di[10]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[8]),
        .I3(left_y[8]),
        .I4(right_y[7]),
        .I5(1'b1)
    );

    localparam [63:0] ADD3_BIT_11_S_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3 ^ LUT_I4)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2 ^ LUT_I4)) |
        (ADD3_SEL_ROW_2 & (LUT_I2 ^ ~LUT_I4)) |
        (ADD3_SEL_ROW_3 & (LUT_I3 ^ ~LUT_I4));
    localparam [63:0] ADD3_BIT_11_DI_INIT =
        (ADD3_SEL_ROW_0 & (~LUT_I3)) |
        (ADD3_SEL_ROW_1 & (~LUT_I2)) |
        (ADD3_SEL_ROW_2 & (LUT_I2)) |
        (ADD3_SEL_ROW_3 & (LUT_I3));
    localparam [63:0] ADD3_BIT_11_INIT =
        ((~LUT_I5) & ADD3_BIT_11_DI_INIT) | (LUT_I5 & ADD3_BIT_11_S_INIT);

    LUT6_2 #(
        .INIT(ADD3_BIT_11_INIT)
    ) add3_lut_bit_11 (
        .O6(add3_s[11]),
        .O5(add3_di[11]),
        .I0(add3_sel[0]),
        .I1(add3_sel[1]),
        .I2(left_y[8]),
        .I3(left_y[8]),
        .I4(right_y[8]),
        .I5(1'b1)
    );

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

    assign y = add3_o[11:0];

endmodule
