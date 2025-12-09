`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.12.2025 14:01:52
// Design Name: 
// Module Name: tb_fir16
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


// tb_fir16.sv


module tb_fir16;

    logic clk, rst_n;
    logic in_valid;
    logic signed [15:0] in_sample;

    logic out_valid;
    logic signed [15:0] out_sample;

    // DUT
    fir16_core dut (
        .clk(clk),
        .rst_n(rst_n),
        .in_valid(in_valid),
        .in_sample(in_sample),
        .out_valid(out_valid),
        .out_sample(out_sample)
    );

    // Clock
    initial clk = 0;
    always #5 clk = ~clk;  // 100 MHz

    // Reset
    initial begin
        rst_n = 0;
        in_valid = 0;
        in_sample = 0;
        repeat (10) @(posedge clk);
        rst_n = 1;
    end

    // ------------------------------------------------------------
    // Golden Model (Software FIR)
    // ------------------------------------------------------------
    integer idx;
    logic signed [31:0] gold_mem[0:1023];
    integer count = 0;

    // same coeffs as core
    logic signed [15:0] coeff[0:15] = '{
        16'sh0200, 16'sh0400, 16'sh0800, 16'sh1000,
        16'sh2000, 16'sh3000, 16'sh2000, 16'sh1000,
        16'sh0800, 16'sh0400, 16'sh0200, 16'sh0100,
        16'sh0080, 16'sh0040, 16'sh0020, 16'sh0010
    };

    logic signed [15:0] hist[0:15];

    task golden_update(input logic signed [15:0] x);
        integer i;
        integer j;
        logic signed [35:0] sum;
        begin
            // shift history
            hist[0] = x;
            for (i = 15; i > 0; i--)
                hist[i] = hist[i-1];

            // dot product
            sum = 0;
            for (j = 0; j < 16; j++)
                sum += hist[j] * coeff[j];

            gold_mem[count] = sum[30:15];
            count++;
        end
    endtask

    // ------------------------------------------------------------
    // Stimulus
    // ------------------------------------------------------------
    initial begin
        @(posedge rst_n);

        // Impulse test: x[0]=1, rest=0
        in_valid = 1;
        in_sample = 16'sh4000; // 0.5 in Q1.15
        golden_update(in_sample);

        @(posedge clk);
        in_sample = 0;

        repeat (40) begin
            @(posedge clk);
            golden_update(in_sample);
        end

        // Random test
        repeat (100) begin
            @(posedge clk);
            in_sample = $random;
            golden_update(in_sample);
        end

        in_valid = 0;

        repeat (100) @(posedge clk);

        $finish;
    end

    // ------------------------------------------------------------
    // Compare DUT vs Golden
    // ------------------------------------------------------------
    integer k = 0;
    always_ff @(posedge clk) begin
        if (out_valid) begin
            if (out_sample !== gold_mem[k]) begin
                $display("MISMATCH @ %0d: DUT=%0d GOLD=%0d", k, out_sample, gold_mem[k]);
            end else begin
                $display("OK @ %0d: %0d", k, out_sample);
            end
            k++;
        end
    end

endmodule


