//===========================================================
// bfCPU Running Tool
//-----------------------------------------------------------
// File Name   : sram.c
// Description : QSPI SRAM Control Routine
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025-2026 M.Maruyama
//===========================================================

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <gpiod.h>
#include <math.h>
#include "raspi.h"
#include "sram.h"
#include "utility.h"

//---------------------------
// SRAM Config as QSPI Mode
//---------------------------
void SRAM_Config_as_QSPI(void)
{
    int i;
    int cmd = 0x38;
    //
    SPI_Init();
    //
	GPIO_SI_Set_Value(1);
    GPIO_CSN_Set_Value(1);
    GPIO_SCK_Set_Value(1);
    //
    GPIO_SCK_Set_Value(0);
    GPIO_CSN_Set_Value(0);
    //
    for (i = 0; i < 8; i++)
    {
	GPIO_SI_Set_Value((cmd >> (7-i)) & 0x01);
	GPIO_SCK_Set_Value(1);
	GPIO_SCK_Set_Value(0);
    }    
    //
    GPIO_CSN_Set_Value(1);
    GPIO_SCK_Set_Value(1);
	GPIO_SI_Set_Value(1);
    //
    SPI_CleanUp();
}

//---------------------------
// SRAM Reset to SPI Mode
//---------------------------
void SRAM_Reset_to_SPI(void)
{
    int i;
    //
    QSPI_Init();
    //
	GPIO_SIO_Set_Value(0xf);
    GPIO_CSN_Set_Value(1);
    GPIO_SCK_Set_Value(1);
    //
    GPIO_SCK_Set_Value(0);
    GPIO_CSN_Set_Value(0);
    //
    for (i = 0; i < 2; i++)
    {
	GPIO_SIO_Set_Value(0xf);
	GPIO_SCK_Set_Value(1);
	GPIO_SCK_Set_Value(0);
    }    
    //
    GPIO_CSN_Set_Value(1);
    GPIO_SCK_Set_Value(1);
	GPIO_SIO_Set_Value(0xf);
    //
    QSPI_CleanUp();
}

//------------------------
// SRAM Write Burst
//------------------------
void SRAM_Write_Burst(unsigned char *rom, int addr_max)
{
    int addr;
    unsigned char byte;
    //
    // Assert CS_N
    GPIO_SIO_Set_Value(0xf);
    GPIO_SCK_Set_Value(0);
    GPIO_CSN_Set_Value(0);
    //
    // Write Command    
    GPIO_SIO_Set_Value(0x0);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    GPIO_SIO_Set_Value(0x2);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    //
    // Address H
    GPIO_SIO_Set_Value(0x0);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    GPIO_SIO_Set_Value(0x0);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    //
    // Address L
    GPIO_SIO_Set_Value(0x0);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    GPIO_SIO_Set_Value(0x0);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    //
    // Data
    for (addr = 0; addr <= addr_max; addr++)
    {
        byte = rom[addr];
        GPIO_SIO_Set_Value((byte >> 4) & 0x0f);
        GPIO_SCK_Set_Value(1);
        GPIO_SCK_Set_Value(0);
        GPIO_SIO_Set_Value((byte >> 0) & 0x0f);
        GPIO_SCK_Set_Value(1);
        GPIO_SCK_Set_Value(0);
    }
    //
    // Negate CS_N
    GPIO_CSN_Set_Value(1);
    GPIO_SCK_Set_Value(1);
	GPIO_SIO_Set_Value(0xf);
}

//------------------------
// SRAM Read Burst
//------------------------
void SRAM_Read_Burst(unsigned char *rom, int addr_max)
{
    int addr;
    int value;
    unsigned char byte;
    //
    // Assert CS_N
    GPIO_SIO_Set_Value(0xf);
    GPIO_SCK_Set_Value(0);
    GPIO_CSN_Set_Value(0);
    //
    // Read Command    
    GPIO_SIO_Set_Value(0x0);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    GPIO_SIO_Set_Value(0x3);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    //
    // Address H
    GPIO_SIO_Set_Value(0x0);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    GPIO_SIO_Set_Value(0x0);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    //
    // Address L
    GPIO_SIO_Set_Value(0x0);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    GPIO_SIO_Set_Value(0x0);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    //
    // Data Dummy
    GPIO_SIO_Set_Value(0xf); // Open Drain Hi-Z
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    //    
    // Data    
    for (addr = 0; addr <= addr_max; addr++)
    {
        GPIO_SCK_Set_Value(1);
        GPIO_SIO_Get_Value(&value);
        byte = ((unsigned char)value & 0x0f) << 4;
        GPIO_SCK_Set_Value(0);
        GPIO_SCK_Set_Value(1);
        GPIO_SIO_Get_Value(&value);
        byte = byte | ((unsigned char)value & 0x0f) << 0;
        GPIO_SCK_Set_Value(0);
        rom[addr] = byte;
    }
    //
    // Negate CS_N
    GPIO_CSN_Set_Value(1);
    GPIO_SCK_Set_Value(1);
	GPIO_SIO_Set_Value(0xf);
}

