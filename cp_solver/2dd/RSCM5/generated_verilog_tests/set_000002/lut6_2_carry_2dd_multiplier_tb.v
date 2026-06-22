`timescale 1ns/1ps

module lut6_2_carry_2dd_multiplier_tb;
    localparam integer INPUT_BW = 5;
    localparam integer OUTPUT_BW = 10;
    localparam integer SEL_BITS = 5;
    localparam integer N_COEFFS = 32;

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
                0: coeff_for_sel = 5;
                1: coeff_for_sel = 6;
                2: coeff_for_sel = -4;
                3: coeff_for_sel = 3;
                4: coeff_for_sel = 9;
                5: coeff_for_sel = 10;
                6: coeff_for_sel = -8;
                7: coeff_for_sel = 7;
                8: coeff_for_sel = 17;
                9: coeff_for_sel = 18;
                10: coeff_for_sel = -16;
                11: coeff_for_sel = 15;
                12: coeff_for_sel = 21;
                13: coeff_for_sel = 22;
                14: coeff_for_sel = -20;
                15: coeff_for_sel = 19;
                16: coeff_for_sel = -15;
                17: coeff_for_sel = -14;
                18: coeff_for_sel = 16;
                19: coeff_for_sel = -17;
                20: coeff_for_sel = -11;
                21: coeff_for_sel = -10;
                22: coeff_for_sel = 12;
                23: coeff_for_sel = -13;
                24: coeff_for_sel = -3;
                25: coeff_for_sel = -2;
                26: coeff_for_sel = 4;
                27: coeff_for_sel = -5;
                28: coeff_for_sel = 1;
                29: coeff_for_sel = 2;
                30: coeff_for_sel = 0;
                31: coeff_for_sel = -1;
                default: coeff_for_sel = 0;
            endcase
        end
    endfunction

    lut6_2_carry_2dd_multiplier dut (
        .x(x),
        .sel(sel),
        .y(y)
    );

    initial begin
        errors = 0;
        for (xi = -16; xi <= 15; xi = xi + 1) begin
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
                end else begin
                    $display("TEST x=%0d sel=%0d coeff=%0d expected=%0d simulated=%0d PASS",
                             xi, si, coeff_for_sel(si), expected_y, $signed(y));
                end
            end
        end
        if (errors == 0) begin
            $display("SUMMARY pass=%0d fail=0 total=%0d",
                     32 * N_COEFFS, 32 * N_COEFFS);
        end else begin
            $display("SUMMARY pass=%0d fail=%0d total=%0d",
                     (32 * N_COEFFS) - errors, errors, 32 * N_COEFFS);
        end
        $finish;
    end
endmodule
