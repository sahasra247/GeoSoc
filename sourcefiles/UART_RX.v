module UART_RX
  #(parameter CLKS_PER_BIT = 87)
  (
    input        i_Clock,
    input        i_Reset,
    input        i_Rx_Serial,
    output reg   o_Rx_DV = 0,
    output reg [7:0] o_Rx_Byte = 8'h00
  );

  parameter s_IDLE         = 3'b000;
  parameter s_RX_START_BIT = 3'b001;
  parameter s_RX_DATA_BITS = 3'b010;
  parameter s_RX_STOP_BIT  = 3'b011;
  parameter s_CLEANUP      = 3'b100;

  reg [2:0]  r_SM_Main     = s_IDLE;
  reg [7:0]  r_Clock_Count = 0;
  reg [2:0]  r_Bit_Index   = 0;
  reg [7:0]  r_Rx_Byte     = 0;

  always @(posedge i_Clock or negedge i_Reset)
  begin
  $display("[%0t ns] FSM = %d", $time, r_SM_Main);

    if (!i_Reset) begin
      r_SM_Main     <= s_IDLE;
      r_Clock_Count <= 0;
      r_Bit_Index   <= 0;
      o_Rx_DV       <= 0;
    end else begin
      case (r_SM_Main)
        s_IDLE: begin
        $display("state idle");
          o_Rx_DV <= 0;
          r_Clock_Count <= 0;
          r_Bit_Index   <= 0;

          if (i_Rx_Serial == 0) // Start bit detected
            r_SM_Main <= s_RX_START_BIT;
        end

       s_RX_START_BIT: begin
  $display("state s_RX_START_BIT");

  if (r_Clock_Count == (CLKS_PER_BIT - 1) / 2) begin
    if (i_Rx_Serial == 0) begin  // Confirm it's still a start bit
      r_Clock_Count <= 0;
      r_SM_Main     <= s_RX_DATA_BITS;
    end else begin
      r_Clock_Count <= 0;
      r_SM_Main     <= s_IDLE;  // False start bit - return to idle
    end
  end else begin
    r_Clock_Count <= r_Clock_Count + 1;
  end
end

     s_RX_DATA_BITS: begin 
     $display("s_RX_DATA_BITS"); 
     $display("[%0t ns] Bit %0d sampled: %b", $time, r_Bit_Index, i_Rx_Serial); 
     if (r_Bit_Index < 8)begin
            if (r_Clock_Count < CLKS_PER_BIT - 1) begin
                r_Clock_Count <= r_Clock_Count + 1;
            end else 
            begin
                r_Clock_Count <= 0;
                r_Rx_Byte[r_Bit_Index] <= i_Rx_Serial;
                r_Bit_Index <= r_Bit_Index + 1;
                r_SM_Main     <= s_RX_DATA_BITS;
                end
                
                end
      else
          r_SM_Main <= s_RX_STOP_BIT;
          r_Bit_Index<=0;

      end

        s_RX_STOP_BIT: begin
        $display("s_RX_STOP_BIT");
          if (r_Clock_Count < CLKS_PER_BIT - 1)
            r_Clock_Count <= r_Clock_Count + 1;
          else begin
            o_Rx_Byte <= r_Rx_Byte;
            o_Rx_DV   <= 1;
            r_Clock_Count <= 0;
            r_SM_Main     <= s_CLEANUP;
          end
        end

        s_CLEANUP: begin
        $display("s_CLEANUP");
          r_SM_Main <= s_IDLE;
        end

        default: r_SM_Main <= s_IDLE;
      endcase
    end
  end

endmodule