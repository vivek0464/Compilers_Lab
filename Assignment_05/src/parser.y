%{

        
    #include <stdio.h>
    #include <stdlib.h>
    #include <stdbool.h>
    #include <string.h>
    #include <assert.h>
    #define YYDEBUG 1
    #define INTERMEDIATE_VARIABLES_MAX_COUNT 32
    #define MAX_SYMBOL_TABLE_SIZE 100
    #define MAX_DECLARATIONS_PER_STATEMENT 10
    #define MAX_VAR_LEN 20
    #define MAX_ERROR_STRING_LEN 100
    #define MAX_ARG_LEN 50
    #define MAX_CODE_LEN 1024
    #define MAX_LABEL_COUNT 64
    #define MAX_LABEL_LENGTH 64
    #define MAX_LIST_SIZE 20
    #define MAX_INSTRUCTION_LENGTH 1024

    void yyerror(const char *s);
    int yylex(); 


    /*
    TYPES:
     -1 unassigned
      0 int
      1 float
      2 void
      3 bool
    */
    char * type_names[] =   { "int", "float", "void", "bool" };
    char* names[] = { 
                    "t0" , "t1" , "t2" , "t3" , "t4" , "t5", "t6", "t7", 
                    "t8" , "t9" , "t10", "t11", "t12", "t13", "t14", "t15", 
                    "t16", "t17", "t18", "t19", "t20", "t21", "t22", "t23", 
                    "t24", "t25", "t26", "t27", "t28", "t29", "t30", "t31"
                    };
    int name_ptr = 0;
    /* structures for intermediate code generation and buffer format output*/
    /* 
    ** symbol_table: Array of pointers to symbol_table_entry objects
    ** symbol_table_top: Index of topmost empty slot in table. 0 means empty stack.
     */
    typedef
    struct symbol_table_entry{
        int scope;
        int type;
        char* name;
    } symbol_table_entry;
    symbol_table_entry * symbol_table[MAX_SYMBOL_TABLE_SIZE];
    int symbol_table_top = 0;
    int curr_scope = 0;
    void symbol_table_append(int scope, int type , char* name);
    bool symbol_table_lookup(char * name);
    void print_symbol_table();

    /* var_declaration_list
    ** names: array of ids of declared variables
    ** assigned_types: array of ints denoting type of assigned value to var. Eg: int foo = 45.6 then names[i]="foo" and assigned_types[i]=1 for float. -1 for uninitialized
    ** index: number of elements in list
    */
    typedef
    struct var_declaration_list{
        char* names[MAX_DECLARATIONS_PER_STATEMENT];
        int assigned_types[MAX_DECLARATIONS_PER_STATEMENT];
        int index;
    } var_declaration_list;
    void var_declaration_list_append(var_declaration_list * list_ptr, char * name, int type);
    void var_declaration_list_union(var_declaration_list * dest_ptr, var_declaration_list * src_ptr);
    void print_var_declaration_list(var_declaration_list * list_ptr);


    /* struct to store quadruple code for current operation and concatenated code for the subtree */
    typedef
    struct buffer{
        char*    operation; /* denotes operation */
        char*    argument1;   /*  name of first argument */
        char*    argument2;   /*  name of second argumen */
        char*    result;    /*  name of the intermediate variable*/
        char *   code;       /*  code for the subtree contained */
    } buffer;
    buffer* create_buffer(char *oper , char *arg1 , char *arg2 , char* result , char* code); /* create a new buffer and return it's reference */
    void display_buffer(buffer* Q); /* display the intermediate code from the buffer format */
    buffer* combine_buffer(buffer *Q1 , buffer *Q2 , char *operation); /* combining two buffers*/
    char* get_next_name(); /*returns the next available variable. Works cyclically*/
    void print_code(buffer* Q); /*prints the code of the */



     /* relevant structures for backpatching approach*/
    typedef
    struct list{
            int* arr;
            int size;
    } list;
    /*create an empty list and return it's reference */
    list* create_list(){
            list* l = (list *) malloc(sizeof(list));
            l->arr = (int *) malloc(sizeof(int) * MAX_INSTRUCTION_LENGTH);
            l->size = 0;
            return l;
    }
    /* insert value into list */
    void insert_list(list *l , int value){
            (l->arr)[l->size] = value;
            ++(l->size);
            return;
    }

    /* debuging list */
    void debug_list(list *l){
            printf("list : ");
            for(int i = 0; i < l->size; i++){
                    printf("%d " , (l->arr)[i]);
            }
            printf("\n");
    }
     /* node for boolean expressions */
    typedef 
    struct node{
            list* truelist;
            list* falselist; 
            char* code;
    } node;  
                              /*utility functions and variables */
    
    /* instruction_list[i] is the ith instruction string */
    char* instruction_list[MAX_INSTRUCTION_LENGTH]; 
    
    /* pointer to the next instruction*/
    int next_instr = 0;
    int previous_instr = 0;
    /* adding an instruction string */

    void add_instruction(char * str){
            instruction_list[next_instr] = str;
            ++next_instr;
    }

    /*allocate memory to a node and return its reference*/
    node* 
    create_node(){
            node* n = (node *) malloc(sizeof(node));
            n->truelist  = create_list();
            n->falselist = create_list();
            return n;
    }
    /* backpatch the value = val at locations present in list */ 

    int 
    number_of_digits(int x){
            int d = 0;
            while(x){
                    x /= 10;
                    d++;
            }
            return d;
    }   

    void replace_with(char * str , int val){
             // find first occurence of '_'
             int f = 0;
             while(str[f] != '\0'){
                     if(str[f] == '_') break;
                     ++f;
             }

            // calculate the number of digits
             int ndigits = number_of_digits(val);

            // write an L at the first location
             str[f] = 'L';
                
            // copy the digits into string from f + ndigits backwards
             int j = f + ndigits;

             int temp = val;

             while(temp){
                     str[j] = (char)(temp % 10 + '0');
                     temp /= 10;
                     --j;
             }

            // remove any trailing '_' s if pres
             j = f + ndigits + 1;
             while(str[j] != '\0' && str[j] == '_'){
                     str[j] = ' ';
                     ++j;
             }
             str[j] = '\n';
    }
    void 
    backpatch(list* l , int val){
            for(int i = 0; i < l->size; i++){
                char* str = instruction_list[(l->arr)[i]];
                replace_with(str , val);
            }
            return;
    }
    /* merge two lists l1 and l2*/
    list* 
    merge(list* l1 , list* l2){
            for(int i = 0; i < (l2->size); i++){
                    insert_list(l1 , (l2->arr)[i]);
            }
            return l1;
    }   
    /* create a list with value index and return its reference*/
    list* 
    makelist(int index){
            list* l = create_list();
            insert_list(l , index);
            return l;
    }

    void
    debug_node(node* n){
            printf("true ");
            debug_list(n->truelist);
            printf("false ");
            debug_list(n->falselist);
    }
    typedef
    struct M{
            int instruction_number;
    } M;


    typedef
    struct statement{
            list* nextlist;
    } statement;
%}

