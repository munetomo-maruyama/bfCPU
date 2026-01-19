//===========================================================
// bfCPU Assember / Simulator
//-----------------------------------------------------------
// File Name   : sim.h
// Description : Simulator Header
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025 M.Maruyama
//===========================================================

#include <stdint.h>
#include "defines.h"
#include "utility.h"
#include "asm.h"

#ifndef __SIM_H__
#define __SIM_H__

//-----------------------------------
// Increment / Decrement Pointers
//------------------------------------
#define INC_PTR(ptr) (((ptr) == (MAXRAM - 1))? 0          : (ptr) + 1)
#define DEC_PTR(ptr) (((ptr) == 0           )? MAXRAM - 1 : (ptr) - 1)
//
#define INC_PC(pc) (((pc) == (MAXROM - 1))? 0          : (pc) + 1)
#define DEC_PC(pc) (((pc) == 0           )? MAXROM - 1 : (pc) - 1)

//-------------------------------
// Prototypes
//-------------------------------
void Do_Sim(sOPTION *psOPTION);

#endif 

//===========================================================
// End of Program
//===========================================================
