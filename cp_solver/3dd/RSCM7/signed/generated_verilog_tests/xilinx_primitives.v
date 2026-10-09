`timescale 1ns/1ps
// Functional Xilinx LUT and carry models; no propagation delays.
module LUT6 #(parameter [63:0] INIT = 64'b0)
(input I0,I1,I2,I3,I4,I5, output O);
assign O = INIT[{I5,I4,I3,I2,I1,I0}];
endmodule
module LUT6_2 #(parameter [63:0] INIT = 64'b0)
(input I0,I1,I2,I3,I4,I5, output O5,O6);
assign O5 = INIT[{1'b0,I4,I3,I2,I1,I0}];
assign O6 = INIT[{I5,I4,I3,I2,I1,I0}];
endmodule
module CARRY4 (input CI,CYINIT, input [3:0] DI,S, output [3:0] CO,O);
wire [4:0] carry;
assign carry[0] = CI | CYINIT;
genvar i;
generate for (i=0;i<4;i=i+1) begin: chain
assign O[i] = S[i] ^ carry[i];
assign carry[i+1] = S[i] ? carry[i] : DI[i];
end endgenerate
assign CO = carry[4:1];
endmodule