//---------------------------
// SRAM Verify
//---------------------------
int SRAM_Verify(unsigned char *rom_src, unsigned char *rom_dst, int addr_max)
{
    int result;
    int addr;
    //
    result = 0;
    for (addr = 0; addr <= addr_max; addr++)
    {
        if (rom_src[addr] != rom_dst[addr]) result = 1;
        DEBUG_printf(DEBUG_MID, "0x%02x 0x%02x 0x%02x\n", addr, rom_src[addr], rom_dst[addr]);
    }
    //
    return result;
}

//------------------------
// SRAM Write Byte
//------------------------
void SRAM_Write_Byte(int addr, unsigned char byte)
{
    //
    // Assert CS_N
    GPIO_SIO_Set_Value(0xf);
    GPIO_SCK_Set_Value(0);
    GPIO_CSN_Set_Value(0);
    //
    // Write Command    
    GPIO_SIO_Set_Value(0x0);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    GPIO_SIO_Set_Value(0x2);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    //
    // Address H
    GPIO_SIO_Set_Value((addr >> 12) & 0x0f);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    GPIO_SIO_Set_Value((addr >>  8) & 0x0f);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    //
    // Address L
    GPIO_SIO_Set_Value((addr >>  4) & 0x0f);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    GPIO_SIO_Set_Value((addr >>  0) & 0x0f);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    //
    // Data
    GPIO_SIO_Set_Value((byte >> 4) & 0x0f);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    GPIO_SIO_Set_Value((byte >> 0) & 0x0f);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    //
    // Negate CS_N
    GPIO_CSN_Set_Value(1);
    GPIO_SCK_Set_Value(1);
	GPIO_SIO_Set_Value(0xf);
}

//------------------------
// SRAM Read Byte
//------------------------
void SRAM_Read_Byte(int addr, unsigned char *byte)
{
    int value;
    //
    // Assert CS_N
    GPIO_SIO_Set_Value(0xf);
    GPIO_SCK_Set_Value(0);
    GPIO_CSN_Set_Value(0);
    //
    // Read Command    
    GPIO_SIO_Set_Value(0x0);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    GPIO_SIO_Set_Value(0x3);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    //
    // Address H
    GPIO_SIO_Set_Value((addr >> 12) & 0x0f);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    GPIO_SIO_Set_Value((addr >>  8) & 0x0f);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    //
    // Address L
    GPIO_SIO_Set_Value((addr >>  4) & 0x0f);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    GPIO_SIO_Set_Value((addr >>  0) & 0x0f);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    //
    // Data Dummy
    GPIO_SIO_Set_Value(0xf); // Open Drain Hi-Z
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    GPIO_SCK_Set_Value(1);
    GPIO_SCK_Set_Value(0);
    //    
    // Data    
    GPIO_SCK_Set_Value(1);
    GPIO_SIO_Get_Value(&value);
    *byte = ((unsigned char)value & 0x0f) << 4;
    GPIO_SCK_Set_Value(0);
    GPIO_SCK_Set_Value(1);
    GPIO_SIO_Get_Value(&value);
    *byte = *byte | ((unsigned char)value & 0x0f) << 0;
    GPIO_SCK_Set_Value(0);
    //
    // Negate CS_N
    GPIO_CSN_Set_Value(1);
    GPIO_SCK_Set_Value(1);
	GPIO_SIO_Set_Value(0xf);
}

//------------------------------
// SRAM Set Baud Rate Data
//------------------------------
int SRAM_Set_BaudRate_Data(int freq)
{
    // BaudRate = (fclk/4) / ((div0+2)*(div1))
    //     clk=10MHz, 115200bps
    //     115200*4=460800
    //     10MHz/460800Hz=22=11*2
    //     div0=9 (11-2) , div1=2
    //
    // div1 = 2, fixed
    // BaudRate = (fclk/4) / ((div0+2)*div1)
    // div0 = fclk/BaudRate/div1/4 - 2
    // if 115200bps, fclk=10MHz, div1=2 then div0 = 9
    double dFreq, dBaud, dDiv0, dDiv1;
    unsigned char div0, div1;
    unsigned char byte0, byte1;
    int result;
    //
    dFreq = (double)freq;
    dBaud = 115200.0;
    dDiv1 = 2.0;
    dDiv0 = dFreq / dBaud / dDiv1 / 4.0 - 2.0;
    div0 = (unsigned char)round(dDiv0);
    div1 = (unsigned char)round(dDiv1);
    printf("(Freq=%d Baud=%d div0=%d div1=%d)...",
        freq, (int)dBaud, div0, div1);
    //
    SRAM_Write_Byte(0x0fffe, div0);
    SRAM_Write_Byte(0x0ffff, div1);
    SRAM_Read_Byte(0x0fffe, &byte0);
    SRAM_Read_Byte(0x0ffff, &byte1);
    result = ((div0 == byte0) && (div1 == byte1))? 0 : 1;
    //
    return result;
}

//===========================================================
// End of File
//===========================================================
