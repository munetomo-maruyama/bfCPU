//===========================================================
// bfCPU Running Tool
//-----------------------------------------------------------
// File Name   : main.c
// Description : Main Program
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025-2026 M.Maruyama
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
//
#include "defines.h"
#include "raspi.h"
#include "sram.h"
#include "utility.h"

//=====================
// Globals
//=====================
int CLKFREQ = CLKFREQ_DEFAULT;
extern int ctrl_c;

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
    printf("---------------------------------------------------------------\n");
    printf("bfCPU Running Tool Rev.%02d\n", REVISION);
    printf("---------------------------------------------------------------\n");
    printf("$ bfRun [options] InputHexFile.hex                             \n");
    printf("    --clk freq, -c freq : Clock Frequency in Hz (Default 10MHz)\n");
    printf("---------------------------------------------------------------\n");
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
        {"clk", required_argument, NULL, 'c'},
        {NULL , no_argument      , NULL, 0  }
    };
    //
    // Initialize
    psOPTION->opt_clk = OPT_NO;
    psOPTION->opt_clk_freq = NULL;
    psOPTION->input_file_name = NULL;
    //
    // Parse Option Line
    while ((c = getopt_long(argc, argv, "c:", long_option, &long_option_index)) != -1)
    {
        switch(c)
        {
            case 'c' :
            {
                psOPTION->opt_clk = OPT_YES;
                psOPTION->opt_clk_freq = optarg;
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
    // Decode Clock Frequency
    if (psOPTION->opt_clk)
    {
        long_num = strtol(psOPTION->opt_clk_freq, &endptr, 10);
        if ((errno == ERANGE) || (*endptr != '\0') || (long_num <= 0) || (long_num > LONG_MAX))
        {
            fprintf(stderr, "Clock Frequency is Illegal.\n");
            error = 1;
        }
        CLKFREQ = (int)long_num;;
    }
    else
    {
        CLKFREQ = CLKFREQ_DEFAULT;
    }
    //
    DEBUG_printf(DEBUG_MAX, "psOPTION->opt_clk = %d, freq = %d\n", psOPTION->opt_clk, CLKFREQ);
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
    char *obj_str;
    unsigned char *rom_src; // 8bit width
    unsigned char *rom_dst; // 8bit width
    int addr_max;
    int error = 0;
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
    // Allocate ROM
    rom_src = (unsigned char*)malloc(sizeof(unsigned char) * MAXROM);
    rom_dst = (unsigned char*)malloc(sizeof(unsigned char) * MAXROM);
    if ((rom_src == NULL) || (rom_dst == NULL))
    {
        fprintf(stderr, "======== ERROR: Can't allocate ROM area.\n");
        exit(EXIT_FAILURE);
    }
    //
    // Get Hex File as String
    printf("Read Hex File...");
    obj_str = Get_InputFile_as_String(&option);
    printf("Done.\n");
    //
    // Decode Hex Format
    printf("Decode Hex Format...");
    addr_max = Read_Hex_File(rom_src, obj_str);
    printf("Done.\n");
    for (int addr = 0; addr < 16; addr++) DEBUG_printf(DEBUG_MAX, "0x%02x 0x%02x\n", addr, rom_src[addr]);
    //
    // Open the Chip
    CHIP_Open();
    //
    // Assert RES_N
    RESN_Init();
    GPIO_RESN_Set_Value(0);
    //
    // Start Clock
    printf("Start System Clock...");
    SysClk_Output(1);
    printf("Done.\n");
    //
    // Configure SRAM as QSPI
    printf("Set Serial SRAM in QSPI Mode...");
    SRAM_Reset_to_SPI();
    SRAM_Config_as_QSPI();
    printf("Done.\n");
    //
    // Initialzie GPIO as QSPI        
    printf("Configure GPIO of Raspberry Pi...");
    QSPI_Init();
    printf("Done.\n");
    //
    // SRAM Write
    printf("Write Hex Data to SRAM...");
    SRAM_Write_Burst(rom_src, addr_max);
    printf("Done.\n");
    //
    // SRAM Read
    printf("Read Hex Data from SRAM...");
    SRAM_Read_Burst(rom_dst, addr_max);
    for (int addr = 0; addr < 16; addr++) DEBUG_printf(DEBUG_MAX, "0x%02x 0x%02x\n", addr, rom_dst[addr]);
    printf("Done.\n");
    //
    // SRAM Data Verify
    printf("Verify Hex Data in SRAM...");
    if (SRAM_Verify(rom_src, rom_dst, addr_max))
    {
        printf("NG.\n");
        error = 1;
    }
    else
    {
        printf("OK.\n");
    }
    //
    // Set Baud Rate data
    printf("Set Baud Rate Data in SRAM ");
    if (SRAM_Set_BaudRate_Data(CLKFREQ))
    {
        printf("NG.\n");
        error = 1;
    }
    else
    {
        printf("OK.\n");
    }
    //
    // Start bfCPU System
    if (error)
    {
        printf("Can not start the bfCPU System due to the error.\n");
    }
    else
    {
        printf("Start the bfCPU System (Ctrl-C to Quit).\n");
        //
        // Negate RES_N
        GPIO_RESN_Set_Value(1);
        while(1)
        {
            if (ctrl_c) break;
        }
        // Assert RES_N
        GPIO_RESN_Set_Value(0);
    }
    // Clean Up
    printf("Clean Up all\n");    
    //
    // CleanUp GPIO    
    QSPI_CleanUp();
    //
    // Stop Clock
    SysClk_Output(0);
    //
    // Negate RES_N
    GPIO_RESN_Set_Value(1);
    RESN_CleanUp();
    //
    // Close the Chip
    CHIP_Close();
    //
    //
    // Exit
    if (error)
        exit(EXIT_FAILURE);
    else
        exit(EXIT_SUCCESS);
}

//===========================================================
// End of Program
//===========================================================
