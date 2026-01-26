//===========================================================
// bfCPU Running Tool
//-----------------------------------------------------------
// File Name   : defines.c
// Description : Common Definitions
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025-2026 M.Maruyama
//===========================================================

#ifndef __DEFINES_H__
#define __DEFINES_H__

//=====================
// Defines
//=====================
// Version
#define REVISION 1

//-----------------------------------------------------------------------
// Architecture
#define MAXROM (32768*1) // width 8bit
#define MAXRAM (32768  ) // width 8bit
//
#define CODE_NOP   15

//-----------------------------------------------------------------------
// Clock Frequency
#define CLKFREQ_DEFAULT 10000000 //Hz

//-----------------------------------------------------------------------
// Miscellaneous
#define MAXLEN_WORD  256
#define MAXLEN_LINE 1024

//-----------------------------------------------------------------------
// Debug Level
enum DEBUG_LVL {DEBUG_NONE, DEBUG_MIN, DEBUG_MID, DEBUG_MAX};
#define DEBUG_LEVEL DEBUG_NONE

//-----------------------------------------------------------------------
// Result Code
#define RESULT_OK          0x0000
#define RESULT_NO          0x0001
#define RESULT_ILLG        0x0002
#define RESULT_IMOVF       0x0004
#define RESULT_CANNOTFIND  0x0008
#define RESULT_CANNOTALLOC 0x0010

//-----------------------------------------------------------------------
// Command Line Option
enum BF_OPT    {OPT_CLK};
enum BF_OPTARG {OPT_NO, OPT_YES};
typedef struct
{
    int opt_clk;
    char *opt_clk_freq;
    char *input_file_name;
} sOPTION;

#endif // __DEFINES_H__

//===========================================================
// End of Program
//===========================================================
