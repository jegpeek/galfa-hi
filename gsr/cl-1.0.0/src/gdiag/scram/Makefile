

DEPTH           = ../../..
include ${DEPTH}/make/common.mk

CC              = ${TARGET_GCC} 

CFLAGS          = -I. -Iphil -Iaoui
OBJ	            = gscram.o scram.o flip.o swapdata.o

all:		gscram.a stest 

gscram.a:	    ${OBJ} gscram.h Makefile
		${TARGET_AR} rc gscram.a ${OBJ}
		${TARGET_RANLIB} gscram.a

stest:	${OBJ} stest.o
	${CC} ${CFLAGS} stest.o ${OBJ} -lpthread -o stest

clean:
	rm -rf *.o stest gscram.a
