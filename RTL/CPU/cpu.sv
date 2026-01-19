//===========================================================
// bfCPU Project
//-----------------------------------------------------------
// File Name   : cpu.sv
// Description : CPU Core
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.21 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025-2026 M.Maruyama
//===========================================================

//----------------------
// Define Constant
//----------------------
`define STATE_INIT   5'h00
`define STATE_DECODE 5'h01
//
`define STATE_PINC   5'h10
`define STATE_PDEC   5'h11
`define STATE_INC    5'h12
`define STATE_DEC    5'h13
`define STATE_OUT    5'h14
`define STATE_IN     5'h15
`define STATE_BEGIN  5'h16
`define STATE_END    5'h17
`define STATE_RESET  5'h18
`define STATE_NOP    5'h1f
//
`define OPCODE_PINC  4'h0
`define OPCODE_PDEC  4'h1
`define OPCODE_INC   4'h2
`define OPCODE_DEC   4'h3
`define OPCODE_OUT   4'h4
`define OPCODE_IN    4'h5
`define OPCODE_BEGIN 4'h6
`define OPCODE_END   4'h7
`define OPCODE_RESET 4'h8
`define OPCODE_NOP   4'hf
//
`define ALUFUNC_ZERO 4'h0
`define ALUFUNC_THRU 4'h1
`define ALUFUNC_INC  4'h2
`define ALUFUNC_DEC  4'h3

//----------------------------
// Module Top
//----------------------------
module CPU
(
    input  logic CLK,
    input  logic RES,
    //
    // CPU Instruction Fetch 
    //     PC Address (64kwords x 4bits)
    output logic        IF_REQ,
    output logic [15:0] IF_ADDR,
    input  logic [ 3:0] IF_CODE,
    input  logic        IF_RDY,
    //
    // CPU Data Memory Access
    //     PTR Address (32kbytes x 8bits)
    output logic        DM_REQ,
    output logic        DM_WRITE,
    output logic [14:0] DM_ADDR,
    output logic [ 7:0] DM_WDATA,
    input  logic [ 7:0] DM_RDATA,
    input  logic        DM_RDY,
    //
    // I/O Access
    output logic        IO_REQ,
    output logic        IO_WRITE,
    output logic [ 1:0] IO_ADDR,
    output logic [ 7:0] IO_WDATA,
    input  logic [ 7:0] IO_RDATA,
    input  logic        IO_RDY
);

//==========================================
// Control Slot
//==========================================
logic slot;
assign slot = IF_RDY & DM_RDY & IO_RDY;

//==========================================
// Data Path
//==========================================
//---------------------------------------------------------------
// Instruction Access 
//---------------------------------------------------------------
logic        if_do;
logic        if_do_dphase;
logic [15:0] if_addr; // PC Address (1word = 4bit)
logic [ 3:0] if_code;
logic [ 3:0] if_code_keep;
//
assign IF_REQ  = if_do & slot;
assign IF_ADDR = if_addr;
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        if_do_dphase <= 1'b0;
    else if (IF_REQ & IF_RDY)
        if_do_dphase <= 1'b1;
    else if (IF_RDY)
        if_do_dphase <= 1'b0;
end
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        if_code_keep <= 4'hf;
    else if (if_do_dphase & IF_RDY)
        if_code_keep <= IF_CODE;    
end
//
assign if_code = (if_do_dphase & IF_RDY)? IF_CODE : if_code_keep;

//---------------------------------------------------------------
// Data Access 
//---------------------------------------------------------------
logic        dr_do;
logic        dr_do_dphase;
logic        dw_do;
logic [14:0] dm_addr;
logic [ 7:0] dw_data;
logic [ 7:0] dr_data;
logic [ 7:0] dr_data_keep;
//
assign DM_REQ   = (dr_do | dw_do) & slot;
assign DM_WRITE = dw_do;
assign DM_ADDR  = dm_addr;
assign DM_WDATA = dw_data;
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        dr_do_dphase <= 1'b0;
    else if (DM_REQ & ~DM_WRITE & DM_RDY)
        dr_do_dphase <= 1'b1;
    else if (DM_RDY)
        dr_do_dphase <= 1'b0;
end
//
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        dr_data_keep <= 8'h00;
    else if (dr_do_dphase & DM_RDY)
        dr_data_keep <= DM_RDATA;    
