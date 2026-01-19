//===========================================================
// bfCPU Assember / Simulator
//-----------------------------------------------------------
// File Name   : utility.c
// Description : Utulity Header
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025 M.Maruyama
//===========================================================

#include <stdint.h>

#include "defines.h"

#ifndef __UTILITY_H__
#define __UTILITY_H__

//-------------------------------
// Prototypes
//-------------------------------
void Interrupt_Handler(int dummy);
void DUAL_printf(FILE *fp, const char *format, ...);
void DEBUG_printf(uint32_t debug_level, const char *format, ...);
char* Get_InputFile_as_String(sOPTION *psOPTION);
void Get_Basename_without_Ext(char *basename, const char *filename, size_t size);
void String_Concatenate(char *str_1st_half, const char *str_2nd_half, size_t size);
void String_Copy(char *str_dest, const char *str_src, size_t size);
int Get_Hex_from_STDIN(unsigned char *hex);
int Get_ASCII_from_STDIN(unsigned char *ascii);

#endif 
//===========================================================
// End of File
//===========================================================
