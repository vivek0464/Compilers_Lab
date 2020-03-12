%{
    void yyerror(char *s);
    #include <stdio.h>
    #include <stdlib.h>
    extern int yylex(); 
%}

%union {char *str;}
%start QUERY
%token MORE
%token RP
%token LP
%token EQUAL
%token COMMA
%token LESS
%token LESSEQUAL
%token MOREEQUAL
%token NOTEQUAL
%token WHITESPACE
%token NUM
%token QUOTE
%token DOT
%token AND
%token OR
%token NOT
%token SELECT
%token PROJECT
%token CARTESIAN_PRODUCT
%token EQUI_JOIN
%token ID


/* actual grammar implementation in C*/
%%
QUERY : SELECT LESS SELECT_COND MORE LP TABLE RP {printf("SELECT matched\n");}
       | PROJECT LESS ATTR_LIST MORE LP TABLE RP 
       | LP TABLE RP CARTESIAN_PRODUCT LP TABLE RP 
       | LP TABLE RP EQUI_JOIN LESS JOIN_COND MORE LP TABLE RP
       ;
TABLE : ID
       ;
ATTR_LIST : ID 
        | ID COMMA ATTR_LIST

SELECT_COND : OR_NOT_COND {printf("SELECT_COND -> OR_NOT_COND\n");}
            | OR_NOT_COND AND SELECT_COND {printf("SELECT_COND -> OR_NOT_COND AND SELECT_COND\n");}
            ;
OR_NOT_COND : NOT_COND {printf("OR_NOT_COND -> NOT_COND\n");}
            | NOT_COND OR OR_NOT_COND {printf("OR_NOT_COND -> NOT_COND OR OR_NOT_COND\n");}
            ;
NOT_COND : NOT COND {printf("NOT_COND -> NOT COND\n");}
           | COND {printf("NOT_COND -> COND\n");}
           ;
COND : CONST_OR_ID OP CONST_OR_ID {printf("COND -> CONST_OR_ID OP CONST_OR_ID\n");}
    ;
OP : EQUAL | LESS | MORE | LESSEQUAL | MOREEQUAL | NOTEQUAL 
    ;
CONST_OR_ID : ID | QUOTE ID QUOTE | NUM
    ;
JOIN_COND : EQUI_COND | EQUI_COND AND JOIN_COND
    ;
EQUI_COND : TABLE DOT ID EQUAL TABLE DOT ID
    ;
%%

int main(void){
    return yyparse();
}
void yyerror(char *s){
    fprintf(stderr , "%s\n",s);
}