%union {
        char* str;
        float val;
        void* var_declaration_list;
        int type;
        void* three_addr_code;
        void* labeled_node_ptr;
        void* node_ptr;
        void* m_ptr;
        void* stmt;
       }


%start PROGRAM
%token DOT
%token RP
%token LP
%token CRP
%token CLP
%token ASSIGN
%token ADD
%token MINUS
%token MUL
%token DIV
%token MOD
%token QUES
%left OR
%left AND
%token NOT
%token BITAND
%token BITOR
%token BITNOT
%token BITXOR
%token COMMA
%token MORE
%token LESS
%token LESSEQUAL
%token MOREEQUAL
%token EQUAL
%token NOTEQUAL
%token QUOTE
%token SEMI
%token COLON
%token null
%token FALSE
%token TRUE
%token FOR
%token WHILE
%token INT
%token FLOAT
%token VOID
%token MAIN
%token IF
%token ELSE
%token SWITCH
%token CASE
%token DEFAULT
%token BREAK
// %type<str> INT
%token <str> NUM
%token <str> ID
%type <str> RELOP
%type <three_addr_code> EXP
%type <three_addr_code> ASSIGNMENT_EXPR
%type <three_addr_code> CONDITIONAL_EXPR
%type <three_addr_code> LOGICAL_OR_EXPR
%type <three_addr_code> LOGICAL_AND_EXPR
%type <three_addr_code> INCLUSIVE_OR_EXPR
%type <three_addr_code> EXCLUSIVE_OR_EXPR
%type <three_addr_code> AND_EXPR
%type <three_addr_code> EQUALITY_EXPR
%type <three_addr_code> RELATIONAL_EXPR
%type <three_addr_code> ADDITION_EXPR
%type <three_addr_code> MULTIPLICATION_EXPR
%type <three_addr_code> BASIC_EXPR


%type <stmt> STMT
%type <stmt> STMT_LIST
%type <stmt> N


%type <labeled_node_ptr> BODY
%type <labeled_node_ptr> IF_AND_SWICH_STATEMENTS
%type <node_ptr> BOOLEAN_EXPR
%type <m_ptr> M
%type <var_declaration_list> DECLARATION MULTI_DECLARATION
%type <val> TYPECAST
/* actual grammar implementation in C*/
%%

PROGRAM 
        : 
         |
         BOOLEAN_EXPR  SEMI{
                 printf("------------matched boolean expression------------\n");
                 printf("testing the instructions\n");
                 for(int i = previous_instr; i < next_instr; i++){
                         printf("L%d : %s",i, instruction_list[i]);
                 }
                 previous_instr = next_instr ;
         } PROGRAM 
         
        ;


