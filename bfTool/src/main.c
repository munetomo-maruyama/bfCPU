//===========================================================
// bfCPU Assember / Simulator
//-----------------------------------------------------------
// File Name   : brainfuel.c
// Description : Main Program
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025 M.Maruyama
//===========================================================

#define REVISION 1
#include <ctype.h>
#include <errno.h> 
#include <getopt.h>
#include <limits.h>
#include <signal.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>

#include "asm.h"
#include "defines.h"
#include "sim.h"

//=====================
// Architecture
//=====================
int MAXROM = MAXROM_DEFAULT;
int MAXRAM = MAXRAM_DEFAULT;
int VERBOSE = 0;
int ASCII = 0;
int SIM_LOG = 0;

//=====================
// Globals
//=====================
extern int ctrl_c;

//=============================
// Get Source String from File
//=============================
uint32_t Get_Source_String(char *file_name, char **source_buf)
{
    FILE *fp;
    int size;
    //
    // Open the File
    fp = fopen((char*) file_name, "r");
    if (fp == NULL)
    {
        return RESULT_CANNOTFIND;
    }
    //
    // Get File Size
    fseek(fp, 0, SEEK_END);
    size = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    //
    // Allocate Memory
    *source_buf = (char *)malloc(size + 1);
    if (*source_buf  == NULL)
    {
        fclose(fp);
        return RESULT_CANNOTALLOC;
    }    
    //
    // Read File
    fread(*source_buf, 1, size, fp);
    source_buf[size] = '\0'; // Add Null as Termination
    //
    // Close File
    fclose(fp);
    //
    // Success
    return RESULT_OK;
}

//=============================================================
//-------------------------------------------------------------
// Main Routine
//-------------------------------------------------------------
//=============================================================

//=====================
// Print Usage
//=====================
void Print_Usage(void)
{
    printf("-----------------------------------------------------------\n");
    printf("bfCPU Assembler-Simulator Rev.%02d\n", REVISION);
    printf("-----------------------------------------------------------\n");
    printf("$ bfTool [options] InputFile                               \n");
    printf("    --asm, -a : Assembler (Default)                        \n");
    printf("    --sim, -s : Simulator                                  \n");
    printf("-----------------------------------------------------------\n");
    printf("Architecture :                                             \n");
    printf("    --rom, -i : ROM Size in bytes (Default %3dbytes)       \n", MAXROM_DEFAULT);
    printf("    --ram, -d : RAM Size in bytes (Default %3dbytes)       \n", MAXRAM_DEFAULT);
    printf("-----------------------------------------------------------\n");
    printf("Assembler :                                                \n");
    printf("    InputFile is a Source List : InputFile.asm             \n");
    printf("    Generates following Files as default                   \n");
    printf("        InputFile.hex : Object File in Hex Format          \n");
    printf("        InputFile.v   : Object File in Verilog Format      \n");
    printf("        InputFile.lis : Assemble List File                 \n");
    printf("    You can specify each file name by following options    \n");
    printf("    --obj, -o : Object Hex File Name (Intel Hex)           \n");
    printf("    --ver, -v : Object Hex File Name (Verilog  )           \n");
    printf("    --lis, -l : Assemble List                              \n");
    printf("-----------------------------------------------------------\n");
    printf("Simulator : InputFile is a Object Hex File.                \n");
    printf("    --log,     -g : Log File Name (Default: InputFile.sim) \n");
    printf("    --verbose, -b : Print Log Messages on STDOUT           \n");
    printf("    --ascii,   -t : I/O is in ASCII Characters             \n");
    printf("-----------------------------------------------------------\n");
}

