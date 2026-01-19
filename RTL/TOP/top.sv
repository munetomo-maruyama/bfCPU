//===========================================================
// bfCPU Project
//-----------------------------------------------------------
// File Name   : top.sv
// Description : Core Logic Top
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.21 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025-2026 M.Maruyama
//===========================================================

//----------------------------
// Module Top
//----------------------------
module TOP
(
    input  logic CLK,
    input  logic RES_N,
    //
    output logic       QSPI_CS_N,
    output logic       QSPI_CS_E,
    output logic       QSPI_SCK,
    output logic       QSPI_SCK_E,    
    output logic [3:0] QSPI_SIO_O,
    output logic [3:0] QSPI_SIO_E,
    input  logic [3:0] QSPI_SIO_I,
    //
    output logic UART_TXD,
    input  logic UART_RXD
);

//----------------------------------
// QSPI Output Driver (Open Drain)
//----------------------------------
logic       qspi_cs_n;
logic       qspi_sck;
logic [3:0] qspi_sio_o;
logic [3:0] qspi_sio_e;
logic [3:0] qspi_sio_i;
//
assign QSPI_CS_N  = 1'b0;
assign QSPI_CS_E  = (~qspi_cs_n & RES_N);
assign QSPI_SCK   = 1'b0;
assign QSPI_SCK_E = (~qspi_sck & RES_N);
assign QSPI_SIO_O    = 4'b0000;
assign QSPI_SIO_E[0] = (~qspi_sio_o[0] & qspi_sio_e[0] & RES_N);
assign QSPI_SIO_E[1] = (~qspi_sio_o[1] & qspi_sio_e[1] & RES_N);
assign QSPI_SIO_E[2] = (~qspi_sio_o[2] & qspi_sio_e[2] & RES_N);
assign QSPI_SIO_E[3] = (~qspi_sio_o[3] & qspi_sio_e[3] & RES_N);
assign qspi_sio_i = QSPI_SIO_I;

//----------------------------
// CPU
//----------------------------
logic        if_req;
logic [15:0] if_addr;
logic [ 3:0] if_code;
logic        if_rdy;
//
logic        dm_req;
logic        dm_write;
logic [14:0] dm_addr;
logic [ 7:0] dm_wdata;
logic [ 7:0] dm_rdata;
logic        dm_rdy;
//
logic        io_req;
logic        io_write;
logic [ 1:0] io_addr;
logic [ 7:0] io_wdata;
logic [ 7:0] io_rdata;
logic        io_rdy;
//
CPU U_CPU
(
    .CLK (CLK),
    .RES (~RES_N),
    //
    .IF_REQ  (if_req),
    .IF_ADDR (if_addr),
    .IF_CODE (if_code),
    .IF_RDY  (if_rdy),
    //
    .DM_REQ   (dm_req),
    .DM_WRITE (dm_write),
    .DM_ADDR  (dm_addr),
    .DM_WDATA (dm_wdata),
    .DM_RDATA (dm_rdata),
    .DM_RDY   (dm_rdy),
    //
    .IO_REQ   (io_req),
    .IO_WRITE (io_write),
    .IO_ADDR  (io_addr),
    .IO_WDATA (io_wdata),
    .IO_RDATA (io_rdata),
    .IO_RDY   (io_rdy)
);

//----------------------------
// CACHE
//----------------------------
logic        bus_req;
logic        bus_write;
logic [15:0] bus_addr;
logic [ 7:0] bus_wdata;
logic [ 7:0] bus_rdata;
logic        bus_rdy;
//
CACHE U_CACHE
(
    .CLK (CLK),
    .RES (~RES_N),
    //
    .IF_REQ  (if_req),
    .IF_ADDR (if_addr),
    .IF_CODE (if_code),
    .IF_RDY  (if_rdy),
    //
    .DM_REQ   (dm_req),
    .DM_WRITE (dm_write),
    .DM_ADDR  (dm_addr),
    .DM_WDATA (dm_wdata),
    .DM_RDATA (dm_rdata),
    .DM_RDY   (dm_rdy),
    //
    .BUS_REQ   (bus_req),
    .BUS_WRITE (bus_write),
    .BUS_ADDR  (bus_addr),
    .BUS_WDATA (bus_wdata),
    .BUS_RDATA (bus_rdata),
    .BUS_RDY   (bus_rdy)
);

//----------------------------
// QSPI SRAM
//----------------------------
QSPI_SRAM U_RAM
(
    .CLK (CLK),
    .RES (~RES_N),
    //
    .BUS_REQ   (bus_req),
    .BUS_WRITE (bus_write),
    .BUS_ADDR  (bus_addr),
    .BUS_WDATA (bus_wdata),
    .BUS_RDATA (bus_rdata),
    .BUS_RDY   (bus_rdy),
    //
    .QSPI_CS_N  (qspi_cs_n),
    .QSPI_SCK   (qspi_sck),
    .QSPI_SIO_O (qspi_sio_o),
    .QSPI_SIO_E (qspi_sio_e),
    .QSPI_SIO_I (qspi_sio_i)
);

//----------------------------
// UART
//----------------------------
UART U_UART
(
    .CLK (CLK),
    .RES (~RES_N),
    //
    .IO_REQ   (io_req),
    .IO_WRITE (io_write),
    .IO_ADDR  (io_addr),
    .IO_WDATA (io_wdata),
    .IO_RDATA (io_rdata),
    .IO_RDY   (io_rdy),
    //
    .UART_TXD (UART_TXD),
    .UART_RXD (UART_RXD)
);

endmodule
//===========================================================
// End of File
//===========================================================
