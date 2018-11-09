/*
      mfpl.y

 	Specifications for the MFPL language, YACC input file.

      To create syntax analyzer:

        flex mfpl.l
        bison mfpl.y
        g++ mfpl.tab.c -o mfpl_parser
        mfpl_parser < inputFileName
 */

/*
 *	Declaration section.
 */
%{
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <string>
#include <cstring>
#include <stack>
//use for pair structure for arithlogic operators
//#include <utility>
#include "SymbolTable.h"
using namespace std;

#define ARITHMETIC_OP	1   // classification for operators
#define LOGICAL_OP   	2
#define RELATIONAL_OP	3

typedef struct 
{ 
  int first;       
  char* second;
} PAIR;

int lineNum = 1;

stack<SYMBOL_TABLE> scopeStack;    // stack of scope hashtables

bool isIntCompatible(const int theType);
bool isStrCompatible(const int theType);
bool isIntOrStrCompatible(const int theType);

void beginScope();
void endScope();
void cleanUp();
TYPE_INFO findEntryInAnyScope(const string theName);

void printRule(const char*, const char*);
int yyerror(const char* s) {
  printf("Line %d: %s\n", lineNum, s);
  cleanUp();
  exit(1);
}

extern "C" {
    int yyparse(void);
    int yylex(void);
    int yywrap() {return 1;}
}

%}

%union {
  char* text;
  PAIR num_and_type;
  char* op_type;
  int num;
  TYPE_INFO typeInfo;
};

/*
 *	Token declarations
*/
%token  T_LPAREN T_RPAREN 
%token  T_IF T_LETSTAR T_PRINT T_INPUT
%token  T_ADD  T_SUB  T_MULT  T_DIV
%token  T_LT T_GT T_LE T_GE T_EQ T_NE T_AND T_OR T_NOT	 
%token  T_INTCONST T_STRCONST T_T T_NIL T_IDENT T_UNKNOWN

%type	<text> T_IDENT T_INTCONST T_STRCONST T_T T_NIL
%type <typeInfo> N_EXPR N_PARENTHESIZED_EXPR N_ARITHLOGIC_EXPR  
%type <typeInfo> N_CONST N_IF_EXPR N_PRINT_EXPR N_INPUT_EXPR 
%type <typeInfo> N_LET_EXPR N_EXPR_LIST  
%type <num_and_type> N_BIN_OP
%type <op_type> N_ARITH_OP N_LOG_OP N_REL_OP

/*
 *	Starting point.
 */
%start  N_START

/*
 *	Translation rules.
 */
%%
N_START		: N_EXPR
			{
			printRule("START", "EXPR");
			printf("\n---- Completed parsing ----\n\n");
			printf("\nValue of the expression is: %s\n",$1.value);
			return 0;
			}
			;
N_EXPR		: N_CONST
			{
			printRule("EXPR", "CONST");
			$$.type = $1.type; 
			$$.value = $1.value;
			}
                | T_IDENT
                {
			printRule("EXPR", "IDENT");
                string ident = string($1);
                TYPE_INFO exprTypeInfo = 
						findEntryInAnyScope(ident);
                if (exprTypeInfo.type == UNDEFINED) 
                {
                  yyerror("Undefined identifier");
                  return(0);
               	}
                $$.type = exprTypeInfo.type; 
                $$.value = exprTypeInfo.value;
			}
                | T_LPAREN N_PARENTHESIZED_EXPR T_RPAREN
                {
			printRule("EXPR", "( PARENTHESIZED_EXPR )");
			$$.type = $2.type; 
			$$.value = $2.value;
			}
			;
N_CONST		: T_INTCONST
			{
			printRule("CONST", "INTCONST");
                $$.type = INT;
                $$.value = $1; 
			}
                | T_STRCONST
			{
			printRule("CONST", "STRCONST");
                $$.type = STR; 
                $$.value = $1;
			}
                | T_T
                {
			printRule("CONST", "t");
                $$.type = BOOL;
                $$.value = (char*)"t"; 
			}
                | T_NIL
                {
			printRule("CONST", "nil");
			$$.type = BOOL; 
			$$.value = (char*)"nil";
			}
			;