VAR
        : INT MULTI_DECLARATION SEMI                                {
                                                                        printf("matched int declaration\n\n");
                                                                        var_declaration_list * list_ptr = (var_declaration_list *) $2;
                                                                        print_var_declaration_list(list_ptr);
                                                                        for(int i = 0 ; i < list_ptr->index ; i++) {
                                                                            // check var is not already declared in current scope
                                                                            if(symbol_table_lookup(list_ptr->names[i])) {
                                                                                char error_str[MAX_ERROR_STRING_LEN];
                                                                                sprintf(error_str, "Redeclaration of variable '%s'.", list_ptr->names[i]);
                                                                                yyerror(error_str);
                                                                            }
                                                                            // insert into symbol table
                                                                            symbol_table_append(curr_scope, 0, list_ptr->names[i]);

                                                                            // TODO : convert from assigned type to int
                                                                        }
                                                                        print_symbol_table();
                                                                    }
        | FLOAT MULTI_DECLARATION SEMI                              {
                                                                        printf("matched float declaration\n\n");
                                                                        var_declaration_list * list_ptr = (var_declaration_list *) $2;
                                                                        print_var_declaration_list(list_ptr);
                                                                        for(int i = 0 ; i < list_ptr->index ; i++) {
                                                                            // check var is not already declared in current scope
                                                                            if(symbol_table_lookup(list_ptr->names[i])) {
                                                                                char error_str[MAX_ERROR_STRING_LEN];
                                                                                sprintf(error_str, "Redeclaration of variable '%s'.", list_ptr->names[i]);
                                                                                yyerror(error_str);
                                                                            }
                                                                            // insert into symbol table
                                                                            symbol_table_append(curr_scope, 1, list_ptr->names[i]);

                                                                            // TODO : convert from assigned type to int
                                                                        }
                                                                        print_symbol_table();
                                                                    }
        ;

MULTI_DECLARATION 
        : DECLARATION COMMA MULTI_DECLARATION                       {
                                                                        var_declaration_list_union((var_declaration_list *)$$, (var_declaration_list *)$3);
                                                                        // print_var_declaration_list((var_declaration_list *)$$);
                                                                    }
        | DECLARATION                                               {
                                                                        $$ = $1;
                                                                        // print_var_declaration_list((var_declaration_list *)$$);
                                                                    }
        ;

DECLARATION 
        : ID                                                        {
                                                                        printf("id matched in declaration %s\n", $1);
                                                                        var_declaration_list_append((var_declaration_list *)$$, $1, -1);
                                                                    }
        | ID ASSIGN TYPECAST ASSIGNMENT_EXPR                        {
                                                                        printf("id matched in declaration %s\n", $1);
                                                                        int type;
                                                                        if($3 == -1) {
                                                                            type = 0; // TODO: type from expr
                                                                        }
                                                                        else {
                                                                            // TODO: convert expr to $3 type.
                                                                            type = $3;
                                                                        }
                                                                        var_declaration_list_append((var_declaration_list *)$$, $1, type);
                                                                    }
        ;

TYPECAST 
        :                                                           {
                                                                        $$ = -1;
                                                                    }
        | LP INT RP                                                 {
                                                                        $$ = 0;
                                                                    }
        | LP FLOAT RP                                               {
                                                                        $$ = 1;
                                                                    }
        ;

DATA_TYPE 
        : VOID 
        | INT
        | FLOAT
        ;

FUNC_DECLARATION 
        : INT ID LP PARAM_LIST_WITH_DATATYPE RP SEMI             { printf("matched int function declaration\n");}
        | FLOAT ID LP PARAM_LIST_WITH_DATATYPE RP SEMI           { printf("matched float function declaration\n");}
        | VOID ID LP PARAM_LIST_WITH_DATATYPE RP SEMI            { printf("matched void function declaration\n");}
        ;

PARAM_LIST_WITH_DATATYPE
        : 
        | PARAM_WITH_DATATYPE COMMA PARAM_LIST_WITH_DATATYPE 
        | PARAM_WITH_DATATYPE                                    {}
        ;

PARAM_WITH_DATATYPE 
        : DATA_TYPE ID                                           {}
        ;

FUNC_DEFINITION 
        : INT ID LP PARAM_LIST_WITH_DATATYPE RP CLP STMT_LIST CRP   { 
                                                                        printf("matched int   function definition\n");
                                                                        printf("-------------------testing----------------------\n");
                                                                        printf("------ code for stmt list of this function -----\n");
                                                                        char * cd = ((labeled_node *) $7)->code;
                                                                        printf("%s", cd);
                                                                        char * lbl = ((labeled_node *)$7)->next_label;
                                                                        printf("label for stmt_list = %s\n", lbl);
                                                                    }
        | FLOAT ID LP PARAM_LIST_WITH_DATATYPE RP CLP STMT_LIST CRP { printf("matched float function definition\n");}
        | VOID ID LP PARAM_LIST_WITH_DATATYPE RP CLP STMT_LIST CRP  { printf("matched void  function definition\n"); }
        ;


