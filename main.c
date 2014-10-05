#include <iostream>

extern int yyparse();

int main(int argc, char **argv)
{
    yyparse();
    puts("Parsing completed.\n");
    return 0;
}