N_PARENTHESIZED_EXPR	: N_ARITHLOGIC_EXPR 
				{
				printRule("PARENTHESIZED_EXPR",
                                "ARITHLOGIC_EXPR");
				$$.type = $1.type;
				$$.value = $1.value ;
				}
                      | N_IF_EXPR 
				{
				printRule("PARENTHESIZED_EXPR", "IF_EXPR");
				$$.type = $1.type; 
				$$.value = $1.value;
				}
                      | N_LET_EXPR 
				{
				printRule("PARENTHESIZED_EXPR", 
                                "LET_EXPR");
				$$.type = $1.type; 
				$$.value = $1.value;
				}
                      | N_PRINT_EXPR 
				{
				printRule("PARENTHESIZED_EXPR", 
					    "PRINT_EXPR");
				$$.type = $1.type; 
				$$.value = $1.value;
				}
                      | N_INPUT_EXPR 
				{
				printRule("PARENTHESIZED_EXPR",
					    "INPUT_EXPR");
				$$.type = $1.type;
				$$.value = $1.value; 
				}
                     | N_EXPR_LIST 
				{
				printRule("PARENTHESIZED_EXPR",
				          "EXPR_LIST");
				$$.type = $1.type;
				$$.value = $1.value; 
				}
				;
N_ARITHLOGIC_EXPR	: N_UN_OP N_EXPR
				{
				printRule("ARITHLOGIC_EXPR", 
				          "UN_OP EXPR");
                      $$.type = BOOL; 
                      if($2.value != "nil")
                      {
                        $$.value = (char*)"nil";
                      }
                      else
                      {
                        $$.value = (char*)"t";
                      }
				}
				| N_BIN_OP N_EXPR N_EXPR
				{
				printRule("ARITHLOGIC_EXPR", 
				          "BIN_OP EXPR EXPR");
                      $$.type = BOOL;
                      //
                      char numstr[21];
                      int sCmp;
                      //
                      switch ($1.first)
                      {
                      case (ARITHMETIC_OP) :
                        $$.type = INT;
                        if (!isIntCompatible($2.type)) 
                        {
                          yyerror("Arg 1 must be integer");
                          return(0);
                     	}
                     	if (!isIntCompatible($3.type)) 
                        {
                          yyerror("Arg 2 must be integer");
                          return(0);
                     	}
                     	//if statements to determine which operator is being used
                     	if($1.second == "+")
                     	{
                     	  sprintf(numstr, "%d", (atoi($2.value) + atoi($3.value)));
                     	  $$.value = numstr;
                     	}
                     	else if($1.second == "-")
                     	{
                     	  sprintf(numstr, "%d", (atoi($2.value) - atoi($3.value)));
                     	  $$.value = numstr;
                     	}
                     	else if($1.second == "*")
                     	{
                     	  sprintf(numstr, "%d", (atoi($2.value) * atoi($3.value)));
                     	  $$.value = numstr;
                     	}
                     	else if($1.second == "/")
                     	{
                     	  if(atoi($3.value) == 0)
                     	  {
                     	    yyerror("Attempted division by zero");
                     	  }
                     	  sprintf(numstr, "%d", (atoi($2.value) / atoi($3.value)));
                     	  $$.value = numstr;
                     	}
                        break;

				case (LOGICAL_OP) :
						if($1.second == "and")
						{
						  if($2.value != "nil" && $3.value != "nil")
						  {
						    $$.value = (char*)"t";
						  }
						  else
						  {
						    $$.value = (char*)"nil";
						  }
						}
						else
						{
						  if($2.value != "nil" || $3.value != "nil")
						  {
						    $$.value = (char*)"t";
						  }
						  else
						  {
						    $$.value = (char*)"nil";
						  }
						}
                        break;

                      case (RELATIONAL_OP) :
                        if (!isIntOrStrCompatible($2.type)) 
                        {
                          yyerror("Arg 1 must be integer or string");
                          return(0);
                        }
                        if (!isIntOrStrCompatible($3.type)) 
                        {
                          yyerror("Arg 2 must be integer or string");
                          return(0);
                        }
                        if (isIntCompatible($2.type) &&
                            !isIntCompatible($3.type)) 
                        {
                          yyerror("Arg 2 must be integer");
                          return(0);
                     	  }
                        else if (isStrCompatible($2.type) &&
                                 !isStrCompatible($3.type)) 
                        {
                               yyerror("Arg 2 must be string");
                               return(0);
                             }
                        if($2.type == STR) //then we're doing a string comparison
                        {
                          sCmp = strcmp($2.value,$3.value);
                          if(sCmp == 0)
                          {
                            if($1.second == "=" || $1.second == "<=" || $1.second == ">=")
                            {
                              $$.value = (char*)"t";
                            }
                            else
                            {
                              $$.value = (char*)"nil";
                            }
                          }
                          else if(sCmp > 0)
                          {
                            if($1.second == ">" || $1.second == ">=" || $1.second == "/=")
                            {
                              $$.value = (char*)"t";
                            }
                            else
                            {
                              $$.value = (char*)"nil";
                            }
                          }
                          else 
                          {
                            if($1.second == "<" || $1.second == "<=" || $1.second == "/=")
                            {
                              $$.value = (char*)"t";
                            }
                            else
                            {
                              $$.value = (char*)"nil";
                            }
                          }
                        }
                        else //otherwise we're dealing with an INT comparison
                        {
                          if(atoi($2.value) > atoi($3.value))
                          {
                            if($1.second == ">" || $1.second == ">=" || $1.second == "/=")
                            {
                              $$.value = (char*)"t";
                            }
                            else
                            {
                              $$.value = (char*)"nil";
                            }  
                          }
                          else if(atoi($2.value) < atoi($3.value))
                          {
                            if($1.second == "<" || $1.second == "<=" || $1.second == "/=")
                            {
                              $$.value = (char*)"t";
                            }
                            else
                            {
                              $$.value = (char*)"nil";
                            }  
                          }
                          else //otherwise they're the same number
                          {
                            if($1.second == "=" || $1.second == "<=" || $1.second == ">=")
                            {
                              $$.value = (char*)"t";
                            }
                            else
                            {
                              $$.value = (char*)"nil";
                            }
                          }
                        }
                        break; 
                      }  // end switch
				}
                     	;
