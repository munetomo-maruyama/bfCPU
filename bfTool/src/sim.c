//===========================================================
// bfCPU Assember / Simulator
//-----------------------------------------------------------
// File Name   : sim.c
// Description : Simulator Routine
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
#include "sim.h"

//-------------------------
// Global Variables
//-------------------------
int ctrl_c = 0;
int MAXPTR = 0;
extern int MAXROM;
extern int MAXRAM;
extern int VERBOSE;
extern int ASCII;

//--------------------------------
// Interrupt Hander for CTRL-C
//--------------------------------
void Interrupt_Handler(int dummy)
{
    ctrl_c = 1;
    printf("\nAborted: MAXPTR=0x%04x(%d)\n", MAXPTR, MAXPTR);
    exit(EXIT_FAILURE);
}

//----------------------------------
// bfCPU Model
//----------------------------------
void bfCPU_Model(FILE *fp, unsigned char *rom)
{
    int  i;
    int  pc;
    int  ptr;
    int  count;
    unsigned char code;
    unsigned char data;
    unsigned char *ram;
    int  indent;
    //
    // Allocate RAM
    ram = (unsigned char*)malloc(sizeof(unsigned char) * MAXRAM);
    if (ram == NULL)
    {
        fprintf(stderr, "======== ERROR: Can't allocate RAM area.\n");
        exit(EXIT_FAILURE);
    }
    //
    // Initialize Model
    pc = 0;
    ptr = 0;
    count = 0;
    MAXPTR = 0;
    for (i = 0; i < MAXRAM; i++) ram[i] = 0x00;
    //
    // Run
    while(1)
    {
        // Fetch
        code = rom[pc];
        //
        // Print Count
        DUAL_printf(fp, "%05d : ", count);
        //
        // Decode and Exec
        switch(code)
        {
            // CODE_PINC     0
            case CODE_PINC :
            {
                DUAL_printf(fp, "PC=0x%02x ROM[0x%02x]=0x%1x (P++  ) ", pc, pc, code);
                ptr = INC_PTR(ptr);
                MAXPTR = (ptr > MAXPTR)? ptr : MAXPTR;
                DUAL_printf(fp, "--> PTR=0x%02x RAM[0x%02x]=0x%02x(%3d)\n", ptr, ptr, ram[ptr], ram[ptr]);
                pc = INC_PC(pc);
                break;
            }
            // CODE_PDEC     1
            case CODE_PDEC :
            {
                DUAL_printf(fp, "PC=0x%02x ROM[0x%02x]=0x%1x (P--  ) ", pc, pc, code);
                ptr = DEC_PTR(ptr); 
                DUAL_printf(fp, "--> PTR=0x%02x RAM[0x%02x]=0x%02x(%3d)\n", ptr, ptr, ram[ptr], ram[ptr]);
                pc = INC_PC(pc);
                break;
            }
            // CODE_INC      2
            case CODE_INC :
            {
                DUAL_printf(fp, "PC=0x%02x ROM[0x%02x]=0x%1x (INC  ) ", pc, pc, code);
                ram[ptr] = ram[ptr] + 1;
                DUAL_printf(fp, "--> PTR=0x%02x RAM[0x%02x]=0x%02x(%3d)\n", ptr, ptr, ram[ptr],ram[ptr]);
                pc = INC_PC(pc);
                break;
            }
            // CODE_DEC      3
            case CODE_DEC :
            {
                DUAL_printf(fp, "PC=0x%02x ROM[0x%02x]=0x%1x (DEC  ) ", pc, pc, code);
                ram[ptr] = ram[ptr] - 1;
                DUAL_printf(fp, "--> PTR=0x%02x RAM[0x%02x]=0x%02x(%3d)\n", ptr, ptr, ram[ptr], ram[ptr]);
                pc = INC_PC(pc);
                break;
            }
            // CODE_OUT      4
            case CODE_OUT :
            {
                if (ASCII == 0)
                {
                    printf("PC=0x%02x ROM[0x%02x]=0x%1x (OUT  ) ", pc, pc, code);
                    printf("--> PTR=0x%02x RAM[0x%02x]=0x%02x OUTPUT=0x%02x(%3d)(%c)\n", ptr, ptr, ram[ptr], ram[ptr], ram[ptr], ram[ptr]);
                    if (fp) fprintf(fp, "PC=0x%02x ROM[0x%02x]=0x%1x (OUT  ) ", pc, pc, code);
                    if (fp) fprintf(fp, "--> PTR=0x%02x RAM[0x%02x]=0x%02x OUTPUT=0x%02x(%3d)(%c)\n", ptr, ptr, ram[ptr], ram[ptr], ram[ptr], ram[ptr]);
                }
                else
                {
                    DUAL_printf(fp, "PC=0x%02x ROM[0x%02x]=0x%1x (OUT  ) ", pc, pc, code);
                    DUAL_printf(fp, "--> PTR=0x%02x RAM[0x%02x]=0x%02x OUTPUT=0x%02x(%3d)(%c)\n", ptr, ptr, ram[ptr], ram[ptr], ram[ptr], ram[ptr]);
                    printf("%c", ram[ptr]);
                    if (VERBOSE) printf("\n");
                }
                pc = INC_PC(pc);
                break;
            }
            // CODE_IN       5
            case CODE_IN :
            {
                if (ASCII == 0)
                {
                    printf("PC=0x%02x ROM[0x%02x]=0x%1x (IN   ) ", pc, pc, code);
                    printf("Input 8bit Hex Number? ");
                    while(1)
                    {
                        if (Get_Hex_from_STDIN(&data) == RESULT_OK) break;
                        if (ctrl_c) {data = 0; break;}
                    }
                    ram[ptr] = data;
                }
                else
                {
                    if (VERBOSE) printf("Input an ASCII Character? ");
                    while(1)
                    {
                        if (Get_ASCII_from_STDIN(&data) == RESULT_OK) break;
                        if (ctrl_c) {data = 0; break;}
                    }
                    ram[ptr] = data;
                    if (VERBOSE) printf("\n");
                }
                //
                DUAL_printf(fp, "PC=0x%02x ROM[0x%02x]=0x%1x (IN   ) ", pc, pc, code);
                DUAL_printf(fp, "--> PTR=0x%02x RAM[0x%02x]=0x%02x INPUT=0x%02x(%3d)(%c)\n", ptr, ptr, ram[ptr], ram[ptr], data, data);
                pc = INC_PC(pc);
                break;
            }
            // CODE_BEGIN    6
            case CODE_BEGIN :
            {
                DUAL_printf(fp, "PC=0x%02x ROM[0x%02x]=0x%1x (BEGIN) ", pc, pc, code);
                DUAL_printf(fp, "--> PTR=0x%02x RAM[0x%02x]=0x%02x(%3d)\n", ptr, ptr, ram[ptr], ram[ptr]);
                if (ram[ptr] == 0)
                {
                    indent = 0;
                    pc = INC_PC(pc);
                    while(1)
                    {
                        code = rom[pc];
                             if ((indent == 0) && (code == CODE_END)) {pc = INC_PC(pc); break;}
                        else if ((indent >  0) && (code == CODE_END)) {pc = INC_PC(pc); indent--;}
                        else if (code == CODE_BEGIN) {pc = INC_PC(pc); indent++;}
                        else pc = INC_PC(pc);
                        if (ctrl_c) break;
                    }
                }
                else
                {
                    pc = INC_PC(pc);
                }
                break;
            }
            // CODE_END      7
            case CODE_END :
            {
                DUAL_printf(fp, "PC=0x%02x ROM[0x%02x]=0x%1x (END  ) ", pc, pc, code);
                DUAL_printf(fp, "--> PTR=0x%02x RAM[0x%02x]=0x%02x(%3d)\n", ptr, ptr, ram[ptr], ram[ptr]);
                if (ram[ptr] != 0)
                {
                    indent = 0;
                    pc = DEC_PC(pc);
                    while(1)
                    {
                        code = rom[pc];
                             if ((indent == 0) && (code == CODE_BEGIN)) {pc = INC_PC(pc); break;}
                        else if ((indent >  0) && (code == CODE_BEGIN)) {pc = DEC_PC(pc); indent--;}
                        else if (code == CODE_END) {pc = DEC_PC(pc); indent++;}
                        else pc = DEC_PC(pc);
                        if (ctrl_c) break;
                    }
                }
                else
                {
                    pc = INC_PC(pc);
                }
                break;
            }
            // CODE_RESET    8
            case CODE_RESET :
            {
                DUAL_printf(fp, "PC=0x%02x ROM[0x%02x]=0x%1x (RESET) ", pc, pc, code);
                DUAL_printf(fp, "--> PTR=0x%02x RAM[0x%02x]=0x%02x(%3d)\n", ptr, ptr, ram[ptr], ram[ptr]);
                pc = 0;
                ptr = 0;
                for (i = 0; i < MAXRAM; i++) ram[i] = 0x00;
                printf("Hit Enter to Reset\n");
                while(1)
                {
                    int ch = getchar();
                    if ((ch == '\n') || (ch == '\r')) break;
                }
                break;
            }
            // CODE_NOP     15
            case CODE_NOP :
            {
                DUAL_printf(fp, "PC=0x%02x ROM[0x%02x]=0x%1x (NOP  ) ", pc, pc, code);
                DUAL_printf(fp, "--> PTR=0x%02x RAM[0x%02x]=0x%02x(%3d)\n", ptr, ptr, ram[ptr], ram[ptr]);
                pc = INC_PC(pc);
                break;
            }
            // Never Reach Here
            default :
            {
                fprintf(stderr, "======== ERROR: Illegal Code PC=0x%02x Code=0x%1x\n", pc, code);
                exit(EXIT_FAILURE);
                break;
            }
        }
        // Increment or Clear Count
        count = (code == CODE_RESET)? 0 : count + 1;
        //
        // Ctrl-C ?
        if (ctrl_c) break;
    }
    ctrl_c = 0;
}

