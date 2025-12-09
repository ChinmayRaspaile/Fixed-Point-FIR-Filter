`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.12.2025 13:58:33
// Design Name: 
// Module Name: fir16_core
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


// fir16_core.sv
// 16-tap fully pipelined fixed-point FIR filter
// Input: 16-bit signed (Q1.15), Output: 16-bit signed (Q1.15 equivalent)

module fir16_core #(
    parameter TAPS = 16
)(
    input  logic               clk,
    input  logic               rst_n,

    input  logic               in_valid,
    input  logic signed [15:0] in_sample,

    output logic               out_valid,
    output logic signed [15:0] out_sample
);

    // ------------------------------------------------------------
    // Coefficients (Q1.15). Replace with real designed taps later.
    // ------------------------------------------------------------
    logic signed [15:0] coeff[0:TAPS-1] = '{
        16'sh0200, 16'sh0400, 16'sh0800, 16'sh1000,
        16'sh2000, 16'sh3000, 16'sh2000, 16'sh1000,
        16'sh0800, 16'sh0400, 16'sh0200, 16'sh0100,
        16'sh0080, 16'sh0040, 16'sh0020, 16'sh0010
    };

    // ------------------------------------------------------------
    // Input shift register (x[n], x[n-1], ..., x[n-15])
    // ------------------------------------------------------------
    logic signed [15:0] shift_reg[0:TAPS-1];

    integer i;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < TAPS; i++)
                shift_reg[i] <= 16'sd0;
        end else if (in_valid) begin
            shift_reg[0] <= in_sample;
            for (i = 1; i < TAPS; i++)
                shift_reg[i] <= shift_reg[i-1];
        end
    end

    // ------------------------------------------------------------
    // Multiply stage (fully pipelined)
    // ------------------------------------------------------------
    logic signed [31:0] prod[0:TAPS-1];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < TAPS; i++)
                prod[i] <= 32'sd0;
        end else begin
            for (i = 0; i < TAPS; i++)
                prod[i] <= shift_reg[i] * coeff[i];
        end
    end

    // ------------------------------------------------------------
    // Pipelined adder tree
    // ------------------------------------------------------------
    logic signed [35:0] sum1[0:7];
    logic signed [35:0] sum2[0:3];
    logic signed [35:0] sum3[0:1];
    logic signed [35:0] final_sum;

    // Level 1: 16 → 8
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            for (i = 0; i < 8; i++) sum1[i] <= 0;
        else
            for (i = 0; i < 8; i++) sum1[i] <= prod[2*i] + prod[2*i+1];
    end

    // Level 2: 8 → 4
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            for (i = 0; i < 4; i++) sum2[i] <= 0;
        else
            for (i = 0; i < 4; i++) sum2[i] <= sum1[2*i] + sum1[2*i+1];
    end

    // Level 3: 4 → 2
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum3[0] <= 0;
            sum3[1] <= 0;
        end else begin
            sum3[0] <= sum2[0] + sum2[1];
            sum3[1] <= sum2[2] + sum2[3];
        end
    end

    // Level 4: 2 → 1
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            final_sum <= 0;
        else
            final_sum <= sum3[0] + sum3[1];
    end

    // ------------------------------------------------------------
    // Output calculation (truncate Q1.15)
    // ------------------------------------------------------------
    assign out_sample = final_sum[30:15];  // scale down
    // Output valid --> delayed by TAPS pipeline levels

    logic valid_pipe[0:TAPS+4]; // +4 for adder tree latency

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            for (i = 0; i < TAPS+5; i++) valid_pipe[i] <= 0;
        else begin
            valid_pipe[0] <= in_valid;
            for (i = 1; i < TAPS+5; i++)
                valid_pipe[i] <= valid_pipe[i-1];
        end
    end

    assign out_valid = valid_pipe[TAPS+4];

endmodule