STMT 
        :
         IF LP BOOLEAN_EXPR RP M STMT{
                 backpatch((node*)$3)->truelist , ((M*)$5)->instruction_number);
                 statement * stmt = (statement*) malloc(sizeof(statement));
                 stmt->nextlist = merge(((node*)$3)->falselist, ((statement*)$6)->nextlist);
                 $$=stmt;
         }
        | IF LP BOOLEAN_EXPR RP M STMT N ELSE M STMT{
                 backpatch((node*)$3)->truelist , ((M*)$5)->instruction_number);
                 backpatch((node*)$3)->falselist ,((M*)$9)->instruction_number);
                 list* temp = merge(((statement*)$6)->nextlist,((statement*)$7)->nextlist);
                 statement* stmt= (statement*)malloc(sizeof(statement));
                 stmt->nextlist=merge(temp, ((statement*)$10)->nextlist);
                 $$=(void*)stmt;
        }
        | WHILE M LP BOOLEAN_EXPR RP M STMT{
                backpatch( ((statement *)$7)->nextlist, ((M*)$2)->instruction_number);
                backpatch( ((statement*)$4)->truelist , ((M*)$6)->instruction_number);
                statement * stmt = (statement *) malloc(sizeof(statement));
                stmt->nextlist = ((node*)$4)->falselist;
                char* str=(char*) malloc(sizeof(char) * MAX_INSTRUCTION_LENGTH);
                strcpy(str,"goto Lcap\n");
                add_instruction(str);
                $$=(void*)stmt;
        }
        | CLP STMT_LIST CRP{
                statement * stmt = (statement *) malloc(sizeof(statement));
                stmt->nextlist = ((node*)$2)->falselist;
                $$=(void*)stmt;
        }
        | VAR {
                statement * stmt = (statement *) malloc(sizeof(statement));
                stmt->nextlist = NULL;
                $$=(void*)stmt;
        }                                     
        | FUNC_CALL{
                statement * stmt = (statement *) malloc(sizeof(statement));
                stmt->nextlist = NULL;
                $$=(void*)stmt;

        }                                                                                          
        | EXP {
                statement * stmt = (statement *) malloc(sizeof(statement));
                stmt->nextlist = NULL;
                $$=(void*)stmt;
        }                                     
        ;
STMT_LIST
        : STMT_LIST M STMT{
                backpatch( ((statement *)$1)->nextlist, ((M*)$2)->instruction_number);
                statement * stmt = (statement *) malloc(sizeof(statement));
                stmt->nextlist = ((statement *)$3)->nextlist;
                $$ = (void*)stmt;
        }
        | STMT{
                statement * stmt = (statement *) malloc(sizeof(statement));
                stmt->nextlist = ((statement *)$1)->nextlist;
                $$ = (void*) stmt;
        }
        ;
N : %empty{
        statement* stmt = (statement *) malloc(sizeof(statement));
        stmt->nextlist = makelist(next_instr);
        char *str= (char *) malloc(sizeof(char) * MAX_INSTRUCTION_LENGTH);
        strcpy(str, "goto _");
        add_instruction(str);
        $$ = (void *) stmt;     
     }
  ;


FUNC_CALL 
        : ID LP PARAM_LIST_WO_DATATYPE RP SEMI                      { printf("matched function call\n"); }
        ;

PARAM_LIST_WO_DATATYPE 
        : PARAM_WO_DATATYPE COMMA PARAM_LIST_WO_DATATYPE 
        | PARAM_WO_DATATYPE                                         {}
        ;

PARAM_WO_DATATYPE 
        :
        | EXP 
        ;

LOOP 
        : FOR FORLOOP BODY                                          { printf("for loop matched\n"); }
        | WHILE LP CONDITION RP BODY                                { printf("while loop matched\n"); }
        ;

BODY 
        : CLP STMT_LIST CRP                                         
        | STMT                                                      
        ;

FORLOOP 
        : LP COMMA_SEP_INIT SEMI CONDITION SEMI COMMA_SEP_INCR RP  
        ;

COMMA_SEP_INIT 
        : 
        | ID ASSIGN EXP COMMA COMMA_SEP_INIT 
        | COMMA_SEP_DATATYPE_INIT
        ;

COMMA_SEP_DATATYPE_INIT
        : ID ASSIGN EXP 
        | DATA_TYPE COMMA_SEP_INIT_PRIME
        ;

COMMA_SEP_INIT_PRIME
        : ID ASSIGN EXP COMMA COMMA_SEP_INIT_PRIME 
        | ID ASSIGN EXP
        ;

CONDITION 
        : 
        | EXP
        ;

COMMA_SEP_INCR 
        :
        | ADD ADD ID 
        | MINUS MINUS ID 
        | ID ADD ADD 
        | ID MINUS MINUS 
        | ID ASSIGN EXP 
        | ID OTHER ASSIGN EXP
        ;

OTHER 
        : MOD
        | ADD 
        | MINUS 
        | MUL
        | DIV 
        | BITAND
        | BITOR 
        | BITXOR 
        ;

EXP 
        : ASSIGNMENT_EXPR                                       { 
                                                                        $$ = $1;
                                                                }
        | EXP COMMA ASSIGNMENT_EXPR                             {   
                                                                       printf("second\n");
                                                                        $$ = $3; // all assignment expressions already handled by children
                                                                        print_code( (buffer *) $3);
                                                                }
        ;

