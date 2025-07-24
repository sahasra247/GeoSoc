
`timescale 1ns / 1ps
`include "UART_RX.v"
`include "GPS_parser_mod.v"
`include "UART_TX.v"

module top_mod_complete(
    input wire clk,
    input wire rst,
    input wire i_Rx_Serial,       // UART RX serial input
    output wire o_Tx_Serial       // UART TX serial output
);

  // UART RX to GPS Parser
  wire [7:0] uart_data;
  wire uart_valid;

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

  // TX FSM state
  reg [3:0]  tx_state = 0;
  reg [3:0]  tx_index = 0;
  reg [7:0]  tx_buffer [0:8];

  // Instantiate UART RX
  UART_RX #(.CLKS_PER_BIT(87)) uart_rx_inst (
    .i_Clock(clk),
    .i_Reset(!rst),
    .i_Rx_Serial(i_Rx_Serial),
    .o_Rx_DV(uart_valid),
    .o_Rx_Byte(uart_data)
  );

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

  // Instantiate UART TX
  UART_TX uart_tx_inst (
    .i_Clock(clk),
    .i_Reset(!rst),
    .i_Tx_DV(i_Tx_DV),
    .i_Tx_Byte(i_Tx_Byte),
    .o_Tx_Active(o_Tx_Active),
    .o_Tx_Serial(o_Tx_Serial),
    .o_Tx_Done(o_Tx_Done)
  );

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
              tx_state <= 0;
            end
          end
        end

        default: tx_state <= 0;
      endcase
    end
  end

endmodule
