`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.07.2025 19:13:40
// Design Name: 
// Module Name: top_mod
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



module top_mod(
    input wire clk,
    input wire rst,
    input wire [7:0] uart_data,
    input wire uart_valid,
    output wire o_Tx_Serial
);

  // GPS Parser Outputs
  wire [15:0] latitude_deg;
  wire [15:0] latitude_min;
  wire [23:0] longitude_deg;
  wire [15:0] longitude_min;
  wire        data_ready;

  // UART TX control signals
  reg        i_Tx_DV = 0;
  reg [7:0]  i_Tx_Byte = 8'h00;
  wire       o_Tx_Done;
  wire       o_Tx_Active;

  // State machine for sending bytes
  reg [3:0]  tx_state = 0;
  reg [3:0]  tx_index = 0;
  reg [7:0]  tx_buffer [0:8];

  // Instantiate GPS Parser
  GPS_parser_mod gps_inst (
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

  // Instantiate UART Transmitter
  UART_TX uart_tx_inst (
    .i_Clock(clk),
    .i_Reset(rst),
    .i_Tx_DV(i_Tx_DV),
    .i_Tx_Byte(i_Tx_Byte),
    .o_Tx_Active(o_Tx_Active),
    .o_Tx_Serial(o_Tx_Serial),
    .o_Tx_Done(o_Tx_Done)
  );
  always @(posedge clk) begin
  $display("[%0t ns] UART Output Bit: %b", $time, o_Tx_Serial);
end


  // Transmission FSM
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      tx_state <= 0;
      tx_index <= 0;
      i_Tx_DV  <= 0;
    end else begin
      case (tx_state)
        0: begin
          if (data_ready) begin
            // Pack GPS data into bytes
            tx_buffer[0] <= latitude_deg[15:8];
            tx_buffer[1] <= latitude_deg[7:0];
            tx_buffer[2] <= latitude_min[15:8];
            tx_buffer[3] <= latitude_min[7:0];
            tx_buffer[4] <= longitude_deg[23:16];
            tx_buffer[5] <= longitude_deg[15:8];
            tx_buffer[6] <= longitude_deg[7:0];
            tx_buffer[7] <= longitude_min[15:8];
            tx_buffer[8] <= longitude_min[7:0];
            tx_index     <= 0;
            tx_state     <= 1;
          end
        end

        1: begin
          i_Tx_Byte <= tx_buffer[tx_index];
          i_Tx_DV   <= 1;
          tx_state  <= 2;
        end

        2: begin
          i_Tx_DV <= 0;
          if (o_Tx_Done) begin
            if (tx_index < 8) begin
              tx_index <= tx_index + 1;
              tx_state <= 1;
            end else begin
              tx_state <= 0; // Done sending all bytes
            end
          end
        end

        default: tx_state <= 0;
      endcase
    end
  end

endmodule

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.07.2025 16:16:47
// Design Name: 
// Module Name: GPS_parser_mod
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


module GPS_parser_mod (
    input wire clk,
    input wire rst,
    input wire [7:0] uart_data,
    input wire uart_valid,
    output reg [15:0] latitude_deg,
    output reg [15:0] latitude_min,
    output reg [23:0] longitude_deg,
    output reg [15:0] longitude_min,
    output reg data_ready
);

    reg [3:0] state;
    reg [7:0] buffer [0:4];
    reg [7:0] lat_buf [0:3];
    reg [7:0] lon_buf [0:4];
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state         <= 0;
            data_ready    <= 0;
            latitude_deg  <= 0;
            latitude_min  <= 0;
            longitude_deg <= 0;
            longitude_min <= 0;
            i             <= 0;
        end else if (uart_valid) begin
            case (state)
                0: begin
                $display("FSM state 0");

                    data_ready <= 0;
                    if (uart_data == 8'h24) begin // '$'
                        state <= 1;
                        i <= 0;
                    end
                end

                1: begin
                $display("FSM state 1");
                    if (i < 5) begin
                        buffer[i] <= uart_data;
                        i <= i + 1;
                    end else begin
                        if (
                            buffer[0] == 8'h47 && // 'G'
                            buffer[1] == 8'h50 && // 'P'
                            buffer[2] == 8'h47 && // 'G'
                            buffer[3] == 8'h47 && // 'G'
                            buffer[4] == 8'h41    // 'A'
                        ) begin
                            state <= 2;
                        end else begin
                            state <= 0;
                        end
                        i <= 0;
                    end
                end

                2: begin
                $display("FSM state 2");
                    if (uart_data == 8'h2C) begin // ','
                        state <= 3;
                        i <= 0;
                    end
                end

                3: begin
                $display("FSM state 3");
                    if (i < 4) begin
                        lat_buf[i] <= uart_data;
                        i <= i + 1;
                    end else if (uart_data == 8'h2C) begin
                        state <= 4;
                        i <= 0;
                    end
                end

                4: begin
                $display("FSM state 4");
                    if (uart_data == 8'h2C) begin
                        state <= 5;
                        i <= 0;
                    end
                end

                5: begin
                $display("FSM state 5");
                $display("i value:%d",i);
                
                    if (i < 5) begin
                        lon_buf[i] <= uart_data;
                        
                        i <= i + 1;
                    end else if (uart_data == 8'h2C) begin
                    $display("heheh");
                    
                        state <= 6;
                        i <= 0;
                    end
                end

                6: begin
                $display("FSM state 6");
                    // ASCII-to-decimal conversion logic
                    latitude_deg  <= ((lat_buf[0] - 8'h30) * 10) + (lat_buf[1] - 8'h30);
                    latitude_min  <= ((lat_buf[2] - 8'h30) * 10) + (lat_buf[3] - 8'h30);
                    longitude_deg <= ((lon_buf[0] - 8'h30) * 100) + ((lon_buf[1] - 8'h30) * 10) + (lon_buf[2] - 8'h30);
                    longitude_min <= ((lon_buf[3] - 8'h30) * 10) + (lon_buf[4] - 8'h30);
                    data_ready    <= 1;
                    state         <= 0;
                end

                default: state <= 0;
            endcase
        end
    end
endmodule
`timescale 1ns / 1ps

