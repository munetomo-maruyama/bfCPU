//===========================================================
// bfCPU Assember / Simulator
//-----------------------------------------------------------
// File Name   : asm.h
// Description : Assembler Header
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025 M.Maruyama
//===========================================================

#include <stdint.h>
#include "utility.h"

#ifndef __ASM_H__
#define __ASM_H__

//-------------------------
// Instruction Codes
//-------------------------
#define CODE_NONE  -1
#define CODE_PINC   0
#define CODE_PDEC   1
#define CODE_INC    2
#define CODE_DEC    3
#define CODE_OUT    4
#define CODE_IN     5
#define CODE_BEGIN  6
#define CODE_END    7
#define CODE_RESET  8
#define CODE_NOP   15

//----------------------------
// Instruction Structure
//----------------------------
struct instr
{
    int            instr_addr;
    int            instr_code;
    char          *instr_str;
    struct instr  *instr_next;
};
typedef struct instr sINSTR;

//-------------------------------
// Prototypes
//-------------------------------
void Instruction_Chain_Install(int instr_code, char *instr_str);
void Instruction_Chain_Dispose(void);
void Do_Asm(sOPTION *psOPTION);

#endif 

//===========================================================
// End of Program
//===========================================================
