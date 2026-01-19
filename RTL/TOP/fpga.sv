//===========================================================
// bfCPU Project
//-----------------------------------------------------------
// File Name   : fpga.sv
// Description : FPGA Top
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.21 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025-2026 M.Maruyama
//===========================================================

//----------------------------
// Module Top
//----------------------------
module FPGA
(
    input  logic CLK,
    input  logic RES_N,
    //
    inout  wire        QSPI_CS_N,
    inout  wire        QSPI_SCK,
    inout  wire  [3:0] QSPI_SIO,
    //
    output logic UART_TXD,
    input  logic UART_RXD,
    //
    output logic LED
);

//----------------
// LED 
//----------------
assign LED = RES_N; // Running

//----------------------------
// QSPI Output Buffer
//----------------------------
logic       qspi_cs_n;
logic       qspi_cs_e;
logic       qspi_sck;
logic       qspi_sck_e;    
logic [3:0] qspi_sio_o;
logic [3:0] qspi_sio_e;
logic [3:0] qspi_sio_i;
//
assign QSPI_CS_N   = (qspi_cs_e    )? qspi_cs_n     : 1'bz;
assign QSPI_SCK    = (qspi_sck_e   )? qspi_sck      : 1'bz;
assign QSPI_SIO[0] = (qspi_sio_e[0])? qspi_sio_o[0] : 1'bz;
assign QSPI_SIO[1] = (qspi_sio_e[1])? qspi_sio_o[1] : 1'bz;
assign QSPI_SIO[2] = (qspi_sio_e[2])? qspi_sio_o[2] : 1'bz;
assign QSPI_SIO[3] = (qspi_sio_e[3])? qspi_sio_o[3] : 1'bz;
assign qspi_sio_i[0] = QSPI_SIO[0];
assign qspi_sio_i[1] = QSPI_SIO[1];
assign qspi_sio_i[2] = QSPI_SIO[2];
assign qspi_sio_i[3] = QSPI_SIO[3];

//----------------------------
// TOP
//----------------------------
TOP U_TOP
(
    .CLK    (CLK),
    .RES_N  (RES_N),
    //
    .QSPI_CS_N  (qspi_cs_n),
    .QSPI_CS_E  (qspi_cs_e),
    .QSPI_SCK   (qspi_sck),
    .QSPI_SCK_E (qspi_sck_e),
    .QSPI_SIO_O (qspi_sio_o),
    .QSPI_SIO_E (qspi_sio_e),
    .QSPI_SIO_I (qspi_sio_i),
    //
    .UART_TXD   (UART_TXD),
    .UART_RXD   (UART_RXD)
);

endmodule
//===========================================================
// End of File
//===========================================================
