
#include "ab.h"
#include "pixmap.h"
#include <math.h>
#include <fftw3.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <getopt.h>

#include "galfa_sock/galfa_sock.h"
#include "galfa.h"

int
io_open(Ab **ab)
{
    int     r=0;

    if (opt_sock)
        gsock_open(ab);
    if (!opt_nofits)
        r = gfits_open(ab);
    return r;
}

int
io_write(Ab **ab, galfa_pkt **g, struct timeval *tv)
{
    int     r=0;

    if (opt_sock)
        gsock_write(ab, g, tv);
    if (!opt_nofits)
        r = gfits_write(ab, g, tv);
    return r;
}

int
io_close(void)
{
    int     r=0;

    printf("I/O close...\n");
    if (opt_sock)
        gsock_close();
    if (!opt_nofits)
        r = gfits_close();
    return r;
}
