`include "global_defs.sv"
`timescale 1ns / 1ps

module running_mean_tb;

  // Parameters
  parameter DATA_WIDTH = 16;
  parameter WINDOW_SIZE = 8;
  parameter CLK_PERIOD = 10;

  // Signals
  reg clk;
  reg rst_n;
  reg [DATA_WIDTH-1:0] data_in;
  reg valid_in;
  wire [DATA_WIDTH-1:0] mean_out;
  wire valid_out;

  // Instantiate the running_mean module
  running_mean #(
    .DATA_WIDTH(DATA_WIDTH),
    .WINDOW_SIZE(WINDOW_SIZE)
  ) uut (
    .clk(clk),
    .rst_n(rst_n),
    .data_in(data_in),
    .valid_in(valid_in),
    .mean_out(mean_out),
    .valid_out(valid_out)
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
  end

  // Test sequence
  initial begin
    // Initialize signals
    rst_n = 0;
    data_in = 0;
    valid_in = 0;

    // Apply reset
    #(CLK_PERIOD*2);
    rst_n = 1;

    // Apply test vectors
    #(CLK_PERIOD);
    apply_input(10);
    #(CLK_PERIOD);
    apply_input(20);
    #(CLK_PERIOD);
    apply_input(30);
    #(CLK_PERIOD);
    apply_input(40);
    #(CLK_PERIOD);
    apply_input(50);
    #(CLK_PERIOD);
    apply_input(60);
    #(CLK_PERIOD);
    apply_input(70);
    #(CLK_PERIOD);
    apply_input(80);

    // Wait for some time to observe outputs
    #(CLK_PERIOD*10);

    // Finish simulation
    $finish;
  end

  // Task to apply input data
  task apply_input(input [DATA_WIDTH-1:0] value);
    begin
      data_in = value;
      valid_in = 1;
      #(CLK_PERIOD);
      valid_in = 0;
    end
  endtask
endmodule