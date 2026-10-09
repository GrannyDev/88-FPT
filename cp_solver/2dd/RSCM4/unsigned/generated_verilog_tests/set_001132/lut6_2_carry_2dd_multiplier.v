`timescale 1ns/1ps
// Structural translation of the accompanying flopoco.vhdl.
// LUT INIT values, signal widths, shifts and primitive connections preserved.
// Authors: Bastien Barbe, Florent de Dinechin (2026)
module lut6_2_carry_2dd_multiplier (
    input wire [3:0] x,
    input wire [3:0] sel,
    output wire signed [8:0] y
);
wire [6:0] adder_1_o;
wire [4:0] a_shift1;
wire [5:0] a_shift2;
wire [8:0] adder_1_o_shift2;
wire [1:0] adder_1_o_sel;
wire [7:0] adder_1_o_s;
wire [7:0] adder_1_o_di;
wire [7:0] adder_1_o_carry_co;
wire [7:0] adder_1_o_carry_o;
wire adder_1_o_carry_in;
wire [1:0] y_sel;
wire [11:0] y_s;
wire [11:0] y_di;
wire [11:0] y_carry_co;
wire [11:0] y_carry_o;
wire y_carry_in;
assign a_shift1 = ({{1{1'b0}}, x} << 1);
assign a_shift2 = ({{2{1'b0}}, x} << 2);
assign adder_1_o_shift2 = ({{2{adder_1_o[6]}}, adder_1_o} << 2);
assign adder_1_o_sel = sel[3:2];
assign adder_1_o_s[7] = 1'b0;
assign adder_1_o_di[7] = 1'b0;
assign adder_1_o_carry_in = 1'b1;
assign adder_1_o = adder_1_o_carry_o[6:0];
assign y_sel = sel[1:0];
assign y_s[9] = 1'b0;
assign y_di[9] = 1'b0;
assign y_s[10] = 1'b0;
assign y_di[10] = 1'b0;
assign y_s[11] = 1'b0;
assign y_di[11] = 1'b0;
assign y_carry_in = y_sel[1];
assign y = y_carry_o[8:0];
LUT6_2 #(.INIT(64'h56DE47CFCE469B13)) adder_1_o_lut_0 (.I0(adder_1_o_sel[0]), .I1(adder_1_o_sel[1]), .I2(x[0]), .I3(a_shift1[0]), .I4(a_shift2[0]), .I5(1'b1), .O5(adder_1_o_di[0]), .O6(adder_1_o_s[0]));
LUT6_2 #(.INIT(64'h56DE47CFCE469B13)) adder_1_o_lut_1 (.I0(adder_1_o_sel[0]), .I1(adder_1_o_sel[1]), .I2(x[1]), .I3(a_shift1[1]), .I4(a_shift2[1]), .I5(1'b1), .O5(adder_1_o_di[1]), .O6(adder_1_o_s[1]));
LUT6_2 #(.INIT(64'h56DE47CFCE469B13)) adder_1_o_lut_2 (.I0(adder_1_o_sel[0]), .I1(adder_1_o_sel[1]), .I2(x[2]), .I3(a_shift1[2]), .I4(a_shift2[2]), .I5(1'b1), .O5(adder_1_o_di[2]), .O6(adder_1_o_s[2]));
LUT6_2 #(.INIT(64'h56DE47CFCE469B13)) adder_1_o_lut_3 (.I0(adder_1_o_sel[0]), .I1(adder_1_o_sel[1]), .I2(x[3]), .I3(a_shift1[3]), .I4(a_shift2[3]), .I5(1'b1), .O5(adder_1_o_di[3]), .O6(adder_1_o_s[3]));
LUT6_2 #(.INIT(64'h56DE47CFCE469B13)) adder_1_o_lut_4 (.I0(adder_1_o_sel[0]), .I1(adder_1_o_sel[1]), .I2(1'b0), .I3(a_shift1[4]), .I4(a_shift2[4]), .I5(1'b1), .O5(adder_1_o_di[4]), .O6(adder_1_o_s[4]));
LUT6_2 #(.INIT(64'h56DE47CFCE469B13)) adder_1_o_lut_5 (.I0(adder_1_o_sel[0]), .I1(adder_1_o_sel[1]), .I2(1'b0), .I3(1'b0), .I4(a_shift2[5]), .I5(1'b1), .O5(adder_1_o_di[5]), .O6(adder_1_o_s[5]));
LUT6_2 #(.INIT(64'h56DE47CFCE469B13)) adder_1_o_lut_6 (.I0(adder_1_o_sel[0]), .I1(adder_1_o_sel[1]), .I2(1'b0), .I3(1'b0), .I4(1'b0), .I5(1'b1), .O5(adder_1_o_di[6]), .O6(adder_1_o_s[6]));
CARRY4 adder_1_o_carry4_0 (.CI(1'b0), .CYINIT(adder_1_o_carry_in), .DI(adder_1_o_di[3:0]), .S(adder_1_o_s[3:0]), .CO(adder_1_o_carry_co[3:0]), .O(adder_1_o_carry_o[3:0]));
CARRY4 adder_1_o_carry4_1 (.CI(adder_1_o_carry_co[3]), .CYINIT(1'b0), .DI(adder_1_o_di[7:4]), .S(adder_1_o_s[7:4]), .CO(adder_1_o_carry_co[7:4]), .O(adder_1_o_carry_o[7:4]));
LUT6_2 #(.INIT(64'hD793286C7D396C28)) y_lut_0 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(x[0]), .I3(a_shift1[0]), .I4(adder_1_o_shift2[0]), .I5(1'b1), .O5(y_di[0]), .O6(y_s[0]));
LUT6_2 #(.INIT(64'hD793286C7D396C28)) y_lut_1 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(x[1]), .I3(a_shift1[1]), .I4(adder_1_o_shift2[1]), .I5(1'b1), .O5(y_di[1]), .O6(y_s[1]));
LUT6_2 #(.INIT(64'hD793286C7D396C28)) y_lut_2 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(x[2]), .I3(a_shift1[2]), .I4(adder_1_o_shift2[2]), .I5(1'b1), .O5(y_di[2]), .O6(y_s[2]));
LUT6_2 #(.INIT(64'hD793286C7D396C28)) y_lut_3 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(x[3]), .I3(a_shift1[3]), .I4(adder_1_o_shift2[3]), .I5(1'b1), .O5(y_di[3]), .O6(y_s[3]));
LUT6_2 #(.INIT(64'hD793286C7D396C28)) y_lut_4 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(1'b0), .I3(a_shift1[4]), .I4(adder_1_o_shift2[4]), .I5(1'b1), .O5(y_di[4]), .O6(y_s[4]));
LUT6_2 #(.INIT(64'hD793286C7D396C28)) y_lut_5 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(1'b0), .I3(1'b0), .I4(adder_1_o_shift2[5]), .I5(1'b1), .O5(y_di[5]), .O6(y_s[5]));
LUT6_2 #(.INIT(64'hD793286C7D396C28)) y_lut_6 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(1'b0), .I3(1'b0), .I4(adder_1_o_shift2[6]), .I5(1'b1), .O5(y_di[6]), .O6(y_s[6]));
LUT6_2 #(.INIT(64'hD793286C7D396C28)) y_lut_7 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(1'b0), .I3(1'b0), .I4(adder_1_o_shift2[7]), .I5(1'b1), .O5(y_di[7]), .O6(y_s[7]));
LUT6_2 #(.INIT(64'hD793286C7D396C28)) y_lut_8 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(1'b0), .I3(1'b0), .I4(adder_1_o_shift2[8]), .I5(1'b1), .O5(y_di[8]), .O6(y_s[8]));
CARRY4 y_carry4_0 (.CI(1'b0), .CYINIT(y_carry_in), .DI(y_di[3:0]), .S(y_s[3:0]), .CO(y_carry_co[3:0]), .O(y_carry_o[3:0]));
CARRY4 y_carry4_1 (.CI(y_carry_co[3]), .CYINIT(1'b0), .DI(y_di[7:4]), .S(y_s[7:4]), .CO(y_carry_co[7:4]), .O(y_carry_o[7:4]));
CARRY4 y_carry4_2 (.CI(y_carry_co[7]), .CYINIT(1'b0), .DI(y_di[11:8]), .S(y_s[11:8]), .CO(y_carry_co[11:8]), .O(y_carry_o[11:8]));
endmodule
