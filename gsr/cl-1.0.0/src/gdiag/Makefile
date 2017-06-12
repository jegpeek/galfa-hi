
DEPTH           = ../..
include ${DEPTH}/make/common.mk

CC              = ${TARGET_GCC} 
INC             = -I${TARGET_DIR}/include -I${TARGET_DIR}/include/freetype2
LIBX            = -L${TARGET_DIR}/lib -lpci 
LIB             = ${LIBX} -lfftw3 -lm -lfreetype -lvncserver -lz -lpthread \
		  -ljpeg -lcfitsio 
SCRAM           = scram/gscram.a
OBJ             = ab.o pixmap.o util.o gscope.o gfits.o levels.o io.o \
                  gsock.o socklib.o lo2.o ${SCRAM}

all:		gdiag gload set_dac ${SCRAM}
		mkdir -p ${TARGET_DIR}/fpga
		cp *.gz ${TARGET_DIR}/fpga
		cp set_dac ${TARGET_DIR}/bin
		cp gdiag ${TARGET_DIR}/bin
		cp gload ${TARGET_DIR}/bin
		cp mailboxdefs alfalogo.jpg ${TARGET_DIR}/etc

${SCRAM}:	
		${MAKE} -C scram

set_dac:        set_dac.c
		${CC} set_dac.c -o set_dac
		${TARGET_STRIP} set_dac

gdiag:		${OBJ} main.o
		${CC} main.o ${OBJ} -o gdiag ${LIB}
		${TARGET_STRIP} gdiag

main.o:		main.c ab.h
		${CC} -Wall -O2 ${INC} main.c -c

levels.o:	levels.c 
		${CC} -Wall -O2 ${INC} levels.c -c

gscope.o:	gscope.c 
		${CC} -Wall -O2 ${INC} gscope.c -c

gfits.o:	gfits.c 
		${CC} -Wall -O2 ${INC} gfits.c -c

util.o:		util.c 
		${CC} -Wall -O2 ${INC} util.c -c

ab.o:		ab.c ab.h
		${CC} -Wall -O2 ${INC} ab.c -c

io.o:		io.c 
		${CC} -Wall -O2 ${INC} io.c -c

lo2.o:		lo2.c 
		${CC} -O2 ${INC} lo2.c -c

gsock.o:	gsock.c 
		${CC} -Wall -O2 ${INC} gsock.c -c

socklib.o:	socklib.c 
		${CC} -O2 ${INC} socklib.c -c

pixmap.o:	pixmap.c pixmap.h
		${CC} -Wall -O2 ${INC} pixmap.c -c

gload:		gload.o
		${CC} gload.o ab.o -o gload ${LIBX}
		${TARGET_STRIP} gload

gload.o:	gload.c
		${CC} -Wall -O2 ${INC} gload.c -c

clean:  
		rm -rf *.o  gdiag gload ft set_dac
		${MAKE} -C galfa_sock clean
		${MAKE} -C scram clean