ASSIGNMENT_EXPR 
        : CONDITIONAL_EXPR                                          {
                                                                        $$ = $1;
                                                                    }
        | ID ASSIGN ASSIGNMENT_EXPR                                 {   // combine assignment expressions using assign
                                                                        char* variable_name = $1;
                                                                        buffer* assign_expr = (buffer*) $3;
                                                                        // result goes directly into the variable_name
                                                                        char * assignment_code = (char *) malloc(sizeof(char) * MAX_CODE_LEN);
                                                                        assignment_code[0] = '\0';
                                                                        strcat(assignment_code , assign_expr->code);
                                                                        strcat(assignment_code , variable_name);
                                                                        strcat(assignment_code , " = ");
                                                                        strcat(assignment_code , assign_expr->result);
                                                                        strcat(assignment_code , "\n");
                                                                        $$ = (void *) create_buffer("=" , assign_expr->result , NULL , variable_name , assignment_code);
                                                                        // display_buffer((buffer *) $$);
                                                                    }
        ;

CONDITIONAL_EXPR 
        : LOGICAL_OR_EXPR                                           {
                                                                        $$ = $1;
                                                                    }
        ;

LOGICAL_OR_EXPR 
        : LOGICAL_AND_EXPR                                          {
                                                                        $$ = $1;
                                                                    }
        | LOGICAL_OR_EXPR OR LOGICAL_AND_EXPR                       {  // combine logical and expressions using or
                                                                       buffer * logical_or  = (buffer *) $1;
                                                                       buffer * logical_and = (buffer *) $3;
                                                                       $$ = (void *) combine_buffer(logical_or , logical_and , "||");
                                                                //        display_buffer((buffer *) $$);
                                                                    }
        ;
LOGICAL_AND_EXPR 
        : INCLUSIVE_OR_EXPR                                         {
                                                                        $$ = $1;
                                                                    }
        | LOGICAL_AND_EXPR AND INCLUSIVE_OR_EXPR                    {  // combine inclusive or expressions using and
                                                                       buffer * Q_logical_and  = (buffer *) $1;
                                                                       buffer * Q_inclusive_or = (buffer *) $3;
                                                                       $$ = (void *) combine_buffer(Q_logical_and , Q_inclusive_or , "&&");
                                                                //        display_buffer((buffer *)$$);
                                                                    }
        ;

INCLUSIVE_OR_EXPR 
        : EXCLUSIVE_OR_EXPR                                         {
                                                                        $$ = $1;
                                                                    }
        | INCLUSIVE_OR_EXPR BITOR EXCLUSIVE_OR_EXPR                 {   // combine exclusive or expressions using bit or
                                                                        buffer * Q_inclusive_or = (buffer *) $1;
                                                                        buffer * Q_exclusive_or = (buffer *) $3;
                                                                        $$ = (void *)combine_buffer(Q_inclusive_or , Q_exclusive_or , "|");
                                                                        // display_buffer((buffer *)$$);
                                                                    }
        ;

EXCLUSIVE_OR_EXPR
        : AND_EXPR                                                  {
                                                                        $$ = $1;
                                                                    }
        | EXCLUSIVE_OR_EXPR BITXOR AND_EXPR                         {   // combine and expresssions using bit xor operation
                                                                        buffer * Q_exclusive_or = (buffer *) $1;
                                                                        buffer * Q_and          = (buffer *) $3;
                                                                        $$ = (void *)combine_buffer(Q_exclusive_or , Q_and , "^");
                                                                        // display_buffer((buffer *) $$);
                                                                    }
        ;

AND_EXPR 
        : EQUALITY_EXPR                                            { 
                                                                       $$ = $1;
                                                                   }
        | AND_EXPR BITAND EQUALITY_EXPR                            {    // combine equality_expressions using bitand
                                                                        buffer * Q_and = (buffer *) $1;
                                                                        buffer * Q_equality = (buffer *) $3;
                                                                        $$ = (void *) combine_buffer(Q_and , Q_equality , "&");
                                                                        // display_buffer((buffer *) $$);
                                                                   }
        ;

EQUALITY_EXPR 
        : RELATIONAL_EXPR                                          {
                                                                        $$ = $1;
                                                                   }
        | EQUALITY_EXPR EQUAL RELATIONAL_EXPR                      {   // combine relational operations using equal
                                                                       buffer * Q_equality = (buffer *) $1;
                                                                       buffer * Q_relation = (buffer *) $3;
                                                                       $$ = (void *) combine_buffer(Q_equality , Q_relation , "==");
                                                                //        display_buffer((buffer *) $$); 
                                                                   }
        | EQUALITY_EXPR NOTEQUAL RELATIONAL_EXPR                   {  // combine relational operations using equal
                                                                       buffer * Q_equality = (buffer *) $1;
                                                                       buffer * Q_relation = (buffer *) $3;
                                                                       $$ = (void *) combine_buffer(Q_equality , Q_relation , "!=");
                                                                //        display_buffer((buffer *) $$); 
                                                                   }
        ;

