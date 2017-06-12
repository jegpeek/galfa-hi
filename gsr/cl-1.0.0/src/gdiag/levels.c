

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

#include <termios.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <sys/io.h>

static void setdac (int fd, int dac, int level);

u_char g_dac[14];
u_long g_rms[14];

static void 
get_levels(Ab *ab, double *mean, double *rms, double *pow)
{
    int     a, n;

    s_char  *a0, *a1, *a2, *a3;
    double  sum0, sum1, sum2, sum3;
    double  ssq0, ssq1, ssq2, ssq3;
    int     slen = ab->mbus_len/4;
    double  tot;

    sum0 = sum1 = sum2 = sum3 = 0.0;
    ssq0 = ssq1 = ssq2 = ssq3 = 0.0;
    for(a=0; a<opt_avg; a++) {
        adc_capture(ab, CAP_ADC, 0, 0, &a0, &a1, &a2, &a3);
        for(n=0; n<slen; n++) {
            sum0 += a0[n];
            sum1 += a1[n];
            sum2 += a2[n];
            sum3 += a3[n];
            ssq0 += a0[n]*a0[n];
            ssq1 += a1[n]*a1[n];
            ssq2 += a2[n]*a2[n];
            ssq3 += a3[n]*a3[n];
        }
    }

    tot = opt_avg * slen;

    rms[0] = 1.0 / 256.0 * sqrt(ssq0 / tot);
    rms[1] = 1.0 / 256.0 * sqrt(ssq1 / tot);
    rms[2] = 1.0 / 256.0 * sqrt(ssq2 / tot);
    rms[3] = 1.0 / 256.0 * sqrt(ssq3 / tot);

    pow[0] = 10.0 * log10(1000.0 * rms[0] * rms[0] / 50.0);
    pow[1] = 10.0 * log10(1000.0 * rms[1] * rms[1] / 50.0);
    pow[2] = 10.0 * log10(1000.0 * rms[2] * rms[2] / 50.0);
    pow[3] = 10.0 * log10(1000.0 * rms[3] * rms[3] / 50.0);

    mean[0] = sum0 / tot;
    mean[1] = sum1 / tot;
    mean[2] = sum2 / tot;
    mean[3] = sum3 / tot;
}

// Get levels from all of the boards at once...
//
#define AVG 2

static void 
get_levels_new(Ab **ab, double *mean, double *rms, double *pow)
{
    int     i, a, n;

    s_char  *a0, *a1, *a2, *a3;
    double  sum0, sum1, sum2, sum3;
    double  ssq0, ssq1, ssq2, ssq3;
    int     slen = ab[0]->mbus_len/4;
    double  tot;

    for(i=0; i<G_BEAMS; i++) {
        if (!ab[i])
            continue;

        sum0 = sum1 = sum2 = sum3 = 0.0;
        ssq0 = ssq1 = ssq2 = ssq3 = 0.0;
        for(a=0; a<AVG; a++) {
            adc_capture(ab[i], CAP_ADC, 0, 0, &a0, &a1, &a2, &a3);
            for(n=0; n<slen; n++) {
                sum0 += a0[n];
                sum1 += a1[n];
                sum2 += a2[n];
                sum3 += a3[n];
                ssq0 += a0[n]*a0[n];
                ssq1 += a1[n]*a1[n];
                ssq2 += a2[n]*a2[n];
                ssq3 += a3[n]*a3[n];
            }
        }

        tot = AVG * slen;

        rms[i*4+0] = 1.0 / 256.0 * sqrt(ssq0 / tot);
        rms[i*4+1] = 1.0 / 256.0 * sqrt(ssq1 / tot);
        rms[i*4+2] = 1.0 / 256.0 * sqrt(ssq2 / tot);
        rms[i*4+3] = 1.0 / 256.0 * sqrt(ssq3 / tot);

        pow[i*4+0] = 10.0 * log10(1000.0 * rms[i*4+0] * 
                rms[i*4+0] / 50.0);
        pow[i*4+1] = 10.0 * log10(1000.0 * rms[i*4+1] * 
                rms[i*4+1] / 50.0);
        pow[i*4+2] = 10.0 * log10(1000.0 * rms[i*4+2] * 
                rms[i*4+2] / 50.0);
        pow[i*4+3] = 10.0 * log10(1000.0 * rms[i*4+3] * 
                rms[i*4+3] / 50.0);

        mean[i*4+0] = sum0 / tot;
        mean[i*4+1] = sum1 / tot;
        mean[i*4+2] = sum2 / tot;
        mean[i*4+3] = sum3 / tot;
    }
}

