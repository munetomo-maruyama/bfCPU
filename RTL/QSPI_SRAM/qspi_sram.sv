//===========================================================
// bfCPU Project
//-----------------------------------------------------------
// File Name   : qspi_sram.sv
// Description : QSPI SRAM Interface
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.21 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025-2026 M.Maruyama
//===========================================================
//-----------------------------
// Define States
//-----------------------------
`define STATE_STUP 3'b000
`define STATE_IDLE 3'b010
`define STATE_INIT 3'b011
`define STATE_READ 3'b100
`define STATE_WRTE 3'b101

//-------------------
// Module Top
//-------------------
module QSPI_SRAM
(
    input  logic CLK,
    input  logic RES,
    //
    input  logic        BUS_REQ,
    input  logic        BUS_WRITE,
    input  logic [15:0] BUS_ADDR,
    input  logic [ 7:0] BUS_WDATA,
    output logic [ 7:0] BUS_RDATA,
    output logic        BUS_RDY,
    //
    output logic       QSPI_CS_N,
    output logic       QSPI_SCK,
    output logic [3:0] QSPI_SIO_O,
    output logic [3:0] QSPI_SIO_E,
    input  logic [3:0] QSPI_SIO_I
);

//==========================================
// Data Path Logic
//==========================================
//------------------------
// BUS Access Request
//------------------------
logic req_read;
logic req_wrte;
//
assign req_read = BUS_REQ & ~BUS_WRITE & BUS_RDY;
assign req_wrte = BUS_REQ &  BUS_WRITE & BUS_RDY;

//------------------
// Bus Address
//------------------
logic [15:0] addr;
logic        addr_inc;
logic        addr_ovf;
logic        addr_cont;
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        addr <= 16'h0000;
    else if (req_read | req_wrte)
        addr <= BUS_ADDR;
    else if (addr_inc)
        addr <= addr + 16'h0001;
end
//
`ifdef SIMULATION
assign addr_ovf = (addr == 16'h8004);
`else
assign addr_ovf = (addr == 16'h0000);
`endif
assign addr_cont = BUS_REQ & (addr == BUS_ADDR) & BUS_RDY;

//------------------
// Bus Write Data
//------------------
logic [7:0] wdata;
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        wdata <= 8'h00;
    else if (req_wrte)
        wdata <= BUS_WDATA;
end

//------------------
// Bus Read Data
//------------------
logic [7:0] rdata;
//
assign BUS_RDATA = rdata;

//------------------
// Bus Ready
//------------------
logic bus_ready_set;
logic bus_ready_clr;
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        BUS_RDY <= 1'b0;
    else if (bus_ready_clr &  BUS_RDY)
        BUS_RDY <= 1'b0;
    else if (bus_ready_set & ~BUS_RDY)
        BUS_RDY <= 1'b1;
end        

//----------------------
// QSPI CS_N Control
//----------------------
logic qspi_csn_assert;
logic qspi_csn_negate;
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        QSPI_CS_N <= 1'b1;
    else if (qspi_csn_assert)
        QSPI_CS_N <= 1'b0;
    else if (qspi_csn_negate)
        QSPI_CS_N <= 1'b1;
end

//----------------------
// QSPI SCK Control
//----------------------
logic qspi_sckenb;
logic qspi_sckenb_set;
logic qspi_sckenb_clr;
//
logic qspi_sckenb2;
logic qspi_scke;
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        qspi_sckenb <= 1'b0;
    else if (qspi_sckenb_set)
        qspi_sckenb <= 1'b1;
    else if (qspi_sckenb_clr)
        qspi_sckenb <= 1'b0;
end
//
// Nagatieve Edge
always_ff @(negedge CLK, posedge RES)
begin
    if (RES)
        qspi_sckenb2 <= 1'b0;
    else
        qspi_sckenb2 <= qspi_sckenb;
end
//
assign qspi_scke = qspi_sckenb & qspi_sckenb2;
assign QSPI_SCK = ~CLK & qspi_scke;

//----------------------
// QSPI TXD Register
//----------------------
logic [7:0] qspi_txd;
logic       qspi_txd_set_eqio;
logic       qspi_txd_set_rdcmd;
logic       qspi_txd_set_wrcmd;
logic       qspi_txd_set_addrh;
logic       qspi_txd_set_addrl;
logic       qspi_txd_set_wdata_spi;
logic       qspi_txd_set_wdata_qspi;
logic       qspi_txd_set_wdata_qspi_fwd;
logic       qspi_txd_sft_1bit;
logic       qspi_txd_sft_4bit;
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        qspi_txd <= 8'h00;
    //
    else if (qspi_txd_set_wdata_spi)
        qspi_txd <= {wdata[2:0], wdata[7], wdata[6:3]};
    else if (qspi_txd_sft_1bit)
        qspi_txd <= {qspi_txd[6:0], qspi_txd[7]};
    else if (qspi_txd_set_eqio)
        qspi_txd <= 8'b000_00111; //8'h38;
    //
    else if (qspi_txd_set_wdata_qspi)
        qspi_txd <= wdata[7:0];
    else if (qspi_txd_set_wdata_qspi_fwd)
        qspi_txd <= BUS_WDATA;
    else if (qspi_txd_sft_4bit)
        qspi_txd <= {qspi_txd[3:0], qspi_txd[7:4]};
    //
    else if (qspi_txd_set_rdcmd)
        qspi_txd <= 8'h03;
    else if (qspi_txd_set_wrcmd)
        qspi_txd <= 8'h02;
    else if (qspi_txd_set_addrh)
        qspi_txd <= addr[15:8];
    else if (qspi_txd_set_addrl)
        qspi_txd <= addr[ 7:0];
end
//
assign QSPI_SIO_O[0] = qspi_txd[4]; // spi bit7-->bit0
assign QSPI_SIO_O[1] = qspi_txd[5];
assign QSPI_SIO_O[2] = qspi_txd[6];
assign QSPI_SIO_O[3] = qspi_txd[7];
//
logic [3:0] qspi_sio_e_set;
logic [3:0] qspi_sio_e_clr;
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        QSPI_SIO_E[0] <= 1'b0;
    else if (qspi_sio_e_set[0])
        QSPI_SIO_E[0] <= 1'b1;
    else if (qspi_sio_e_clr[0])
        QSPI_SIO_E[0] <= 1'b0;
end
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        QSPI_SIO_E[1] <= 1'b0;
    else if (qspi_sio_e_set[1])
        QSPI_SIO_E[1] <= 1'b1;
    else if (qspi_sio_e_clr[1])
        QSPI_SIO_E[1] <= 1'b0;
end
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        QSPI_SIO_E[2] <= 1'b0;
    else if (qspi_sio_e_set[2])
        QSPI_SIO_E[2] <= 1'b1;
    else if (qspi_sio_e_clr[2])
        QSPI_SIO_E[2] <= 1'b0;
end
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        QSPI_SIO_E[3] <= 1'b0;
    else if (qspi_sio_e_set[3])
        QSPI_SIO_E[3] <= 1'b1;
    else if (qspi_sio_e_clr[3])
        QSPI_SIO_E[3] <= 1'b0;
end

//----------------------
// QSPI RXD Register
//----------------------
logic       qspi_rxd_capture;
logic [3:0] qspi_rxd_temp;
logic [7:0] qspi_rxd;
logic       qspi_rxd_set_hi;
logic       qspi_rxd_set_lo;
//
// Negative Edge
always_ff @(negedge CLK, posedge RES)
begin
    if (RES)
        qspi_rxd_temp <= 4'h0;
    else if (qspi_rxd_capture)
        qspi_rxd_temp <= QSPI_SIO_I;
end
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        qspi_rxd <= 8'h00;
    else if (qspi_rxd_set_hi)
        qspi_rxd <= {qspi_rxd_temp, qspi_rxd[3:0]};
    else if (qspi_rxd_set_lo)
        qspi_rxd <= {qspi_rxd[7:4], qspi_rxd_temp};    
end
//
assign rdata = qspi_rxd;

//==========================================
// Control Logic
//==========================================
//--------------------------
// State Transition
//--------------------------
logic [2:0] state;
logic [2:0] state_next;
logic       state_update;
//
logic [3:0] seq;
logic       seq_clr;
logic       seq_inc;
logic       seq_dec;
logic       seq_dec2;
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        state <= `STATE_STUP;
    else if (state_update) 
        state <= state_next;
end
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        seq <= 4'h0;
    else if (seq_clr)
        seq <= 4'h0;
    else if (seq_inc)
        seq <= seq + 4'h1;
    else if (seq_dec)
        seq <= seq - 4'h1;
    else if (seq_dec2)
        seq <= seq - 4'h2;
end

//----------------------
// Control Signals
//----------------------
always_comb
begin
    //------------------
    // Default Outputs
    //------------------
    state_next = `STATE_STUP;
    state_update = 1'b0;
    seq_clr  = 1'b0;
    seq_inc  = 1'b0;
    seq_dec  = 1'b0;
    seq_dec2 = 1'b0;
    //
    bus_ready_set = 1'b0;
    bus_ready_clr = 1'b0;
    //
    addr_inc = 1'b0;
    //
    qspi_csn_assert = 1'b0;
    qspi_csn_negate = 1'b0;
    //
    qspi_sckenb_set = 1'b0;
    qspi_sckenb_clr = 1'b0;
    //
    qspi_txd_set_eqio  = 1'b0;
    qspi_txd_set_rdcmd = 1'b0;
    qspi_txd_set_wrcmd = 1'b0;
    qspi_txd_set_addrh = 1'b0;
    qspi_txd_set_addrl = 1'b0;
    qspi_txd_set_wdata_spi  = 1'b0;
    qspi_txd_set_wdata_qspi = 1'b0;
    qspi_txd_set_wdata_qspi_fwd = 1'b0;
    qspi_txd_sft_1bit  = 1'b0;
    qspi_txd_sft_4bit  = 1'b0;
    //
    qspi_sio_e_set = 4'b0000;
    qspi_sio_e_clr = 4'b0000;
    //
    qspi_rxd_capture = 1'b0;
    qspi_rxd_set_hi  = 1'b0;
    qspi_rxd_set_lo  = 1'b0;
    //
    //---------------------
    // Overwrite Outputs
    //---------------------
    case (state)
        //==================================================
        `STATE_STUP :
        begin
            seq_clr      = 1'b1;
            state_next   = `STATE_INIT;
            state_update = 1'b1;
        end
        //==================================================
        `STATE_INIT :
        begin
            case (seq)
                //------------------------------------------
                4'h0 :
                begin
                    qspi_csn_assert   = 1'b1;
                    qspi_sckenb_set   = 1'b1;
                    qspi_txd_set_eqio = 1'b1;
                    qspi_sio_e_set    = 4'b0001;
                    seq_inc           = 1'b1;
                end
                //------------------------------------------
                4'h1, 4'h2, 4'h3, 4'h4, 4'h5, 4'h6 :
                begin
                    qspi_txd_sft_1bit = 1'b1;
                    seq_inc           = 1'b1;
                end
                //------------------------------------------
                4'h7 :
                begin
                    qspi_txd_sft_1bit = 1'b1;
                    bus_ready_set     = 1'b1;
                    seq_inc           = 1'b1;
                end
                //------------------------------------------
                4'h8 :
                begin
                    qspi_csn_negate = 1'b1;
                    qspi_sckenb_clr = 1'b1;                    
                    qspi_sio_e_clr  = 4'b0001;
                    seq_clr         = 1'b1;
                    state_next      = (req_wrte)? `STATE_WRTE
                                    : (req_read)? `STATE_READ
                                    :             `STATE_IDLE;
                    bus_ready_clr   = req_wrte | req_read;
                    state_update    = 1'b1;
                end
                //------------------------------------------
                default : // Never Reach Here
                begin
                    seq_clr      = 1'b1;
                    state_next   = `STATE_STUP;
                    state_update = 1'b1;
                end
                //------------------------------------------
            endcase
        end
        //==================================================
        `STATE_IDLE :
        begin
                    seq_clr         = 1'b1;
                    state_next      = (req_wrte)? `STATE_WRTE
                                    : (req_read)? `STATE_READ
                                    :             `STATE_IDLE;
                    bus_ready_clr   = req_wrte | req_read;
                    state_update    = 1'b1;
        end
        //==================================================
        `STATE_WRTE :
        begin
            case (seq)
                //------------------------------------------
                4'h0 :
                begin
                    qspi_csn_assert    = 1'b1;
                    qspi_sckenb_set    = 1'b1;
                    qspi_txd_set_wrcmd = 1'b1;
                    qspi_sio_e_set     = 4'b1111;
                    seq_inc            = 1'b1;
                end
                //------------------------------------------
                4'h1 :
                begin
                    qspi_txd_sft_4bit = 1'b1;
                    seq_inc           = 1'b1;
                end
                //------------------------------------------
                4'h2 :
                begin
                    qspi_txd_set_addrh = 1'b1;
                    seq_inc            = 1'b1;
                end
                //------------------------------------------
                4'h3 :
                begin
                    qspi_txd_sft_4bit = 1'b1;
                    seq_inc           = 1'b1;
                end
                //------------------------------------------
                4'h4 :
                begin
                    qspi_txd_set_addrl = 1'b1;
                    seq_inc            = 1'b1;
                end
                //------------------------------------------
                4'h5 :
                begin
                    qspi_txd_sft_4bit = 1'b1;
                    seq_inc           = 1'b1;
                end
                //------------------------------------------
                4'h6 :
                begin
                    qspi_txd_set_wdata_qspi = 1'b1;
                    seq_inc                 = 1'b1;
                end
                //------------------------------------------
                4'h7 :
                begin
                    qspi_txd_sft_4bit = 1'b1;
                    bus_ready_set     = 1'b1;
                    addr_inc          = 1'b1;
                    seq_inc           = 1'b1;
                end
                //------------------------------------------
                4'h8 :
                begin
                    if (req_wrte & addr_cont)
                    begin
                        bus_ready_clr   = 1'b1;
                        qspi_txd_set_wdata_qspi_fwd = 1'b1;
                        qspi_sckenb_set = 1'b1;
                        qspi_sio_e_set  = 4'b1111;
                        seq_dec         = 1'b1;
                    end
                    else if (req_wrte | req_read)
                    begin
                        qspi_csn_negate = 1'b1;
                        qspi_sckenb_clr = 1'b1;
                        qspi_sio_e_clr  = 4'b1111;
                        seq_clr         = 1'b1;
                        state_next      = (req_wrte)? `STATE_WRTE
                                        : (req_read)? `STATE_READ
                                        :             state;
                        bus_ready_clr   = 1'b1;
                        state_update    = 1'b1;
                    end
                    else
                    begin
                        // wait for bus acccess command
                        qspi_sckenb_clr = 1'b1;
                        qspi_sio_e_clr  = 4'b1111;
                    end
                end
                //------------------------------------------
                default : // Never Reach Here
                begin
                    seq_clr      = 1'b1;
                    state_next   = `STATE_STUP;
                    state_update = 1'b1;
                end
                //------------------------------------------
            endcase
        end
        //==================================================
        `STATE_READ :
        begin
            case (seq)
                //------------------------------------------
                4'h0 :
                begin
                    qspi_csn_assert    = 1'b1;
                    qspi_sckenb_set    = 1'b1;
                    qspi_txd_set_rdcmd = 1'b1;
                    qspi_sio_e_set     = 4'b1111;
                    seq_inc            = 1'b1;
                end
                //------------------------------------------
                4'h1 :
                begin
                    qspi_txd_sft_4bit = 1'b1;
                    seq_inc           = 1'b1;
                end
                //------------------------------------------
                4'h2 :
                begin
                    qspi_txd_set_addrh = 1'b1;
                    seq_inc            = 1'b1;
                end
                //------------------------------------------
                4'h3 :
                begin
                    qspi_txd_sft_4bit = 1'b1;
                    seq_inc           = 1'b1;
                end
                //------------------------------------------
                4'h4 :
                begin
                    qspi_txd_set_addrl = 1'b1;
                    seq_inc            = 1'b1;
                end
                //------------------------------------------
                4'h5 :
                begin
                    qspi_txd_sft_4bit = 1'b1;
                    seq_inc           = 1'b1;
                end
                //------------------------------------------
                4'h6 :
                begin
                    qspi_sio_e_clr = 4'b1111;
                    seq_inc        = 1'b1;
                end
                //------------------------------------------
                4'h7, 4'h8 :
                begin
                    seq_inc        = 1'b1;
                end
                //------------------------------------------
                4'h9 :
                begin
                    qspi_rxd_capture = 1'b1;
                    qspi_rxd_set_hi  = 1'b1;
                    addr_inc         = 1'b1;
                    seq_inc          = 1'b1;
                end
                //------------------------------------------
                4'ha :
                begin
                    qspi_sckenb_clr  = 1'b1;
                    qspi_rxd_capture = 1'b1;
                    qspi_rxd_set_lo  = 1'b1;
                    bus_ready_set    = 1'b1;
                    seq_inc          = 1'b1;
                end
                //------------------------------------------
                4'hb :
                begin
                    if (req_read & addr_cont)
                    begin
                        bus_ready_clr   = 1'b1;
                        qspi_sckenb_set = 1'b1;
                        seq_dec2        = 1'b1;
                    end
                    else if (req_wrte | req_read)
                    begin
                        qspi_csn_negate = 1'b1;
                        qspi_sckenb_clr = 1'b1;
                        qspi_sio_e_clr  = 4'b1111;
                        seq_clr         = 1'b1;
                        state_next      = (req_wrte)? `STATE_WRTE
                                        : (req_read)? `STATE_READ
                                        :             state;
                        bus_ready_clr   = 1'b1;
                        state_update    = 1'b1;
                    end
                    else
                    begin
                        // wait for bus acccess command
                    end
                end
                //------------------------------------------
                default : // Never Reach Here
                begin
                    seq_clr      = 1'b1;
                    state_next   = `STATE_STUP;
                    state_update = 1'b1;
                end
                //------------------------------------------
            endcase
        end
        //==================================================
        default : // Never Reach Here
        begin
            seq_clr      = 1'b1;
            state_next   = `STATE_STUP;
            state_update = 1'b1;
        end
        //==================================================
    endcase
end

endmodule
//===========================================================
// End of File
//===========================================================
