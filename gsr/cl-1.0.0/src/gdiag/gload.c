
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

#include <time.h>

#define BUFSZ   (4*(1<<20))

enum {
    opti_load,
    opti_wink,
    opti_reset,
    opti_mtest,
    opti_beam
};

static struct option lopts[] = {
    { "load",         0, 0, opti_load },
    { "wink",         0, 0, opti_wink },
    { "reset",        0, 0, opti_reset },
    { "mtest",        0, 0, opti_mtest },
    { "beam",         1, 0, opti_beam },
    { NULL,           0, 0, 0 },
};

void
usage(char *prog) 
{
    printf("\nUsage: %s [options]\n", prog);
    printf("        [--load]    Load FPGAs with bitstream from stdin\n");
    printf("        [--wink]    Twinkle LEDs to identify boards\n");
    printf("        [--reset]   Force reset to FPGAs\n");
    printf("        [--mtest]   Test PCI memory aperature\n");
    printf("        [--beam=n]  Blink LED on beam n\n");
    
    printf("\n");
}

void
pfb_reset(Ab *ab)
{
    // reset PFB
    //
    ab->ctl[0] = 0x20;
    usleep(10000);
    ab->ctl[0] = 0x00;
    usleep(10000);
}

void
beam(Ab **ab, int i)
{
    if (ab[i]) {
        printf("Beam %d\n", i);
        while (1) {
            ab[i]->ctl[0] = ab[i]->ctl[0] & ~0x1;
            usleep(100000);
            ab[i]->ctl[0] = ab[i]->ctl[0] | 0x1;
            usleep(100000);
        }
    } else 
        printf("Beam %d doesn't exist.\n", i);
    exit(0);
}

void
wink(Ab **ab)
{
    int             i, j;

    // First turn off the LEDs
    for(i=0; i<G_BEAMS; i++) 
        if (ab[i])
            ab[i]->ctl[0] = ab[i]->ctl[0] | 0x3;

    for(i=0; i<G_BEAMS; i++) 
        if (ab[i]) {
            printf("Beam %d\n", i);
            for(j=0; j<10; j++) {
                ab[i]->ctl[0] = ab[i]->ctl[0] & ~0x1;
                AbGkRegOne(ab, i, Gk_led3, 1);
                usleep(100000);
                ab[i]->ctl[0] = ab[i]->ctl[0] | 0x1;
                AbGkRegOne(ab, i, Gk_led3, 0);
                usleep(100000);
            }
        }
}

int 
doload(Ab **ab)
{
    u_char          *buf;
    int             sz, szt;
    int             err;
    int             i;

    if (!ab[0]) {
        fprintf(stderr, "No boards to program.\n");
        return 1;
    }

    buf = (u_char *) malloc(BUFSZ);
    if (!buf) {
        fprintf(stderr, "Malloc failed in xload.\n");
        exit(1);
    }

    sz = 0;
    while (sz<BUFSZ && (szt = read(fileno(stdin), buf+sz, BUFSZ-sz))) {
        if (szt < 0) {
            fprintf(stderr, "Error reading file in xload\n");
            exit(1);
        }
        sz += szt;
    }
    if (sz == BUFSZ) {
        fprintf(stderr, "Buffer is too small: %d\n", BUFSZ);
        exit(1);
    }
    printf("Got %d configuration bits\n", sz*8);

    err = 0;
    for(i=0; i<G_BEAMS; i++) {
        if (ab[i]) {
            err |= AbLoad(ab[i], 0, buf, sz);
            pfb_reset(ab[i]);
        }
    }

    free(buf);
    return err;
}

//  Test virtex-2 blockrams mapped into the PCI address space.
//  
void
mbus_memtest(Ab **ab)
{
    int             i;
    int             beam;
    int             pass;
    int             seed;
    int             v, rv;
    int             len;

    len = ab[0]->mbus_len/4;
    printf("Testing %d byte PCI aperature.\n", len*4);
    for(pass=1; pass<=100000; pass++) {
        for(beam=0; beam<G_BEAMS; beam++) {
            if (!ab[beam])
                continue;
            for(i=0; i<len; i++) {
                ab[beam]->mbus[i] = 0;
            }
            for(i=0; i<len; i++) {
                rv = ab[beam]->mbus[i];
                if (0 != rv) {
                    fprintf(stderr, "Zero: pass:%d inx:%d r:%08x\n",
                            pass, i, rv);
                }
            }

            seed = time(0);
            srand(seed);
            for(i=0; i<len; i++) {
                v = rand();
                ab[beam]->mbus[i] = v;
            }
            srand(seed);
            for(i=0; i<len; i++) {
                rv = ab[beam]->mbus[i];
                v = rand();
                if (v != rv) {
                    fprintf(stderr, "Err1: pass:%d inx:%d w:%08x r:%08x\n",
                            pass, i, v, rv);
                }
            }
            srand(seed);
            for(i=0; i<len; i++) {
                rv = ab[beam]->mbus[i];
                v = rand();
                if (v != rv) {
                    fprintf(stderr, "Err2: pass:%d inx:%d w:%08x r:%08x\n",
                            pass, i, v, rv);
                }
            }
            if ((pass%10) == 0)
                printf("Pass %d complete, beam %d.\n", pass, beam);
        }
    }
}

int
main(int ac, char **av)
{
    Ab              **ab;
    int             c;
    int             i;
    int             n;

    ab = AbOpen();
    if (!ab[0]) {
        fprintf(stderr, "No boards found...\n");
        exit(1);
    }

    while ((c=getopt_long_only(ac, av, "", lopts, NULL)) != -1) {
        switch (c) {
            case opti_load:     
                exit(doload(ab));
            case opti_wink:     
                wink(ab);
                exit(0);
            case opti_beam:     
                n = strtol(optarg, NULL, 0);
                beam(ab, n);
                exit(0);
            case opti_reset:    
                for(i=0; i<G_BEAMS; i++)
                    if (ab[i])
                        pfb_reset(ab[i]);
                exit(0);
            case opti_mtest:
                mbus_memtest(ab);
                exit(0);
        }
    }
    usage(av[0]);
    exit(1);
}
