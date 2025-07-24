`timescale 1ns / 1ps

module UART_RX_tb;

   parameter c_CLOCK_PERIOD_NS = 1;
   parameter c_CLKS_PER_BIT    = 87;
   parameter c_BIT_PERIOD      = 87;

  // Signals
  reg clk = 0;
  reg rst = 0;
  reg i_Rx_Serial = 1;  // UART idle = high

  wire o_Rx_DV;
  wire [7:0] o_Rx_Byte;

  // Instantiate UART Receiver
  UART_RX #(.CLKS_PER_BIT(c_CLKS_PER_BIT)) DUT (
    .i_Clock(clk),
    .i_Reset(rst),
    .i_Rx_Serial(i_Rx_Serial),
    .o_Rx_DV(o_Rx_DV),
    .o_Rx_Byte(o_Rx_Byte)
  );

  // Clock generation (100MHz = 10ns)
  always #0.5 clk <= !clk;

  // Task to send one UART byte serially
  task UART_WRITE_BYTE;
    
   input [7:0] byte;
  integer i;
  begin
    i_Rx_Serial = 0;
    $display("checkpoint tb start bit before");         // Start bit
    #(c_BIT_PERIOD);
    #1;
      
    
           // Hold start bit
    $display("checkpoint tb start bit");
    for (i = 0; i < 8; i = i + 1) begin
      i_Rx_Serial = byte[i]; 
      $display("[%0t ns] i_Rx_Serial = %d", $time, i_Rx_Serial);  // Data bits
      #(c_BIT_PERIOD);
      $display("[%0t ns] i_Rx_Serial = %d ", $time, i_Rx_Serial);
    end

    i_Rx_Serial = 1;           // Stop bit
    #(c_BIT_PERIOD);         // Give idle time
  end
endtask


  // Monitor received data
  always @(posedge clk) begin
    if (o_Rx_DV) begin
      $display("[%0t ns] ✅ UART_RX got byte: 0x%h ('%c')", $time, o_Rx_Byte, o_Rx_Byte);
    end
  end

  // Simulation sequence
  initial
    begin
    @(posedge clk);
        rst=1;
        #2;
        $display("checkpoint");
      UART_WRITE_BYTE(8'h3F);
      UART_WRITE_BYTE(8'h3A);
      @(posedge clk);
      #2000000 // 2 milliseconds to comfortably receive and clean up
        $finish;
      end
      


endmodule