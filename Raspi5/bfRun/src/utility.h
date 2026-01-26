//===========================================================
// bfCPU Running Tool
//-----------------------------------------------------------
// File Name   : utility.c
// Description : Utulity Header
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025-2026 M.Maruyama
//===========================================================

#include <stdint.h>
#include "defines.h"

#ifndef __UTILITY_H__
#define __UTILITY_H__

//-------------------------------
// Prototypes
//-------------------------------
void Interrupt_Handler(int dummy);
void DEBUG_printf(uint32_t debug_level, const char *format, ...);
char* Get_InputFile_as_String(sOPTION *psOPTION);
int  Read_Hex_File(unsigned char *rom, char *obj_str);

#endif 
//===========================================================
// End of File
//===========================================================
