`timescale 1ns/1ps

module lut6_2_carry_2dd_multiplier_tb;
    localparam integer INPUT_BW = 4;
    localparam integer OUTPUT_BW = 8;
    localparam integer SEL_BITS = 4;
    localparam integer N_COEFFS = 16;

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
                0: coeff_for_sel = -12;
                1: coeff_for_sel = -15;
                2: coeff_for_sel = 4;
                3: coeff_for_sel = -9;
                4: coeff_for_sel = -4;
                5: coeff_for_sel = -5;
                6: coeff_for_sel = 2;
                7: coeff_for_sel = -3;
                8: coeff_for_sel = 8;
                9: coeff_for_sel = 10;
                10: coeff_for_sel = -1;
                11: coeff_for_sel = 6;
                12: coeff_for_sel = 12;
                13: coeff_for_sel = 15;
                14: coeff_for_sel = -2;
                15: coeff_for_sel = 9;
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
        for (xi = -8; xi <= 7; xi = xi + 1) begin
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
                     16 * N_COEFFS, 16 * N_COEFFS);
        end else begin
            $display("SUMMARY pass=%0d fail=%0d total=%0d",
                     (16 * N_COEFFS) - errors, errors, 16 * N_COEFFS);
        end
        $finish;
    end
endmodule
