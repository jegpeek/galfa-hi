
DEPTH           = ../..
include ${DEPTH}/make/common.mk

CC              = ${TARGET_GCC} 
INC             = -I${TARGET_DIR}/include
LIB             = -L${TARGET_DIR}/lib -lz -lpci
OBJ             = pixmap.o main.o

all:		g 

g:		${OBJ}
		${CC} ${OBJ} -o g ${LIB}
		${TARGET_STRIP} g

clean:  
		rm -rf *.o  g
