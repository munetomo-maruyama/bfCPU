/*
//===========================================================
// bfCPU Assember / Simulator
//-----------------------------------------------------------
// File Name   : parser.l
// Description : Bison Code
//-----------------------------------------------------------
// History :
// Rev.01 2025.11.03 M.Maruyama First Release
//-----------------------------------------------------------
// Copyright (C) 2025 M.Maruyama
//===========================================================
*/

/*
//===========================================================
// Definition Section
//===========================================================
*/
%{
#include <stdio.h>
#include <stdlib.h>
#include "asm.h"

extern int yylineno;

int yylex (void);
int yyerror(char *s);

char *strdup(const char *s);
%}

%union {
    char *str;
}

%token <str> COMMENT
%token <str> INSTR_PINC
%token <str> INSTR_PDEC
%token <str> INSTR_INC
%token <str> INSTR_DEC
%token <str> INSTR_OUT
%token <str> INSTR_IN
%token <str> INSTR_BEGIN
%token <str> INSTR_END
%token <str> INSTR_RESET
%token <str> INSTR_NOP

/*
//===========================================================
// Rule Section
//===========================================================
*/
%%
    
instr:
    /* vacant */
    | instr COMMENT     { Instruction_Chain_Install(CODE_NONE,  $2); }
    | instr INSTR_PINC  { Instruction_Chain_Install(CODE_PINC,  $2); }
    | instr INSTR_PDEC  { Instruction_Chain_Install(CODE_PDEC,  $2); }
    | instr INSTR_INC   { Instruction_Chain_Install(CODE_INC,   $2); }
    | instr INSTR_DEC   { Instruction_Chain_Install(CODE_DEC,   $2); }
    | instr INSTR_OUT   { Instruction_Chain_Install(CODE_OUT,   $2); }
    | instr INSTR_IN    { Instruction_Chain_Install(CODE_IN,    $2); }
    | instr INSTR_BEGIN { Instruction_Chain_Install(CODE_BEGIN, $2); }
    | instr INSTR_END   { Instruction_Chain_Install(CODE_END,   $2); }
    | instr INSTR_RESET { Instruction_Chain_Install(CODE_RESET, $2); }
    | instr INSTR_NOP   { Instruction_Chain_Install(CODE_NOP,   $2); }
    ;

%%
/*
//===========================================================
// User Subroutine
//===========================================================
*/
int yyerror(char *s){ printf("%s at line %d\n",s, yylineno); }

/*
//===========================================================
// End of Program
//===========================================================
*/
