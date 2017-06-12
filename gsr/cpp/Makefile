# This Makefile should compile all necessary C++ code needed to run the IDL
# routine SDGRID.PRO.
# It has been tested on the following architectures:

#================
# DARWIN...
#================
# Berkeley:
# Darwin Cybertron.local 8.6.0 Darwin Kernel Version 8.6.0: Tue Mar  7 16:58:48 PST 2006; root:xnu-792.6.70.obj~1/RELEASE_PPC Power Macintosh powerpc

#================
# SOLARIS...
#================
# Berkeley:
# SunOS saturn 5.7 Generic_106541-40 sun4u sparc SUNW,Ultra-5_10
# SunOS garavito 5.7 Generic_106541-40 sun4u sparc SUNW,Ultra-5_10
# SunOS fornax 5.7 Generic_106541-40 sun4u sparc SUNW,Ultra-5_10
# SunOS pavo 5.7 Generic_106541-40 sun4u sparc SUNW,Ultra-5_10
# SunOS saturn 5.7 Generic_106541-40 sun4u sparc SUNW,Ultra-5_10
# SunOS slothrop 5.7 Generic_106541-40 sun4u sparc SUNW,Ultra-5_10
# SunOS brando 5.8 Generic_117350-26 sun4u sparc SUNW,Ultra-30
# SunOS meso 5.8 Generic_117350-26 sun4u sparc SUNW,Ultra-Enterprise

# TOOK A BIG DUMP...
# Arecibo:
# SunOS remote 5.7 Generic_106541-18 sun4u sparc SUNW,Ultra-1
# ld.so.1: gmake: fatal: libkvm.so.0.3: open failed: No such file or directory
# SunOS e420r 5.8 Generic sun4u sparc SUNW,Ultra-80
# ld.so.1: gmake: fatal: libkvm.so.0.3: open failed: No such file or directory

#================
# GNU/LINUX...
#================
# Berkeley:
# Linux aster 2.6.13-15.10-default #1 Fri May 12 16:13:03 UTC 2006 x86_64 x86_64 x86_64 GNU/Linux
# Linux vermi 2.4.21-260-default #1 Wed Nov 17 20:02:31 UTC 2004 x86_64 x86_64 x86_64 GNU/Linux
# Linux carcosa 2.6.11.4-21.9-smp #1 SMP Fri Aug 19 11:58:59 UTC 2005 x86_64 x86_64 x86_64 GNU/Linux
# Linux creek 2.4.21-291-default #1 Tue May 24 10:53:23 UTC 2005 x86_64 x86_64 x86_64 GNU/Linux
# Linux harpo 2.6.13-15.8-smp #1 SMP Tue Feb 7 11:07:24 UTC 2006 x86_64 x86_64 x86_64 GNU/Linux
# Linux gaol 2.4.21-202-athlon #1 Fri Apr 2 21:22:14 UTC 2004 i686 athlon i386 GNU/Linux
# Linux chandra 2.6.13-15.7-bigsmp #1 SMP Tue Nov 29 14:32:29 UTC 2005 i686 i686 i386 GNU/Linux
# Linux fenway 2.6.15 #1 PREEMPT Tue Feb 14 12:46:31 PST 2006 i686 GNU/Linux

# Arecibo:
# Linux mofongo.naic.edu 2.4.20-8smp #1 SMP Thu Mar 13 17:45:54 EST 2003 i686 i686 i386 GNU/Linux
# Linux aolc1 2.4.21-4.ELsmp #1 SMP Fri Oct 3 17:52:56 EDT 2003 i686 i686 i386 GNU/Linux
# Linux mango 2.4.21-231-default #1 Mon Jun 28 15:39:34 UTC 2004 i686 i686 i386 GNU/Linux


# TOOK A BIG CRAP....
#
# Berkeley:
# Linux master 2.4.18 #17 SMP Fri Dec 20 08:39:19 PST 2002 i686 athlon i386 GNU/Linux
#
# Green Bank:
# Linux prospero 2.6.9-34.0.1.ELsmp #1 SMP Wed May 17 17:05:24 EDT 2006 i686 i686 i386 GNU/Linux
# Linux euclid 2.6.9-34.0.1.ELsmp #1 SMP Wed May 17 17:05:24 EDT 2006 i686 i686 i386 GNU/Linux
# Linux euler 2.6.9-34.0.1.ELsmp #1 SMP Wed May 17 17:05:24 EDT 2006 i686 i686 i386 GNU/Linux
# Linux despina 2.6.9-34.0.1.ELsmp #1 SMP Wed May 17 17:05:24 EDT 2006 i686 i686 i386 GNU/Linux
# Linux naiad 2.6.9-34.0.1.ELsmp #1 SMP Wed May 17 17:05:24 EDT 2006 i686 i686 i386 GNU/Linux
# SunOS pollux 5.8 Generic_117350-37 sun4u sparc SUNW,Ultra-5_10
# SunOS titan 5.8 Generic_117350-37 sun4u sparc SUNW,Ultra-5_10
#
# "parse error" = one of the 4 most common gcc error messages
#
# g++ -c -o nist_spblas.o nist_spblas.cc
# nist_spblas.cc:1107: parse error before `reinterpret_cast'
# nist_spblas.cc: In function `void BLAS_zusdot(blas_conj_type, int, const void *, const int *, const void *, int, void *, blas_base_type)':

#================
# WINDOWS...
#================
# Yeah, right.

# Robishaw 8/3/2006

#!!!!!!!!!!!!!!!
# IDL VERSIONS <= 5.5 USE A DIFFERENT FILE IN $(IDL_DIR)/external/
# idl_export.h
# (a) Will the SDGRID even work with <= 5.5; what are the version dependencies?
# (b) Do we even care?

#!!!!!!!!!!!!!!!
# WE NEED TO CHECK TO SEE IF $(IDL_DIR) IS EVEN SET...

CC = gcc
CXX = c++
#LD = ld
LD = g++
CPPFLAGS += -I$(IDL_DIR)/external/include
##CFLAGS = -O5 -fPIC
CFLAGS = -O3 -fPIC
CXXFLAGS = $(CFLAGS)
LDFLAGS += nist_spblas.o

# shared/dynamic library targets (semi-portable)
normal_targs = nist_spblas.o smm.so smmd.so
ifeq ($(OSTYPE),darwin)
        targs = $(normal_targs:.so=.dylib)
else
        targs = $(normal_targs)
endif


all:	$(targs)

nist_spblas.o:	nist_spblas.cc
	${CXX} -c -o nist_spblas.o $< ${CXXFLAGS}

%.so:	%.o
	${LD} -shared -o $@ $< ${LDFLAGS}

%.dylib:	%.o
	${LD} -dynamiclib -install_name $@ -o $@ $< ${LDFLAGS}

clean:  
	-rm -f $(normal_targs)
