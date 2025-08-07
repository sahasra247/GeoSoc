# GeoSoc
This project focuses on designing and simulating a hardware module that parses GPS NMEA sentence data received via UART interface, targeting integration with commercial GPS receivers such as the NEO-7M. The design also facilitates transmitting the processed GPS data over UART or further communication interfaces.

# UART-GPS Module:

## Overview

The module is a comprehensive design that interfaces with UART RX and UART TX modules, including a GPS data parser. It receives GPS data via UART serial input, processes/parses the GPS coordinates, and transmits the parsed latitude and longitude data back over UART.

## Features

- **UART Reception**: Receives serial data using the `UART_RX` module.
- **GPS Parsing**: Parses incoming GPS data stream and extracts latitude and longitude values using the `GPS_parser_mod`.
- **UART Transmission**: Sends parsed GPS coordinates back using the `UART_TX` module.
- **Finite State Machine (FSM)**: Controls transmission logic and data buffering.
- Handles asynchronous reset and synchronized clock input.

## Module Interface

| Port        | Direction | Description                          |
|-------------|-----------|------------------------------------|
| `clk`       | Input     | System clock input                  |
| `rst`       | Input     | Active-high system reset            |
| `i_Rx_Serial` | Input     | UART serial RX line (GPS input)    |
| `o_Tx_Serial` | Output    | UART serial TX line (transmit out) |

## Internal Signals

- `uart_data` [7:0]: Data received from UART RX.
- `uart_valid`: Indicates received new valid byte from UART RX.
- `latitude_deg` [15:0]: Parsed latitude degrees from GPS parser.
- `latitude_min` [15:0]: Parsed latitude minutes from GPS parser.
- `longitude_deg` [23:0]: Parsed longitude degrees from GPS parser.
- `longitude_min` [15:0]: Parsed longitude minutes from GPS parser.
- `data_ready`: Flag raised by GPS parser indicating new GPS data is ready for transmission.
- `i_Tx_DV`: Data valid signal to UART TX to start transmission.
- `i_Tx_Byte` [7:0]: Byte to transmit via UART TX.
- `o_Tx_Done`: UART TX signal indicating completion of transmission of current byte.
- `o_Tx_Active`: UART TX busy signal.

## Functional Description

### 1. UART Receiver (UART_RX)
- Receives serial data bits from `i_Rx_Serial`.
- Outputs received byte and data valid pulse.
- Configured for a fixed baud rate (`CLKS_PER_BIT = 87`).

### 2. GPS Parser Module (GPS_parser_mod)
- Takes the UART RX data stream and detects valid GPS NMEA messages.
- Extracts latitude and longitude information.
- Outputs coordinate data and signals when the parsed data is ready (`data_ready`).

### 3. UART Transmitter (UART_TX)
- Transmits bytes serially out through `o_Tx_Serial`.
- Uses `i_Tx_DV` to trigger transmission and outputs `o_Tx_Done` upon completion.
  
### 4. Transmit FSM
- On arrival of new GPS data (`data_ready`), prepares a 9-byte buffer containing:
  - Latitude degrees (2 bytes)
  - Latitude minutes (2 bytes)
  - Longitude degrees (3 bytes)
  - Longitude minutes (2 bytes)
- Sequentially transmits the bytes via UART TX.
- Uses a simple 3-state FSM:
  - **State 0**: Waits for new data.
  - **State 1**: Loads a byte into UART TX and triggers transmission.
  - **State 2**: Waits for transmission done, then moves to next byte or returns to State 0 when done.

## Usage Notes

- The module expects a system clock `clk` aligned with UART `CLKS_PER_BIT` setting for correct data timing.
- Reset (`rst`) is active-high and asynchronous in this top module.
- `i_Rx_Serial` should be connected to a UART serial data source providing GPS data.
- `o_Tx_Serial` outputs transmitted serial data; connect to a UART receiver on the other end.
- GPS parser details and implementation (`GPS_parser_mod`) must be compatible with the input data format and expected coordinate resolution.
  
---

## Integration Details

- This top module includes the instantiation of:
  - `UART_RX.v`
  - `GPS_parser_mod.v`
  - `UART_TX.v`
  

- Adjust `CLKS_PER_BIT` parameter in `UART_RX` and `UART_TX` for your clock frequency and baud rate.



