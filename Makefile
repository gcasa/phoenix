phoenix: parser.o tokens.o main.o
	gcc -o swift main.o tokens.o parser.o


parser.c: parser.y
	bison -d -o parser.c parser.y

tokens.c: tokens.l
	flex -o tokens.c tokens.l

parser.o: parser.c
	gcc -c parser.c -o parser.o

tokens.o: tokens.c
	gcc -c tokens.c -o tokens.o

main.o: main.c
	gcc -c main.o main.c

