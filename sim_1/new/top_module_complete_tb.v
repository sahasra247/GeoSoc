`timescale 1ns / 1ps

module top_module_complete_tb;

  reg clk = 0;
  reg rst = 0;
  reg i_Rx_Serial = 1;
  wire o_Tx_Serial;

  // Clock generation: 50 MHz
  always #0.5 clk = ~clk;

  // Instantiate top module
  top_module_complete uut (
    .clk(clk),
    .rst(rst),
    .i_Rx_Serial(i_Rx_Serial),
    .o_Tx_Serial(o_Tx_Serial)
  );

  // UART Parameters
 
  parameter BIT_PERIOD = 87;

  // Task to send ASCII byte over serial
  task uart_send_byte;
    input [7:0] data;
    integer i;
    begin
      // Start Bit
      i_Rx_Serial = 0;
      #(BIT_PERIOD);

      // Data Bits (LSB first)
      for (i = 0; i < 8; i = i + 1) begin
        i_Rx_Serial = data[i];
        #(BIT_PERIOD);
      end

      // Stop Bit
      i_Rx_Serial = 1;
      #(BIT_PERIOD);
    end
  endtask

  initial begin
   
    #10 rst = 1;
    #20;

    // Send NMEA sentence as ASCII
    uart_send_byte(8'h24); // $  
    uart_send_byte(8'h47); // G  
    uart_send_byte(8'h50); // P  
    uart_send_byte(8'h47); // G  
    uart_send_byte(8'h4C); // L  
    uart_send_byte(8'h4C); // L  
    uart_send_byte(8'h2C); // ,

    uart_send_byte(8'h31); // 1  
    uart_send_byte(8'h32); // 2  
    uart_send_byte(8'h33); // 3  
    uart_send_byte(8'h34); // 4  
    uart_send_byte(8'h2E); // .  
    uart_send_byte(8'h35); // 5  
    uart_send_byte(8'h36); // 6  
    uart_send_byte(8'h2C); // ,

    uart_send_byte(8'h4E); // N  
    uart_send_byte(8'h2C); // ,

    uart_send_byte(8'h39); // 9  
    uart_send_byte(8'h38); // 8  
    uart_send_byte(8'h37); // 7  
    uart_send_byte(8'h36); // 6  
    uart_send_byte(8'h2E); // .  
    uart_send_byte(8'h35); // 5  
    uart_send_byte(8'h34); // 4  
    uart_send_byte(8'h2C); // ,

    uart_send_byte(8'h45); // E  
    uart_send_byte(8'h2C); // ,

    uart_send_byte(8'h31); // 1  
    uart_send_byte(8'h32); // 2  
    uart_send_byte(8'h32); // 2  
    uart_send_byte(8'h35); // 5  
    uart_send_byte(8'h31); // 1  
    uart_send_byte(8'h39); // 9  
    uart_send_byte(8'h2C); // ,

    uart_send_byte(8'h41); // A  
    uart_send_byte(8'h2A); // *
    uart_send_byte(8'h30); // 0  
    uart_send_byte(8'h30); // 0  
    uart_send_byte(8'h0D); // \r  
    uart_send_byte(8'h0A); // \n

    // Allow time for TX completion
    #10000;
    $display("Testbench complete.");
    $finish;
  end

endmodule