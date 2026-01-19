//===========================================================
// bfCPU Assember / Simulator
//-----------------------------------------------------------
// File Name   : utility.c
// Description : Utulity Routines
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025 M.Maruyama
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

//--------------------------------
// Globals
//--------------------------------
extern int VERBOSE;
extern int SIM_LOG;

//--------------------------------
// DUAL printf
//--------------------------------
void DUAL_printf(FILE *fp, const char *format, ...)
{
    va_list arg1, arg2;
    //
    va_start(arg1, format);
    va_copy(arg2, arg1); // need copy because va_list can be used only once
    if (VERBOSE) vprintf(format, arg1); // stdout
    va_end(arg1);
    if ((fp != NULL) && (SIM_LOG))
    {
        vfprintf(fp, format, arg2);
    }
    va_end(arg2);
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
        fprintf(stderr, "======== ERROR: Memory Allocation Error in Do_Asm().\n");
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

//------------------------------------------------
// Get Basename without Extension
//------------------------------------------------
void Get_Basename_without_Ext(char *basename, const char *filename, size_t size)
{
    const char *dot_pos = strrchr(filename, '.');
    // If no period, all filename is Basename
    if (dot_pos == NULL)
    {
        strncpy(basename, filename, size - 1);
        basename[size - 1] = '\0';
    }
    // Extract Basename
    else
    {
        // Calculate the basename length
        size_t length = dot_pos - filename;
        if (length >= size)
        {
            length = size - 1; // limit to buffer size
        }
        strncpy(basename, filename, length);
        basename[length] = '\0';
    }
}

//-----------------------------------
// Concatenate Strings
//-----------------------------------
void String_Concatenate(char *str_1st_half, const char *str_2nd_half, size_t size)
{
    // Calculate remaining spaces with considering NULL termination
    size_t remain = size - strlen(str_1st_half) - 1;
    // Concatenate
    strncat(str_1st_half, str_2nd_half, remain);
}

//-----------------------------
// Copy String
//-----------------------------
void String_Copy(char *str_dest, const char *str_src, size_t size)
{
    strncpy(str_dest, str_src, size - 1); 
    str_dest[size - 1] = '\0';
}

//------------------------------
// Get Hex from STDIN
//------------------------------
int Get_Hex_from_STDIN(unsigned char *hex)
{
    char input_buffer[MAXLEN_WORD];
    char *endptr;
    long value;
    //
    // Clear input_buffer
    input_buffer[0] = '\0';
    //
    // Read 1 line from STDIN
    if (fgets(input_buffer, sizeof(input_buffer), stdin) == NULL)
    {
        return RESULT_ILLG; // Read Error or EOF
    }
    //
    // Initilize errno to detect error
    errno = 0;
    //
    // Analize the string as Hex Number
    // strtol() can process space in head and optional "0x" automatically
    value = strtol(input_buffer, &endptr, 16);
    //
    // Error Check
    // 1. Not Converted (endptr == input_buffer)
    // 2. Overflow or Underflow (errno = ERANGE)
    // 3. Illegal Characters are included
    if (endptr == input_buffer || errno == ERANGE)
    {
        return RESULT_ILLG; // Hex Format Error
    }
    // Check Trainling Characters
    while ((*endptr != '\0') && isspace((unsigned char)*endptr))
    {
        endptr++;
    }
    if (*endptr != '\0') // Illegal Characters after the Hex Number 
    {
        return RESULT_ILLG;
    }
    // Return the Result
    *hex = (unsigned char)(value % 256);
    return RESULT_OK;
}

//------------------------------
// Get ASCII from STDIN
//------------------------------
int Get_ASCII_from_STDIN(unsigned char *ascii)
{
    int input_char;
    int c;
    //
    // Receive a Character from Stream
    input_char = getchar();
    //
    // Return the Result
    *ascii = (unsigned char)input_char;
    return RESULT_OK;
}

//===========================================================
// End of File
//===========================================================
