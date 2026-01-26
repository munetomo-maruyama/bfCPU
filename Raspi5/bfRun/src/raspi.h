//===========================================================
// bfCPU Running Tool
//-----------------------------------------------------------
// File Name   : raspi.h
// Description : Raspberry Pi Control Header
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025-2026 M.Maruyama
//===========================================================

#ifndef __RASPI_H__
#define __RASPI_H__

//-------------------------------
// Prototypes
//-------------------------------
int  SysClk_Output(int start);
//
void CHIP_Open(void);
void CHIP_Close(void);
//
void RESN_Init(void);
void RESN_CleanUp(void);
void GPIO_RESN_Set_Value(int value);
//
void QSPI_Init(void);
void QSPI_CleanUp(void);
void SPI_Init(void);
void SPI_CleanUp(void);
//
void GPIO_CS_N_Set_Direction(int direction);
void GPIO_SCK_Set_Direction(int direction);
void GPIO_SIO_Set_Direction(int direction);
void GPIO_SI_Set_Direction(int direction);
void GPIO_RESN_Set_Value(int value);
void GPIO_CSN_Set_Value(int value);
void GPIO_SCK_Set_Value(int value);
void GPIO_SIO_Set_Value(int value);
void GPIO_SIO_Get_Value(int *value);
void GPIO_SI_Set_Value(int value);
void GPIO_SI_Get_Value(int *value);


#endif
//===========================================================
// End of File
//===========================================================
