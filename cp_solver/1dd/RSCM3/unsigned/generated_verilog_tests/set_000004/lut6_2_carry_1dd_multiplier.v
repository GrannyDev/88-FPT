`timescale 1ns/1ps
// Structural translation of the accompanying flopoco.vhdl.
// LUT INIT values, signal widths, shifts and primitive connections preserved.
// Authors: Bastien Barbe, Florent de Dinechin (2026)
module lut6_2_carry_1dd_multiplier (
    input wire [2:0] x,
    input wire [2:0] sel,
    output wire signed [6:0] y
);
wire [4:0] a_shift2;
wire [2:0] y_sel;
wire [7:0] y_s;
wire [7:0] y_di;
wire [7:0] y_carry_co;
wire [7:0] y_carry_o;
wire y_carry_in;
assign a_shift2 = ({{2{1'b0}}, x} << 2);
assign y_sel = sel[2:0];
assign y_s[7] = 1'b0;
assign y_di[7] = 1'b0;
assign y_carry_in = y_sel[2];
assign y = y_carry_o[6:0];
LUT6_2 #(.INIT(64'hE54C59F0CFC43B30)) y_lut_0 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(y_sel[2]), .I3(x[0]), .I4(a_shift2[0]), .I5(1'b1), .O5(y_di[0]), .O6(y_s[0]));
LUT6_2 #(.INIT(64'hE54C59F0CFC43B30)) y_lut_1 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(y_sel[2]), .I3(x[1]), .I4(a_shift2[1]), .I5(1'b1), .O5(y_di[1]), .O6(y_s[1]));
LUT6_2 #(.INIT(64'hE54C59F0CFC43B30)) y_lut_2 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(y_sel[2]), .I3(x[2]), .I4(a_shift2[2]), .I5(1'b1), .O5(y_di[2]), .O6(y_s[2]));
LUT6_2 #(.INIT(64'hE54C59F0CFC43B30)) y_lut_3 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(y_sel[2]), .I3(1'b0), .I4(a_shift2[3]), .I5(1'b1), .O5(y_di[3]), .O6(y_s[3]));
LUT6_2 #(.INIT(64'hE54C59F0CFC43B30)) y_lut_4 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(y_sel[2]), .I3(1'b0), .I4(a_shift2[4]), .I5(1'b1), .O5(y_di[4]), .O6(y_s[4]));
LUT6_2 #(.INIT(64'hE54C59F0CFC43B30)) y_lut_5 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(y_sel[2]), .I3(1'b0), .I4(1'b0), .I5(1'b1), .O5(y_di[5]), .O6(y_s[5]));
LUT6_2 #(.INIT(64'hE54C59F0CFC43B30)) y_lut_6 (.I0(y_sel[0]), .I1(y_sel[1]), .I2(y_sel[2]), .I3(1'b0), .I4(1'b0), .I5(1'b1), .O5(y_di[6]), .O6(y_s[6]));
CARRY4 y_carry4_0 (.CI(1'b0), .CYINIT(y_carry_in), .DI(y_di[3:0]), .S(y_s[3:0]), .CO(y_carry_co[3:0]), .O(y_carry_o[3:0]));
CARRY4 y_carry4_1 (.CI(y_carry_co[3]), .CYINIT(1'b0), .DI(y_di[7:4]), .S(y_s[7:4]), .CO(y_carry_co[7:4]), .O(y_carry_o[7:4]));
endmodule
