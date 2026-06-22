`timescale 1ns/1ps

module lut6_2_carry_2dd_multiplier (
    input wire signed [3:0] x,
    input wire [3:0] sel,
    output wire signed [7:0] y
);
    localparam integer INPUT_BW = 4;
    localparam integer COEFF_BW = 5;
    localparam integer ADD1_OUTPUT_BW = 3;
    localparam integer ADD1_Y_BW = 6;
    localparam integer OUTPUT_BW = 8;
    localparam integer ADD1_SEL_BITS = 2;
    localparam integer ADD2_SEL_BITS = 2;
    localparam integer N_COEFFS = 16;
    // requested coeffs sorted = [-15, -11, -10, -7, -4, -3, -2, -1, 1, 2, 3, 4, 9, 10, 13, 15]
    // selector coeffs        = [-11, -15, 4, -4, -7, -10, 3, -3, 9, 10, -1, 1, 13, 15, -2, 2]
    // add1 coeffs            = [-3, -2, 2, 3]

    localparam [63:0] LUT_I0 = 64'hAAAAAAAAAAAAAAAA;
    localparam [63:0] LUT_I1 = 64'hCCCCCCCCCCCCCCCC;
    localparam [63:0] LUT_I2 = 64'hF0F0F0F0F0F0F0F0;
    localparam [63:0] LUT_I3 = 64'hFF00FF00FF00FF00;
    localparam [63:0] LUT_I4 = 64'hFFFF0000FFFF0000;
    localparam [63:0] LUT_I5 = 64'hFFFFFFFF00000000;

    wire [1:0] add1_sel = sel[3:2];
    wire [1:0] add2_sel = sel[1:0];
    wire signed [5:0] add1_y;

    // add1: rows reordered for op select bit: false
    // add1: pack mode: lut-di
    // add1: correction carry-in is constant 1
    wire [7:0] add1_s;
    wire [7:0] add1_di;
    wire [7:0] add1_o;
    wire [7:0] add1_co;
    wire add1_carry_init = 1'b1;

    localparam [63:0] ADD1_SEL_ROW_0 =
        (~LUT_I0) & (~LUT_I1);
    localparam [63:0] ADD1_SEL_ROW_1 =
        (LUT_I0) & (~LUT_I1);
    localparam [63:0] ADD1_SEL_ROW_2 =
        (~LUT_I0) & (LUT_I1);
    localparam [63:0] ADD1_SEL_ROW_3 =
        (LUT_I0) & (LUT_I1);

    localparam [63:0] ADD1_BIT_0_S_INIT =
        (ADD1_SEL_ROW_0 & (~LUT_I4 ^ LUT_I2)) |
        (ADD1_SEL_ROW_1 & (~LUT_I4 ^ LUT_I3)) |
        (ADD1_SEL_ROW_2 & (LUT_I3 ^ 64'hFFFFFFFFFFFFFFFF)) |
        (ADD1_SEL_ROW_3 & (LUT_I4 ^ ~LUT_I2));
    localparam [63:0] ADD1_BIT_0_DI_INIT =
        (ADD1_SEL_ROW_0 & (~LUT_I4)) |
        (ADD1_SEL_ROW_1 & (~LUT_I4)) |
        (ADD1_SEL_ROW_2 & (LUT_I3)) |
        (ADD1_SEL_ROW_3 & (LUT_I4));
    localparam [63:0] ADD1_BIT_0_INIT =
        ((~LUT_I5) & ADD1_BIT_0_DI_INIT) | (LUT_I5 & ADD1_BIT_0_S_INIT);

    LUT6_2 #(
        .INIT(ADD1_BIT_0_INIT)
    ) add1_lut_bit_0 (
        .O6(add1_s[0]),
        .O5(add1_di[0]),
        .I0(add1_sel[0]),
        .I1(add1_sel[1]),
        .I2(x[0]),
        .I3(1'b0),
        .I4(1'b0),
        .I5(1'b1)
    );

    localparam [63:0] ADD1_BIT_1_S_INIT =
        (ADD1_SEL_ROW_0 & (~LUT_I4 ^ LUT_I2)) |
        (ADD1_SEL_ROW_1 & (~LUT_I4 ^ LUT_I3)) |
        (ADD1_SEL_ROW_2 & (LUT_I3 ^ 64'hFFFFFFFFFFFFFFFF)) |
        (ADD1_SEL_ROW_3 & (LUT_I4 ^ ~LUT_I2));
    localparam [63:0] ADD1_BIT_1_DI_INIT =
        (ADD1_SEL_ROW_0 & (~LUT_I4)) |
        (ADD1_SEL_ROW_1 & (~LUT_I4)) |
        (ADD1_SEL_ROW_2 & (LUT_I3)) |
        (ADD1_SEL_ROW_3 & (LUT_I4));
    localparam [63:0] ADD1_BIT_1_INIT =
        ((~LUT_I5) & ADD1_BIT_1_DI_INIT) | (LUT_I5 & ADD1_BIT_1_S_INIT);

    LUT6_2 #(
        .INIT(ADD1_BIT_1_INIT)
    ) add1_lut_bit_1 (
        .O6(add1_s[1]),
        .O5(add1_di[1]),
        .I0(add1_sel[0]),
        .I1(add1_sel[1]),
        .I2(x[1]),
        .I3(x[0]),
        .I4(1'b0),
        .I5(1'b1)
    );

    localparam [63:0] ADD1_BIT_2_S_INIT =
        (ADD1_SEL_ROW_0 & (~LUT_I4 ^ LUT_I2)) |
        (ADD1_SEL_ROW_1 & (~LUT_I4 ^ LUT_I3)) |
        (ADD1_SEL_ROW_2 & (LUT_I3 ^ 64'hFFFFFFFFFFFFFFFF)) |
        (ADD1_SEL_ROW_3 & (LUT_I4 ^ ~LUT_I2));
    localparam [63:0] ADD1_BIT_2_DI_INIT =
        (ADD1_SEL_ROW_0 & (~LUT_I4)) |
        (ADD1_SEL_ROW_1 & (~LUT_I4)) |
        (ADD1_SEL_ROW_2 & (LUT_I3)) |
        (ADD1_SEL_ROW_3 & (LUT_I4));
    localparam [63:0] ADD1_BIT_2_INIT =
        ((~LUT_I5) & ADD1_BIT_2_DI_INIT) | (LUT_I5 & ADD1_BIT_2_S_INIT);

    LUT6_2 #(
        .INIT(ADD1_BIT_2_INIT)
    ) add1_lut_bit_2 (
        .O6(add1_s[2]),
        .O5(add1_di[2]),
        .I0(add1_sel[0]),
        .I1(add1_sel[1]),
        .I2(x[2]),
        .I3(x[1]),
        .I4(x[0]),
        .I5(1'b1)
    );

    localparam [63:0] ADD1_BIT_3_S_INIT =
        (ADD1_SEL_ROW_0 & (~LUT_I4 ^ LUT_I2)) |
        (ADD1_SEL_ROW_1 & (~LUT_I4 ^ LUT_I3)) |
        (ADD1_SEL_ROW_2 & (LUT_I3 ^ 64'hFFFFFFFFFFFFFFFF)) |
        (ADD1_SEL_ROW_3 & (LUT_I4 ^ ~LUT_I2));
    localparam [63:0] ADD1_BIT_3_DI_INIT =
        (ADD1_SEL_ROW_0 & (~LUT_I4)) |
        (ADD1_SEL_ROW_1 & (~LUT_I4)) |
        (ADD1_SEL_ROW_2 & (LUT_I3)) |
        (ADD1_SEL_ROW_3 & (LUT_I4));
    localparam [63:0] ADD1_BIT_3_INIT =
        ((~LUT_I5) & ADD1_BIT_3_DI_INIT) | (LUT_I5 & ADD1_BIT_3_S_INIT);

    LUT6_2 #(
        .INIT(ADD1_BIT_3_INIT)
    ) add1_lut_bit_3 (
        .O6(add1_s[3]),
        .O5(add1_di[3]),
        .I0(add1_sel[0]),
        .I1(add1_sel[1]),
        .I2(x[3]),
        .I3(x[2]),
        .I4(x[1]),
        .I5(1'b1)
    );

    localparam [63:0] ADD1_BIT_4_S_INIT =
        (ADD1_SEL_ROW_0 & (~LUT_I4 ^ LUT_I2)) |
        (ADD1_SEL_ROW_1 & (~LUT_I4 ^ LUT_I3)) |
        (ADD1_SEL_ROW_2 & (LUT_I3 ^ 64'hFFFFFFFFFFFFFFFF)) |
        (ADD1_SEL_ROW_3 & (LUT_I4 ^ ~LUT_I2));
    localparam [63:0] ADD1_BIT_4_DI_INIT =
        (ADD1_SEL_ROW_0 & (~LUT_I4)) |
        (ADD1_SEL_ROW_1 & (~LUT_I4)) |
        (ADD1_SEL_ROW_2 & (LUT_I3)) |
        (ADD1_SEL_ROW_3 & (LUT_I4));
    localparam [63:0] ADD1_BIT_4_INIT =
        ((~LUT_I5) & ADD1_BIT_4_DI_INIT) | (LUT_I5 & ADD1_BIT_4_S_INIT);

    LUT6_2 #(
        .INIT(ADD1_BIT_4_INIT)
    ) add1_lut_bit_4 (
        .O6(add1_s[4]),
        .O5(add1_di[4]),
        .I0(add1_sel[0]),
        .I1(add1_sel[1]),
        .I2(x[3]),
        .I3(x[3]),
        .I4(x[2]),
        .I5(1'b1)
    );

    localparam [63:0] ADD1_BIT_5_S_INIT =
        (ADD1_SEL_ROW_0 & (~LUT_I4 ^ LUT_I2)) |
        (ADD1_SEL_ROW_1 & (~LUT_I4 ^ LUT_I3)) |
        (ADD1_SEL_ROW_2 & (LUT_I3 ^ 64'hFFFFFFFFFFFFFFFF)) |
        (ADD1_SEL_ROW_3 & (LUT_I4 ^ ~LUT_I2));
    localparam [63:0] ADD1_BIT_5_DI_INIT =
        (ADD1_SEL_ROW_0 & (~LUT_I4)) |
        (ADD1_SEL_ROW_1 & (~LUT_I4)) |
        (ADD1_SEL_ROW_2 & (LUT_I3)) |
        (ADD1_SEL_ROW_3 & (LUT_I4));
    localparam [63:0] ADD1_BIT_5_INIT =
        ((~LUT_I5) & ADD1_BIT_5_DI_INIT) | (LUT_I5 & ADD1_BIT_5_S_INIT);

    LUT6_2 #(
        .INIT(ADD1_BIT_5_INIT)
    ) add1_lut_bit_5 (
        .O6(add1_s[5]),
        .O5(add1_di[5]),
        .I0(add1_sel[0]),
        .I1(add1_sel[1]),
        .I2(x[3]),
        .I3(x[3]),
        .I4(x[3]),
        .I5(1'b1)
    );

    assign add1_s[6] = 1'b0;
    assign add1_di[6] = 1'b0;
    assign add1_s[7] = 1'b0;
    assign add1_di[7] = 1'b0;

    CARRY4 add1_carry_0 (
        .CO(add1_co[3:0]),
        .O(add1_o[3:0]),
        .CI(1'b0),
        .CYINIT(add1_carry_init),
        .DI(add1_di[3:0]),
        .S(add1_s[3:0])
    );

    CARRY4 add1_carry_1 (
        .CO(add1_co[7:4]),
        .O(add1_o[7:4]),
        .CI(add1_co[3]),
        .CYINIT(1'b0),
        .DI(add1_di[7:4]),
        .S(add1_s[7:4])
    );

    assign add1_y = add1_o[5:0];

    // add2: rows reordered for op select bit: false
    // add2: pack mode: lut-di
    // add2: correction carry-in is add2_sel[1]
    wire [7:0] add2_s;
    wire [7:0] add2_di;
    wire [7:0] add2_o;
    wire [7:0] add2_co;
    wire add2_carry_init = add2_sel[1];

    localparam [63:0] ADD2_SEL_ROW_0 =
        (~LUT_I0) & (~LUT_I1);
    localparam [63:0] ADD2_SEL_ROW_1 =
        (LUT_I0) & (~LUT_I1);
    localparam [63:0] ADD2_SEL_ROW_2 =
        (~LUT_I0) & (LUT_I1);
    localparam [63:0] ADD2_SEL_ROW_3 =
        (LUT_I0) & (LUT_I1);

    localparam [63:0] ADD2_BIT_0_S_INIT =
        (ADD2_SEL_ROW_0 & (LUT_I3 ^ LUT_I4)) |
        (ADD2_SEL_ROW_1 & (LUT_I2 ^ LUT_I3)) |
        (ADD2_SEL_ROW_2 & (~LUT_I2 ^ LUT_I4)) |
        (ADD2_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD2_BIT_0_DI_INIT =
        (ADD2_SEL_ROW_0 & (LUT_I3)) |
        (ADD2_SEL_ROW_1 & (LUT_I2)) |
        (ADD2_SEL_ROW_2 & (~LUT_I2)) |
        (ADD2_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD2_BIT_0_INIT =
        ((~LUT_I5) & ADD2_BIT_0_DI_INIT) | (LUT_I5 & ADD2_BIT_0_S_INIT);

    LUT6_2 #(
        .INIT(ADD2_BIT_0_INIT)
    ) add2_lut_bit_0 (
        .O6(add2_s[0]),
        .O5(add2_di[0]),
        .I0(add2_sel[0]),
        .I1(add2_sel[1]),
        .I2(add1_y[0]),
        .I3(1'b0),
        .I4(x[0]),
        .I5(1'b1)
    );

    localparam [63:0] ADD2_BIT_1_S_INIT =
        (ADD2_SEL_ROW_0 & (LUT_I3 ^ LUT_I4)) |
        (ADD2_SEL_ROW_1 & (LUT_I2 ^ LUT_I3)) |
        (ADD2_SEL_ROW_2 & (~LUT_I2 ^ LUT_I4)) |
        (ADD2_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD2_BIT_1_DI_INIT =
        (ADD2_SEL_ROW_0 & (LUT_I3)) |
        (ADD2_SEL_ROW_1 & (LUT_I2)) |
        (ADD2_SEL_ROW_2 & (~LUT_I2)) |
        (ADD2_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD2_BIT_1_INIT =
        ((~LUT_I5) & ADD2_BIT_1_DI_INIT) | (LUT_I5 & ADD2_BIT_1_S_INIT);

    LUT6_2 #(
        .INIT(ADD2_BIT_1_INIT)
    ) add2_lut_bit_1 (
        .O6(add2_s[1]),
        .O5(add2_di[1]),
        .I0(add2_sel[0]),
        .I1(add2_sel[1]),
        .I2(add1_y[1]),
        .I3(1'b0),
        .I4(x[1]),
        .I5(1'b1)
    );

    localparam [63:0] ADD2_BIT_2_S_INIT =
        (ADD2_SEL_ROW_0 & (LUT_I3 ^ LUT_I4)) |
        (ADD2_SEL_ROW_1 & (LUT_I2 ^ LUT_I3)) |
        (ADD2_SEL_ROW_2 & (~LUT_I2 ^ LUT_I4)) |
        (ADD2_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD2_BIT_2_DI_INIT =
        (ADD2_SEL_ROW_0 & (LUT_I3)) |
        (ADD2_SEL_ROW_1 & (LUT_I2)) |
        (ADD2_SEL_ROW_2 & (~LUT_I2)) |
        (ADD2_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD2_BIT_2_INIT =
        ((~LUT_I5) & ADD2_BIT_2_DI_INIT) | (LUT_I5 & ADD2_BIT_2_S_INIT);

    LUT6_2 #(
        .INIT(ADD2_BIT_2_INIT)
    ) add2_lut_bit_2 (
        .O6(add2_s[2]),
        .O5(add2_di[2]),
        .I0(add2_sel[0]),
        .I1(add2_sel[1]),
        .I2(add1_y[2]),
        .I3(add1_y[0]),
        .I4(x[2]),
        .I5(1'b1)
    );

    localparam [63:0] ADD2_BIT_3_S_INIT =
        (ADD2_SEL_ROW_0 & (LUT_I3 ^ LUT_I4)) |
        (ADD2_SEL_ROW_1 & (LUT_I2 ^ LUT_I3)) |
        (ADD2_SEL_ROW_2 & (~LUT_I2 ^ LUT_I4)) |
        (ADD2_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD2_BIT_3_DI_INIT =
        (ADD2_SEL_ROW_0 & (LUT_I3)) |
        (ADD2_SEL_ROW_1 & (LUT_I2)) |
        (ADD2_SEL_ROW_2 & (~LUT_I2)) |
        (ADD2_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD2_BIT_3_INIT =
        ((~LUT_I5) & ADD2_BIT_3_DI_INIT) | (LUT_I5 & ADD2_BIT_3_S_INIT);

    LUT6_2 #(
        .INIT(ADD2_BIT_3_INIT)
    ) add2_lut_bit_3 (
        .O6(add2_s[3]),
        .O5(add2_di[3]),
        .I0(add2_sel[0]),
        .I1(add2_sel[1]),
        .I2(add1_y[3]),
        .I3(add1_y[1]),
        .I4(x[3]),
        .I5(1'b1)
    );

    localparam [63:0] ADD2_BIT_4_S_INIT =
        (ADD2_SEL_ROW_0 & (LUT_I3 ^ LUT_I4)) |
        (ADD2_SEL_ROW_1 & (LUT_I2 ^ LUT_I3)) |
        (ADD2_SEL_ROW_2 & (~LUT_I2 ^ LUT_I4)) |
        (ADD2_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD2_BIT_4_DI_INIT =
        (ADD2_SEL_ROW_0 & (LUT_I3)) |
        (ADD2_SEL_ROW_1 & (LUT_I2)) |
        (ADD2_SEL_ROW_2 & (~LUT_I2)) |
        (ADD2_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD2_BIT_4_INIT =
        ((~LUT_I5) & ADD2_BIT_4_DI_INIT) | (LUT_I5 & ADD2_BIT_4_S_INIT);

    LUT6_2 #(
        .INIT(ADD2_BIT_4_INIT)
    ) add2_lut_bit_4 (
        .O6(add2_s[4]),
        .O5(add2_di[4]),
        .I0(add2_sel[0]),
        .I1(add2_sel[1]),
        .I2(add1_y[4]),
        .I3(add1_y[2]),
        .I4(x[3]),
        .I5(1'b1)
    );

    localparam [63:0] ADD2_BIT_5_S_INIT =
        (ADD2_SEL_ROW_0 & (LUT_I3 ^ LUT_I4)) |
        (ADD2_SEL_ROW_1 & (LUT_I2 ^ LUT_I3)) |
        (ADD2_SEL_ROW_2 & (~LUT_I2 ^ LUT_I4)) |
        (ADD2_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD2_BIT_5_DI_INIT =
        (ADD2_SEL_ROW_0 & (LUT_I3)) |
        (ADD2_SEL_ROW_1 & (LUT_I2)) |
        (ADD2_SEL_ROW_2 & (~LUT_I2)) |
        (ADD2_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD2_BIT_5_INIT =
        ((~LUT_I5) & ADD2_BIT_5_DI_INIT) | (LUT_I5 & ADD2_BIT_5_S_INIT);

    LUT6_2 #(
        .INIT(ADD2_BIT_5_INIT)
    ) add2_lut_bit_5 (
        .O6(add2_s[5]),
        .O5(add2_di[5]),
        .I0(add2_sel[0]),
        .I1(add2_sel[1]),
        .I2(add1_y[5]),
        .I3(add1_y[3]),
        .I4(x[3]),
        .I5(1'b1)
    );

    localparam [63:0] ADD2_BIT_6_S_INIT =
        (ADD2_SEL_ROW_0 & (LUT_I3 ^ LUT_I4)) |
        (ADD2_SEL_ROW_1 & (LUT_I2 ^ LUT_I3)) |
        (ADD2_SEL_ROW_2 & (~LUT_I2 ^ LUT_I4)) |
        (ADD2_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD2_BIT_6_DI_INIT =
        (ADD2_SEL_ROW_0 & (LUT_I3)) |
        (ADD2_SEL_ROW_1 & (LUT_I2)) |
        (ADD2_SEL_ROW_2 & (~LUT_I2)) |
        (ADD2_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD2_BIT_6_INIT =
        ((~LUT_I5) & ADD2_BIT_6_DI_INIT) | (LUT_I5 & ADD2_BIT_6_S_INIT);

    LUT6_2 #(
        .INIT(ADD2_BIT_6_INIT)
    ) add2_lut_bit_6 (
        .O6(add2_s[6]),
        .O5(add2_di[6]),
        .I0(add2_sel[0]),
        .I1(add2_sel[1]),
        .I2(add1_y[5]),
        .I3(add1_y[4]),
        .I4(x[3]),
        .I5(1'b1)
    );

    localparam [63:0] ADD2_BIT_7_S_INIT =
        (ADD2_SEL_ROW_0 & (LUT_I3 ^ LUT_I4)) |
        (ADD2_SEL_ROW_1 & (LUT_I2 ^ LUT_I3)) |
        (ADD2_SEL_ROW_2 & (~LUT_I2 ^ LUT_I4)) |
        (ADD2_SEL_ROW_3 & (LUT_I2 ^ ~LUT_I4));
    localparam [63:0] ADD2_BIT_7_DI_INIT =
        (ADD2_SEL_ROW_0 & (LUT_I3)) |
        (ADD2_SEL_ROW_1 & (LUT_I2)) |
        (ADD2_SEL_ROW_2 & (~LUT_I2)) |
        (ADD2_SEL_ROW_3 & (LUT_I2));
    localparam [63:0] ADD2_BIT_7_INIT =
        ((~LUT_I5) & ADD2_BIT_7_DI_INIT) | (LUT_I5 & ADD2_BIT_7_S_INIT);

    LUT6_2 #(
        .INIT(ADD2_BIT_7_INIT)
    ) add2_lut_bit_7 (
        .O6(add2_s[7]),
        .O5(add2_di[7]),
        .I0(add2_sel[0]),
        .I1(add2_sel[1]),
        .I2(add1_y[5]),
        .I3(add1_y[5]),
        .I4(x[3]),
        .I5(1'b1)
    );

    CARRY4 add2_carry_0 (
        .CO(add2_co[3:0]),
        .O(add2_o[3:0]),
        .CI(1'b0),
        .CYINIT(add2_carry_init),
        .DI(add2_di[3:0]),
        .S(add2_s[3:0])
    );

    CARRY4 add2_carry_1 (
        .CO(add2_co[7:4]),
        .O(add2_o[7:4]),
        .CI(add2_co[3]),
        .CYINIT(1'b0),
        .DI(add2_di[7:4]),
        .S(add2_s[7:4])
    );

    assign y = add2_o[7:0];

endmodule
