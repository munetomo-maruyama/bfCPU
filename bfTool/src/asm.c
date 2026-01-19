//===========================================================
// bfCPU Assember / Simulator
//-----------------------------------------------------------
// File Name   : asm.c
// Description : Assembler Routine
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025 M.Maruyama
//===========================================================

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "asm.h"
#include "defines.h"
#include "utility.h"
#include "parser.tab.h"

//-------------------------
// Global Variables
//-------------------------
int PC = 0;
sINSTR *pINSTR_ROOT = NULL;
extern int MAXROM;
extern int MAXRAM;

//-----------------------------------------
// Function Prototype
//-----------------------------------------
extern int yyparse();

//-------------------------------
// Instruction Chain Install
//-------------------------------
void Instruction_Chain_Install(int instr_code, char *instr_str)
{
    int     result;
    sINSTR *pinstr;
    //
    if (pINSTR_ROOT == NULL)
    {
        pinstr = (sINSTR*) malloc(sizeof(sINSTR));
        if (pinstr == NULL)
        {
            result = RESULT_CANNOTALLOC;
        }
        else
        {
            pinstr->instr_code = instr_code;
            pinstr->instr_str  = instr_str;
            pinstr->instr_addr = PC;
            pinstr->instr_next = NULL;
            pINSTR_ROOT = pinstr;
            PC = (instr_code != CODE_NONE)? PC + 1 : PC;
            DEBUG_printf(DEBUG_MAX, "PC=0x%02x CODE=0x%1x SRC=%s\n", pinstr->instr_addr, pinstr->instr_code, instr_str);
            result = RESULT_OK;
        }
    }
    else
    {
        for (pinstr = pINSTR_ROOT; pinstr->instr_next != NULL; pinstr = pinstr->instr_next);
        pinstr->instr_next = (sINSTR*) malloc(sizeof(sINSTR));
        if (pinstr->instr_next == NULL)
        {
            Instruction_Chain_Dispose();
			result = RESULT_CANNOTALLOC;
		}
		pinstr = pinstr->instr_next;
		pinstr->instr_code = instr_code;
        pinstr->instr_str  = instr_str;
		pinstr->instr_addr = PC;
		pinstr->instr_next = NULL;
        PC = (instr_code != CODE_NONE)? PC + 1 : PC;
        DEBUG_printf(DEBUG_MAX, "PC=0x%02x CODE=0x%1x SRC=%s\n", pinstr->instr_addr, pinstr->instr_code, instr_str);
        result = RESULT_OK;
    }    
    //
    if (result != RESULT_OK)
    {
        fprintf(stderr, "Memory Allocation Error in Instruction_Chain_Install().\n");
        exit(EXIT_FAILURE);
    }
}

//-------------------------------
// Instruction Chain Dispose
//-------------------------------
void Instruction_Chain_Dispose(void)
{
    sINSTR *pinstr, *pinstr_next;
    //
    if (pINSTR_ROOT != NULL)
    {
        pinstr = pINSTR_ROOT;
        while(1)
        {
            pinstr_next = pinstr->instr_next;
            if (pinstr->instr_str) free(pinstr->instr_str);
            if (pinstr)            free(pinstr);
            pinstr = pinstr_next;
            if (pinstr == NULL) break;
        }        
    }
    pINSTR_ROOT = NULL;
}

