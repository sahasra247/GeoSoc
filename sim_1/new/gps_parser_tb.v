`timescale 1ns / 1ps

module gps_parser_tb;

  // Inputs
  reg clk = 0;
  reg rst = 1;
  reg [7:0] uart_data = 8'h00;
  reg uart_valid = 0;

  // Outputs
  wire [15:0] latitude_deg;
  wire [15:0] latitude_min;
  wire [23:0] longitude_deg;
  wire [15:0] longitude_min;
  wire data_ready;

  // Instantiate the Device Under Test (DUT)
  GPS_parser_mod DUT (
    .clk(clk),
    .rst(rst),
    .uart_data(uart_data),
    .uart_valid(uart_valid),
    .latitude_deg(latitude_deg),
    .latitude_min(latitude_min),
    .longitude_deg(longitude_deg),
    .longitude_min(longitude_min),
    .data_ready(data_ready)
  );

  // Clock generation (100MHz = 10ns period)
  always #0.5 clk = ~clk;

  // Stimulus sequence
  initial begin
    $display("[%0t ns] 🔧 Resetting parser...", $time);
    #2 rst = 0;
    $display("[%0t ns] 🚀 Starting test sequence...", $time);

    // Simulate sending "$GPGGA,123519,3130,12024"
    send_char(8'h24); // '$'
    send_char(8'h47); // 'G'
    send_char(8'h50); // 'P'
    send_char(8'h47); // 'G'
    send_char(8'h47); // 'G'
    send_char(8'h41); // 'A'
    send_char(8'h2C); // ','

    // Time stamp HHMMSS → 12:35:19
    send_char(8'h31); send_char(8'h32); send_char(8'h33); // '1','2','3'
    send_char(8'h35); send_char(8'h31); send_char(8'h39); // '5','1','9'

    send_char(8'h2C); // ','

    // Latitude = 31°30'
    send_char(8'h33); send_char(8'h31); // '3','1' → Degrees
    send_char(8'h33); send_char(8'h30); // '3','0' → Minutes

    send_char(8'h2C); // ','
    send_char(8'h4E); // 'N' → Latitude direction

    send_char(8'h2C); // ','


    // Longitude = 120°24'
    send_char(8'h31); send_char(8'h32); send_char(8'h30); // '1','2','0' → Degrees
    send_char(8'h32); send_char(8'h34);send_char(8'h34);send_char(8'h34);                 // '2','4' → Minutes
    send_char(8'h2C); // ','
    send_char(8'h4E); // 'N' → Latitude direction

    send_char(8'h2C); // ','
    

    // Display results
    
    if (data_ready) begin
      $display("[%0t ns] ✅ Data parsed successfully!", $time);
      $display("[%0t ns] 📍 Latitude  = %d° %d'", $time, latitude_deg, latitude_min);
      $display("[%0t ns] 📍 Longitude = %d° %d'", $time, longitude_deg, longitude_min);
    end else begin
      $display("[%0t ns] ⚠️ Data not ready. Verify input timing and format.", $time);
    end
    
   

    $stop;
  end

  // UART character transmission task with timestamp
  task send_char;
    input [7:0] char;
    begin
      uart_data  = char;
      uart_valid = 1;
      $display("[%0t ns] 📤 Sending Char: '%c' (Hex: %h)", $time, char, char);
      #1;
      uart_valid = 0;
      #1;
    end
  endtask

endmodule