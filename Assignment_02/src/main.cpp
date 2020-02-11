#include<stdio.h>
#include<bits/stdc++.h>

using namespace std;

#include "code_gen.h"
#include "lex.h"
int main(int argc, char const *argv[])
{
	// deleting previous contents of the file
	// printf("%d\n",argc);
	int res = 1;
	if(argc > 1) {
		res = strcmp(argv[1],"code_gen");
		// printf("%d\n",res);
	}
	if(argc > 1 && res==0){
		printf("Intermediate code : \n\n");
		prog();
		
	}
	else {
		printf("Please check lex_output.txt for output\n\n");
		FILE *fptr;
		fptr=fopen("lex_output.txt", "w");
		fclose(fptr);

		fptr=fopen("token_stream.txt", "w");
		fclose(fptr);

		fptr=fopen("symbol_table.txt", "w");
		fclose(fptr);
		perform_lexical_analysis();

	}
	return 0;
}