module UART_TX
  #(parameter CLKS_PER_BIT = 87)
  (
    input       i_Clock,
    input       i_Reset,        // Added for reset handling
    input       i_Tx_DV,
    input [7:0] i_Tx_Byte,
    output      o_Tx_Active,
    output reg  o_Tx_Serial,
    output      o_Tx_Done
  );

  // FSM state parameters
  parameter s_IDLE         = 3'b000;
  parameter s_TX_START_BIT = 3'b001;
  parameter s_TX_DATA_BITS = 3'b010;
  parameter s_TX_STOP_BIT  = 3'b011;
  parameter s_CLEANUP      = 3'b100;

  // Internal registers
  reg [2:0] r_SM_Main     = s_IDLE;
  reg [7:0] r_Clock_Count = 0;
  reg [2:0] r_Bit_Index   = 0;
  reg [7:0] r_Tx_Data     = 0;
  reg       r_Tx_Done     = 0;
  reg       r_Tx_Active   = 0;

  // Main FSM process
  always @(posedge i_Clock or negedge i_Reset)
  begin
    if (!i_Reset)
    begin
      r_SM_Main     <= s_IDLE;
      r_Clock_Count <= 0;
      r_Bit_Index   <= 0;
      r_Tx_Done     <= 0;
      r_Tx_Active   <= 0;
      o_Tx_Serial   <= 1'b1;
    end
    else
    begin
      case (r_SM_Main)
        s_IDLE:
        begin
          r_Tx_Done     <= 1'b0;
          r_Clock_Count <= 0;
          r_Bit_Index   <= 0;
          o_Tx_Serial   <= 1'b1;

          if (i_Tx_DV)
          begin
            r_Tx_Active <= 1'b1;
            r_Tx_Data   <= i_Tx_Byte;
            r_SM_Main   <= s_TX_START_BIT;
          end
        end

        s_TX_START_BIT:
        begin
          o_Tx_Serial <= 1'b0;

          if (r_Clock_Count < CLKS_PER_BIT - 1)
            r_Clock_Count <= r_Clock_Count + 1;
          else
          begin
            r_Clock_Count <= 0;
            r_SM_Main     <= s_TX_DATA_BITS;
          end
        end

        s_TX_DATA_BITS:
        begin
          o_Tx_Serial <= r_Tx_Data[r_Bit_Index];

          if (r_Clock_Count < CLKS_PER_BIT - 1)
            r_Clock_Count <= r_Clock_Count + 1;
          else
          begin
            r_Clock_Count <= 0;

            if (r_Bit_Index < 7)
              r_Bit_Index <= r_Bit_Index + 1;
            else
            begin
              r_Bit_Index <= 0;
              r_SM_Main   <= s_TX_STOP_BIT;
            end
          end
        end

        s_TX_STOP_BIT:
        begin
          o_Tx_Serial <= 1'b1;

          if (r_Clock_Count < CLKS_PER_BIT - 1)
            r_Clock_Count <= r_Clock_Count + 1;
          else
          begin
            r_Clock_Count <= 0;
            r_Tx_Done     <= 1'b1;
            r_Tx_Active   <= 1'b0;
            r_SM_Main     <= s_CLEANUP;
          end
        end

        s_CLEANUP:
        begin
          r_Tx_Done <= 1'b0; // Clear done after one cycle
          r_SM_Main <= s_IDLE;
        end

        default: r_SM_Main <= s_IDLE;
      endcase
    end
  end

  // Continuous assignments
  assign o_Tx_Active = r_Tx_Active;
  assign o_Tx_Done   = r_Tx_Done;

endmodule
