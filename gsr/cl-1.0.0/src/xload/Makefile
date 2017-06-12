
DEPTH           = ../..
include ${DEPTH}/make/common.mk

CC              = ${TARGET_GCC} 
INC             = -I${TARGET_DIR}/include -I${TARGET_DIR}/include/freetype2
LIB             = -L${TARGET_DIR}/lib -lpci -lfftw3 -lm -lfreetype -lvncserver -lz -lpthread -ljpeg
OBJ             = main.o ab.o pixmap.o

all:		xload 
		mkdir -p ${TARGET_DIR}/fpga
		cp *.gz ${TARGET_DIR}/fpga
		cp *.mcs ${TARGET_DIR}/fpga
		cp xload ${TARGET_DIR}/bin
		cp updatex ${TARGET_DIR}/bin

xload:		${OBJ}
		${CC} ${OBJ} -o xload ${LIB}
		${TARGET_STRIP} xload

ft:		ft.o ab.o pixmap.o
		${CC} ${OBJ} -o ft ${LIB}
		${TARGET_STRIP} ft

ft.o:		ft.c ab.h
		${CC} -Wall -O2 ${INC} ft.c -c

main.o:		main.c ab.h
		${CC} -Wall -O2 ${INC} main.c -c

ab.o:		ab.c ab.h
		${CC} -Wall -O2 ${INC} ab.c -c

pixmap.o:	pixmap.c pixmap.h
		${CC} -Wall -O2 ${INC} pixmap.c -c

example:	example.c
		${CC} ${INC} example.c ${LIB} -o example
clean:  
		rm -rf *.o  xload ft

