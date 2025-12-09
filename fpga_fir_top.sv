`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.12.2025 14:00:57
// Design Name: 
// Module Name: fpga_fir_top
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


// fpga_fir_top.sv
module fpga_fir_top (
    input  logic clk_in,     // 100 MHz
    input  logic rst_btn,    // active-high button
    output logic led0        // filtered output indicator
);

    // Reset synchronizer
    wire rst_n_raw = ~rst_btn;
    logic [1:0] rst_sync;
    always_ff @(posedge clk_in or negedge rst_n_raw) begin
        if (!rst_n_raw)
            rst_sync <= 0;
        else
            rst_sync <= {rst_sync[0], 1'b1};
    end
    wire rst_n = rst_sync[1];

    // Generate slow ramp input
    logic [15:0] ramp;
    logic        ramp_valid = 1'b1;

    always_ff @(posedge clk_in or negedge rst_n) begin
        if (!rst_n)
            ramp <= 0;
        else
            ramp <= ramp + 16'd100; // slow increase
    end

    // FIR output
    logic out_valid;
    logic signed [15:0] out_data;

    fir16_core fir (
        .clk(clk_in),
        .rst_n(rst_n),
        .in_valid(ramp_valid),
        .in_sample(ramp),
        .out_valid(out_valid),
        .out_sample(out_data)
    );

    // LED shows filtered signal as PWM
    assign led0 = out_data[15];

endmodule