//------------------------------------
// Output Assemble Results
//------------------------------------
void Output_Assemble_Results(sOPTION *psOPTION)
{
    char fname_basename[MAXLEN_WORD];
    char fname_obj[MAXLEN_WORD];
    char fname_ver[MAXLEN_WORD];
    char fname_lis[MAXLEN_WORD];
    FILE *fp_obj;
    FILE *fp_ver;
    FILE *fp_lis;
    int  error;
    unsigned char *rom; // 4bit width
    int  i;
    int  addr;
    int  addr_max;
    int  indent;
    unsigned char checksum;
    sINSTR *pinstr;
    //
    // Allocate ROM
    rom = (unsigned char*)malloc(sizeof(unsigned char) * (MAXROM));
    if (rom == NULL)
    {
        fprintf(stderr, "======== ERROR: Can't allocate ROM area.\n");
        exit(EXIT_FAILURE);
    }
    //
    // Get Base Name
    Get_Basename_without_Ext(fname_basename, psOPTION->input_file_name, MAXLEN_WORD);
    //
    // Make fname_hex
    if (psOPTION->opt_obj)
    {
        String_Copy(fname_obj, psOPTION->opt_obj_name, MAXLEN_WORD);
    }
    else
    {
        String_Copy(fname_obj, fname_basename, MAXLEN_WORD);
        String_Concatenate(fname_obj, ".hex", MAXLEN_WORD);
    }
    //
    // Make fname_ver
    if (psOPTION->opt_ver)
    {
        String_Copy(fname_ver, psOPTION->opt_ver_name, MAXLEN_WORD);
    }
    else
    {
        String_Copy(fname_ver, fname_basename, MAXLEN_WORD);
        String_Concatenate(fname_ver, ".v", MAXLEN_WORD);
    }
    //
    // Make fname_lis
    if (psOPTION->opt_lis)
    {
        String_Copy(fname_lis, psOPTION->opt_lis_name, MAXLEN_WORD);
    }
    else
    {
        String_Copy(fname_lis, fname_basename, MAXLEN_WORD);
        String_Concatenate(fname_lis, ".lis", MAXLEN_WORD);
    }
    DEBUG_printf(DEBUG_MAX, "fname_obj=%s\n", fname_obj);
    DEBUG_printf(DEBUG_MAX, "fname_ver=%s\n", fname_ver);
    DEBUG_printf(DEBUG_MAX, "fname_lis=%s\n", fname_lis);
    //
    // Check File Name
    error = 0;
    error = (strcmp(psOPTION->input_file_name, fname_obj))? error : 1;
    error = (strcmp(psOPTION->input_file_name, fname_ver))? error : 1;
    error = (strcmp(psOPTION->input_file_name, fname_lis))? error : 1;
    error = (strcmp(fname_obj, fname_ver))? error : 1;
    error = (strcmp(fname_obj, fname_lis))? error : 1;
    error = (strcmp(fname_ver, fname_lis))? error : 1;
    if (error)
    {
        fprintf(stderr, "======== ERROR: File Name Confliction\n");
        exit(EXIT_FAILURE);
    }
    //
    // Generate each file
    fp_obj = fopen(fname_obj, "w");    
    fp_ver = fopen(fname_ver, "w");    
    fp_lis = fopen(fname_lis, "w");    
    if ((fp_obj == NULL) || (fp_ver == NULL) || (fp_lis == NULL))
    {
        if (fp_obj == NULL) fprintf(stderr, "======== ERROR: Can't open \"%s\".\n", fname_obj);
        if (fp_ver == NULL) fprintf(stderr, "======== ERROR: Can't open \"%s\".\n", fname_ver);
        if (fp_lis == NULL) fprintf(stderr, "======== ERROR: Can't open \"%s\".\n", fname_lis);
        if (fp_obj != NULL) fclose(fp_obj);
        if (fp_ver != NULL) fclose(fp_ver);
        if (fp_lis != NULL) fclose(fp_lis);
        exit(EXIT_FAILURE);
    }
    //
    // Clear ROM
    for (addr = 0; addr < MAXROM; addr++) rom[addr] = CODE_NOP;
    //
    // Set ROM
    addr = 0;
    addr_max = 0;
    if (pINSTR_ROOT != NULL)
    {
        for (pinstr = pINSTR_ROOT; pinstr != NULL; pinstr = pinstr->instr_next)
        {
            if (pinstr->instr_addr >= MAXROM)
            {
                fprintf(stderr, "======== ERROR: Overflow ROM Size.\n");
                free(rom);
                if (fp_obj != NULL) fclose(fp_obj);
                if (fp_ver != NULL) fclose(fp_ver);
                if (fp_lis != NULL) fclose(fp_lis);
                exit(EXIT_FAILURE);
                
            }
            if (pinstr->instr_code != CODE_NONE)
            {
                rom[pinstr->instr_addr] = (pinstr->instr_code) & 0x0f;
                addr_max = (addr_max < pinstr->instr_addr)? pinstr->instr_addr : addr_max;
            }
        }
    }
    //
    // Write Object File
    if (pINSTR_ROOT != NULL)
    {
        checksum = 0;
        for (addr = 0; addr < MAXROM; addr = addr + 32)
        {
            if (addr > addr_max) break;
            //
            int addr_byte = addr / 2;
            fprintf(fp_obj, ":%02X%04X%02X", 16, addr_byte, 0x00);
            checksum = 16 + ((addr_byte >> 8) & 0x0ff) + ((addr_byte >> 0) & 0x0ff) + 0;
            for (i = 0; i < 32; i = i + 2)
            {
                fprintf(fp_obj, "%1X", rom[addr + i + 1]);
                fprintf(fp_obj, "%1X", rom[addr + i    ]);
                checksum = checksum + (rom[addr + i + 1] << 4) + (rom[addr + i]);
            }
            checksum = 0 - checksum;
            fprintf(fp_obj, "%02X\n", checksum);
        }
    }
    fprintf(fp_obj, ":00000001FF\n");
    //
    // Write Verilog File
	for (addr = 0; addr < MAXROM; addr = addr + 2)
	{
        if (addr > addr_max) break;
		fprintf(fp_ver, "@%02x %1x%1x\n", addr / 2, rom[addr + 1], rom[addr]);
	}    
    //
    // Write List File
    if (pINSTR_ROOT != NULL)
    {
        indent = 0;
        for (pinstr = pINSTR_ROOT; pinstr != NULL; pinstr = pinstr->instr_next)
        {
            if (pinstr->instr_code == CODE_NONE)
            {
                fprintf(fp_lis, "%02x -    ",  pinstr->instr_addr);
            }
            else
            {
                fprintf(fp_lis, "%02x %1x    ",  pinstr->instr_addr, pinstr->instr_code);
            }
            //
            if (pinstr->instr_code == CODE_END  ) indent = (indent == 0)? 0 : indent - 1;
            for (i = 0; i < indent; i++) fprintf(fp_lis, "    ");
            fprintf(fp_lis, "%s\n", pinstr->instr_str);
            if (pinstr->instr_code == CODE_BEGIN) indent = indent + 1;
        }
    }    
    //
    // Close each file
    fclose(fp_obj);
    fclose(fp_ver);
    fclose(fp_lis);
    //
    // Clean Up
    free(rom);
}

//-----------------------------------------
// Do Assemble
//-----------------------------------------
void Do_Asm(sOPTION *psOPTION)
{
    FILE *fp_src;
    char *str_src;
    //
    // Get Input File as String
    str_src =  Get_InputFile_as_String(psOPTION);
    //
    // Show me the Text
    DEBUG_printf(DEBUG_MAX, "%s\n", str_src);
    //
    // Set the String as Lexer Input
    Copy_String_to_YY_Buffer(str_src);
    //
    // Execute Parser
    yyparse();
    //
    // Assemble Output
    Output_Assemble_Results(psOPTION);
    //
    // Clean Up
    Instruction_Chain_Dispose();
    Dispose_YY_Buffer();
    free(str_src);
}

//===========================================================
// End of Program
//===========================================================