N_IF_EXPR    	: T_IF N_EXPR N_EXPR N_EXPR
			{
			printRule("IF_EXPR", "if EXPR EXPR EXPR");
			//printf("\n%s\n",$2.value);
			if($2.value != "nil")
			{
			  //printf("\nHERE\n");
			  $$.type = $3.type;
              $$.value = $3.value;   
			}
			else
			{
			  $$.type = $4.type;
              $$.value = $4.value;  
			}
			}
			;
N_LET_EXPR      : T_LETSTAR T_LPAREN N_ID_EXPR_LIST T_RPAREN 
                  N_EXPR
			{
			printRule("LET_EXPR", 
				    "let* ( ID_EXPR_LIST ) EXPR");
			endScope();
                $$.type = $5.type; 
                $$.value = $5.value;
			}
			;
N_ID_EXPR_LIST  : /* epsilon */
			{
			printRule("ID_EXPR_LIST", "epsilon");
			}
                | N_ID_EXPR_LIST T_LPAREN T_IDENT N_EXPR T_RPAREN 
			{
			printRule("ID_EXPR_LIST", 
                          "ID_EXPR_LIST ( IDENT EXPR )");
			string lexeme = string($3);
                 TYPE_INFO exprTypeInfo = $4;
                 printf("___Adding %s to symbol table\n", $3);
                 bool success = scopeStack.top().addEntry
                                (SYMBOL_TABLE_ENTRY(lexeme,
									 exprTypeInfo));
                 if (! success) 
                 {
                   yyerror("Multiply defined identifier");
                   return(0);
                 }
			}
			;
N_PRINT_EXPR    : T_PRINT N_EXPR
			{
			printRule("PRINT_EXPR", "print EXPR");
                $$.type = $2.type;
                $$.value = $2.value;
                printf("\n%s\n",$2.value);
			}
			;
N_INPUT_EXPR    : T_INPUT
			{
			printRule("INPUT_EXPR", "input");
			char temp[50];
			cin.getline(temp, 50);
			if(temp[0] == '0' || temp[0] == '1' || temp[0] == '2' || temp[0] == '3' || temp[0] == '4' || temp[0] == '5' || temp[0] == '6' || temp[0] == '7' || temp[0] == '8' || temp[0] == '9' || temp[0] == '+' || temp[0] == '-')
			{
			  $$.type = INT;
			  $$.value = temp;
			}
			else
			{
			  $$.type = STR;
			  $$.value = temp;
			}
			}
			;