RELATIONAL_EXPR 
        : ADDITION_EXPR                                            {
                                                                        $$ = $1;
                                                                   }
        | RELATIONAL_EXPR LESS ADDITION_EXPR                       {    // combine addition expressions using less
                                                                        buffer * Q_relation = (buffer *) $1;
                                                                        buffer * Q_addition = (buffer *) $3;
                                                                        $$ = (void *) combine_buffer(Q_relation , Q_addition , "<");
                                                                        // display_buffer((buffer *)$$);
                                                                   }
        | RELATIONAL_EXPR MORE ADDITION_EXPR                       {    // combine addition expressions using more
                                                                        buffer * Q_relation = (buffer *) $1;
                                                                        buffer * Q_addition = (buffer *) $3;
                                                                        $$ = (void *) combine_buffer(Q_relation , Q_addition , ">");
                                                                        // display_buffer((buffer *)$$);

                                                                   }
        | RELATIONAL_EXPR MOREEQUAL ADDITION_EXPR                  {    // combine addition expressions using more equals
                                                                        buffer * Q_relation = (buffer *) $1;
                                                                        buffer * Q_addition = (buffer *) $3;
                                                                        $$ = (void *) combine_buffer(Q_relation , Q_addition , ">=");
                                                                        // display_buffer((buffer *)$$);
                                                                   }
        | RELATIONAL_EXPR LESSEQUAL ADDITION_EXPR                  {
                                                                        // combine addition expressions using less equals
                                                                        buffer * Q_relation = (buffer *) $1;
                                                                        buffer * Q_addition = (buffer *) $3;
                                                                        $$ = (void *) combine_buffer(Q_relation , Q_addition , "<=");
                                                                        // display_buffer((buffer *)$$);
                                                                   }                  
        ;

ADDITION_EXPR 
        : MULTIPLICATION_EXPR                                      {
                                                                        $$ = $1;
                                                                   }
        | ADDITION_EXPR ADD MULTIPLICATION_EXPR                    {   // combine multiplication expressions using add
                                                                       buffer * Q_addition = (buffer *) $1;
                                                                       buffer * Q_multi = (buffer *) $3;
                                                                       $$ = (void *) combine_buffer(Q_addition , Q_multi , "+");
                                                                //        display_buffer((buffer *) $$);
                                                                   }
        | ADDITION_EXPR MINUS MULTIPLICATION_EXPR                  {   // combine multiplication expressions using minus
                                                                       buffer * Q_addition = (buffer *) $1;
                                                                       buffer * Q_multi =    (buffer *) $3;
                                                                       $$ = (void *) combine_buffer(Q_addition , Q_multi , "-");
                                                                //        display_buffer((buffer *) $$);
                                                                   }
        ;

MULTIPLICATION_EXPR
        : BASIC_EXPR                                               {
                                                                        $$ = $1;
                                                                   }
        | MULTIPLICATION_EXPR MUL BASIC_EXPR                       {
                                                                       // combine basic operation with multiplication operation
                                                                       buffer * Q_multi = (buffer *) $1;
                                                                       buffer * Q_basic = (buffer *) $3;
                                                                       $$ = (void *) combine_buffer(Q_multi , Q_basic , "*");
                                                                //        display_buffer((buffer *) $$);
                                                                   }
        | MULTIPLICATION_EXPR DIV BASIC_EXPR                       {
                                                                       // combine basic expr with division operation
                                                                       buffer * Q_multi = (buffer *) $1;
                                                                       buffer * Q_basic = (buffer *) $3;
                                                                       $$ = (void *) combine_buffer(Q_multi , Q_basic , "/");
                                                                //        display_buffer((buffer *) $$);
                                                                   }
        | MULTIPLICATION_EXPR MOD BASIC_EXPR                       {   
                                                                       // combine basic expr with modulo operation
                                                                       buffer * Q_multi = (buffer *) $1;
                                                                       buffer * Q_basic = (buffer *) $3;
                                                                       $$ = (void *) combine_buffer(Q_multi , Q_basic , "%");
                                                                //        display_buffer((buffer *) $$);
                                                                   }
        ;

BASIC_EXPR 
        : ID                                                       {
                                                                        char* intermediate_var = get_next_name();
                                                                        $$ = (void *)create_buffer("=" , $1 , NULL , $1 , "");
                                                                        // display_buffer((buffer *) $$);
                                                                   }                                                   
        | NUM                                                      {
                                                                        char* intermediate_var = get_next_name();
                                                                        $$ = (void *)create_buffer("=" , $1 , NULL , $1 , "");
                                                                        // display_buffer((buffer *) $$);
                                                                   }
        | LP EXP RP                                                {
                                                                        $$ = $2; // use code for expression
                                                                        // display_buffer((buffer *) $$); // may be redundant here
                                                                   }
        ;

// involves a marker 
IF_AND_SWICH_STATEMENTS
        : IF LP BOOLEAN_EXPR RP BODY ELSE_OR_ELSE_IF        
        | SWITCH LP EXP RP CLP CASE_STMTS CRP 
        ;

ELSE_OR_ELSE_IF
        :
        | ELSE BODY
        ;

CASE_STMTS
        :
        | CASE NUM COLON STMT_LIST CASE_STMTS
        | DEFAULT COLON STMT_LIST
        ;



