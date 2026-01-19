//===========================================================
// bfCPU Project
//-----------------------------------------------------------
// File Name   : tb.sv
// Description : Testbench for QSPI SRAM
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.21 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025-2026 M.Maruyama
//===========================================================

`timescale 1ns/10ps

`define TB_CYCLE  100         //ns
`define TB_FINISH_COUNT 1000  //cyc

//------------------
// Top of Test Bench
//------------------
module tb();
integer i;

//-----------------------------
// Generate Wave File to Check
//-----------------------------
initial
begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
end

//-------------------------------
// Generate Clock
//-------------------------------
logic clk;
//
initial clk = 1'b0;
always #(`TB_CYCLE / 2) clk = ~clk;

//--------------------------
// Generate Reset
//--------------------------
logic res;
//
initial
begin
    res = 1'b1;
        # (`TB_CYCLE * 10)
    res = 1'b0;       
end

//----------------------
// Cycle Counter
//----------------------
logic [31:0] tb_cycle_counter;
//
always_ff @(posedge clk, posedge res)
begin
    if (res)
        tb_cycle_counter <= 32'h0;
    else
        tb_cycle_counter <= tb_cycle_counter + 32'h1;
end
//
initial
begin
    forever
    begin
        @(posedge clk);
        if (tb_cycle_counter == `TB_FINISH_COUNT)
        begin
            $display("***** SIMULATION TIMEOUT ***** at %d", tb_cycle_counter);
            $finish;
        end
    end
end

//---------------------
// SPI_SRAM
//---------------------
logic        bus_req;
logic        bus_write;
logic        bus_rdy;
logic [15:0] bus_addr;
logic [ 7:0] bus_wdata;
logic [ 7:0] bus_rdata;
logic        qspi_cs_n;
logic        qspi_sck;
logic [ 3:0] qspi_sio_o;
logic [ 3:0] qspi_sio_e;
logic [ 3:0] qspi_sio_i;
//
QSPI_SRAM U_QSPI_SRAM
(
    .CLK (clk),
    .RES (res),
    //
    .BUS_REQ    (bus_req),
    .BUS_WRITE  (bus_write),
    .BUS_RDY    (bus_rdy),
    .BUS_ADDR   (bus_addr),
    .BUS_WDATA  (bus_wdata),
    .BUS_RDATA  (bus_rdata),
    //
    .QSPI_CS_N  (qspi_cs_n),
    .QSPI_SCK   (qspi_sck),
    .QSPI_SIO_O (qspi_sio_o),
    .QSPI_SIO_E (qspi_sio_e),
    .QSPI_SIO_I (qspi_sio_i)
);

//-----------------------------
// Functional Model : 23LC512
//-----------------------------
wire [3:0] qspi_sio;
pullup (qspi_sio[0]);
pullup (qspi_sio[1]);
pullup (qspi_sio[2]);
pullup (qspi_sio[3]);
assign qspi_sio[0] = (qspi_sio_e[0])? qspi_sio_o[0] : 1'bz;
assign qspi_sio[1] = (qspi_sio_e[1])? qspi_sio_o[1] : 1'bz;
assign qspi_sio[2] = (qspi_sio_e[2])? qspi_sio_o[2] : 1'bz;
assign qspi_sio[3] = (qspi_sio_e[3])? qspi_sio_o[3] : 1'bz;
assign qspi_sio_i[0] = qspi_sio[0];
assign qspi_sio_i[1] = qspi_sio[1];
assign qspi_sio_i[2] = qspi_sio[2];
assign qspi_sio_i[3] = qspi_sio[3];
//
M23LC512 U_M23LC512
(
    .SI_SIO0      (qspi_sio[0]),
    .SO_SIO1      (qspi_sio[1]),
    .SCK          (qspi_sck),
    .CS_N         (qspi_cs_n),
    .SIO2         (qspi_sio[2]),
    .HOLD_N_SIO3  (qspi_sio[3]),
    .RESET        (res)
);

//-----------------------------------------
// Bus Function Model
//-----------------------------------------
logic [15:0] seq;
logic [26:0] busseq[0:65535];
//
always_ff @(posedge clk, posedge res)
begin
    if (res)
    begin
        seq <= 0;
    end
    else if (bus_rdy)
    begin
        seq <= seq + 1;
    end
end
//
assign bus_req  = busseq[seq][26];
assign bus_write = busseq[seq][25];
assign bus_addr  = busseq[seq][23: 8];
assign bus_wdata = busseq[seq][ 7: 0];
//
logic       rdphase, wdphase;
logic [7:0] rdata;
//
always_ff @(posedge clk, posedge res)
begin
    if (res)
        rdphase <= 1'b0;
    else if (bus_req & ~bus_write & bus_rdy)
        rdphase <= 1'b1;
    else if (bus_rdy)
        rdphase <= 1'b0;
end
//
always_ff @(posedge clk, posedge res)
begin
    if (res)
        wdphase <= 1'b0;
    else if (bus_req & bus_write & bus_rdy)
        wdphase <= 1'b1;
    else if (bus_rdy)
        wdphase <= 1'b0;
end
//
always_ff @(posedge clk, posedge res)
begin
    if (res)
        rdata <= 8'h00;
    else if (rdphase & bus_rdy)
        rdata <= bus_rdata;
end

//-----------------------------------------
// Task : Configure Bus Sequence
//-----------------------------------------
task INIT_BUS_SEQUENCE();
begin
    for (i = 0; i < 65536; i = i + 1) busseq[i] = 27'h0;
    seq = 0;
end
endtask
//
task CONFIG_BUS_SEQUENCE(input TRANS, input WRITE, input HCLR, input [15:0] ADDR, input [7:0] WDATA);
begin
    busseq[seq] = {TRANS, WRITE, HCLR, ADDR, WDATA};
    seq = seq + 1;
end
endtask

//--------------------------
// Input Pattern (Stimulus)
//--------------------------
initial
begin
    // Configure Bus Sequence
    INIT_BUS_SEQUENCE();
    CONFIG_BUS_SEQUENCE(1'b0, 1'bx, 1'bx, 16'hxxxx, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b0, 1'bx, 1'bx, 16'hxxxx, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b0, 1'bx, 1'bx, 16'hxxxx, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b0, 1'bx, 1'bx, 16'hxxxx, 8'hxx);
  ////
  //// All Clear
  //CONFIG_BUS_SEQUENCE(1'b1, 1'bx, 1'b1, 16'hxxxx, 8'hxx);
    //
    // Write
    CONFIG_BUS_SEQUENCE(1'b1, 1'b1, 1'b0, 16'h0000, 8'h00);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b1, 1'b0, 16'h0001, 8'h11);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b1, 1'b0, 16'h0002, 8'h22);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b1, 1'b0, 16'h0004, 8'h44);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b1, 1'b0, 16'h0005, 8'h55);
    CONFIG_BUS_SEQUENCE(1'b0, 1'bx, 1'bx, 16'hxxxx, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b0, 1'bx, 1'bx, 16'hxxxx, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b0, 1'bx, 1'bx, 16'hxxxx, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b0, 1'bx, 1'bx, 16'hxxxx, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b1, 1'b0, 16'h0006, 8'h66);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b1, 1'b0, 16'h0007, 8'h77);
    //
    CONFIG_BUS_SEQUENCE(1'b0, 1'bx, 1'bx, 16'hxxxx, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b0, 1'bx, 1'bx, 16'hxxxx, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b1, 1'b0, 16'h8000, 8'h00);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b1, 1'b0, 16'h8001, 8'h11);
    CONFIG_BUS_SEQUENCE(1'b0, 1'bx, 1'bx, 16'hxxxx, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b1, 1'b0, 16'h8002, 8'h22);
    CONFIG_BUS_SEQUENCE(1'b0, 1'bx, 1'bx, 16'hxxxx, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b1, 1'b0, 16'h8003, 8'h33);
    CONFIG_BUS_SEQUENCE(1'b0, 1'bx, 1'bx, 16'hxxxx, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b1, 1'b0, 16'h8004, 8'h44);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b1, 1'b0, 16'h8005, 8'h55);
    CONFIG_BUS_SEQUENCE(1'b0, 1'bx, 1'bx, 16'hxxxx, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b1, 1'b0, 16'h8006, 8'h66);
    CONFIG_BUS_SEQUENCE(1'b0, 1'bx, 1'bx, 16'hxxxx, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b1, 1'b0, 16'h8007, 8'h77);
    CONFIG_BUS_SEQUENCE(1'b0, 1'bx, 1'bx, 16'hxxxx, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b1, 1'b0, 16'h8007, 8'h88);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b1, 1'b0, 16'h8007, 8'h99);
    //
    // Read
    CONFIG_BUS_SEQUENCE(1'b1, 1'b0, 1'b0, 16'h8001, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b0, 1'b0, 16'h8002, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b0, 1'b0, 16'h8003, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b0, 1'b0, 16'h8005, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b0, 1'b0, 16'h8006, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b0, 1'b0, 16'h8007, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b0, 1'b0, 16'h8006, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b0, 1'b0, 16'h8007, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b0, 1'b0, 16'h8006, 8'hxx);
    CONFIG_BUS_SEQUENCE(1'b1, 1'b0, 1'b0, 16'h8006, 8'hxx);
    //
    @(posedge clk);
    @(negedge res);
    @(posedge clk);
    // Start Bus Sequence
end

endmodule
//===========================================================
// End of File
//===========================================================


