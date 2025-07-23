`timescale 1ns / 1ps
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