void
set_levels(Ab **ab)
{
    int     i, it;
    double  mean[4];
    double  rms[4];
    double  pow[4];
    int     fd=0;
    int     fdo;

    int     mina, maxa;
    int     minb, maxb;
    int     daca, dacb;
    u_char  u_dac;

    // open the device
    // if ((fd = open("/dev/ttyS1", O_RDWR | O_NDELAY)) < 0) {
    //     fprintf(stderr, "device not found");
    //     exit(1);
    // }

    // open output file with dac settings
    if ((fdo = open("/tmp/dac", O_CREAT | O_WRONLY, 0666)) < 0) {
        fprintf(stderr, "cannot open /tmp/dac for output\n");
        exit(1);
    }

    //enable I/O port controls
    iopl(3);

    printf("Hey! This is depricated, you should start\n");
    printf("using --newdac=n instead.\n\n");
    printf("Setting levels for RMS level of %.2f ADC units\n", opt_level);

    for(i=0; i<G_BEAMS; i++) {
        if (!ab[i])
            continue;

        mina = 0; maxa = 255;
        minb = 0; maxb = 255;
        printf("Beam %d.\n", i);
        for(it=0; it<8; it++) {
            daca = (mina + maxa)/2;
            dacb = (minb + maxb)/2;

            setdac(fd, i*2, daca);
            setdac(fd, i*2+1, dacb);
            usleep(100000);

            get_levels(ab[i], mean, rms, pow);
            printf("    Daca %d\n", daca);
            printf("    AR mean=%4.2f  RMS=%4.2f %.2f dBm\n", 
                mean[0], 256.0 * rms[0], pow[0]);
            printf("    AI mean=%4.2f  RMS=%4.2f %.2f dBm\n",
                mean[1], 256.0 * rms[1], pow[1]);
            printf("    Dacb %d\n", dacb);
            printf("    BR mean=%4.2f  RMS=%4.2f %.2f dBm\n",
                mean[2], 256.0 * rms[2], pow[2]);
            printf("    BI mean=%4.2f  RMS=%4.2f %.2f dBm\n",
                mean[3], 256.0 * rms[3], pow[3]);
            printf("\n");

            if (128.0 * (rms[0]+rms[1]) > opt_level)
                mina = daca;
            else
                maxa = daca;
            if (128.0 * (rms[2]+rms[3]) > opt_level)
                minb = dacb;
            else
                maxb = dacb;
        }
        u_dac = daca;
        write(fdo, &u_dac, 1);
        u_dac = dacb;
        write(fdo, &u_dac, 1);
        g_dac[i*2] = daca;
        g_dac[i*2+1] = dacb;
    }
    close(fdo);

    printf("\n");
    for(i=0; i<G_BEAMS; i++) {
        if (!ab[i])
            continue;

        printf("Beam %d.\n", i);
        get_levels(ab[i], mean, rms, pow);
        printf("    dac=%3u, AR mean=%4.2f  RMS=%4.2f %.2f dBm\n", 
            g_dac[i*2], mean[0], 256.0 * rms[0], pow[0]);
        printf("             AI mean=%4.2f  RMS=%4.2f %.2f dBm\n",
            mean[1], 256.0 * rms[1], pow[1]);
        printf("    dac=%3u, BR mean=%4.2f  RMS=%4.2f %.2f dBm\n",
            g_dac[i*2+1], mean[2], 256.0 * rms[2], pow[2]);
        printf("             BI mean=%4.2f  RMS=%4.2f %.2f dBm\n",
            mean[3], 256.0 * rms[3], pow[3]);
        printf("\n");
        g_rms[i*2+0] = (u_long) (1000.0 * 256.0 * (rms[i*4+0]+rms[i*4+1])/2.0);
        g_rms[i*2+1] = (u_long) (1000.0 * 256.0 * (rms[i*4+2]+rms[i*4+3])/2.0);
    }
    // close(fd);
}