end
//
assign dr_data = (dr_do_dphase & DM_RDY)? DM_RDATA : dr_data_keep;

//------------------------
// IO Access
//------------------------
logic       ir_do;
logic       iw_do;
logic       ir_do_dphase;
logic [7:0] iw_data;
logic [7:0] ir_data;
logic [7:0] ir_data_keep;
logic [1:0] io_addr;
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        ir_do_dphase <= 1'b0;
    else if (IO_REQ & ~IO_WRITE & IO_RDY)
        ir_do_dphase <= 1'b1;
    else if (slot)
        ir_do_dphase <= 1'b0;
end
//
assign IO_REQ   = (ir_do | iw_do) & slot;
assign IO_WRITE = iw_do;
assign IO_ADDR  = io_addr;
assign IO_WDATA = iw_data;
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        ir_data_keep <= 8'h00;
    else if (ir_do_dphase & IO_RDY)
        ir_data_keep <= IO_RDATA;    
end
//
assign ir_data = (ir_do_dphase & IO_RDY)? IO_RDATA : ir_data_keep;

//------------------------------------
// Program Counter
//------------------------------------
logic [15:0] pc;  // 64k-nibbles
logic        pc_clr;
logic        pc_inc;
logic        pc_dec;
logic        pc_inc2;
logic        pc_dec2;
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        pc <= 16'h0000;
    else if (pc_clr & slot)
        pc <= 16'h0000;
    else if (pc_inc & slot)
        pc <= pc + 16'h0001;
    else if (pc_dec & slot)
        pc <= pc - 16'h0001;
    else if (pc_inc2 & slot)
        pc <= pc + 16'h0002;
    else if (pc_dec2 & slot)
        pc <= pc - 16'h0002;
end
//
assign if_addr = pc;

//------------------------------------
// Data Pointer
//------------------------------------
logic [14:0] ptr; // 32k-bytes
logic        ptr_clr;
logic        ptr_inc;
logic        ptr_dec;
logic        ptr_end;
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        ptr <= 15'h0000;
    else if (ptr_clr & slot)
        ptr <= 15'h0000;
    else if (ptr_inc & slot)
        ptr <= ptr + 15'h0001;
    else if (ptr_dec & slot)
        ptr <= ptr - 15'h0001;
