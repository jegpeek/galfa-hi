
TARGET_PREFIX       = i386-linux-uclibc-

TARGET_GCC          = ${TARGET_PREFIX}gcc
TARGET_AS           = ${TARGET_PREFIX}as
TARGET_LD           = ${TARGET_PREFIX}ld
TARGET_STRIP        = ${TARGET_PREFIX}strip
TARGET_AR           = ${TARGET_PREFIX}ar
TARGET_NM           = ${TARGET_PREFIX}nm
TARGET_OBJCOPY      = ${TARGET_PREFIX}objcopy
TARGET_OBJDUMP      = ${TARGET_PREFIX}objdump
TARGET_RANLIB       = ${TARGET_PREFIX}ranlib
TARGET_SIZE         = ${TARGET_PREFIX}size
TARGET_LDD          = ${TARGET_PREFIX}ldd

TARGET_DIR          := $(shell cd $(DEPTH); pwd)/root

HOST_DIR            = /usr/local/uclibc

TARGET_HOST         = i386-linux
MAD_ARCH            = intel
LINUX_ARCH          = i386

# for multiprocessor builds
JF                  = -j3

DL                  = ${DEPTH}/dl
WGET                = wget