BOOLEAN_EXPR
        : BOOLEAN_EXPR OR M BOOLEAN_EXPR{
               backpatch(((node*)$1)->falselist,((M*)$3)->instruction_number);
               node* n = (node*) malloc(sizeof(node));
               n->truelist = merge(((node*)$1)->truelist,((node*)$4)->truelist);
               n->falselist = ((node*)$4)->falselist;
               $$ = (void*)n;
        }
        | BOOLEAN_EXPR AND M BOOLEAN_EXPR{
                backpatch(((node*)$1)->truelist,((M*)$3)->instruction_number);
                node* n = (node*) malloc(sizeof(node));
                n->truelist = ((node*)$4)->truelist;
                n->falselist = merge(((node*)$1)->falselist,((node*)$4)->falselist);
                $$=(void*)n;
        }
        | NOT BOOLEAN_EXPR{
                node* n = (node*) malloc(sizeof(node));
                n->truelist = ((node*)$2)->falselist;
                n->falselist = ((node*)$2)->truelist;
                $$=(void*)n;
        }
        | LP BOOLEAN_EXPR RP{
                node* n = (node*) malloc(sizeof(node));
                n->truelist = ((node*)$2)->truelist;
                n->falselist = ((node*)$2)->falselist;
                $$=(void*)n;
        }
        | ADDITION_EXPR RELOP ADDITION_EXPR{
                node* n = (node*) malloc(sizeof(node));
                n->truelist = makelist(next_instr);
                n->falselist = makelist(next_instr + 1);
                char* str=(char*)malloc(sizeof(char)*MAX_CODE_LEN);
                str[0]='\0';
                strcat(str,((buffer*)$1)->code);
                strcat(str,((buffer*)$3)->code);

                strcat(str,"if ");
                strcat(str, ((buffer*)$1)->result);
                strcat(str, " ");
                strcat(str, $2);
                strcat(str, " ");
                strcat(str, ((buffer*)$3)->result);
                strcat(str, " goto _ \n");
                add_instruction(str);
                char* str2=(char*)malloc(sizeof(char)*MAX_CODE_LEN);
                str2[0]='\0';
                strcpy(str2,"goto _\n");
                add_instruction(str2);
                $$=(void*)n;
        }
        | TRUE{
                node* n = (node*) malloc(sizeof(node));
                n->truelist = makelist(next_instr);
                char* str=(char*)malloc(sizeof(char)*MAX_CODE_LEN);
                str[0]='\0';
                strcpy(str ," goto __\n");
                add_instruction(str);
                $$=(void*)n;
        }
        | FALSE{
                node* n = (node*) malloc(sizeof(node));
                n->falselist = makelist(next_instr);
                char* str=(char*)malloc(sizeof(char)*MAX_CODE_LEN);
                str[0]='\0';
                strcpy(str," goto __\n");
                add_instruction(str);
                $$=(void*)n;
        }
        ;
M       : %empty{
                M* m = (M*) malloc(sizeof(M));
                m->instruction_number = next_instr;
                $$=(void*)m;
        }
        ;
RELOP   
        : MORE    {
                char* str = (char* ) malloc(sizeof(char) * 4);
                str[0] = '\0';
                strcpy(str , ">");
                $$ = str;
        }   
        | LESS{
                char* str = (char* ) malloc(sizeof(char) * 4);
                str[0] = '\0';
                strcpy(str , "<");
                $$ = str;

        }       
        | EQUAL {
                char* str = (char* ) malloc(sizeof(char) * 4);
                str[0] = '\0';
                strcpy(str , "==");
                $$ = str;

        }     
        | NOTEQUAL{
                char* str = (char* ) malloc(sizeof(char) * 4);
                str[0] = '\0';
                strcpy(str , "!=");
                $$ = str;

        }   
        | LESSEQUAL{
                char* str = (char* ) malloc(sizeof(char) * 4);
                str[0] = '\0';
                strcpy(str , "<=");
                $$ = str;

        }  
        | MOREEQUAL{
                char* str = (char* ) malloc(sizeof(char) * 4);
                str[0] = '\0';
                strcpy(str , ">=");
                $$ = str;
        }  
        ;
%%


                // functions 
int main(void){
    //yydebug = 1;
    return yyparse();
}

void yyerror(const char *s){
    fprintf(stderr, "ERROR: %s\n", s);
    exit(1);
}

/*custom string copy function*/
void 
string_copy(char *dest , char* src){
        if(src == NULL) return; // don't modify dest in case of null
        char *temp_dest = dest;
        char *temp_src  = src;
        do{
                *temp_dest = *temp_src , temp_src++ , temp_dest++;
        } while(*temp_src != '\0');
        assert(*temp_src == '\0'); 

}

          /* operations on buffer struct */
/* create a new buffer and return it's reference */
buffer* 
create_buffer(char *oper , char *arg1 , char *arg2 , char* result , char* code){
        buffer* Q    = (buffer*) malloc(sizeof(buffer));
        Q->operation = (char*) malloc(MAX_ARG_LEN);
        Q->argument1 = (char*) malloc(MAX_ARG_LEN);
        Q->argument2 = (char*) malloc(MAX_ARG_LEN);
        Q->result    = (char*) malloc(MAX_ARG_LEN);
        Q->code      = (char*) malloc(MAX_CODE_LEN); 
     
        

        // Q->operation = oper;
        // Q->argument1 = arg1;
        // Q->argument2 = arg2;
        // Q->result    = result;
        // Q->code      = (char*) malloc(MAX_CODE_LEN); 
     
     
        string_copy(Q->operation , oper);
        string_copy(Q->argument1 , arg1);
        string_copy(Q->argument2 , arg2);
        string_copy(Q->result  , result);
        string_copy(Q->code , code);
        assert(Q != NULL);
        return Q;
}