// Just go out and read the current levels
//
void
get_sock_levels_new(Ab **ab)
{
    int     i;
    double  mean[4*G_BEAMS];
    double  rms[4*G_BEAMS];
    double  pow[4*G_BEAMS];
    s_char  *a0, *a1, *a2, *a3;

    // Clear out any sprectrum capture in progress
    //
    for(i=0; i<G_BEAMS; i++)
        if (ab[i])
            adc_capture(ab[i], CAP_ADC, 0, 0, &a0, &a1, &a2, &a3);

    get_levels_new(ab, mean, rms, pow);

    for(i=0; i<4*G_BEAMS; i++)
        g_rms[i] = 0;
    for(i=0; i<G_BEAMS; i++) {
        if (ab[i]) {
            g_rms[i*2+0] = (u_long) (1000.0 * 256.0 * 
                (rms[i*4+0]+rms[i*4+1])/2.0);
            g_rms[i*2+1] = (u_long) (1000.0 * 256.0 * 
                (rms[i*4+2]+rms[i*4+3])/2.0);
        }
    }
    g_capture_start(ab, CAP_PFB);
}

//  Do all 7-beams at once...
//
void
set_levels_new(Ab **ab)
{
    int     i, it;
    double  mean[4*G_BEAMS];
    double  rms[4*G_BEAMS];
    double  pow[4*G_BEAMS];
    int     fd=0;
    int     fdo;
    s_char  *a0, *a1, *a2, *a3;

    int     mina[G_BEAMS];
    int     maxa[G_BEAMS];
    int     minb[G_BEAMS];
    int     maxb[G_BEAMS];
    int     daca[G_BEAMS];
    int     dacb[G_BEAMS];

    u_char  u_dac;

    // Clear out any sprectrum capture in progress
    //
    for(i=0; i<G_BEAMS; i++)
        if (ab[i])
            adc_capture(ab[i], CAP_ADC, 0, 0, &a0, &a1, &a2, &a3);


    for(i=0; i<G_BEAMS; i++) {
        daca[i] = 0;
        dacb[i] = 0;
    }

    // open output file with dac settings
    if ((fdo = open("/tmp/dac", O_CREAT | O_WRONLY, 0666)) < 0) {
        fprintf(stderr, "cannot open /tmp/dac for output\n");
        exit(1);
    }

    //enable I/O port controls
    iopl(3);

    printf("Setting levels for RMS level of %.2f ADC units\n", opt_level);
    for(i=0; i<G_BEAMS; i++) {
        mina[i] = 0;
        minb[i] = 0;
        maxa[i] = 255;
        maxb[i] = 255;
    }
    for(it=0; it<8; it++) {
        for(i=0; i<G_BEAMS; i++) {
            if (!ab[i])
                continue;
            daca[i] = (mina[i] + maxa[i])/2;
            dacb[i] = (minb[i] + maxb[i])/2;
            setdac(fd, i*2, daca[i]);
            setdac(fd, i*2+1, dacb[i]);
        }

        // Let the analog hardware settle with new settings
        usleep(100000);

        get_levels_new(ab, mean, rms, pow);

        for(i=0; i<G_BEAMS; i++) {
            if (!ab[i])
                continue;
            printf("Beam %d\n", i);
            printf("    Daca %d\n", daca[i]);
            printf("    AR mean=%4.2f  RMS=%4.2f %.2f dBm\n", 
                mean[0], 256.0 * rms[0], pow[0]);
            printf("    AI mean=%4.2f  RMS=%4.2f %.2f dBm\n",
                mean[1], 256.0 * rms[1], pow[1]);
            printf("    Dacb %d\n", dacb[i]);
            printf("    BR mean=%4.2f  RMS=%4.2f %.2f dBm\n",
                mean[2], 256.0 * rms[2], pow[2]);
            printf("    BI mean=%4.2f  RMS=%4.2f %.2f dBm\n",
                mean[3], 256.0 * rms[3], pow[3]);
            printf("\n");

            if (128.0 * (rms[i*4+0]+rms[i*4+1]) > opt_level)
                mina[i] = daca[i];
            else
                maxa[i] = daca[i];
            if (128.0 * (rms[i*4+2]+rms[i*4+3]) > opt_level)
                minb[i] = dacb[i];
            else
                maxb[i] = dacb[i];
        }
    }

    for(i=0; i<G_BEAMS; i++) {
        u_dac = daca[i];
        write(fdo, &u_dac, 1);
        u_dac = dacb[i];
        write(fdo, &u_dac, 1);
        g_dac[i*2+0] = daca[i];
        g_dac[i*2+1] = dacb[i];
    }
    close(fdo);

    get_levels_new(ab, mean, rms, pow);
    printf("\n\nSummary\n");
    for(i=0; i<G_BEAMS; i++) {
        if (!ab[i])
            continue;

        printf("Beam %d.\n", i);
        printf("    dac=%3u, AR mean=%4.2f  RMS=%4.2f %.2f dBm\n", 
            g_dac[i*2], 
            mean[i*4+0], 256.0 * rms[i*4+0], pow[i*4+0]);
        printf("             AI mean=%4.2f  RMS=%4.2f %.2f dBm\n",
            mean[i*4+1], 256.0 * rms[i*4+1], pow[i*4+1]);
        printf("    dac=%3u, BR mean=%4.2f  RMS=%4.2f %.2f dBm\n",
            g_dac[i*2+1], 
            mean[i*4+2], 256.0 * rms[i*4+2], pow[i*4+2]);
        printf("             BI mean=%4.2f  RMS=%4.2f %.2f dBm\n",
            mean[i*4+3], 256.0 * rms[i*4+3], pow[i*4+3]);
        printf("\n");

        g_rms[i*2+0] = (u_long) (1000.0 * 256.0 * (rms[i*4+0]+rms[i*4+1])/2.0);
        g_rms[i*2+1] = (u_long) (1000.0 * 256.0 * (rms[i*4+2]+rms[i*4+3])/2.0);
    }

    g_capture_start(ab, CAP_PFB);
}


