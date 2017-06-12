
VERSION         = 1.0.0
TMP             = /usr/tmp
CL              = cl-${VERSION}
TMPCL           = ${TMP}/cl-${VERSION}

all:
		mkdir -p bin
		${MAKE} -C packages dl
		${MAKE} -C packages
		${MAKE} -C src/xload
		${MAKE} -C src/gdiag
		${MAKE} -C image

clean:
		rm -rf root bin
		${MAKE} -C packages clean
		${MAKE} -C src/xload clean
		${MAKE} -C src/gdiag clean
		${MAKE} -C image clean

release:		
		${MAKE} clean
		rm -rf ../cl-${VERSION}.tar.gz
		rm -rf ${TMPCL}
		mkdir ${TMPCL}
		tar cf - --exclude CVS --exclude dl . | (cd ${TMPCL} ; tar xvf - )
		rm -rf ${TMPCL}/dl
		mkdir ${TMPCL}/dl
		(cd ${TMP} ; tar zcvf ${CL}.tar.gz ${CL} )
		cp ${TMPCL}.tar.gz ..
		rm -rf ${TMPCL}.tar.gz ${TMPCL}
		
