//===========================================================
// bfCPU Running Tool
//-----------------------------------------------------------
// File Name   : utility.c
// Description : Utulity Routines
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025-2026 M.Maruyama
//===========================================================

#include <ctype.h>
#include <errno.h>
#include <getopt.h>
#include <signal.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
//
#include "defines.h"
#include "utility.h"

//-------------
// Globals
//-------------
int ctrl_c = 0;

//--------------------------------
// Interrupt Hander for CTRL-C
//--------------------------------
void Interrupt_Handler(int dummy)
{
    ctrl_c = 1;
    printf("\nAborted by Ctrl-C.\n");
}

//--------------------------------
// DEBUG printf
//--------------------------------
void DEBUG_printf(uint32_t debug_level, const char *format, ...)
{
    if (DEBUG_LEVEL >= debug_level)
    {
        uint8_t str[1024];
        va_list arg;
        va_start(arg, format);
        vsnprintf(str, 1024, format, arg);
        va_end(arg);
        fprintf(stderr, "%s", str);
    }
}

//-----------------------------------------
// Get Inpur File as String
//-----------------------------------------
char* Get_InputFile_as_String(sOPTION *psOPTION)
{
    char *str_src;
    FILE *fp_src;
    char fname_src[MAXLEN_WORD];
    //
    // Open the File
    strncpy(fname_src, psOPTION->input_file_name, MAXLEN_WORD);
    fp_src = fopen(fname_src, "r");
    if (fp_src == NULL)
    {
        fprintf(stderr, "======== ERROR: Can't open \"%s\".\n", fname_src);
        exit(EXIT_FAILURE);
    }
    //
    // Get the File Size
    fseek(fp_src, 0, SEEK_END);
    int size = ftell(fp_src);
    rewind(fp_src);
    //
    // Allocate Memory
    str_src = malloc(sizeof(uint8_t) * (size + 1)); // +1 is a Terminate Null Character
    if (str_src == NULL)
    {
        fprintf(stderr, "======== ERROR: Memory Allocation Error.\n");
        exit(EXIT_FAILURE);
    }
    //
    // Read the File
    fread(str_src, 1, size, fp_src);
    str_src[size] = '\0';
    //
    // Close the File
    fclose(fp_src);
    //
    // Retuen Result
    return str_src;
}

//----------------------------------
// Read Hex File
//----------------------------------
int Read_Hex_File(unsigned char *rom, char *obj_str)
{
    char *pline;
    int  bytecount;
    int  checksum;
    int  checksum2;
    int  addr;
    int  addr_bgn;
    int  data;
    int  error;
    char str[MAXLEN_WORD];
    int  addr_max;
    //
    // Clear ROM
    for (addr = 0; addr < MAXROM; addr++) rom[addr] = (CODE_NOP << 4) | CODE_NOP;
    addr_max = 0;
    //
    // Read Intel Hex Format
    error = 0;
    pline = obj_str;
    while(1)
    {
        // Start Code
        if (*pline++ != ':') {error = 1; break;}
        // Byte Count
        str[0] = *pline++;
        str[1] = *pline++;
        str[2] = '\0';
        if (sscanf(str, "%02X", (int*)&bytecount) == EOF) {error = 1; break;}
        checksum = bytecount;
        // Address
        str[0] = *pline++;
        str[1] = *pline++;
        str[2] = *pline++;
        str[3] = *pline++;
        str[4] = '\0';
        if (sscanf(str, "%04X", (int*)&addr_bgn) == EOF) {error = 1; break;}
        checksum = checksum + (addr_bgn >> 8) + (addr_bgn & 0x00ff);
        // Record Type
        str[0] = *pline++;
        str[1] = *pline++;
        str[2] = '\0';
        if (strcmp(str, "01") == 0) break; // End of Record
        if (strcmp(str, "00") != 0) {error = 1; break;} // Unsupported Record
        // Data Record
        for (addr = addr_bgn; addr < (addr_bgn + bytecount); addr++)
        {
            str[0] = *pline++;
            str[1] = *pline++;
            str[2] = '\0';
            if (sscanf(str, "%02X", (int*)&data) == EOF) {error = 1; break;}
            if ((addr * 2 + 1) >= MAXROM) {error = 2; break;}
            rom[addr] = data;
            addr_max = (addr > addr_max)? addr : addr_max;
            checksum = checksum + data;
        }
        if (error) break;
        // Check Sum        
        str[0] = *pline++;
        str[1] = *pline++;
        str[2] = '\0';
        if (sscanf(str, "%02X", (int*)&checksum2) == EOF) {error = 1; break;}
        checksum = (0 - checksum) & 0x00ff;
        if (checksum != checksum2) {error = 3; break;}
        // End of Line
        while(1)
        {
                 if (*pline == '\n') pline++;
            else if (*pline == '\r') pline++;
            else                     break;
        }
        // End of String
        if (*pline == '\0') break;
    }
    if (error == 1)
    {
        fprintf(stderr, "======== ERROR: Hex File Format Error\n");
        exit(EXIT_FAILURE);
    }
    if (error == 2)
    {
        fprintf(stderr, "======== ERROR: Hex File Overflows ROM Size\n");
        exit(EXIT_FAILURE);
    }
    if (error == 3)
    {
        fprintf(stderr, "======== ERROR: Hex File Check Sum Unmatched\n");
        exit(EXIT_FAILURE);
    }
    //
    return addr_max;
}

//===========================================================
// End of File
//===========================================================
