//===========================================================
// bfCPU Project
//-----------------------------------------------------------
// File Name   : tb.sv
// Description : Testbench for FPGA Top
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.21 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025-2026 M.Maruyama
//===========================================================

`timescale 1ns/10ps

`define TB_CYCLE           100 //ns
`define TB_FINISH_COUNT  50000 //cyc
`define TB_UART_BITWIDTH  3200 //ns 
//`define TB_UART_BITWIDTH  8681 //ns (115200bps)

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
// Initialize RAM
//---------------------
initial
begin
    // Initialzie Whole Mat (to avoid get unknown data)
    for (i = 0; i < 65536; i = i + 1) U_M23LC512.MemoryBlock[i] = 8'(i);
    //
    // Program Code
  //$readmemh("./ROM/cache.v", U_M23LC512.MemoryBlock);
  //$readmemh("./ROM/addition.v", U_M23LC512.MemoryBlock);
    $readmemh("./ROM/multiplication.v", U_M23LC512.MemoryBlock);
  //$readmemh("./ROM/helloworld.v", U_M23LC512.MemoryBlock);
  //$readmemh("./ROM/life.v", U_M23LC512.MemoryBlock);
    //
    // UART Baud Rate (Simulaiton)
    U_M23LC512.MemoryBlock[32768+30] = 8'h02; // DIV0
    U_M23LC512.MemoryBlock[32768+31] = 8'h02; // DIV1
    // UART Baud Rate (115200bps)
  //U_M23LC512.MemoryBlock[32768+32766] = 8'h09; // DIV0
  //U_M23LC512.MemoryBlock[32768+32767] = 8'h02; // DIV1
end

//---------------------
// Chip Top
//---------------------
wire         qspi_cs_n;
wire         qspi_sck;
wire  [ 3:0] qspi_sio;
logic uart_txd;
logic uart_rxd;
logic led;
//
FPGA U_FPGA
(
    .CLK    (clk),
    .RES_N  (~res),
    //
    .QSPI_CS_N  (qspi_cs_n),
    .QSPI_SCK   (qspi_sck),
    .QSPI_SIO   (qspi_sio),
    //
    .UART_TXD   (uart_txd),
    .UART_RXD   (uart_rxd),
    //
    .LED   (led)
);

//-----------------------------
// SPIRAM (23LC512)
//-----------------------------
pullup (qspi_cs_n);
pullup (qspi_sck);
pullup (qspi_sio[0]);
pullup (qspi_sio[1]);
pullup (qspi_sio[2]);
pullup (qspi_sio[3]);
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

//-----------------------------
// UART Generate Receive Data
//-----------------------------
logic detect_in;
logic [7:0] tx_data;
//
always_ff @(posedge clk, posedge res)
begin
    if (res)
        detect_in <= 1'b0;
    else
        detect_in <= U_FPGA.U_TOP.U_UART.rxd_dphase;

end
//
logic [7:0] uart_rxd_data[0:255];
logic [7:0] uart_rxd_seq;
//
initial
begin
    uart_rxd = 1'b1;
    uart_rxd_seq = 8'h00;
    //
    for (i = 0; i < 256; i = i + 1) uart_rxd_data[i] = 8'(i+2);
  //uart_rxd_data[0] = 10; // LF (0x0A) for life.v
    //
    @(posedge clk);
    @(negedge res);
    @(posedge clk);
    //
    forever
    begin
        @(posedge detect_in);
        // Message
        $display("===== UART RxD ===== (IN ) at 0x%02x", uart_rxd_data[uart_rxd_seq]);
        // Make RXD Signal
        #(1);
        #(`TB_UART_BITWIDTH);
        uart_rxd = 1'b0;
        #(`TB_UART_BITWIDTH);
        uart_rxd = uart_rxd_data[uart_rxd_seq][0];
        #(`TB_UART_BITWIDTH);
        uart_rxd = uart_rxd_data[uart_rxd_seq][1];
        #(`TB_UART_BITWIDTH);
        uart_rxd = uart_rxd_data[uart_rxd_seq][2];
        #(`TB_UART_BITWIDTH);
        uart_rxd = uart_rxd_data[uart_rxd_seq][3];
        #(`TB_UART_BITWIDTH);
        uart_rxd = uart_rxd_data[uart_rxd_seq][4];
        #(`TB_UART_BITWIDTH);
        uart_rxd = uart_rxd_data[uart_rxd_seq][5];
        #(`TB_UART_BITWIDTH);
        uart_rxd = uart_rxd_data[uart_rxd_seq][6];
        #(`TB_UART_BITWIDTH);
        uart_rxd = uart_rxd_data[uart_rxd_seq][7];
        #(`TB_UART_BITWIDTH);
        uart_rxd = 1'b1;
        uart_rxd_seq = uart_rxd_seq + 8'h01;
    end
end

//-----------------------------
// UART Detect Traansmit Data
//-----------------------------
logic [7:0] uart_txd_data;
//
initial
begin
    @(posedge clk);
    @(negedge res);
    @(posedge clk);
    //
    forever
    begin
        @(negedge uart_txd);
        uart_txd_data = 8'h00;
        #(`TB_UART_BITWIDTH / 2);
        // start bit
        #(`TB_UART_BITWIDTH);
        uart_txd_data[0] = uart_txd;
        #(`TB_UART_BITWIDTH);
        uart_txd_data[1] = uart_txd;
        #(`TB_UART_BITWIDTH);
        uart_txd_data[2] = uart_txd;
        #(`TB_UART_BITWIDTH);
        uart_txd_data[3] = uart_txd;
        #(`TB_UART_BITWIDTH);
        uart_txd_data[4] = uart_txd;
        #(`TB_UART_BITWIDTH);
        uart_txd_data[5] = uart_txd;
        #(`TB_UART_BITWIDTH);
        uart_txd_data[6] = uart_txd;
        #(`TB_UART_BITWIDTH);
        uart_txd_data[7] = uart_txd;
        #(`TB_UART_BITWIDTH);
        // stop bit
        //
        // Message
        $display("===== UART TxD ===== (OUT) at 0x%02x", uart_txd_data);
    end
end

//--------------------------
// Task : UART Send to RXD
//--------------------------
task UART_INIT_RXD();
begin
    uart_rxd = 1'b1;
end
endtask
//
task UART_SEND_RXD(input [7:0] DATA);
begin    
    // Start Bit
    uart_rxd = 1'b0;
    #(`TB_UART_BITWIDTH);
    // Data
    for (i = 0; i < 8; i = i + 1)
    begin
        uart_rxd = DATA[i];
        #(`TB_UART_BITWIDTH);
    end
    // Stop Bit
    uart_rxd = 1'b1;
    #(`TB_UART_BITWIDTH);
end
endtask

//--------------------------
// Input Pattern (Stimulus)
//--------------------------
initial
begin
    UART_INIT_RXD();
    @(posedge clk);
    @(negedge res);
    @(posedge clk);
    // Start
  //UART_SEND_RXD(8'h55);

end

endmodule
//===========================================================
// End of File
//===========================================================