/*  set_dac.c 
 *  
 *  Func:   set_dac.c uses the RTS and DTR pins of a serial device 
            found at /dev/ttyS1 to 
 *          set the power levels of the DAC. 
 *          DTR is used as the clock signal SCL
 *          RTS is used as the data signal SDA
 *          Please refer to the Max521 specs page for more information 
            on SCL, SDA
 *
 *  Usage:  set_dac <dac number> <dac power level>
 *          <dac number> should be between 0-15 and indicate which dac to set.
 *          <dac power level> should be between 0-255 and indicate the power 
            level to set.
 *  
 *  Author: Wonsop Sim
 *
 *  Date:   July 28, 2004
 */

//implements a <count> microsecond delay by reading from a slow I/O port.
static void 
xdelay (int count)
{
    volatile int x;
    int i;
    for(i=0; i<count; i++)
        x = inb(0x40);       // safe slow I/O port to read
}



static void 
setdac (int fd, int dac, int level)
{
    int dac_adr;
    int dac_num;
    int flags;
    int i;
    int count = 5;

    if ((fd = open("/dev/ttyS1", O_RDWR | O_NDELAY)) < 0) {
        fprintf(stderr, "device not found");
        exit(1);
    }

    //check to make sure arguments are in the correct range
    if (dac >= 0 && dac < 8) {
        dac_adr = 0;
        dac_num = dac;
    }
    else if (dac >= 8 && dac < 16) {
        dac_adr = 3;
        dac_num = dac - 8;
    }
    else {
        fprintf(stderr, "DAC address must be in range 0-15\n");
        exit(1);
    }
    if (level < 0 || level > 255) {
        fprintf(stderr, "Power level must be in range 0-255\n");
        exit(1);
    }
    
    //add in factory set bits to the address
    dac_adr = (dac_adr * 2) + 80;

    //get line bits for serial port
    ioctl(fd, TIOCMGET, &flags);

    //make sure RTS and DTR lines are high
    flags &= ~TIOCM_RTS;
    flags &= ~TIOCM_DTR;
    ioctl(fd, TIOCMSET, &flags);
    xdelay(count);
    
    //do start condition 
    flags |= TIOCM_RTS;
    ioctl(fd, TIOCMSET, &flags);
    xdelay(count);
    flags |= TIOCM_DTR;
    ioctl(fd, TIOCMSET, &flags);
    xdelay(count);

    //do address byte
    for (i = 7; i >=0; i--) {
        if ((dac_adr >> i) & 1)
            flags &= ~TIOCM_RTS;
        else
            flags |= TIOCM_RTS;
        ioctl(fd, TIOCMSET, &flags);
        xdelay(count);
        flags &= ~TIOCM_DTR;
        ioctl(fd, TIOCMSET, &flags);
        xdelay(count);
        flags |= TIOCM_DTR;
        ioctl(fd, TIOCMSET, &flags);
        xdelay(count);
    }
    //acknowledge bit
    flags |= TIOCM_RTS;
    ioctl(fd, TIOCMSET, &flags);
    xdelay(count);
    flags &= ~TIOCM_DTR;
    ioctl(fd, TIOCMSET, &flags);
    xdelay(count);
    flags |= TIOCM_DTR;
    ioctl(fd, TIOCMSET, &flags);
    xdelay(count);

    //do command byte
    for (i = 7; i >=0; i--) {
        if ((dac_num >> i) & 1)
            flags &= ~TIOCM_RTS;
        else
            flags |= TIOCM_RTS;
        ioctl(fd, TIOCMSET, &flags);
        xdelay(count);
        flags &= ~TIOCM_DTR;
        ioctl(fd, TIOCMSET, &flags);
        xdelay(count);
        flags |= TIOCM_DTR;
        ioctl(fd, TIOCMSET, &flags);
        xdelay(count);
    }
    //acknowledge bit
    flags |= TIOCM_RTS;
    ioctl(fd, TIOCMSET, &flags);
    xdelay(count);
    flags &= ~TIOCM_DTR;
    ioctl(fd, TIOCMSET, &flags);
    xdelay(count);
    flags |= TIOCM_DTR;
    ioctl(fd, TIOCMSET, &flags);
    xdelay(count);
    
    //do output byte
    for (i = 7; i >=0; i--) {
        if ((level >> i) & 1)
            flags &= ~TIOCM_RTS;
        else
            flags |= TIOCM_RTS;
        ioctl(fd, TIOCMSET, &flags);
        xdelay(count);
        flags &= ~TIOCM_DTR;
        ioctl(fd, TIOCMSET, &flags);
        xdelay(count);
        flags |= TIOCM_DTR;
        ioctl(fd, TIOCMSET, &flags);
        xdelay(count);
    }

    //acknowledge bit
    flags |= TIOCM_RTS;
    ioctl(fd, TIOCMSET, &flags);
    xdelay(count);
    flags &= ~TIOCM_DTR;
    ioctl(fd, TIOCMSET, &flags);
    xdelay(count);
    flags |= TIOCM_DTR;
    ioctl(fd, TIOCMSET, &flags);
    xdelay(count);

    //do stop condition
    flags &= ~TIOCM_DTR;
    ioctl(fd, TIOCMSET, &flags);
    xdelay(count);
    flags &= ~TIOCM_RTS;
    ioctl(fd, TIOCMSET, &flags);
    xdelay(count);

    close(fd);
}
