//===========================================================
// bfCPU Assember / Simulator
//-----------------------------------------------------------
// File Name   : defines.c
// Description : Common Definitions
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025 M.Maruyama
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
#define MAXROM_DEFAULT (32768*2) // width 4bitx2
#define MAXRAM_DEFAULT (32768  ) // width 8bit

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
enum BF_FUNC   {FUNC_ASM, FUNC_SIM};
enum BF_OPT    {OPT_ROM, OPT_RAM, OPT_OBJ, OPT_VER, OPT_LIS, OPT_LOG, OPT_VERBOSE, OPT_ASCII};
enum BF_OPTARG {OPT_NO, OPT_YES};
typedef struct
{
    int func;
    int opt_rom;
    int opt_ram;
    int opt_obj;
    int opt_ver;
    int opt_lis;
    int opt_log;
    int opt_verbose;
    int opt_ascii;
    char *opt_rom_byte;
    char *opt_ram_byte;
    char *opt_obj_name;
    char *opt_ver_name;
    char *opt_lis_name;
    char *opt_log_name;
    char *input_file_name;
} sOPTION;

//-----------------------------------
// Prototype for Lexer
//-----------------------------------
void Copy_String_to_YY_Buffer(char *string);
void Dispose_YY_Buffer(void);

#endif // __DEFINES_H__

//===========================================================
// End of Program
//===========================================================
