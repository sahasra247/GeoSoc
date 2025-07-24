`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.07.2025 19:31:22
// Design Name: 
// Module Name: top_mod_tb
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




module top_mod_tb;

  // Inputs
  reg clk = 0;
  reg rst = 1;
  reg [7:0] uart_data = 8'h00;
  reg uart_valid = 0;

  // Output
  wire o_Tx_Serial;

  // Instantiate the top module
  top_mod DUT (
    .clk(clk),
    .rst(rst),
    .uart_data(uart_data),
    .uart_valid(uart_valid),
    .o_Tx_Serial(o_Tx_Serial)
  );

  // Clock generation (10ns period = 100MHz)
  always #5 clk = ~clk;

  // Stimulus
  initial begin
    $display("[%0t ns] 🧪 Starting GPS sentence simulation...", $time);
    #20 rst = 0;

    // Send: $GPGGA,123519,3130,N,12024,E
    // Format: Header, Time, Latitude, Longitude

    // $GPGGA
    send_char(8'h24); // '$'
    send_char(8'h47); send_char(8'h50); // 'G', 'P'
    send_char(8'h47); send_char(8'h47); // 'G', 'G'
    send_char(8'h41); // 'A'
    send_char(8'h2C); // ','

    // Time: 123519
    send_char(8'h31); send_char(8'h32); send_char(8'h33); // '1','2','3'
    send_char(8'h35); send_char(8'h31); send_char(8'h39); // '5','1','9'
    send_char(8'h2C); // ','

    // Latitude: 3130
    send_char(8'h33); send_char(8'h31); // '3','1'
    send_char(8'h33); send_char(8'h30); // '3','0'
    send_char(8'h2C); send_char(8'h4E); // ',', 'N'

    // Longitude: 12024
    send_char(8'h2C); // ','
    send_char(8'h31); send_char(8'h32); send_char(8'h30); // '1','2','0'
    send_char(8'h32); send_char(8'h34);                   // '2','4'
    send_char(8'h2C); send_char(8'h45); // ',', 'E'

    #300; // Wait for UART to transmit entire buffer

    $display("[%0t ns] 🧪 Simulation complete", $time);
    
  end

  // Task to send each byte with valid pulse
  task send_char;
    input [7:0] char;
    begin
      uart_data  = char;
      uart_valid = 1;
      $display("[%0t ns] 📥 Sent UART char: '%c' (0x%h)", $time, char, char);
      #10;
      uart_valid = 0;
      #10;
    end
  endtask

endmodule