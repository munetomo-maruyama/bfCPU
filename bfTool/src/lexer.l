/*
//===========================================================
// bfCPU Assember / Simulator
//-----------------------------------------------------------
// File Name   : lexer.l
// Description : Flex Code
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
%option noyywrap nodefault yylineno
%{
 #include <string.h>
 #include <stdint.h>
 #include "parser.tab.h"
%}

/*
//===========================================================
// Rule Section
//===========================================================
//([Pp][Ii][Nn][Cc])|([Pp][+][+])|([>]) { yylval.str = strdup(yytext); return INSTR_PINC;  }
([Pp][Dd][Ee][Cc])|([Pp][-][-])|([<]) { yylval.str = strdup(yytext); return INSTR_PDEC;  }
([Ii][Nn][Cc])|([+])                  { yylval.str = strdup(yytext); return INSTR_INC;   }
([Dd][Ee][Cc])|([-])                  { yylval.str = strdup(yytext); return INSTR_DEC;   }
([Oo][Uu][Tt])|([.])                  { yylval.str = strdup(yytext); return INSTR_OUT;   }
([Ii][Nn])|([,])                      { yylval.str = strdup(yytext); return INSTR_IN;    }
([Bb][Ee][Gg][Ii][Nn])|([\[])         { yylval.str = strdup(yytext); return INSTR_BEGIN; }
([Ee][Nn][Dd])|([\]])                 { yylval.str = strdup(yytext); return INSTR_END;   }
([Rr][Ee][Ss][Ee][Tt])                { yylval.str = strdup(yytext); return INSTR_RESET; }
([Nn][Oo][Pp])                        { yylval.str = strdup(yytext); return INSTR_NOP;   }
*/
%%

((\/\/|;).*)                            { yylval.str = strdup(yytext); return COMMENT;     }
((?i:pinc)|(?i:p)\+\+|>)([ \t]*"//".*)? { yylval.str = strdup(yytext); return INSTR_PINC;  }
((?i:pdec)|(?i:p)\-\-|<)([ \t]*"//".*)? { yylval.str = strdup(yytext); return INSTR_PDEC;  }
((?i:inc)|\+)([ \t]*"//".*)?            { yylval.str = strdup(yytext); return INSTR_INC;   }
((?i:dec)|\-)([ \t]*"//".*)?            { yylval.str = strdup(yytext); return INSTR_DEC;   }
((?i:out)|\.)([ \t]*"//".*)?            { yylval.str = strdup(yytext); return INSTR_OUT;   }
((?i:in)|\,)([ \t]*"//".*)?             { yylval.str = strdup(yytext); return INSTR_IN;    }
((?i:begin)|\[)([ \t]*"//".*)?          { yylval.str = strdup(yytext); return INSTR_BEGIN; }
((?i:end)|\])([ \t]*"//".*)?            { yylval.str = strdup(yytext); return INSTR_END;   }
(?i:reset)([ \t]*"//".*)?               { yylval.str = strdup(yytext); return INSTR_RESET; }
(?i:nop)([ \t]*"//".*)?                 { yylval.str = strdup(yytext); return INSTR_NOP;   }
[\ \t\n] { /* ignore */ }
.        {printf("Syntax Error %s in line %d\n", strdup(yytext), yylineno); exit(EXIT_FAILURE);}



%%
/*
//===========================================================
// User Subroutine
//===========================================================
*/
YY_BUFFER_STATE bp;

void Copy_String_to_YY_Buffer(char *string)
{
    bp = yy_scan_string(string);
    yy_switch_to_buffer(bp);
}

void Dispose_YY_Buffer(void)
{
    yy_flush_buffer(bp);
    yy_delete_buffer(bp);
}

/*
//===========================================================
// End of Program
//===========================================================
*/