//=====================
// Parse Command Line
//=====================
uint32_t Parse_Command_Line(int argc, char **argv, sOPTION *psOPTION)
{
    int c;
    int long_option_index = 0;
    int error = 0;
    //
    char *endptr;
    long long_num;
    //
    // Define Long Option
    static struct option long_option[] =
    {
        {"asm", no_argument      , NULL, 'a'},
        {"sim", no_argument      , NULL, 's'},
        {"rom", required_argument, NULL, 'i'},
        {"ram", required_argument, NULL, 'd'},
        {"obj", required_argument, NULL, 'o'},
        {"ver", required_argument, NULL, 'v'},
        {"lis", required_argument, NULL, 'l'},
        {"log", optional_argument, NULL, 'g'},
        {"verbose", no_argument  , NULL, 'b'},
        {"ascii"  , no_argument  , NULL, 't'},
        {NULL , no_argument      , NULL, 0  }
    };
    //
    // Initialize
    psOPTION->func = FUNC_ASM;
    psOPTION->opt_rom = OPT_NO;
    psOPTION->opt_ram = OPT_NO;
    psOPTION->opt_obj = OPT_NO;
    psOPTION->opt_lis = OPT_NO;
    psOPTION->opt_log = OPT_NO;
    psOPTION->opt_verbose = OPT_NO;
    psOPTION->opt_ascii   = OPT_NO;
    psOPTION->opt_rom_byte = NULL;
    psOPTION->opt_ram_byte = NULL;
    psOPTION->opt_obj_name = NULL;
    psOPTION->opt_ver_name = NULL;
    psOPTION->opt_lis_name = NULL;
    psOPTION->opt_log_name = NULL;
    psOPTION->input_file_name = NULL;
    //
    // Parse Option Line
    while ((c = getopt_long(argc, argv, "asi:d:o:v:l:g::bt", long_option, &long_option_index)) != -1)
    {
        switch(c)
        {
            case 'a' :
            {
                psOPTION->func = FUNC_ASM;
                break;
            }
            case 's' :
            {
                psOPTION->func = FUNC_SIM;
                break;
            }
            case 'i' :
            {
                psOPTION->opt_rom = OPT_YES;
                psOPTION->opt_rom_byte = optarg;
                break;
            }
            case 'd' :
            {
                psOPTION->opt_ram = OPT_YES;
                psOPTION->opt_ram_byte = optarg;
                break;
            }
            case 'o' :
            {
                psOPTION->opt_obj = OPT_YES;
                psOPTION->opt_obj_name = optarg;
                break;
            }
            case 'v' :
            {
                psOPTION->opt_ver = OPT_YES;
                psOPTION->opt_ver_name = optarg;
                break;
            }
            case 'l' :
            {
                psOPTION->opt_lis = OPT_YES;
                psOPTION->opt_lis_name = optarg;
                break;
            }
            case 'g' :
            {
                psOPTION->opt_log = OPT_YES;
                psOPTION->opt_log_name = optarg;
                break;
            }
            case 'b' :
            {
                psOPTION->opt_verbose = OPT_YES;
                break;
            }
            case 't' :
            {
                psOPTION->opt_ascii = OPT_YES;
                break;
            }
            default  :
            {
                fprintf(stderr, "Undefined Option \"%c\", ignored.\n", c);
                error = 1;
                break;
            }
        }
        if (error) break;
    }
    //
    // Input File Name
    if (optind < argc)
    {
        psOPTION->input_file_name = argv[optind];
        optind++;
        while (optind < argc) fprintf (stderr, "Ignored Extra Item \"%s\".\n", argv[optind++]);
    }
    else
    {
        fprintf(stderr, "Input File is not Specified.\n");
        error = 1;
    }
    //
    // Decode ROM/RAM Size and Set them in each global variable
    if (psOPTION->opt_rom)
    {
        long_num = strtol(psOPTION->opt_rom_byte, &endptr, 10);
        if ((errno == ERANGE) || (*endptr != '\0') || (long_num < 0) || (long_num > LONG_MAX))
        {
            fprintf(stderr, "ROM Size is Illegal.\n");
            error = 1;
        }
        MAXROM = (int)long_num;;
    }
    else
    {
        MAXROM = MAXROM_DEFAULT;
    }
    //
    if (psOPTION->opt_ram)
    {
        long_num = strtol(psOPTION->opt_ram_byte, &endptr, 10);
        if ((errno == ERANGE) || (*endptr != '\0') || (long_num < 0) || (long_num > LONG_MAX))
        {
            fprintf(stderr, "RAM Size is Illegal.\n");
            error = 1;
        }
        MAXRAM = (int)long_num;;
    }
    else
    {
        MAXRAM = MAXRAM_DEFAULT;
    }
    // Options for Simulation 
    SIM_LOG = (psOPTION->opt_log == OPT_YES)? 1 : 0;
    VERBOSE = (psOPTION->opt_verbose == OPT_YES)? 1 : 0;
    ASCII   = (psOPTION->opt_ascii   == OPT_YES)? 1 : 0;
    //
    DEBUG_printf(DEBUG_MAX, "psOPTION->func    = %d\n", psOPTION->func);
    DEBUG_printf(DEBUG_MAX, "psOPTION->opt_rom = %d, byte = %d\n", psOPTION->opt_rom, MAXROM);
    DEBUG_printf(DEBUG_MAX, "psOPTION->opt_ram = %d, byte = %d\n", psOPTION->opt_ram, MAXRAM);
    DEBUG_printf(DEBUG_MAX, "psOPTION->opt_obj = %d, name = %s\n", psOPTION->opt_obj, psOPTION->opt_obj_name);
    DEBUG_printf(DEBUG_MAX, "psOPTION->opt_ver = %d, name = %s\n", psOPTION->opt_ver, psOPTION->opt_ver_name);
    DEBUG_printf(DEBUG_MAX, "psOPTION->opt_lis = %d, name = %s\n", psOPTION->opt_lis, psOPTION->opt_lis_name);
    if (psOPTION->opt_log_name == NULL)
        DEBUG_printf(DEBUG_MAX, "psOPTION->opt_log = %d\n"           , psOPTION->opt_log);
    else
        DEBUG_printf(DEBUG_MAX, "psOPTION->opt_log = %d, name = %s\n", psOPTION->opt_log, psOPTION->opt_log_name);
    DEBUG_printf(DEBUG_MAX, "psOPTION->opt_verbose = %d\n"       , psOPTION->opt_verbose);
    DEBUG_printf(DEBUG_MAX, "psOPTION->opt_ascii   = %d\n"       , psOPTION->opt_ascii  );
    DEBUG_printf(DEBUG_MAX, "psOPTION->input_file_name = %s\n", psOPTION->input_file_name);
    //
    return error;
}

//=======================
// Main Routine
//=======================
int main (int argc, char **argv)
{
    sOPTION option;
    //
    // Configure Interrupt (Ctrl-C)
    signal(SIGINT, Interrupt_Handler);
    //
    // Parse Command Line
    if (Parse_Command_Line(argc, argv, &option))
    {
        Print_Usage();
        exit(EXIT_FAILURE);
    }
    //
    // Do Each Operation
    switch (option.func)
    {
        case FUNC_ASM : {Do_Asm(&option); break;}
        case FUNC_SIM : {Do_Sim(&option); break;}
        default : break;
    }
    //
    // Exit
    exit(EXIT_SUCCESS);
}

//===========================================================
// End of Program
//===========================================================
