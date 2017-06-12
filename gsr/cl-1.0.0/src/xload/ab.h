
#ifndef __AB__
#define __AB__

#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>
#include <pci.h>

#define AB_DEVMEM       "/dev/mem"
#define AB_CURRENT_REV  0x05            // PCI revision byte for 2v1000

typedef unsigned char uchar;

typedef struct AbStruct Ab;
struct AbStruct {
    struct pci_dev              pci;
    volatile unsigned long      *ctl;
    volatile unsigned long      *mbus;
    unsigned long               ctl_len;
    unsigned long               mbus_len;
    Ab                          *next;
};

Ab          *AbOpen(void);
int         AbLoad(Ab *ab, int skip, unsigned char *buf, int sz);
void        AbPrint(Ab *ab);

#endif

