//===========================================================
// bfCPU Running Tool
//-----------------------------------------------------------
// File Name   : sram.h
// Description : QSPI SRAM Control Header
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025-2026 M.Maruyama
//===========================================================

#ifndef __QSPI_H__
#define __QSPI_H__

//-------------------------------
// Prototypes
//-------------------------------
void SRAM_Config_as_QSPI(void);
void SRAM_Reset_to_SPI(void);
void SRAM_Write_Burst(unsigned char *rom, int addr_max);
void SRAM_Read_Burst(unsigned char *rom, int addr_max);
int SRAM_Verify(unsigned char *rom_src, unsigned char *rom_dst, int addr_max);
void SRAM_Write_Byte(int addr, unsigned char byte);
void SRAM_Read_Byte(int addr, unsigned char *byte);
int  SRAM_Set_BaudRate_Data(int freq);

#endif
//===========================================================
// End of File
//===========================================================
