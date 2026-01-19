//===========================================================
// bfCPU Project
//-----------------------------------------------------------
// File Name   : uart.sv
// Description : UART Module Top
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.21 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025-2026 M.Maruyama
//===========================================================
//
// ---------------
// ADDR    REG
// ---------------
// 2'b00   TXD/RXD
// 2'b10   DIV0
// 2'b11   DIV1
// ---------------

//-------------------
// Module Top
//-------------------
module UART
(
    input  logic CLK,
    input  logic RES,
    //
    input  logic        IO_REQ,
    input  logic        IO_WRITE,
    input  logic [1:0]  IO_ADDR,
    input  logic [ 7:0] IO_WDATA,
    output logic [ 7:0] IO_RDATA,
    output logic        IO_RDY,
    //
    output logic UART_TXD,
    input  logic UART_RXD
);

//---------------------
// Internal Signals
//---------------------
logic       we;
logic       re;
logic [7:0] din;
logic [7:0] dout;
logic       sio_ce, sio_ce_x4;
logic [7:0] div0, div1;
logic       tx_full, rx_empty;
logic       rts;
logic _unused;
assign _unused = rts;

//---------------------
// Baud Rate Register
//---------------------
// Baud Rate = (fCLK/4) / ((div0+2)*(div1))
//     CLK=10MHz, 115200bps
//     115200*4=460800
//     10MHz/460800Hz=22=11*2
//     div0=9 (11-2) , div1=2
//
logic div0_aphase;
logic div0_dphase;
logic div1_aphase;
logic div1_dphase;
//
assign div0_aphase = IO_REQ & IO_WRITE & (IO_ADDR == 2'b10) & IO_RDY;
assign div1_aphase = IO_REQ & IO_WRITE & (IO_ADDR == 2'b11) & IO_RDY;
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        div0_dphase <= 1'b0;
    else if(div0_aphase)
        div0_dphase <= 1'b1;
    else if (IO_RDY)
        div0_dphase <= 1'b0;
end
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        div1_dphase <= 1'b0;
    else if(div1_aphase)
        div1_dphase <= 1'b1;
    else if (IO_RDY)
        div1_dphase <= 1'b0;
end
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        div0 <= 8'h00;
    else if (div0_aphase)
        div0 <= IO_WDATA;
end
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        div1 <= 8'h00;
    else if (div1_aphase)
        div1 <= IO_WDATA;
end
//
//---------------------
// Instance of UART IP
//---------------------
sasc_top U_SASC_TOP
(
    .clk       (CLK),
    .rst       (~RES),
    .rxd_i     (UART_RXD),
    .txd_o     (UART_TXD),
    .cts_i     (1'b0),
    .rts_o     (rts),
    .sio_ce    (sio_ce),
    .sio_ce_x4 (sio_ce_x4),
    .din_i     (din),
    .dout_o    (dout),
    .re_i      (re),
    .we_i      (we),
    .full_o    (tx_full),
    .empty_o   (rx_empty)
);
//
sasc_brg BRG
(
    .clk       (CLK),
    .rst       (~RES),
    .div0      (div0),
    .div1      (div1),  
    .sio_ce    (sio_ce),
    .sio_ce_x4 (sio_ce_x4)
);

//------------------
// I/O Data Write
//------------------
logic  txd_aphase;
logic  txd_dphase;
logic  tx_rdy;
//
assign tx_rdy = ~tx_full;
assign txd_aphase  = IO_REQ & IO_WRITE & (IO_ADDR == 2'b00) & IO_RDY;
//
assign we = txd_dphase & IO_RDY;
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        din <= 8'h00;
    else if (txd_aphase)
        din <= IO_WDATA;
    else if (IO_RDY)
        din <= 8'h00;
end
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        txd_dphase <= 1'b0;
    else if (txd_aphase)
        txd_dphase <= 1'b1;
    else if (IO_RDY)
        txd_dphase <= 1'b0;
end

//------------------
// I/O Data Read
//------------------
logic  rxd_aphase;
logic  rxd_dphase;
logic  rx_rdy;
//
assign rx_rdy = ~rx_empty;
assign rxd_aphase  = IO_REQ & ~IO_WRITE & (IO_ADDR == 2'b00) & IO_RDY;
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        rxd_dphase <= 1'b0;
    else if (rxd_aphase)
        rxd_dphase <= 1'b1;
    else if (IO_RDY)
        rxd_dphase <= 1'b0;
end
//
assign re = rxd_dphase & IO_RDY;

//---------------------------------
// I/O Access Read Data and Ready
//---------------------------------
assign IO_RDATA = (rxd_dphase )? dout
                : (div0_dphase)? div0
                : (div1_dphase)? div1
                : 8'h00;
//
assign IO_RDY = (txd_dphase)? tx_rdy
              : (rxd_dphase)? rx_rdy
              : 1'b1;

endmodule
//===========================================================
// End of File
//===========================================================