//----------------------------------
// Read Hex File
//----------------------------------
void Read_Hex_File(unsigned char *rom, char *obj_str)
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
    //
    // Clear ROM
    for (addr = 0; addr < MAXROM; addr++) rom[addr] = CODE_NOP;
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
            rom[addr * 2 + 0] = (data >> 0) & 0x0f;
            rom[addr * 2 + 1] = (data >> 4) & 0x0f;
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
}

//-----------------------------------------
// Execute Simulation
//-----------------------------------------
void Execute_Simulation(sOPTION *psOPTION, unsigned char *rom)
{
    char fname_basename[MAXLEN_WORD];
    char fname_log[MAXLEN_WORD];
    FILE *fp_log;
    int  error;
    //
    // Get Base Name
    Get_Basename_without_Ext(fname_basename, psOPTION->input_file_name, MAXLEN_WORD);
    //
    // Make fname_log
    if ((psOPTION->opt_log) && (psOPTION->opt_log_name != NULL))
    {
        String_Copy(fname_log, psOPTION->opt_log_name, MAXLEN_WORD);
    }
    else if ((psOPTION->opt_log) && (psOPTION->opt_log_name == NULL))
    {
        String_Copy(fname_log, fname_basename, MAXLEN_WORD);
        String_Concatenate(fname_log, ".sim", MAXLEN_WORD);
    }
    else
    {
        *fname_log = '\0';
    }
    DEBUG_printf(DEBUG_MAX, "fname_log=%s\n", fname_log);
    //
    // Check File Name
    error = 0;
    error = (strcmp(psOPTION->input_file_name, fname_log))? error : 1;
    if (error)
    {
        fprintf(stderr, "======== ERROR: File Name Confliction\n");
        exit(EXIT_FAILURE);
    }
    //
    // Generate log file
    if (psOPTION->opt_log)
    {
        fp_log = fopen(fname_log, "w");
        if (fp_log == NULL)
        {
            fprintf(stderr, "======== ERROR: Can't open \"%s\".\n", fname_log);
            exit(EXIT_FAILURE);
        }
    }
    else
    {
        fp_log = NULL;
    }
    //
    // bfCPU Model
    bfCPU_Model(fp_log, rom);
    //
    // Close log file
    if (fp_log) fclose(fp_log);
}


//-----------------------------------------
// Do Simulation
//-----------------------------------------
void Do_Sim(sOPTION *psOPTION)
{
    char *obj_str;
    unsigned char *rom; // 4bit width
    int   addr;
    //
    // Allocate ROM
    rom = (unsigned char*)malloc(sizeof(unsigned char) * MAXROM);
    if (rom == NULL)
    {
        fprintf(stderr, "======== ERROR: Can't allocate ROM area.\n");
        exit(EXIT_FAILURE);
    }
    //
    // Get Hex File as String
    obj_str = Get_InputFile_as_String(psOPTION);
    //
    // Read Hex File
    Read_Hex_File(rom, obj_str);
    for (addr = 0; addr < 256; addr++) DEBUG_printf(DEBUG_MAX, "0x%02x 0x%02x\n", addr, rom[addr]);
    //
    // Execute Simulation
    Execute_Simulation(psOPTION, rom);
    //
    // Clean Up
    free(obj_str);
}

//===========================================================
// End of Program
//===========================================================
