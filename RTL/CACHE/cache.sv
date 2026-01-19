//===========================================================
// bfCPU Project
//-----------------------------------------------------------
// File Name   : cache.sv
// Description : Instruction Cache / Data Cache
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.21 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025-2026 M.Maruyama
//===========================================================

//===============================================================
//---------------------------------------------------------------
// If you want to remove the cache, comment out a line below.
`define USE_CACHE
//---------------------------------------------------------------
//===============================================================

//----------------------------
// Module Top
//----------------------------
module CACHE
(
    // System Signal
    input  logic CLK,
    input  logic RES,
    //
    // CPU Instruction Fetch 
    //     PC Address (64kwords x 4bits)
    input  logic        IF_REQ,
    input  logic [15:0] IF_ADDR,
    output logic [ 3:0] IF_CODE,
    output logic        IF_RDY,
    //
    // CPU Data Memory Access
    //     PTR Address (32kbytes x 8bits)
    input  logic        DM_REQ,
    input  logic        DM_WRITE,
    input  logic [14:0] DM_ADDR,
    input  logic [ 7:0] DM_WDATA,
    output logic [ 7:0] DM_RDATA,
    output logic        DM_RDY,
    //
    // External Bus Access
    //     64kbytes x 8bits
    output logic        BUS_REQ,
    output logic        BUS_WRITE,
    output logic [15:0] BUS_ADDR,
    output logic [ 7:0] BUS_WDATA,
    input  logic [ 7:0] BUS_RDATA,
    input  logic        BUS_RDY
);

//===============================================================
//---------------------------------------------------------------
// Cache Enable
//---------------------------------------------------------------
//===============================================================
`ifdef USE_CACHE
//===============================================================
// Instruction Cache 
//     Direct Map
//     Entry = 1
//     Line  = 4bytes = 8instructions
//===============================================================
//1
// Slot
logic if_slot; // Slot of Instruction Fetch
//
// I-Cache Body
logic [12:0] ic_a; // Address Array, Upper 16-3=13bits
logic [31:0] ic_d; // Data Array, 1line = 4bytes = 8instructions 
logic        ic_v; // Valid Bit
//
// I-Cache Hit Access
logic        if_hit;
logic        if_hit_dphase;
logic [ 2:0] if_hit_dphase_addr; // Address in a line
//
assign if_hit = IF_REQ & ic_v & (ic_a == IF_ADDR[15:3]);
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        if_hit_dphase      <= 1'b0;
        if_hit_dphase_addr <= 3'b000;
    end
    else if (if_hit & if_slot)
    begin
        if_hit_dphase      <= 1'b1;
        if_hit_dphase_addr <= IF_ADDR[2:0];
    end
    else if (if_slot)
    begin
        if_hit_dphase      <= 1'b0;
        if_hit_dphase_addr <= 3'b000;
    end