N_EXPR_LIST     : N_EXPR N_EXPR_LIST  
			{
			printRule("EXPR_LIST", "EXPR EXPR_LIST");
                $$.type = $2.type;
                $$.value = $2.value;
			}
                | N_EXPR
			{
			printRule("EXPR_LIST", "EXPR");

                $$.type = $1.type;
                $$.value = $1.value;
			}
			;
N_BIN_OP	     : N_ARITH_OP
			{
			printRule("BIN_OP", "ARITH_OP");
			$$.first = ARITHMETIC_OP;
			$$.second = $1;
			}
			|
			N_LOG_OP
			{
			printRule("BIN_OP", "LOG_OP");
			$$.first = LOGICAL_OP;
			$$.second = $1;
			}
			|
			N_REL_OP
			{
			printRule("BIN_OP", "REL_OP");
			$$.first = RELATIONAL_OP;
			$$.second = $1;
			}
			;
N_ARITH_OP	     : T_ADD
			{
			printRule("ARITH_OP", "+");
			$$ = (char*)"+";
			}
                | T_SUB
			{
			printRule("ARITH_OP", "-");
			$$ = (char*)"-";
			}
			| T_MULT
			{
			printRule("ARITH_OP", "*");
			$$ = (char*)"*";
			}
			| T_DIV
			{
			printRule("ARITH_OP", "/");
			$$ = (char*)"/";
			}
			;
N_REL_OP	     : T_LT
			{
			printRule("REL_OP", "<");
			$$ = (char*)"<";
			}	
			| T_GT
			{
			printRule("REL_OP", ">");
			$$ = (char*)">";
			}	
			| T_LE
			{
			printRule("REL_OP", "<=");
			$$ = (char*)"<=";
			}	
			| T_GE
			{
			printRule("REL_OP", ">=");
			$$ = (char*)">=";
			}	
			| T_EQ
			{
			printRule("REL_OP", "=");
			$$ = (char*)"=";
			}	
			| T_NE
			{
			printRule("REL_OP", "/=");
			$$ = (char*)"/=";
			}
			;	
N_LOG_OP	     : T_AND
			{
			printRule("LOG_OP", "and");
			$$ = (char*)"and";
			}	
			| T_OR
			{
			printRule("LOG_OP", "or");
			$$ = (char*)"or";
			}
			;
N_UN_OP	     : T_NOT
			{
			printRule("UN_OP", "not");
			}
			;
%%

#include "lex.yy.c"
extern FILE *yyin;

bool isIntCompatible(const int theType) 
{
  return((theType == INT) || (theType == INT_OR_STR) ||
         (theType == INT_OR_BOOL) || 
         (theType == INT_OR_STR_OR_BOOL));
}

bool isStrCompatible(const int theType) 
{
  return((theType == STR) || (theType == INT_OR_STR) ||
         (theType == STR_OR_BOOL) || 
         (theType == INT_OR_STR_OR_BOOL));
}

bool isIntOrStrCompatible(const int theType) 
{
  return(isStrCompatible(theType) || isIntCompatible(theType));
}

void printRule(const char* lhs, const char* rhs) 
{
  printf("%s -> %s\n", lhs, rhs);
  return;
}

void beginScope() {
  scopeStack.push(SYMBOL_TABLE());
  printf("\n___Entering new scope...\n\n");
}

void endScope() {
  scopeStack.pop();
  printf("\n___Exiting scope...\n\n");
}

TYPE_INFO findEntryInAnyScope(const string theName) 
{
  TYPE_INFO info = {UNDEFINED};
  if (scopeStack.empty( )) return(info);
  info = scopeStack.top().findEntry(theName);
  if (info.type != UNDEFINED)
    return(info);
  else { // check in "next higher" scope
	   SYMBOL_TABLE symbolTable = scopeStack.top( );
	   scopeStack.pop( );
	   info = findEntryInAnyScope(theName);
	   scopeStack.push(symbolTable); // restore the stack
	   return(info);
  }
}

void cleanUp() 
{
  if (scopeStack.empty()) 
    return;
  else {
        scopeStack.pop();
        cleanUp();
  }
}

int main(int argc, char** argv) 
{
  if(argc < 2)
  {
    printf("You must specify a file in the command line!\n");
    exit(1);
  }
  yyin = fopen(argv[1],"r");
  do {
	yyparse();
  } while (!feof(yyin));

  cleanUp();
  return 0;
}