end
//
assign dm_addr = ptr;
//
`ifdef SIMULATION
assign ptr_end      = (ptr == 15'h001d);
`else
assign ptr_end      = (ptr == 15'h7ffd);
`endif

//------------------------------------
// Indent Counter
//------------------------------------
logic [15:0] indent;
logic        indent_clr;
logic        indent_inc;
logic        indent_dec;
logic        indent_zero;
logic        indent_plus;
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        indent <= 16'h0000;
    else if (indent_clr & slot)
        indent <= 16'h0000;
    else if (indent_inc & slot)
        indent <= indent + 16'h0001;
    else if (indent_dec & slot)
        indent <= indent - 16'h0001;
end
//
assign indent_zero = (indent == 16'h0000);
assign indent_plus = ~indent[15] & (|indent[14:0]);

//------------------------------------
// ALU
//------------------------------------
logic [3:0] alufunc;
logic [7:0] aluinx;
//logic [7:0] aluiny;
logic [7:0] aluout;
logic       aluzero;
logic       aluinx_dr;
logic       aluinx_ir;
//
assign aluinx = (aluinx_dr)? dr_data
              : (aluinx_ir)? ir_data
              : 8'h00;
//
always_comb
begin
    case (alufunc)
        `ALUFUNC_ZERO : aluout = 8'h00;
        `ALUFUNC_THRU : aluout = aluinx;
        `ALUFUNC_INC  : aluout = aluinx + 8'h01;
        `ALUFUNC_DEC  : aluout = aluinx - 8'h01;
        default       : aluout = 8'h00;
    endcase
end
//
assign aluzero = (aluout == 8'h00);
//
assign dw_data = aluout;
assign iw_data = aluout;

//==========================================
// Control Logic
//==========================================
//--------------------
// Decode State
//--------------------
logic [4:0] state;
logic [4:0] state_next;
logic [3:0] seq;
logic       seq_clr;
logic       seq_inc;
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        state <= `STATE_INIT;
    else if (slot)
        state <= state_next;
end
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        seq <= 4'h0;
    else if (seq_clr & slot)
        seq <= 4'h0;
    else if (seq_inc & slot)
        seq <= seq + 4'h1;
end

//----------------------
// State Transition
//----------------------
always @*
begin
    // Default Outputs
    state_next = `STATE_INIT;
    seq_clr    = 1'b0;
    seq_inc    = 1'b0;
    if_do   = 1'b0;
    pc_clr  = 1'b0;
    pc_inc  = 1'b0;
    pc_dec  = 1'b0;
    pc_inc2 = 1'b0;
    pc_dec2 = 1'b0;
    ptr_clr = 1'b0;
    ptr_inc = 1'b0;
    ptr_dec = 1'b0;
    dr_do = 1'b0;
    dw_do = 1'b0;
    ir_do = 1'b0;
    iw_do = 1'b0;
    io_addr = 2'b00;
    indent_clr = 1'b0;
    indent_inc = 1'b0;
    indent_dec = 1'b0;
    alufunc   = `ALUFUNC_ZERO;
    aluinx_dr = 1'b0;
    aluinx_ir = 1'b0;
    //    
    // Overwrite Outputs
    casez ({state, seq})
        //=========================================
        // Clear All DM (0x8000 - 0xFFFF)
        //=========================================
        // Initialize CPU Resources
        {`STATE_INIT, 4'h0} :
        begin
            pc_clr     = 1'b1;
            ptr_clr    = 1'b1;
            indent_clr = 1'b1;
            // Clear All Data Memory
            seq_inc    = 1'b1;
            state_next = `STATE_INIT;
        end
        //-----------------------------------------
        // Clear All Data Memory
        {`STATE_INIT, 4'h1} :
        begin
            // PTR Reaches at End, Goto Next Sequence
            if (ptr_end)
            begin
                // Invoke DM Write Zero 
                dw_do   = 1'b1;
                alufunc = `ALUFUNC_ZERO;
                // Increment PTR to read DIV0
                ptr_inc = 1'b1;
                // Next Sequence
                seq_inc = 1'b1;
                state_next = `STATE_INIT;
            end
            // Repeat *PTR++=0
            else
            begin
                // Invoke DM Write Zero 
                dw_do   = 1'b1;
                alufunc = `ALUFUNC_ZERO;
                // Increment PTR
                ptr_inc = 1'b1;
                // Stay in this State
                state_next = `STATE_INIT;
            end
        end
        //-----------------------------------------
        // Initialize UART Baud Rate (DIV0)
        {`STATE_INIT, 4'h2} :
        begin
            // Invoke DM Read at PTR=0x7ffe
            dr_do = 1'b1;
            // Next Sequence
            seq_inc = 1'b1;
            state_next = `STATE_INIT;
        end
        {`STATE_INIT, 4'h3} :
        begin
            // Get dr_data and pass it through ALU
            aluinx_dr = 1'b1;
            alufunc   = `ALUFUNC_THRU;
            // Invoke IO Write at DIV0
            iw_do = 1'b1;
            io_addr = 2'b10;
            // Increment PTR to read DIV1
            ptr_inc = 1'b1;
            // Next Sequence
            seq_inc = 1'b1;
            state_next = `STATE_INIT;
        end
        //-----------------------------------------
        // Initialize UART Baud Rate (DIV1)
        {`STATE_INIT, 4'h4} :
        begin
            // Invoke DM Read at PTR=0x7fff
            dr_do = 1'b1;
            // Next Sequence
            seq_inc = 1'b1;
            state_next = `STATE_INIT;
        end
        {`STATE_INIT, 4'h5} :
        begin
            // Get dr_data and pass it through ALU
            aluinx_dr = 1'b1;
            alufunc   = `ALUFUNC_THRU;
            // Invoke IO Write at DIV1
            iw_do = 1'b1;
            io_addr = 2'b11;
            // Clear PTR
            ptr_clr = 1'b1;
            // Invoke IF
            if_do  = 1'b1;
            pc_inc = 1'b1;
            // Next Instruction Decode
            seq_clr    = 1'b1;
            state_next = `STATE_DECODE;
        end
        //=========================================
        // Dispatch along with if_code
        //=========================================
        {`STATE_DECODE, 4'h0} :
        begin
            case (if_code)
                //---------------------------------
                `OPCODE_PINC, `OPCODE_PDEC : // Finishes in this stage
                begin
                    // Increment PTR, or Decrement PTR
                    ptr_inc = ~if_code[0];
                    ptr_dec =  if_code[0];
                    // Invoke IF
                    if_do  = 1'b1;
                    pc_inc = 1'b1;
                    // Next Instruction Decode
                    seq_clr    = 1'b1;
                    state_next = `STATE_DECODE;
                end
                //---------------------------------
                `OPCODE_INC, `OPCODE_DEC :
                begin
                    // Invoke DM Read
                    dr_do = 1'b1;
                    // Next Sequence
                    seq_inc    = 1'b1;
                    state_next = {1'b1, if_code};                
                end
                //---------------------------------
                `OPCODE_OUT :
                begin
                    // Invoke DM Read
                    dr_do = 1'b1;
                    // Next Sequence
                    seq_inc = 1'b1;
                    state_next = `STATE_OUT;
                end
                //---------------------------------
                `OPCODE_IN :
                begin
                    // Invoke IO Read
                    ir_do = 1'b1;
                    // Next Sequence
                    seq_inc = 1'b1;
                    state_next = `STATE_IN;
                end
                //---------------------------------
                `OPCODE_BEGIN, `OPCODE_END :
                begin
                    // Invoke DM Read
                    dr_do = 1'b1;
                    // Next Sequence
                    seq_inc = 1'b1;
                    state_next = {1'b1, if_code};
                end
                //---------------------------------
                `OPCODE_RESET :
                begin
                    // Restart
                    seq_clr = 1'b1;
                    state_next = `STATE_INIT;
                end
                //---------------------------------
                `OPCODE_NOP :
                begin
                    // Invoke IF
                    if_do  = 1'b1;
                    pc_inc = 1'b1;
                    // Next Instruction Decode
                    seq_clr    = 1'b1;
                    state_next = `STATE_DECODE;
                end
                //---------------------------------
                default : // No Operation
                begin
                    // Invoke IF
                    if_do  = 1'b1;
                    pc_inc = 1'b1;
                    // Next Instruction Decode
                    seq_clr    = 1'b1;
                    state_next = `STATE_DECODE;
                end
                //---------------------------------
            endcase        
        end        
        //=========================================
        // INC,DEC, from 2nd Step
        //=========================================
        {`STATE_INC, 4'h1}, {`STATE_DEC, 4'h1} :
        begin
            // Get dr_data and Increment or Decrement it by ALU
            aluinx_dr = 1'b1;
            alufunc   = state[3:0];
            // Invoke DM Write
            dw_do = 1'b1;
            // Invoke IF
            if_do  = 1'b1;
            pc_inc = 1'b1;
            // Next Instruction Decode
            seq_clr    = 1'b1;
            state_next = `STATE_DECODE;
        end
        //=========================================
        // OUT, from 2nd Step
        //=========================================
        {`STATE_OUT, 4'h1} :
        begin
            // Get dr_data and pass it through ALU
            aluinx_dr = 1'b1;
            alufunc   = `ALUFUNC_THRU;
            // Invoke IO Write
            iw_do = 1'b1;
            // Invoke IF
            if_do  = 1'b1;
            pc_inc = 1'b1;
            // Next Instruction Decode
            seq_clr    = 1'b1;
            state_next = `STATE_DECODE;
        end
        //=========================================
        // IN, from 2nd Step
        //=========================================
        {`STATE_IN, 4'h1} :
        begin
            // Get ir_data and pass it through ALU
            aluinx_ir = 1'b1;
            alufunc   = `ALUFUNC_THRU;
            // Invoke DM Write
            dw_do = 1'b1;
            // Invoke IF
            if_do  = 1'b1;
            pc_inc = 1'b1;
            // Next Instruction Decode
            seq_clr    = 1'b1;
            state_next = `STATE_DECODE;
        end
        //=========================================
        // BEGIN, from 2nd Step
        //=========================================
        {`STATE_BEGIN, 4'h1} :
        begin
            // Get dr_data and pass it through ALU
            aluinx_dr = 1'b1;
            alufunc = `ALUFUNC_THRU;
            // If (*PTR) != 0
            if (~aluzero)
            begin
                // Invoke IF
                if_do  = 1'b1;
                pc_inc = 1'b1;
                // Next Instruction Decode
                seq_clr    = 1'b1;
                state_next = `STATE_DECODE;
            end
            // If (*PTR) == 0
            else
            begin
                // Invoke IF
                if_do  = 1'b1;
                pc_inc = 1'b1;
                // Clear Indent
                indent_clr = 1'b1;
                // Next Sequence
                seq_inc = 1'b1;
                state_next = `STATE_BEGIN;
            end
        end
        {`STATE_BEGIN, 4'h2} :
        begin
            // Found Matched END
            if (indent_zero && (if_code == `OPCODE_END))
            begin
                // Invoke IF
                if_do  = 1'b1;
                pc_inc = 1'b1;
                // Next Instruction Decode
                seq_clr    = 1'b1;
                state_next = `STATE_DECODE;
            end
            // Found Unmatched END
            else if (indent_plus && (if_code == `OPCODE_END))
            begin
                // Decrement Indent
                indent_dec = 1'b1;
                // Invoke IF
                if_do  = 1'b1;
                pc_inc = 1'b1;
                // Stay in this State
                state_next = `STATE_BEGIN;
            end
            // Found Nested BEGIN
            else if (if_code == `OPCODE_BEGIN)
            begin
                // Increment Indent
                indent_inc = 1'b1;
                // Invoke IF
                if_do  = 1'b1;
                pc_inc = 1'b1;
                // Stay in this State
                state_next = `STATE_BEGIN;
            end
            // Other Instructions
            else
            begin
                // Invoke IF
                if_do  = 1'b1;
                pc_inc = 1'b1;
                // Stay in this State
                state_next = `STATE_BEGIN;
            end                    
        end        
        //=========================================
        // END, from 2nd Step
        //=========================================
        {`STATE_END, 4'h1} :
        begin
            // Get dr_data and pass it through ALU
            aluinx_dr = 1'b1;
            alufunc = `ALUFUNC_THRU;
            // If (*PTR) == 0
            if (aluzero)
            begin
                // Invoke IF
                if_do  = 1'b1;
                pc_inc = 1'b1;
                // Next Instruction Decode
                seq_clr    = 1'b1;
                state_next = `STATE_DECODE;
            end
            // If (*PTR) != 0
            else
            begin
                // PC = PC - 2
                pc_dec2 = 1'b1;
                // Clear Indent
                indent_clr = 1'b1;
                // Next Sequence
                seq_inc = 1'b1;
                state_next = `STATE_END;
            end
        end
        {`STATE_END, 4'h2} :
        begin
            // Invoke IF
            if_do  = 1'b1;
            pc_dec = 1'b1;
            // Next Sequence
            seq_inc = 1'b1;
            state_next = `STATE_END;
        end
        {`STATE_END, 4'h3} :
        begin
            // Found Matched BEGIN
            if (indent_zero && (if_code == `OPCODE_BEGIN))
            begin
                // PC = PC + 2
                pc_inc2 = 1'b1;
                // Next Sequence
                seq_inc = 1'b1;
                state_next = `STATE_END;
            end
            // Found Unmatched BEGIN
            else if (indent_plus && (if_code == `OPCODE_BEGIN))
            begin
                // Decrement Indent
                indent_dec = 1'b1;
                // Invoke IF
                if_do  = 1'b1;
                pc_dec = 1'b1;
                // Stay in this State
                state_next = `STATE_END;
            end
            // Found Nested END
            else if (if_code == `OPCODE_END)
            begin
                // Increment Indent
                indent_inc = 1'b1;
                // Invoke IF
                if_do  = 1'b1;
                pc_dec = 1'b1;
                // Stay in this State
                state_next = `STATE_END;
            end
            // Other Instructions
            else
            begin
                // Invoke IF
                if_do  = 1'b1;
                pc_dec = 1'b1;
                // Stay in this State
                state_next = `STATE_END;
            end                    
        end        
        {`STATE_END, 4'h4} :
        begin
            // Invoke IF
            if_do  = 1'b1;
            pc_inc = 1'b1;
            // Next Instruction Decode
            seq_clr    = 1'b1;
            state_next = `STATE_DECODE;
        end
        //=========================================
        default : // Never Reach Here
        begin
            seq_clr    = 1'b1;
            state_next = `STATE_INIT;
        end
        //=========================================
    endcase
end

endmodule
//===========================================================
// End of File
//===========================================================
