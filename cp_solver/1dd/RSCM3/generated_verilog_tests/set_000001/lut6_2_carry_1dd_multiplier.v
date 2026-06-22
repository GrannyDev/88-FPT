`timescale 1ns/1ps

module lut6_2_carry_1dd_multiplier (
    input wire signed [2:0] x,
    input wire [2:0] sel,
    output wire signed [5:0] y
);
    localparam integer INPUT_BW = 3;
    localparam integer COEFF_BW = 4;
    localparam integer OUTPUT_BW = 6;
    localparam integer N_COEFFS = 8;
    // coeffs = [1, 2, 4, 5, -4, -3, 0, 3]
    // s_l    = [1, 1, 1, 1, -1, 1, 1, 1]
    // s_r    = [0, 1, 0, 1, 0, -1, -1, -1]
    // l      = [1, 1, 4, 1, 4, 1, 1, 4]
    // r      = [8, 1, 8, 4, 8, 4, 1, 1]
    // pack mode: lut-di
    // rows reordered for op select bit: true
    // correction carry-in is sel[2]

    localparam [63:0] LUT_I0 = 64'hAAAAAAAAAAAAAAAA;
    localparam [63:0] LUT_I1 = 64'hCCCCCCCCCCCCCCCC;
    localparam [63:0] LUT_I2 = 64'hF0F0F0F0F0F0F0F0;
    localparam [63:0] LUT_I3 = 64'hFF00FF00FF00FF00;
    localparam [63:0] LUT_I4 = 64'hFFFF0000FFFF0000;
    localparam [63:0] LUT_I5 = 64'hFFFFFFFF00000000;

    localparam [63:0] SEL_ROW_0 =
        (~LUT_I0) & (~LUT_I1) & (~LUT_I2);
    localparam [63:0] SEL_ROW_1 =
        (LUT_I0) & (~LUT_I1) & (~LUT_I2);
    localparam [63:0] SEL_ROW_2 =
        (~LUT_I0) & (LUT_I1) & (~LUT_I2);
    localparam [63:0] SEL_ROW_3 =
        (LUT_I0) & (LUT_I1) & (~LUT_I2);
    localparam [63:0] SEL_ROW_4 =
        (~LUT_I0) & (~LUT_I1) & (LUT_I2);
    localparam [63:0] SEL_ROW_5 =
        (LUT_I0) & (~LUT_I1) & (LUT_I2);
    localparam [63:0] SEL_ROW_6 =
        (~LUT_I0) & (LUT_I1) & (LUT_I2);
    localparam [63:0] SEL_ROW_7 =
        (LUT_I0) & (LUT_I1) & (LUT_I2);

    wire [7:0] carry_s;
    wire [7:0] carry_di;
    wire [7:0] carry_o;
    wire [7:0] carry_co;
    wire carry_init = sel[2];

    localparam [63:0] BIT_0_S_INIT =
        (SEL_ROW_0 & (LUT_I3 ^ 64'h0000000000000000)) |
        (SEL_ROW_1 & (LUT_I3 ^ LUT_I3)) |
        (SEL_ROW_2 & (LUT_I4 ^ 64'h0000000000000000)) |
        (SEL_ROW_3 & (LUT_I3 ^ LUT_I4)) |
        (SEL_ROW_4 & (~LUT_I4 ^ 64'h0000000000000000)) |
        (SEL_ROW_5 & (LUT_I3 ^ ~LUT_I4)) |
        (SEL_ROW_6 & (LUT_I3 ^ ~LUT_I3)) |
        (SEL_ROW_7 & (LUT_I4 ^ ~LUT_I3));
    localparam [63:0] BIT_0_DI_INIT =
        (SEL_ROW_0 & (LUT_I3)) |
        (SEL_ROW_1 & (LUT_I3)) |
        (SEL_ROW_2 & (LUT_I4)) |
        (SEL_ROW_3 & (LUT_I3)) |
        (SEL_ROW_4 & (~LUT_I4)) |
        (SEL_ROW_5 & (LUT_I3)) |
        (SEL_ROW_6 & (LUT_I3)) |
        (SEL_ROW_7 & (LUT_I4));
    localparam [63:0] BIT_0_INIT =
        ((~LUT_I5) & BIT_0_DI_INIT) | (LUT_I5 & BIT_0_S_INIT);

    LUT6_2 #(
        .INIT(BIT_0_INIT)
    ) lut_bit_0 (
        .O6(carry_s[0]),
        .O5(carry_di[0]),
        .I0(sel[0]),
        .I1(sel[1]),
        .I2(sel[2]),
        .I3(x[0]),
        .I4(1'b0),
        .I5(1'b1)
    );

    localparam [63:0] BIT_1_S_INIT =
        (SEL_ROW_0 & (LUT_I3 ^ 64'h0000000000000000)) |
        (SEL_ROW_1 & (LUT_I3 ^ LUT_I3)) |
        (SEL_ROW_2 & (LUT_I4 ^ 64'h0000000000000000)) |
        (SEL_ROW_3 & (LUT_I3 ^ LUT_I4)) |
        (SEL_ROW_4 & (~LUT_I4 ^ 64'h0000000000000000)) |
        (SEL_ROW_5 & (LUT_I3 ^ ~LUT_I4)) |
        (SEL_ROW_6 & (LUT_I3 ^ ~LUT_I3)) |
        (SEL_ROW_7 & (LUT_I4 ^ ~LUT_I3));
    localparam [63:0] BIT_1_DI_INIT =
        (SEL_ROW_0 & (LUT_I3)) |
        (SEL_ROW_1 & (LUT_I3)) |
        (SEL_ROW_2 & (LUT_I4)) |
        (SEL_ROW_3 & (LUT_I3)) |
        (SEL_ROW_4 & (~LUT_I4)) |
        (SEL_ROW_5 & (LUT_I3)) |
        (SEL_ROW_6 & (LUT_I3)) |
        (SEL_ROW_7 & (LUT_I4));
    localparam [63:0] BIT_1_INIT =
        ((~LUT_I5) & BIT_1_DI_INIT) | (LUT_I5 & BIT_1_S_INIT);

    LUT6_2 #(
        .INIT(BIT_1_INIT)
    ) lut_bit_1 (
        .O6(carry_s[1]),
        .O5(carry_di[1]),
        .I0(sel[0]),
        .I1(sel[1]),
        .I2(sel[2]),
        .I3(x[1]),
        .I4(1'b0),
        .I5(1'b1)
    );

    localparam [63:0] BIT_2_S_INIT =
        (SEL_ROW_0 & (LUT_I3 ^ 64'h0000000000000000)) |
        (SEL_ROW_1 & (LUT_I3 ^ LUT_I3)) |
        (SEL_ROW_2 & (LUT_I4 ^ 64'h0000000000000000)) |
        (SEL_ROW_3 & (LUT_I3 ^ LUT_I4)) |
        (SEL_ROW_4 & (~LUT_I4 ^ 64'h0000000000000000)) |
        (SEL_ROW_5 & (LUT_I3 ^ ~LUT_I4)) |
        (SEL_ROW_6 & (LUT_I3 ^ ~LUT_I3)) |
        (SEL_ROW_7 & (LUT_I4 ^ ~LUT_I3));
    localparam [63:0] BIT_2_DI_INIT =
        (SEL_ROW_0 & (LUT_I3)) |
        (SEL_ROW_1 & (LUT_I3)) |
        (SEL_ROW_2 & (LUT_I4)) |
        (SEL_ROW_3 & (LUT_I3)) |
        (SEL_ROW_4 & (~LUT_I4)) |
        (SEL_ROW_5 & (LUT_I3)) |
        (SEL_ROW_6 & (LUT_I3)) |
        (SEL_ROW_7 & (LUT_I4));
    localparam [63:0] BIT_2_INIT =
        ((~LUT_I5) & BIT_2_DI_INIT) | (LUT_I5 & BIT_2_S_INIT);

    LUT6_2 #(
        .INIT(BIT_2_INIT)
    ) lut_bit_2 (
        .O6(carry_s[2]),
        .O5(carry_di[2]),
        .I0(sel[0]),
        .I1(sel[1]),
        .I2(sel[2]),
        .I3(x[2]),
        .I4(x[0]),
        .I5(1'b1)
    );

    localparam [63:0] BIT_3_S_INIT =
        (SEL_ROW_0 & (LUT_I3 ^ 64'h0000000000000000)) |
        (SEL_ROW_1 & (LUT_I3 ^ LUT_I3)) |
        (SEL_ROW_2 & (LUT_I4 ^ 64'h0000000000000000)) |
        (SEL_ROW_3 & (LUT_I3 ^ LUT_I4)) |
        (SEL_ROW_4 & (~LUT_I4 ^ 64'h0000000000000000)) |
        (SEL_ROW_5 & (LUT_I3 ^ ~LUT_I4)) |
        (SEL_ROW_6 & (LUT_I3 ^ ~LUT_I3)) |
        (SEL_ROW_7 & (LUT_I4 ^ ~LUT_I3));
    localparam [63:0] BIT_3_DI_INIT =
        (SEL_ROW_0 & (LUT_I3)) |
        (SEL_ROW_1 & (LUT_I3)) |
        (SEL_ROW_2 & (LUT_I4)) |
        (SEL_ROW_3 & (LUT_I3)) |
        (SEL_ROW_4 & (~LUT_I4)) |
        (SEL_ROW_5 & (LUT_I3)) |
        (SEL_ROW_6 & (LUT_I3)) |
        (SEL_ROW_7 & (LUT_I4));
    localparam [63:0] BIT_3_INIT =
        ((~LUT_I5) & BIT_3_DI_INIT) | (LUT_I5 & BIT_3_S_INIT);

    LUT6_2 #(
        .INIT(BIT_3_INIT)
    ) lut_bit_3 (
        .O6(carry_s[3]),
        .O5(carry_di[3]),
        .I0(sel[0]),
        .I1(sel[1]),
        .I2(sel[2]),
        .I3(x[2]),
        .I4(x[1]),
        .I5(1'b1)
    );

    localparam [63:0] BIT_4_S_INIT =
        (SEL_ROW_0 & (LUT_I3 ^ 64'h0000000000000000)) |
        (SEL_ROW_1 & (LUT_I3 ^ LUT_I3)) |
        (SEL_ROW_2 & (LUT_I4 ^ 64'h0000000000000000)) |
        (SEL_ROW_3 & (LUT_I3 ^ LUT_I4)) |
        (SEL_ROW_4 & (~LUT_I4 ^ 64'h0000000000000000)) |
        (SEL_ROW_5 & (LUT_I3 ^ ~LUT_I4)) |
        (SEL_ROW_6 & (LUT_I3 ^ ~LUT_I3)) |
        (SEL_ROW_7 & (LUT_I4 ^ ~LUT_I3));
    localparam [63:0] BIT_4_DI_INIT =
        (SEL_ROW_0 & (LUT_I3)) |
        (SEL_ROW_1 & (LUT_I3)) |
        (SEL_ROW_2 & (LUT_I4)) |
        (SEL_ROW_3 & (LUT_I3)) |
        (SEL_ROW_4 & (~LUT_I4)) |
        (SEL_ROW_5 & (LUT_I3)) |
        (SEL_ROW_6 & (LUT_I3)) |
        (SEL_ROW_7 & (LUT_I4));
    localparam [63:0] BIT_4_INIT =
        ((~LUT_I5) & BIT_4_DI_INIT) | (LUT_I5 & BIT_4_S_INIT);

    LUT6_2 #(
        .INIT(BIT_4_INIT)
    ) lut_bit_4 (
        .O6(carry_s[4]),
        .O5(carry_di[4]),
        .I0(sel[0]),
        .I1(sel[1]),
        .I2(sel[2]),
        .I3(x[2]),
        .I4(x[2]),
        .I5(1'b1)
    );

    localparam [63:0] BIT_5_S_INIT =
        (SEL_ROW_0 & (LUT_I3 ^ 64'h0000000000000000)) |
        (SEL_ROW_1 & (LUT_I3 ^ LUT_I3)) |
        (SEL_ROW_2 & (LUT_I4 ^ 64'h0000000000000000)) |
        (SEL_ROW_3 & (LUT_I3 ^ LUT_I4)) |
        (SEL_ROW_4 & (~LUT_I4 ^ 64'h0000000000000000)) |
        (SEL_ROW_5 & (LUT_I3 ^ ~LUT_I4)) |
        (SEL_ROW_6 & (LUT_I3 ^ ~LUT_I3)) |
        (SEL_ROW_7 & (LUT_I4 ^ ~LUT_I3));
    localparam [63:0] BIT_5_DI_INIT =
        (SEL_ROW_0 & (LUT_I3)) |
        (SEL_ROW_1 & (LUT_I3)) |
        (SEL_ROW_2 & (LUT_I4)) |
        (SEL_ROW_3 & (LUT_I3)) |
        (SEL_ROW_4 & (~LUT_I4)) |
        (SEL_ROW_5 & (LUT_I3)) |
        (SEL_ROW_6 & (LUT_I3)) |
        (SEL_ROW_7 & (LUT_I4));
    localparam [63:0] BIT_5_INIT =
        ((~LUT_I5) & BIT_5_DI_INIT) | (LUT_I5 & BIT_5_S_INIT);

    LUT6_2 #(
        .INIT(BIT_5_INIT)
    ) lut_bit_5 (
        .O6(carry_s[5]),
        .O5(carry_di[5]),
        .I0(sel[0]),
        .I1(sel[1]),
        .I2(sel[2]),
        .I3(x[2]),
        .I4(x[2]),
        .I5(1'b1)
    );

    assign carry_s[6] = 1'b0;
    assign carry_di[6] = 1'b0;
    assign carry_s[7] = 1'b0;
    assign carry_di[7] = 1'b0;

    CARRY4 carry_0 (
        .CO(carry_co[3:0]),
        .O(carry_o[3:0]),
        .CI(1'b0),
        .CYINIT(carry_init),
        .DI(carry_di[3:0]),
        .S(carry_s[3:0])
    );

    CARRY4 carry_1 (
        .CO(carry_co[7:4]),
        .O(carry_o[7:4]),
        .CI(carry_co[3]),
        .CYINIT(1'b0),
        .DI(carry_di[7:4]),
        .S(carry_s[7:4])
    );

    assign y = carry_o[5:0];

endmodule