/* display the intermediate code from the buffer format */
void
display_buffer(buffer* Q){
        assert(Q != NULL);
        assert(Q->operation != NULL);
        char *assign = "=";
        if(strcmp(Q->operation , assign) == 0){
                assert(Q->result != NULL);
                assert(Q->argument1 != NULL);
                printf("%s = %s\n", Q->result , Q->argument1);
        } else{
                assert(Q->argument1 != NULL);
                assert(Q->argument2 != NULL);
                assert(Q->operation != NULL);
                assert(Q->result    != NULL);
                printf("%s = %s %s %s\n", Q->result , Q->argument1 , Q->operation , Q->argument2);
        }
}
/*  combine two buffers to obtain a new buffer */
buffer*
combine_buffer(buffer *Q1 , buffer *Q2 , char *operation){
        char * result_variable = get_next_name();
        char * concatenated_code = (char *) malloc(sizeof(char) * MAX_CODE_LEN);
        concatenated_code[0] = '\0';
        if(Q1->code) strcat(concatenated_code , Q1->code);
        if(Q2->code) strcat(concatenated_code , Q2->code);
        strcat(concatenated_code , result_variable);
        strcat(concatenated_code , " = ");
        strcat(concatenated_code , Q1->result);
        strcat(concatenated_code , " ");
        strcat(concatenated_code , operation);
        strcat(concatenated_code , " ");
        strcat(concatenated_code , Q2->result);
        strcat(concatenated_code , "\n");
        buffer * combination = create_buffer(
                operation ,
                Q1->result,              
                Q2->result,
                result_variable,
                concatenated_code
        );
        return combination;
}

void print_code(buffer * buff){
        assert(buff != NULL);
        printf("code:\n");
        printf("%s" , buff->code); 
}
/* returns the next intermediate variable name to be used */
char* 
get_next_name(){
        assert(name_ptr < INTERMEDIATE_VARIABLES_MAX_COUNT);
        char * next_name = names[name_ptr];
        ++name_ptr;
        if(name_ptr >= INTERMEDIATE_VARIABLES_MAX_COUNT) name_ptr = 0;
        return next_name;
}


void symbol_table_append(int scope, int type, char * name) {
        symbol_table_entry * entry_ptr = (symbol_table_entry *)malloc(sizeof(symbol_table_entry));
        entry_ptr->scope = scope;
        entry_ptr->type = type;
        entry_ptr->name = name;

        if(symbol_table_top >= MAX_SYMBOL_TABLE_SIZE) yyerror("MAX_SYMBOL_TABLE_SIZE limit exceeded.");
        else {
            symbol_table[symbol_table_top] = entry_ptr;
            symbol_table_top++;
            return;
        }
}

bool symbol_table_lookup(char * name) {
        for(int i = 0 ; i < symbol_table_top ; i++) {
            if(strcmp(symbol_table[i]->name, name) == 0) return true;
        }
        return false;
}

void print_symbol_table() {
        printf("symbol_table (stack top to bottom) : ");
        for(int i = symbol_table_top-1 ; i >= 0 ; i--) {
            printf("(%d, %s, %s), ", symbol_table[i]->scope, type_names[symbol_table[i]->type], symbol_table[i]->name);
        }
        printf("\n");
        return;
}


void var_declaration_list_append(var_declaration_list * list_ptr, char * name, int type) {
        if(list_ptr->index >= MAX_DECLARATIONS_PER_STATEMENT) yyerror("MAX_DECLARATIONS_PER_STATEMENT limit exceeded.");
        else {
            int name_len = strlen(name);
            // printf("appending id %s at index %d\n", name, list_ptr->index);
            char * new_name = malloc(name_len+1);
            strcpy(new_name, name);
            list_ptr->names[list_ptr->index] = new_name;
            list_ptr->assigned_types[list_ptr->index] = type;
            list_ptr->index++;
            return;
        }
}

void var_declaration_list_union(var_declaration_list * dest_ptr, var_declaration_list * src_ptr) {
        // Append all elements of src_ptr into dest_ptr
        // printf("unioning\n");
        for(int i = 0 ; i < src_ptr->index ; i++) {
            var_declaration_list_append(dest_ptr, src_ptr->names[i], src_ptr->assigned_types[i]);
        }
        return;
}

void print_var_declaration_list(var_declaration_list * list_ptr) {
        printf("var_declaration_list: ");
        
        if(list_ptr == NULL) {
            printf("NULL\n");
            return;
        }
        else {
            printf("index = %d, names = ", list_ptr->index);
            for(int i = 0 ; i < list_ptr->index ; i++) {
                assert(i < MAX_DECLARATIONS_PER_STATEMENT);
                assert(list_ptr->names[i] != NULL);

                printf("(%s, %s)", list_ptr->names[i], list_ptr->assigned_types[i] == -1 ? "uninitialized" : type_names[list_ptr->assigned_types[i]]);
            }
            printf("\n");
        }
}
