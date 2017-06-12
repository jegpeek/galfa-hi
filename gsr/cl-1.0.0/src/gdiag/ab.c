
#include "ab.h"
#include "pixmap.h"
#include <math.h>
#include <fftw3.h>
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <getopt.h>

#include "galfa_sock/galfa_sock.h"
#include "galfa.h"


// #define ONE_HACK

void
AbGkReg(Ab **ab, int reg, int val)
{
    int                     i;

    for(i=0; i<G_BEAMS; i++)
        AbGkRegOne(ab, i, reg, val);
}

void
AbGkRegOne(Ab **ab, int beam, int reg, int val)
{
    int                     i;

    if (ab[beam]) {
        ab[beam]->ctl[5] = ((reg&0xf)<<16) | (val&0xffff);

        // Make sure registers are really writtten
        i = ab[0]->ctl[0];
        i = ab[0]->ctl[0];
        i = ab[0]->ctl[0];
    }
}

Ab **
AbOpen(void)
{
    Ab                      *ablist = NULL;
    Ab                      **ab;
    Ab                      *atmp;

    struct pci_access       *pacc;
    struct pci_dev          *p;
    int                     fd;
    u_char                  rev;
    int                     cnt = 0;
    int                     i;

    pacc = (struct pci_access *) pci_alloc();
    pci_init(pacc);
    pci_scan_bus(pacc);

    fd = open(AB_DEVMEM, O_RDWR);
    if (fd < 0) {
        fprintf(stderr, "Cannot open %s for read/write.\n", AB_DEVMEM);
        return NULL;
    }
    for(p=pacc->devices; p; p=p->next) {
        if (p->vendor_id == 0x10ee && p->device_id == 0x0300) {
            fprintf(stderr, "Board in slot %02x:%02x.%d might have really old xc2v1000 code, ignoring...\n",
                p->bus, p->dev, p->func);
        } 
        if (p->vendor_id == 0x10ee && p->device_id == 0x0333) {
            rev = pci_read_byte(p, PCI_REVISION_ID);
            if (rev < AB_CURRENT_REV) {
                printf("\nRevision ID in slot %02x:%02x.%d is %02x\n", 
                    p->bus, p->dev, p->func, rev);
                printf("This is older than %02x, the required revision\n",
                    AB_CURRENT_REV);
                printf("required for the xc2v1000.  Manually upgrade the\n");
                printf("PROM with the code in /fpga/pcib_r.mcs.\n\n");
            }

            atmp = (Ab *) malloc(sizeof(Ab));
            if (!atmp) {
                fprintf(stderr, "malloc() failed in AbOpen()\n");
                exit(1);
            }
            atmp->next = ablist;
            ablist = atmp;
            atmp->pci = *p;
            atmp->ctl_len = p->size[0];
            atmp->ctl = mmap(NULL, atmp->ctl_len, PROT_READ | PROT_WRITE, 
                    MAP_SHARED, fd, (off_t) (p->base_addr[0]));
            if ((long)(atmp->ctl) == -1) {
                fprintf(stderr,  "mmap() BAR0 xilinx failed.\n");
                exit(1);
            }
            atmp->mbus_len = p->size[1];
            atmp->mbus = mmap(NULL, atmp->mbus_len, PROT_READ | PROT_WRITE, 
                    MAP_SHARED, fd, (off_t) (p->base_addr[1]));
            if ((long)(atmp->mbus) == -1) {
                fprintf(stderr,  "mmap() BAR1 xilinx failed.\n");
                exit(1);
            }
            cnt++;
        }
    }

    pci_cleanup(pacc);
    close(fd);

    ab = (Ab **) calloc(G_BEAMS, sizeof(Ab *));
    for(i=0; ablist; i++) {
        ab[i] = ablist;
        ablist = ablist->next;
    }
#ifdef ONE_HACK
    if (cnt == 1) {
        printf("Just one board, pointing all beams at the one board.\n");
        for(i=1; i<G_BEAMS; i++)
            ab[i] = ab[0];
    }
#endif
    return ab;
}

void
AbClose(Ab *ab)
{
    Ab      *abn;

    while (ab) {
        munmap((void *) ab->ctl, ab->ctl_len);
        munmap((void *) ab->mbus, ab->mbus_len);
        abn = ab->next;
        free(ab);
        ab = abn;
    }
}

void
AbPrint(Ab **ab)
{
    int                 i;

    for(i=0; i<G_BEAMS; i++)
        if (ab[i])
            printf("    Position: %02x:%02x.%d ctl:%08x mbus:%08x\n",
                ab[i]->pci.bus, ab[i]->pci.dev, ab[i]->pci.func,
                (u_int) ab[i]->ctl, (u_int) ab[i]->mbus);
}

int
AbLoad(Ab *ab, int skip, unsigned char *buf, int sz) 
{
    register long           i, v;

    if (skip && (ab->ctl[2] & 2)) {
        printf("FPGA in %02x:%02x.%d already configured properly, skipping\n", 
            ab->pci.bus, ab->pci.dev, ab->pci.func);
        return 0;
    }
        
    // twiddle prog_b
    ab->ctl[1] = 0;
    usleep(10000);
    ab->ctl[1] = 1;
    usleep(10000);

    for(i=0; i<sz; i+=4) {
        v = (buf[i]<<24) | (buf[i+1]<<16) | (buf[i+2]<<8) | buf[i+3];
        while (ab->ctl[2] & 0x01)
            ;
        ab->ctl[3] = v;
    }
    for(i=0; i<4; i++) {
        while (ab->ctl[2] & 0x01)
            ;
        ab->ctl[3] = 0;
    }

    usleep(100000);
    if (ab->ctl[2] & 2) {
        printf("FPGA in %02x:%02x.%d configured properly\n", ab->pci.bus,
                ab->pci.dev, ab->pci.func);
        return 0;
    } else {
        printf("FPGA in %02x:%02x.%d not configured properly\n", ab->pci.bus,
                ab->pci.dev, ab->pci.func);
        return 1;
    }
}





