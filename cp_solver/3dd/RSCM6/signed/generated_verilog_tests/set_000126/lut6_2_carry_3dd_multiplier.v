`timescale 1ns/1ps
// Structural translation of the accompanying flopoco.vhdl.
// LUT INIT values, signal widths, shifts and primitive connections preserved.
// Authors: Bastien Barbe, Florent de Dinechin (2026)
module lut6_2_carry_3dd_multiplier (
    input wire signed [5:0] x,
    input wire [5:0] sel,
    output wire signed [11:0] y
);
wire [8:0] left_adder_1_o;
wire [7:0] right_adder_1_o;
wire [6:0] a_shift1;
wire [7:0] a_shift2;
wire [8:0] a_shift3;
wire [10:0] left_adder_1_o_shift2;
wire [11:0] left_adder_1_o_shift3;
wire [1:0] left_adder_1_o_sel;
wire [11:0] left_adder_1_o_s;
wire [11:0] left_adder_1_o_di;
wire [11:0] left_adder_1_o_carry_co;
wire [11:0] left_adder_1_o_carry_o;
wire left_adder_1_o_carry_in;
wire [1:0] right_adder_1_o_sel;
wire [7:0] right_adder_1_o_s;
wire [7:0] right_adder_1_o_di;
wire [7:0] right_adder_1_o_carry_co;
wire [7:0] right_adder_1_o_carry_o;
wire right_adder_1_o_carry_in;
wire [1:0] y_sel;
wire [11:0] y_s;
wire [11:0] y_di;
wire [11:0] y_carry_co;
wire [11:0] y_carry_o;
wire y_carry_in;
assign a_shift1 = ({{1{x[5]}}, x} << 1);
assign a_shift2 = ({{2{x[5]}}, x} << 2);
assign a_shift3 = ({{3{x[5]}}, x} << 3);
assign left_adder_1_o_shift2 = ({{2{left_adder_1_o[8]}}, left_adder_1_o} << 2);
assign left_adder_1_o_shift3 = ({{3{left_adder_1_o[8]}}, left_adder_1_o} << 3);
assign left_adder_1_o_sel = sel[5:4];
assign left_adder_1_o_s[9] = 1'b0;
assign left_adder_1_o_di[9] = 1'b0;
assign left_adder_1_o_s[10] = 1'b0;
assign left_adder_1_o_di[10] = 1'b0;
assign left_adder_1_o_s[11] = 1'b0;
assign left_adder_1_o_di[11] = 1'b0;
assign left_adder_1_o_carry_in = left_adder_1_o_sel[1];
assign left_adder_1_o = left_adder_1_o_carry_o[8:0];
assign right_adder_1_o_sel = sel[3:2];
assign right_adder_1_o_carry_in = 1'b1;
assign right_adder_1_o = right_adder_1_o_carry_o[7:0];
assign y_sel = sel[1:0];
assign y_carry_in = 1'b1;
assign y = y_carry_o[11:0];
LUT6_2 #(.INIT(64'h97A41F2CBF8C3704)) left_adder_1_o_lut_0 (.I0(left_adder_1_o_sel[0]), .I1(left_adder_1_o_sel[1]), .I2(x[0]), .I3(a_shift2[0]), .I4(a_shift3[0]), .I5(1'b1), .O5(left_adder_1_o_di[0]), .O6(left_adder_1_o_s[0]));
LUT6_2 #(.INIT(64'h97A41F2CBF8C3704)) left_adder_1_o_lut_1 (.I0(left_adder_1_o_sel[0]), .I1(left_adder_1_o_sel[1]), .I2(x[1]), .I3(a_shift2[1]), .I4(a_shift3[1]), .I5(1'b1), .O5(left_adder_1_o_di[1]), .O6(left_adder_1_o_s[1]));
LUT6_2 #(.INIT(64'h97A41F2CBF8C3704)) left_adder_1_o_lut_2 (.I0(left_adder_1_o_sel[0]), .I1(left_adder_1_o_sel[1]), .I2(x[2]), .I3(a_shift2[2]), .I4(a_shift3[2]), .I5(1'b1), .O5(left_adder_1_o_di[2]), .O6(left_adder_1_o_s[2]));
LUT6_2 #(.INIT(64'h97A41F2CBF8C3704)) left_adder_1_o_lut_3 (.I0(left_adder_1_o_sel[0]), .I1(left_adder_1_o_sel[1]), .I2(x[3]), .I3(a_shift2[3]), .I4(a_shift3[3]), .I5(1'b1), .O5(left_adder_1_o_di[3]), .O6(left_adder_1_o_s[3]));
LUT6_2 #(.INIT(64'h97A41F2CBF8C3704)) left_adder_1_o_lut_4 (.I0(left_adder_1_o_sel[0]), .I1(left_adder_1_o_sel[1]), .I2(x[4]), .I3(a_shift2[4]), .I4(a_shift3[4]), .I5(1'b1), .O5(left_adder_1_o_di[4]), .O6(left_adder_1_o_s[4]));
LUT6_2 #(.INIT(64'h97A41F2CBF8C3704)) left_adder_1_o_lut_5 (.I0(left_adder_1_o_sel[0]), .I1(left_adder_1_o_sel[1]), .I2(x[5]), .I3(a_shift2[5]), .I4(a_shift3[5]), .I5(1'b1), .O5(left_adder_1_o_di[5]), .O6(left_adder_1_o_s[5]));
LUT6_2 #(.INIT(64'h97A41F2CBF8C3704)) left_adder_1_o_lut_6 (.I0(left_adder_1_o_sel[0]), .I1(left_adder_1_o_sel[1]), .I2(x[5]), .I3(a_shift2[6]), .I4(a_shift3[6]), .I5(1'b1), .O5(left_adder_1_o_di[6]), .O6(left_adder_1_o_s[6]));
LUT6_2 #(.INIT(64'h97A41F2CBF8C3704)) left_adder_1_o_lut_7 (.I0(left_adder_1_o_sel[0]), .I1(left_adder_1_o_sel[1]), .I2(x[5]), .I3(a_shift2[7]), .I4(a_shift3[7]), .I5(1'b1), .O5(left_adder_1_o_di[7]), .O6(left_adder_1_o_s[7]));
LUT6_2 #(.INIT(64'h97A41F2CBF8C3704)) left_adder_1_o_lut_8 (.I0(left_adder_1_o_sel[0]), .I1(left_adder_1_o_sel[1]), .I2(x[5]), .I3(a_shift2[7]), .I4(a_shift3[8]), .I5(1'b1), .O5(left_adder_1_o_di[8]), .O6(left_adder_1_o_s[8]));
CARRY4 left_adder_1_o_carry4_0 (.CI(1'b0), .CYINIT(left_adder_1_o_carry_in), .DI(left_adder_1_o_di[3:0]), .S(left_adder_1_o_s[3:0]), .CO(left_adder_1_o_carry_co[3:0]), .O(left_adder_1_o_carry_o[3:0]));
CARRY4 left_adder_1_o_carry4_1 (.CI(left_adder_1_o_carry_co[3]), .CYINIT(1'b0), .DI(left_adder_1_o_di[7:4]), .S(left_adder_1_o_s[7:4]), .CO(left_adder_1_o_carry_co[7:4]), .O(left_adder_1_o_carry_o[7:4]));
CARRY4 left_adder_1_o_carry4_2 (.CI(left_adder_1_o_carry_co[7]), .CYINIT(1'b0), .DI(left_adder_1_o_di[11:8]), .S(left_adder_1_o_s[11:8]), .CO(left_adder_1_o_carry_co[11:8]), .O(left_adder_1_o_carry_o[11:8]));
LUT6_2 #(.INIT(64'hFA9CC9AF6240FBD9)) right_adder_1_o_lut_0 (.I0(right_adder_1_o_sel[0]), .I1(right_adder_1_o_sel[1]), .I2(x[0]), .I3(a_shift1[0]), .I4(a_shift2[0]), .I5(1'b1), .O5(right_adder_1_o_di[0]), .O6(right_adder_1_o_s[0]));
LUT6_2 #(.INIT(64'hFA9CC9AF6240FBD9)) right_adder_1_o_lut_1 (.I0(right_adder_1_o_sel[0]), .I1(right_adder_1_o_sel[1]), .I2(x[1]), .I3(a_shift1[1]), .I4(a_shift2[1]), .I5(1'b1), .O5(right_adder_1_o_di[1]), .O6(right_adder_1_o_s[1]));
LUT6_2 #(.INIT(64'hFA9CC9AF6240FBD9)) right_adder_1_o_lut_2 (.I0(right_adder_1_o_sel[0]), .I1(right_adder_1_o_sel[1]), .I2(x[2]), .I3(a_shift1[2]), .I4(a_shift2[2]), .I5(1'b1), .O5(right_adder_1_o_di[2]), .O6(right_adder_1_o_s[2]));
LUT6_2 #(.INIT(64'hFA9CC9AF6240FBD9)) right_adder_1_o_lut_3 (.I0(right_adder_1_o_sel[0]), .I1(right_adder_1_o_sel[1]), .I2(x[3]), .I3(a_shift1[3]), .I4(a_shift2[3]), .I5(1'b1), .O5(right_adder_1_o_di[3]), .O6(right_adder_1_o_s[3]));
LUT6_2 #(.INIT(64'hFA9CC9AF6240FBD9)) right_adder_1_o_lut_4 (.I0(right_adder_1_o_sel[0]), .I1(right_adder_1_o_sel[1]), .I2(x[4]), .I3(a_shift1[4]), .I4(a_shift2[4]), .I5(1'b1), .O5(right_adder_1_o_di[4]), .O6(right_adder_1_o_s[4]));
LUT6_2 #(.INIT(64'hFA9CC9AF6240FBD9)) right_adder_1_o_lut_5 (.I0(right_adder_1_o_sel[0]), .I1(right_adder_1_o_sel[1]), .I2(x[5]), .I3(a_shift1[5]), .I4(a_shift2[5]), .I5(1'b1), .O5(right_adder_1_o_di[5]), .O6(right_adder_1_o_s[5]));
LUT6_2 #(.INIT(64'hFA9CC9AF6240FBD9)) right_adder_1_o_lut_6 (.I0(right_adder_1_o_sel[0]), .I1(right_adder_1_o_sel[1]), .I2(x[5]), .I3(a_shift1[6]), .I4(a_shift2[6]), .I5(1'b1), .O5(right_adder_1_o_di[6]), .O6(right_adder_1_o_s[6]));
LUT6_2 #(.INIT(64'hFA9CC9AF6240FBD9)) right_adder_1_o_lut_7 (.I0(right_adder_1_o_sel[0]), .I1(right_adder_1_o_sel[1]), .I2(x[5]), .I3(a_shift1[6]), .I4(a_shift2[7]), .I5(1'b1), .O5(right_adder_1_o_di[7]), .O6(right_adder_1_o_s[7]));
CARRY4 right_adder_1_o_carry4_0 (.CI(1'b0), .CYINIT(right_adder_1_o_carry_in), .DI(right_adder_1_o_di[3:0]), .S(right_adder_1_o_s[3:0]), .CO(right_adder_1_o_carry_co[3:0]), .O(right_adder_1_o_carry_o[3:0]));
CARRY4 right_adder_1_o_carry4_1 (.CI(right_adder_1_o_carry_co[3]), .CYINIT(1'b0), .DI(right_adder_1_o_di[7:4]), .S(right_adder_1_o_s[7:4]), .CO(right_adder_1_o_carry_co[7:4]), .O(right_adder_1_o_carry_o[7:4]));
LUT6_2 #(.INIT(64'hF960069FCA53CA53)) y_lut_0 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(left_adder_1_o_shift2[0]), .I3(left_adder_1_o_shift3[0]), .I4(right_adder_1_o[0]), .I5(1'b1), .O5(y_di[0]), .O6(y_s[0]));
LUT6_2 #(.INIT(64'hF960069FCA53CA53)) y_lut_1 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(left_adder_1_o_shift2[1]), .I3(left_adder_1_o_shift3[1]), .I4(right_adder_1_o[1]), .I5(1'b1), .O5(y_di[1]), .O6(y_s[1]));
LUT6_2 #(.INIT(64'hF960069FCA53CA53)) y_lut_2 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(left_adder_1_o_shift2[2]), .I3(left_adder_1_o_shift3[2]), .I4(right_adder_1_o[2]), .I5(1'b1), .O5(y_di[2]), .O6(y_s[2]));
LUT6_2 #(.INIT(64'hF960069FCA53CA53)) y_lut_3 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(left_adder_1_o_shift2[3]), .I3(left_adder_1_o_shift3[3]), .I4(right_adder_1_o[3]), .I5(1'b1), .O5(y_di[3]), .O6(y_s[3]));
LUT6_2 #(.INIT(64'hF960069FCA53CA53)) y_lut_4 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(left_adder_1_o_shift2[4]), .I3(left_adder_1_o_shift3[4]), .I4(right_adder_1_o[4]), .I5(1'b1), .O5(y_di[4]), .O6(y_s[4]));
LUT6_2 #(.INIT(64'hF960069FCA53CA53)) y_lut_5 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(left_adder_1_o_shift2[5]), .I3(left_adder_1_o_shift3[5]), .I4(right_adder_1_o[5]), .I5(1'b1), .O5(y_di[5]), .O6(y_s[5]));
LUT6_2 #(.INIT(64'hF960069FCA53CA53)) y_lut_6 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(left_adder_1_o_shift2[6]), .I3(left_adder_1_o_shift3[6]), .I4(right_adder_1_o[6]), .I5(1'b1), .O5(y_di[6]), .O6(y_s[6]));
LUT6_2 #(.INIT(64'hF960069FCA53CA53)) y_lut_7 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(left_adder_1_o_shift2[7]), .I3(left_adder_1_o_shift3[7]), .I4(right_adder_1_o[7]), .I5(1'b1), .O5(y_di[7]), .O6(y_s[7]));
LUT6_2 #(.INIT(64'hF960069FCA53CA53)) y_lut_8 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(left_adder_1_o_shift2[8]), .I3(left_adder_1_o_shift3[8]), .I4(right_adder_1_o[7]), .I5(1'b1), .O5(y_di[8]), .O6(y_s[8]));
LUT6_2 #(.INIT(64'hF960069FCA53CA53)) y_lut_9 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(left_adder_1_o_shift2[9]), .I3(left_adder_1_o_shift3[9]), .I4(right_adder_1_o[7]), .I5(1'b1), .O5(y_di[9]), .O6(y_s[9]));
LUT6_2 #(.INIT(64'hF960069FCA53CA53)) y_lut_10 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(left_adder_1_o_shift2[10]), .I3(left_adder_1_o_shift3[10]), .I4(right_adder_1_o[7]), .I5(1'b1), .O5(y_di[10]), .O6(y_s[10]));
LUT6_2 #(.INIT(64'hF960069FCA53CA53)) y_lut_11 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(left_adder_1_o_shift2[10]), .I3(left_adder_1_o_shift3[11]), .I4(right_adder_1_o[7]), .I5(1'b1), .O5(y_di[11]), .O6(y_s[11]));
CARRY4 y_carry4_0 (.CI(1'b0), .CYINIT(y_carry_in), .DI(y_di[3:0]), .S(y_s[3:0]), .CO(y_carry_co[3:0]), .O(y_carry_o[3:0]));
CARRY4 y_carry4_1 (.CI(y_carry_co[3]), .CYINIT(1'b0), .DI(y_di[7:4]), .S(y_s[7:4]), .CO(y_carry_co[7:4]), .O(y_carry_o[7:4]));
CARRY4 y_carry4_2 (.CI(y_carry_co[7]), .CYINIT(1'b0), .DI(y_di[11:8]), .S(y_s[11:8]), .CO(y_carry_co[11:8]), .O(y_carry_o[11:8]));
endmodule
