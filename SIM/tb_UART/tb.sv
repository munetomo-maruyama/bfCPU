//===========================================================
// bfCPU Project
//-----------------------------------------------------------
// File Name   : tb.sv
// Description : Testbench for UART
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.21 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025-2026 M.Maruyama
//===========================================================

`timescale 1ns/10ps

`define TB_CYCLE  100          //ns
`define TB_FINISH_COUNT 20000  //cyc


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
// UART
//---------------------
logic       io_req;
logic       io_write;
logic [1:0] io_addr;
logic       io_rdy;
logic [7:0] io_wdata;
logic [7:0] io_rdata;
logic uart_txd;
logic uart_rxd;
//
assign uart_rxd = uart_txd; // loop back
//
UART U_UART
(
    .CLK (clk),
    .RES (res),
    //
    .IO_REQ    (io_req),
    .IO_WRITE  (io_write),
    .IO_ADDR   (io_addr),
    .IO_WDATA  (io_wdata),
    .IO_RDATA  (io_rdata),
    .IO_RDY    (io_rdy),
    //
    .UART_TXD (uart_txd),
    .UART_RXD (uart_rxd)
);

//-----------------------------------------
// Bus Function Model
//-----------------------------------------
logic [15:0] seq;
logic [11:0] busseq[0:65535];
//
always_ff @(posedge clk, posedge res)
begin
    if (res)
    begin
        seq <= 0;
    end
    else if (io_rdy)
    begin
        seq <= seq + 1;
    end
end
//
assign io_req   = busseq[seq][11];
assign io_write = busseq[seq][10];
assign io_addr  = busseq[seq][9:8];
assign io_wdata = busseq[seq][7:0];
//
logic       rdphase, wdphase;
logic [7:0] rdata;
//
always_ff @(posedge clk, posedge res)
begin
    if (res)
        rdphase <= 1'b0;
    else if (io_req & ~io_write & io_rdy)
        rdphase <= 1'b1;
    else if (io_rdy)
        rdphase <= 1'b0;
end
//
always_ff @(posedge clk, posedge res)
begin
    if (res)
        wdphase <= 1'b0;
    else if (io_req & io_write & io_rdy)
        wdphase <= 1'b1;
    else if (io_rdy)
        wdphase <= 1'b0;
end
//
always_ff @(posedge clk, posedge res)
begin
    if (res)
        rdata <= 8'h00;
    else if (rdphase & io_rdy)
        rdata <= io_rdata;
end

//-----------------------------------------
// Task : Configure Bus Sequence
//-----------------------------------------
task INIT_IO_SEQUENCE();
begin
    for (i = 0; i < 65536; i = i + 1) busseq[i] = 12'h000;
    seq = 0;
end
endtask
//
task CONFIG_IO_SEQUENCE(input TRANS, input WRITE, input [1:0] ADDR, input [7:0] WDATA);
begin
    busseq[seq] = {TRANS, WRITE, ADDR, WDATA};
    seq = seq + 1;
end
endtask

//--------------------------
// Input Pattern (Stimulus)
//--------------------------
initial
begin
    // Configure Bus Sequence
    INIT_IO_SEQUENCE();
    CONFIG_IO_SEQUENCE(1'b0, 1'bx, 2'bxx, 8'hxx);
    CONFIG_IO_SEQUENCE(1'b0, 1'bx, 2'bxx, 8'hxx);
    CONFIG_IO_SEQUENCE(1'b0, 1'bx, 2'bxx, 8'hxx);
    CONFIG_IO_SEQUENCE(1'b0, 1'bx, 2'bxx, 8'hxx);
    //
    // Set DIV0 and DIV1
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b10, 8'h02);
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b11, 8'h03);    
    //
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b00, 8'h89);
    CONFIG_IO_SEQUENCE(1'b1, 1'b0, 2'b00, 8'hxx);
    //
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b00, 8'hab);
    CONFIG_IO_SEQUENCE(1'b1, 1'b0, 2'b00, 8'hxx);
    //
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b00, 8'hcd);
    CONFIG_IO_SEQUENCE(1'b1, 1'b0, 2'b00, 8'hxx);
    //
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b00, 8'hef);
    CONFIG_IO_SEQUENCE(1'b1, 1'b0, 2'b00, 8'hxx);
    //
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b00, 8'h01);
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b00, 8'h23);
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b00, 8'h45);
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b00, 8'h67);
    CONFIG_IO_SEQUENCE(1'b1, 1'b0, 2'b00, 8'hxx);
    CONFIG_IO_SEQUENCE(1'b1, 1'b0, 2'b00, 8'hxx);
    CONFIG_IO_SEQUENCE(1'b1, 1'b0, 2'b00, 8'hxx);
    CONFIG_IO_SEQUENCE(1'b1, 1'b0, 2'b00, 8'hxx);
    //
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b00, 8'h11);
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b00, 8'h22);
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b00, 8'h33);
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b00, 8'h44);
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b00, 8'h55);
    CONFIG_IO_SEQUENCE(1'b1, 1'b0, 2'b00, 8'hxx);
    CONFIG_IO_SEQUENCE(1'b1, 1'b0, 2'b00, 8'hxx);
    CONFIG_IO_SEQUENCE(1'b1, 1'b0, 2'b00, 8'hxx);
    CONFIG_IO_SEQUENCE(1'b1, 1'b0, 2'b00, 8'hxx);
    CONFIG_IO_SEQUENCE(1'b1, 1'b0, 2'b00, 8'hxx);
    //
    // Overflow FIFO
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b00, 8'h00);
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b00, 8'h01);
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b00, 8'h02);
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b00, 8'h03);
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b00, 8'h04);
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b00, 8'h05);
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b00, 8'h06);
    CONFIG_IO_SEQUENCE(1'b1, 1'b1, 2'b00, 8'h07);
    CONFIG_IO_SEQUENCE(1'b1, 1'b0, 2'b00, 8'hxx);
    CONFIG_IO_SEQUENCE(1'b1, 1'b0, 2'b00, 8'hxx);
    CONFIG_IO_SEQUENCE(1'b1, 1'b0, 2'b00, 8'hxx);
    CONFIG_IO_SEQUENCE(1'b1, 1'b0, 2'b00, 8'hxx);
    CONFIG_IO_SEQUENCE(1'b1, 1'b0, 2'b00, 8'hxx);
    CONFIG_IO_SEQUENCE(1'b1, 1'b0, 2'b00, 8'hxx);
    CONFIG_IO_SEQUENCE(1'b1, 1'b0, 2'b00, 8'hxx);
    CONFIG_IO_SEQUENCE(1'b1, 1'b0, 2'b00, 8'hxx);
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