end    
//
// I-Cache Miss Access
logic        if_mis_req;
logic [15:0] if_mis_req_addr; // 1byte= 2codes
logic        if_mis_dphase;
logic [15:0] if_mis_dphase_addr;
logic [31:0] if_mis_dphase_rdata;
//
assign if_mis_req = IF_REQ & ~if_hit;
assign if_mis_req_addr = {1'b0, IF_ADDR[15:1]};
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        if_mis_dphase      <= 1'b0;
        if_mis_dphase_addr <= 16'h0000;
    end
    else if (if_mis_req & if_slot)
    begin
        if_mis_dphase      <= 1'b1;
        if_mis_dphase_addr <= IF_ADDR[15:0];        
    end
    else if (if_slot)
    begin
        if_mis_dphase      <= 1'b0;
        if_mis_dphase_addr <= 16'h0000;
    end
end
//
// I-Cache Valid Bit
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        ic_v <= 1'b0;
    else if (if_mis_req & & if_slot)
        ic_v <= 1'b1;
end
//
// I-Cache Address Array
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        ic_a <= 13'h0000;
    else if (if_mis_req & if_slot)
    begin
        ic_a <= IF_ADDR[15:3];
    end
end
//
// I-Cache Data Array
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        ic_d <= 32'h00000000;
    else if (if_mis_dphase & if_slot)
    begin
        ic_d <= if_mis_dphase_rdata;
    end
end
//
// Generate Instruction Fetch Code
always @*
begin
    // Hit Access, Code from I-Cache
    if (if_hit_dphase & if_slot)
        IF_CODE = (if_hit_dphase_addr[2:0] == 3'b000)? ic_d[ 3: 0]
                : (if_hit_dphase_addr[2:0] == 3'b001)? ic_d[ 7: 4]
                : (if_hit_dphase_addr[2:0] == 3'b010)? ic_d[11: 8]
                : (if_hit_dphase_addr[2:0] == 3'b011)? ic_d[15:12]
                : (if_hit_dphase_addr[2:0] == 3'b100)? ic_d[19:16]
                : (if_hit_dphase_addr[2:0] == 3'b101)? ic_d[23:20]
                : (if_hit_dphase_addr[2:0] == 3'b110)? ic_d[27:24]
                : (if_hit_dphase_addr[2:0] == 3'b111)? ic_d[31:28]
                : 4'hf; // NOP
    // Miss Access, Code from BUS
    else if (if_mis_dphase & if_slot)
        IF_CODE = (if_mis_dphase_addr[2:0] == 3'b000)? if_mis_dphase_rdata[ 3: 0]
                : (if_mis_dphase_addr[2:0] == 3'b001)? if_mis_dphase_rdata[ 7: 4]
                : (if_mis_dphase_addr[2:0] == 3'b010)? if_mis_dphase_rdata[11: 8]
                : (if_mis_dphase_addr[2:0] == 3'b011)? if_mis_dphase_rdata[15:12]
                : (if_mis_dphase_addr[2:0] == 3'b100)? if_mis_dphase_rdata[19:16]
                : (if_mis_dphase_addr[2:0] == 3'b101)? if_mis_dphase_rdata[23:20]
                : (if_mis_dphase_addr[2:0] == 3'b110)? if_mis_dphase_rdata[27:24]
                : (if_mis_dphase_addr[2:0] == 3'b111)? if_mis_dphase_rdata[31:28]
                : 4'hf; // NOP
    else
        IF_CODE = 4'hf; // NOP
end
//
// Return Ready
assign IF_RDY = if_slot;

//===============================================================
// Data Cache 
//     Direct Map, Write Back
//     Entry = 1
//     Line  = 4bytes
//===============================================================
//
// Slot
logic dm_slot; // Slot of Data Memory Access
//
// D-Cache Body
logic [12:0] dc_a; // Address Array, Upper 15-2=13bits
logic [31:0] dc_d; // Data Array, 1line = 4bytes 
logic        dc_v; // Valid Bit
//
// D-Cache Hit Access
logic        dm_hit;
logic        dm_hit_dphase;
logic        dm_hit_dphase_write;
logic [ 1:0] dm_hit_dphase_addr; // Address in a line
logic [ 7:0] dm_hit_dphase_wdata;
logic [31:0] dm_hit_dphase_update_data;
//
assign dm_hit = DM_REQ & dc_v & (dc_a == DM_ADDR[14:2]);
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        dm_hit_dphase       <= 1'b0;
        dm_hit_dphase_write <= 1'b0;
        dm_hit_dphase_addr  <= 2'b00;
        dm_hit_dphase_wdata <= 8'h00;
    end
    else if (dm_hit & dm_slot)
    begin
        dm_hit_dphase       <= 1'b1;
        dm_hit_dphase_write <= DM_WRITE;
        dm_hit_dphase_addr  <= DM_ADDR[1:0];
        dm_hit_dphase_wdata <= DM_WDATA;
    end
    else if (dm_slot)
    begin
        dm_hit_dphase       <= 1'b0;
        dm_hit_dphase_write <= 1'b0;
        dm_hit_dphase_addr  <= 2'b00;
        dm_hit_dphase_wdata <= 8'h00;
    end
end
//
// D-Cache Miss Access
logic        dm_mis_req;
logic        dm_mis_req_write;
logic [15:0] dm_mis_req_addr;
logic        dm_mis_replace;
logic [15:0] dm_mis_replace_addr;
logic        dm_mis_dphase;
logic [14:0] dm_mis_dphase_addr;
logic        dm_mis_dphase_write;
logic [ 7:0] dm_mis_dphase_wdata;
logic [31:0] dm_mis_dphase_rdata;
logic [31:0] dm_mis_dphase_update_data;
logic [31:0] dm_mis_dphase_writeback_data;
//
assign dm_mis_req       = DM_REQ & ~dm_hit;
assign dm_mis_req_write = DM_WRITE;
assign dm_mis_req_addr  = {1'b1, DM_ADDR};
assign dm_mis_replace   = dm_mis_req & dc_v;      // if valid, need replace
assign dm_mis_replace_addr = {1'b1, dc_a, 2'b00}; // replace target address
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        dm_mis_dphase       <= 1'b0;
        dm_mis_dphase_write <= 1'b0;
        dm_mis_dphase_addr  <= 15'h0000;
        dm_mis_dphase_wdata <= 8'h00;
    end
    else if (dm_mis_req & dm_slot)
    begin
        dm_mis_dphase       <= 1'b1;
        dm_mis_dphase_write <= dm_mis_req_write;
        dm_mis_dphase_addr  <= DM_ADDR;
        dm_mis_dphase_wdata <= DM_WDATA;
    end
    else if (dm_slot)
    begin
        dm_mis_dphase       <= 1'b0;
        dm_mis_dphase_write <= 1'b0;
        dm_mis_dphase_addr  <= 15'h0000;
        dm_mis_dphase_wdata <= 8'h00;
    end
end
//
// D-Cache Valid Bit
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        dc_v <= 1'b0;
    else if (dm_mis_req & dm_slot)
        dc_v <= 1'b1;
end
//
// D-Cache Address Array
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        dc_a <= 13'h0000;
    else if (dm_mis_req & dm_slot)
        dc_a <= DM_ADDR[14:2];
end
//
// D-Cache Data Array
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        dc_d <= 32'h00000000;
    // Hit Access
    else if (dm_hit_dphase & dm_hit_dphase_write & dm_slot)
        dc_d <= dm_hit_dphase_update_data;
    // Miss Access
    else if (dm_mis_dphase & dm_mis_dphase_write & dm_slot)
        dc_d <= dm_mis_dphase_update_data;
    else if (dm_mis_dphase & dm_slot)
        dc_d <= dm_mis_dphase_rdata;
end
//
// Hit  : Update Data for D-Cache Data Array
always @*
begin
    dm_hit_dphase_update_data = dc_d; // default
    if (dm_hit_dphase_addr[1:0] == 2'b00) dm_hit_dphase_update_data[ 7: 0] = dm_hit_dphase_wdata;
    if (dm_hit_dphase_addr[1:0] == 2'b01) dm_hit_dphase_update_data[15: 8] = dm_hit_dphase_wdata;
    if (dm_hit_dphase_addr[1:0] == 2'b10) dm_hit_dphase_update_data[23:16] = dm_hit_dphase_wdata;
    if (dm_hit_dphase_addr[1:0] == 2'b11) dm_hit_dphase_update_data[31:24] = dm_hit_dphase_wdata;
end
//
// Miss : Update Data for D-Cache Data Array
always @*
begin
    dm_mis_dphase_update_data = dm_mis_dphase_rdata;
    if (dm_mis_dphase_addr[1:0] == 2'b00) dm_mis_dphase_update_data[ 7: 0] = dm_mis_dphase_wdata;
    if (dm_mis_dphase_addr[1:0] == 2'b01) dm_mis_dphase_update_data[15: 8] = dm_mis_dphase_wdata;
    if (dm_mis_dphase_addr[1:0] == 2'b10) dm_mis_dphase_update_data[23:16] = dm_mis_dphase_wdata;
    if (dm_mis_dphase_addr[1:0] == 2'b11) dm_mis_dphase_update_data[31:24] = dm_mis_dphase_wdata;
end
//
// Generate Read Data
always @*
begin
    // Hit Access, Data from D-Cache
    if (dm_hit_dphase & ~dm_hit_dphase_write & dm_slot)
        DM_RDATA = (dm_hit_dphase_addr[1:0] == 2'b00)? dc_d[ 7: 0]
                 : (dm_hit_dphase_addr[1:0] == 2'b01)? dc_d[15: 8]
                 : (dm_hit_dphase_addr[1:0] == 2'b10)? dc_d[23:16]
                 : (dm_hit_dphase_addr[1:0] == 2'b11)? dc_d[31:24]
                 : 8'h00;
    else if (dm_mis_dphase & ~dm_mis_dphase_write & dm_slot)
        DM_RDATA = (dm_mis_dphase_addr[1:0] == 2'b00)? dm_mis_dphase_rdata[ 7: 0]
                 : (dm_mis_dphase_addr[1:0] == 2'b01)? dm_mis_dphase_rdata[15: 8]
                 : (dm_mis_dphase_addr[1:0] == 2'b10)? dm_mis_dphase_rdata[23:16]
                 : (dm_mis_dphase_addr[1:0] == 2'b11)? dm_mis_dphase_rdata[31:24]
                 : 8'h00;
    else
        DM_RDATA = 8'h00;
end
//
// Write Back Data to BUS
assign dm_mis_dphase_writeback_data
    = (dm_mis_req & dm_hit_dphase)? dm_hit_dphase_update_data
    : (dm_mis_req                )? dc_d
    : (dm_mis_dphase             )? dm_mis_dphase_update_data // ??? necessary ???
    : 32'h00000000;
//
// Return Ready
assign DM_RDY = dm_slot;

//===============================================================
// BUS Access (always 8-bursts)
//===============================================================
//
// Bus Access Interface
logic        bus_req_inst;
logic        bus_req_data;
logic        bus_req_read;
logic        bus_req_wrte;
logic [15:0] bus_req_addr;
logic        bus_req_repl;
logic [15:0] bus_req_repl_addr;
logic [31:0] bus_req_wdata;
logic        bus_rdy;
logic [31:0] bus_rdy_rdata;
//
logic        if_mis_req_pend;
logic [15:0] if_mis_req_addr_pend;
//
assign bus_req_inst = (if_mis_req | if_mis_req_pend) & ~dm_mis_req; // priority = Data
assign bus_req_data = dm_mis_req;
assign bus_req_read = dm_mis_req & ~dm_mis_req_write;
assign bus_req_wrte = dm_mis_req &  dm_mis_req_write;
assign bus_req_repl = dm_mis_replace;
assign bus_req_addr = (dm_mis_req     )? dm_mis_req_addr
                    : (if_mis_req_pend)? if_mis_req_addr_pend
                    : (if_mis_req     )? if_mis_req_addr
                    : 16'h0000;
assign bus_req_repl_addr = dm_mis_replace_addr;
assign bus_req_wdata = dm_mis_dphase_writeback_data;
//
assign if_mis_dphase_rdata = bus_rdy_rdata;
assign dm_mis_dphase_rdata = bus_rdy_rdata;
//
// Bus Access Sequencer
logic        bus_inst;
logic        bus_read;
logic        bus_wrte;
logic        bus_repl;
logic [15:0] bus_repl_addr;
logic [15:0] bus_pend_addr;
logic [31:0] bus_pend_wdata;
logic [31:0] bus_pend_rdata;
logic [ 2:0] bus_count;
logic        bus_count_end;
logic        bus_count_0123;
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        bus_count <= 3'b000;
    else if (bus_req_inst & BUS_RDY)
        bus_count <= 3'b101;
    else if ((bus_req_read | bus_req_wrte) &  bus_req_repl & BUS_RDY)
        bus_count <= 3'b001;
    else if ((bus_req_read | bus_req_wrte) & ~bus_req_repl & BUS_RDY)
        bus_count <= 3'b101;
    else if (bus_count_end & BUS_RDY)
        bus_count <= bus_count;
    else if ((|bus_count) & BUS_RDY)
        bus_count <= bus_count + 3'b001;
end
//
assign bus_count_end  = (bus_count == 3'b000);
assign bus_count_0123 = ~bus_count[2];
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        bus_inst <= 1'b0; 
    else if (bus_req_inst & BUS_RDY)
        bus_inst <= 1'b1; 
    else if (bus_count_end & BUS_RDY)
        bus_inst <= 1'b0; 
end
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        bus_read <= 1'b0; 
    else if (bus_req_read & BUS_RDY)
        bus_read <= 1'b1; 
    else if (bus_count_end & BUS_RDY)
        bus_read <= 1'b0; 
end
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        bus_wrte <= 1'b0; 
    else if (bus_req_wrte & BUS_RDY)
        bus_wrte <= 1'b1; 
    else if (bus_count_end & BUS_RDY)
        bus_wrte <= 1'b0; 
end
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        bus_repl      <= 1'b0; 
        bus_repl_addr <= 16'h0000;
    end
    else if ((bus_req_read | bus_req_wrte) & BUS_RDY)
    begin
        bus_repl      <= bus_req_repl; 
        bus_repl_addr <= bus_req_repl_addr;
    end
    else if (bus_count_end & BUS_RDY)
    begin
        bus_repl      <= 1'b0; 
        bus_repl_addr <= 16'h0000;
    end
end
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        bus_pend_addr <= 16'h0000;
    else if ((bus_req_inst | bus_req_read | bus_req_wrte) & BUS_RDY)
        bus_pend_addr <= bus_req_addr;
end
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        bus_pend_wdata <= 32'h00000000;
    else if ((bus_req_read | bus_req_wrte) & BUS_RDY)
        bus_pend_wdata <= bus_req_wdata;
end
//
assign BUS_REQ = bus_req_inst | bus_req_read | bus_req_wrte
               | ((bus_inst | bus_read | bus_wrte) & ~bus_count_end);
//
assign BUS_WRITE = ((bus_req_read | bus_req_wrte) & bus_req_repl)? 1'b1
                 : (bus_req_inst  | bus_inst                    )? 1'b0
                 : ((bus_read | bus_wrte) & bus_count_0123)? 1'b1
                 : 1'b0;
//
assign BUS_ADDR
    = ((bus_req_read | bus_req_wrte) & ~bus_req_repl)? {bus_req_addr [15:2]    , 2'b00}
    : ((bus_req_read | bus_req_wrte) &  bus_req_repl)? {bus_req_repl_addr[15:2], 2'b00}
    : (bus_req_inst                                 )? {bus_req_addr[15:2]     , 2'b00}
    : ((bus_read | bus_wrte) & bus_count_0123)? {bus_repl_addr[15:2], bus_count[1:0]}
    : ((bus_read | bus_wrte)                 )? {bus_pend_addr[15:2], bus_count[1:0]}
    : (bus_inst                              )? {bus_pend_addr[15:2], bus_count[1:0]}
    : 16'h0000;
//
always @*
begin
    if (bus_req_read | bus_req_wrte)
    begin
        BUS_WDATA = bus_req_wdata[7:0];
    end
    else if (bus_read | bus_wrte)
    begin
        BUS_WDATA = (bus_count == 3'b001)? bus_pend_wdata[15: 8]
                  : (bus_count == 3'b010)? bus_pend_wdata[23:16]
                  : (bus_count == 3'b011)? bus_pend_wdata[31:24]
                  : 8'h00;
    end
    else
    begin
        BUS_WDATA = 8'h00;
    end
end
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
        bus_pend_rdata <= 32'h00000000;
    else if (bus_inst & BUS_RDY)
    begin
        if (bus_count == 3'b101)
            bus_pend_rdata[ 7: 0] <= BUS_RDATA;
        else if (bus_count == 3'b110)
            bus_pend_rdata[15: 8] <= BUS_RDATA;
        else if (bus_count == 3'b111)
            bus_pend_rdata[23:16] <= BUS_RDATA;
        else if (bus_count == 3'b000)
            bus_pend_rdata[31:24] <= BUS_RDATA;
    end
    else if ((bus_read | bus_wrte) & BUS_RDY)
    begin
        if (bus_count == 3'b101)
            bus_pend_rdata[ 7: 0] <= BUS_RDATA;
        else if (bus_count == 3'b110)
            bus_pend_rdata[15: 8] <= BUS_RDATA;
        else if (bus_count == 3'b111)
            bus_pend_rdata[23:16] <= BUS_RDATA;
        else if (bus_count == 3'b000)
            bus_pend_rdata[31:24] <= BUS_RDATA;
    end
end
//
assign bus_rdy = bus_count_end & BUS_RDY;
assign bus_rdy_rdata = {BUS_RDATA, bus_pend_rdata[23:0]};
//
// Slot Control
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        if_mis_req_pend      <= 1'b0;
        if_mis_req_addr_pend <= 16'h0000;
    end
    else if (if_mis_req & dm_mis_req & bus_rdy)
    begin
        if_mis_req_pend      <= if_mis_req;
        if_mis_req_addr_pend <= if_mis_req_addr;
    end
    else if (if_mis_req_pend & ~dm_mis_req & bus_rdy)
    begin
        if_mis_req_pend      <= 1'b0;
        if_mis_req_addr_pend <= 16'h0000;
    end
end
//
assign if_slot = bus_rdy & ~if_mis_req_pend;
assign dm_slot = bus_rdy | dm_hit_dphase;

//===============================================================
//---------------------------------------------------------------
// Cache Disable
//---------------------------------------------------------------
//===============================================================
`else
//-------------------------------------------------
// Bus Multiplexer
//     DM Access has higher priority than IF Access
//-------------------------------------------------
logic        if_req_pend;
logic [15:0] if_addr_pend;
logic        if_addr_dphase_lsb;
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        if_req_pend  <= 1'b0;
        if_addr_pend <= 16'h0000;
    end
    else if (IF_REQ & DM_REQ & BUS_RDY)
    begin
        if_req_pend  <= 1'b1;
        if_addr_pend <= IF_ADDR;    
    end
    else if (if_req_pend & ~DM_REQ & BUS_RDY)
    begin
        if_req_pend  <= 1'b0;
        if_addr_pend <= 16'h0000;
    end
end
//
logic bus_dphase_if;
logic bus_dphase_dm;
logic bus_dphase_addr_lsb;
//
always_ff @(posedge CLK, posedge RES)
begin
    if (RES)
    begin
        bus_dphase_if <= 1'b0;
        bus_dphase_dm <= 1'b0;
        bus_dphase_addr_lsb <= 1'b0;
    end
    else if (DM_REQ & BUS_RDY)
    begin
        bus_dphase_if <= 1'b0;
        bus_dphase_dm <= 1'b1;
        bus_dphase_addr_lsb <= DM_ADDR[0];
    end
    else if (IF_REQ & ~DM_REQ & BUS_RDY)
    begin
        bus_dphase_if <= 1'b1;
        bus_dphase_dm <= 1'b0;
        bus_dphase_addr_lsb <= IF_ADDR[0];
    end
    else if (if_req_pend & ~DM_REQ & BUS_RDY)
    begin
        bus_dphase_if <= 1'b1;
        bus_dphase_dm <= 1'b0;
        bus_dphase_addr_lsb <= if_addr_pend[0];
    end
    else if (BUS_RDY)
    begin
        bus_dphase_if <= 1'b0;
        bus_dphase_dm <= 1'b0;
        bus_dphase_addr_lsb <= 1'b0;
    end
end
//
assign BUS_REQ   = DM_REQ | IF_REQ | if_req_pend;
assign BUS_WRITE = (DM_REQ)? DM_WRITE : 1'b0;
assign BUS_ADDR  = (DM_REQ)? {1'b1, DM_ADDR}
                 : (IF_REQ)? {1'b0, IF_ADDR[15:1]}
                 : (if_req_pend)? {1'b0, if_addr_pend[15:1]}
                 : 16'h0000;
assign BUS_WDATA = (DM_REQ)? DM_WDATA : 8'h00;
assign IF_CODE   = (bus_dphase_addr_lsb)? BUS_RDATA[7:4]
                 : BUS_RDATA[3:0];
assign DM_RDATA  = BUS_RDATA;
assign IF_RDY    = (bus_dphase_dm)? 1'b0
                 : (bus_dphase_if)? BUS_RDY
                 : BUS_RDY;
assign DM_RDY    = (bus_dphase_dm)? BUS_RDY
                 : (bus_dphase_if)? 1'b0
                 : BUS_RDY;
`endif

endmodule
//===========================================================
// End of File
//===========================================================
