`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.07.2025 16:23:48
// Design Name: 
// Module Name: UART_TB
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


module UART_TB;

  // Parameters
  parameter CLKS_PER_BIT = 10; // Adjust for simulation speed

  // Testbench signals
  reg clk = 0;
  reg tx_dv = 0;
  reg [7:0] tx_byte = 8'h00;
  wire tx_active;
  wire tx_serial;
  wire tx_done;

  // Instantiate DUT
  UART_TX #(.CLKS_PER_BIT(CLKS_PER_BIT)) uut (
    .i_Clock(clk),
    .i_Tx_DV(tx_dv),
    .i_Tx_Byte(tx_byte),
    .o_Tx_Active(tx_active),
    .o_Tx_Serial(tx_serial),
    .o_Tx_Done(tx_done)
  );

  // Clock generation: 100 MHz
  always #0.5 clk = ~clk;

  // Monitor outputs
  initial begin
    $monitor("⏱ %t | Serial: %b | Active: %b | Done: %b", $time, tx_serial, tx_active, tx_done);
  end

  // Stimulus
  initial begin
    #2;
    tx_byte = 8'hA5;  // Example byte to send
    tx_dv = 1;
    #1;
    tx_dv = 0;

    // Wait for transmission complete
    wait(tx_done);
    $display("Byte 0xA5 transmitted at time %t", $time);

    #5 $finish;
  end

endmodule

