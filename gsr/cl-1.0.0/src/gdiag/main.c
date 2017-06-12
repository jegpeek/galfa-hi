
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
#include <signal.h>
#include <pthread.h>

#include "galfa_sock/galfa_sock.h"
#include "galfa.h"
#include "scram/gscram.h"

enum {
    opti_none,
    opti_adc,
    opti_rfft,
    opti_cfft,
    opti_scope,
    opti_patt,
    opti_dump,
    opti_galfa,
    opti_run,
    opti_dac,
    opti_newdac,

    opti_vnc,
    opti_avg,
    opti_max,
    opti_input,
    opti_ppdb,
    opti_adcfreq,
    opti_nshift,
    opti_wshift,
    opti_beam,
    opti_mix,
    opti_goff,
    opti_ta,
    opti_tb,
    opti_npfb,
    opti_wpfb,
    opti_lpf,
    opti_ppsint,
    opti_fn,
    opti_time,
    opti_level,
    opti_sdiv,
    opti_mask,
    opti_ovftrig,
    opti_sock,
    opti_nofits,
    opti_ref,
    opti_nofix,
    opti_lo2,
    opti_scram,
};

static struct option lopts[] = {
    { "adc",            0, 0, opti_adc },
    { "rfft",           0, 0, opti_rfft },
    { "cfft",           0, 0, opti_cfft },
    { "scope",          0, 0, opti_scope },
    { "patt",           0, 0, opti_patt },
    { "dump",           0, 0, opti_dump },
    { "galfa",          0, 0, opti_galfa },
    { "run",            0, 0, opti_run },
    { "dac",            0, 0, opti_dac },
    { "newdac",         1, 0, opti_newdac },

    { "vnc",            0, 0, opti_vnc },
    { "avg",            1, 0, opti_avg },
    { "max",            0, 0, opti_max },
    { "input",          1, 0, opti_input },
    { "ppdb",           1, 0, opti_ppdb },
    { "adcfreq",        1, 0, opti_adcfreq },
    { "nshift",         1, 0, opti_nshift },
    { "wshift",         1, 0, opti_wshift },
    { "beam",           1, 0, opti_beam },
    { "mix",            1, 0, opti_mix },
    { "offset",         1, 0, opti_goff },
    { "ta",             1, 0, opti_ta },
    { "tb",             1, 0, opti_tb },
    { "npfb",           1, 0, opti_npfb },
    { "wpfb",           1, 0, opti_wpfb },
    { "lpf",            0, 0, opti_lpf },
    { "ppsint",         0, 0, opti_ppsint },
    { "proj",           1, 0, opti_fn },
    { "time",           1, 0, opti_time },
    { "level",          1, 0, opti_level },
    { "sdiv",           1, 0, opti_sdiv },
    { "mask",           1, 0, opti_mask },
    { "ovftrig",        0, 0, opti_ovftrig },
    { "nosock",         0, 0, opti_sock },
    { "nofits",         0, 0, opti_nofits },
    { "ref",            1, 0, opti_ref },
    { "nofix",          0, 0, opti_nofix },
    { "lo2",            1, 0, opti_lo2 },
    { "scram",          0, 0, opti_scram },
    { NULL,             0, 0, 0 },
};

void
usage(char *prog)
{
    printf("\nUsage: %s [options]\n", prog);
    printf("\nMain operating modes\n");
    printf("    -adc       Print out buffer of ADC samples as text\n");
    printf("    -rfft      Plot real FFT of ADC channel samples\n");
    printf("    -cfft      Plot complex FFT of ADC channel samples\n");
    printf("    -scope     Plot oscilloscope view of ADC samples\n");
    printf("    -patt      Pattern test for data acquisition\n");
    printf("    -dump      Print galfa aquisition as text\n");
    printf("    -galfa     Plot galfa data and write FITS file\n");
    printf("    -run       Collect galfa data and write a FITS file\n");
    printf("    -dac       Set DACs for input level of f dBM\n");
    printf("    -newdac=n  Set DACs better for input level of n DAC units\n");
    printf("\nOther options\n");
    printf("    -vnc       Run as VNC server instead of console\n");
    printf("    -avg=n     Average interval for histograms and FFTs\n");
    printf("    -max       Add max-hold line FFT displays\n");
    printf("    -input=n   Take input from channel n\n");
    printf("    -ppdb=f    Pixels per dB for vertical scale\n");
    printf("    -adcfreq=f Use f as ADC sample frequency (MHz)\n");
    printf("    -nshift=n  Set upshift of narrowband PFB before acc\n");
    printf("    -wshift=n  Set upshift of wideband PFB before acc\n");
    printf("    -npfb=x    Set narrowband PFB downshift vector\n");
    printf("    -wpfb=x    Set wideband PFB downshift vector\n");
    printf("    -beam=n    Select beam for single beam operations\n");
    printf("    -mix=0..31 Select mixer for narrowband\n");
    printf("    -offset=f  Global frequency offset (external mixing)\n");
    printf("    -ta=f      Signal generator A frequency\n");
    printf("    -tb=f      Signal generator B frequency\n");
    printf("    -lpf=x     Use LPF output instead of ADC for time domain displays\n");
    printf("    -ppsint    Beam 0 gets PPS from internal source\n");
    printf("    -proj=s    Project portion of filename for FITS dump file\n");
    printf("    -sdiv=n    Number of seconds per FITS file\n");
    printf("    -time=n    Run --run for n seconds\n");
    printf("    -level=f   RMS units for analog level setting\n");
    printf("    -mask=n    Mask off ADC bits (1 means bit is turned off)\n");
    printf("    -ovftrig   Trigger time domain diags on ADC overflow\n");
    printf("    -nosock    Disable socket listening\n");
    printf("    -nofits    Disable FITS file writing\n");
    printf("    -nofix     By default, the diag display clean up wideband\n");
    printf("                 spurs at fs, fs/2, & fs/4, this leaves them ugly");
    printf("    -lo2=f     Set LO2 frequency (MHz) using gpibsock on dataview...\n");
    printf("    -scram     Start thread to listen for scramnet telescope info\n");
    printf("\n");
    printf("During graphical operation\n");
    printf("    Press 'q' to quit program\n");
    printf("    Press 'p' to create raw image file in /tmp\n");
    printf("    Press 'r' to toggle max-hold\n");
    printf("    Press 'a' to toggle through galfa display modes\n");
    printf("    Press '0-6' to select beam in galfa display\n");
    printf("    Press 'c/v' to modify pixels per dB on log display\n");
    printf("    Press 'z/x' to change pre-accum shift in galfa display\n");
    printf("    Press ',/.' to scroll through narrow band displays\n");
    printf("    Press '</>' to scroll faster through narrow band displays\n");
    printf("    Press 'o' to swap drawing order for polarizations\n");
    printf("    Press 'm/n/b' to manually move marker\n");
    printf("    Press 'w/W' to change mix frequency for narrowband\n");
    printf("    Press 'k/l' to zoom in/out x-axis in narrowband displays\n");
    printf("    Press 'K' zoom 1-pixel per frequency X-scale\n");
    printf("    Press 'L' zoom out to full span in X-scale\n");
    printf("    Press 'd/f' decrease/increase PFB downshift vector\n");
    printf("    Press 'h' to toggle linear/log vertical display\n");
    printf("    Press '[]' to move ref level of log galfa displays by 10dB\n");
    printf("\n");
}

int     opt_vnc = 0;                // Act as VNC server
int     opt_avg = 5;                // averaging for freq displays
int     opt_max = 0;                // max hold on freq displays
int     opt_nshift = 0;             // narrowband upshift
int     opt_wshift = 2;             // wideband upshift
int     opt_input = 0;              // ADC input
double  opt_ppdb = 3.0;             // pixels per dB option
double  opt_adcfreq = DEF_ADC_FREQ;
int     opt_beam = 0;
int     opt_mix = -6;
double  opt_goff =  0.0;            // Usually get from scramnet 1438.75;
double  opt_ta = 0.0;
int     opt_ta_use = 0;
double  opt_tb = 0.0;
int     opt_tb_use = 0;
int     opt_npfb = 0x0555;           // 13-bit shift mask
int     opt_wpfb = 0x1ff; // 0x1db;            // 9-bit shift mask
int     opt_lpf = 0;
int     opt_ppsint = 0;
char    *opt_fn = "diag"; 
int     opt_run = 0;
int     opt_time = 0;
double  opt_level = 0.0;
int     opt_sdiv = 0;
int     opt_mask = 0;
int     opt_ovftrig = 0;
int     opt_sock = 1;
int     opt_nofits = 0;
double  opt_ref = 0.0;
int     diag_reg = 0;
int     opt_fix = 1;
int     opt_setlo2 = 0;
double  opt_lo2 = 0.0;
int     opt_scram = 0;

static void
gk_reset(Ab **ab)
{
    int         i;

    // reset PFB
    //
    for(i=0; i<G_BEAMS; i++) {
        if (ab[i]) {
            ab[i]->ctl[0] = 0x20;
            usleep(10000);
            ab[i]->ctl[0] = 0x00;
            usleep(10000);
        }
    }
}

static u_long
testfreq(double f)
{
    int     neg=0;;
    u_long  v;
    double  rf;

    if (f <= -opt_adcfreq || f >= opt_adcfreq) 
        printf("Frequency is out of range: %g\n", f);

    if (f<0.0) {
        neg = 1;
        f = -f;
    }
    f *= (double) (((long long) 1) << 32);
    f /= opt_adcfreq;
    v = f;
    v &= 0x7fffffff;
    if (neg)
        v |= 0x80000000;
    
    rf = opt_adcfreq * ((double) (v&0x7fffffff)) / 
            (double) (((long long) 1) << 32);
    if (v&0x80000000)
        rf = -rf;

    printf("Actual freq is %.4f MHz\n", rf);
    return v;
}

// For freetype
//
FT_Library   library;
FT_Face      regface;

//  Just grab ADC samples and print them 
//
void
adc_test(Ab **abl)
{
    int             j;
    s_char          *adc0;
    s_char          *adc1;
    s_char          *adc2;
    s_char          *adc3;
    Ab              *ab = abl[opt_beam];

    if (!ab) {
        printf("Beam %d doesn't exist.\n", opt_beam);
        exit(0);
    }
    if (opt_lpf)
        adc_capture(ab, CAP_LPF, N_DEC-1, 0, &adc0, &adc1, &adc2, &adc3);
    else
        adc_capture(ab, CAP_ADC, 0, 0, &adc0, &adc1, &adc2, &adc3);
    for(j=0; j<ab->mbus_len/4; j++)
        printf("%3d %3d %3d %3d\n", adc0[j], adc1[j], adc2[j], adc3[j]);
    exit(0);
}

//  Dump galfa data as text
//
void
galfa_dump(Ab **ab)
{
    galfa_pkt       gm[G_BEAMS];

    int             i;
    int             beam;
    double          pola_w[W_BINS];
    double          polb_w[W_BINS];
    double          pola_n[N_BINS];
    double          polb_n[N_BINS];
    
    double          scale;
    char            fstr[20];

    // Set upshift for transforms
    g_set_shift(ab);

    // Two dummy captures to make sure we're synced up and parameters
    // like shift have settled so we collect good data
    //
    printf("Syncing...\n");
    g_capture(ab, CAP_PFB, gm);
    g_capture(ab, CAP_PFB, gm);

    g_capture(ab, CAP_PFB, gm);
    for(beam=0; beam<G_BEAMS; beam++) {
        if (!ab[beam])
            continue;
        printf("Beam %d\n", beam);
        for(i=0; i<W_BINS; i++) {
            pola_w[i] = (double) gm[beam].pola_w[i];
            polb_w[i] = (double) gm[beam].polb_w[i];
            if (pola_w[i] <= 0.0)
                pola_w[i] = 0.5;
            if (polb_w[i] <= 0.0)
                polb_w[i] = 0.5;
        }
        scale = (double) W_MAX;
        for(i=0; i<W_BINS; i++) {
            pola_w[i] = pola_w[i] / scale; 
            polb_w[i] = polb_w[i] / scale; 

            if (pola_w[i] <= 0.0)
                pola_w[i] = -200.0;
            else 
                pola_w[i] = 10.0 * log10(pola_w[i]);
            if (polb_w[i] <= 0.0)
                polb_w[i] = -200.0;
            else 
                polb_w[i] = 10.0 * log10(polb_w[i]);
        }

        for(i=0; i<N_BINS; i++) {
            pola_n[i] = (double) gm[beam].pola_n[i];
            polb_n[i] = (double) gm[beam].polb_n[i];
            if (pola_n[i] <= 0.0)
                pola_n[i] = 0.5;
            if (polb_n[i] <= 0.0)
                polb_n[i] = 0.5;
        }
        scale = (double) N_MAX;
        for(i=0; i<N_BINS; i++) {
            pola_n[i] = pola_n[i] / scale; 
            polb_n[i] = polb_n[i] / scale; 

            if (pola_n[i] <= 0.0)
                pola_n[i] = -200.0;
            else 
                pola_n[i] = 10.0 * log10(pola_n[i]);
            if (polb_n[i] <= 0.0)
                polb_n[i] = -200.0;
            else 
                polb_n[i] = 10.0 * log10(polb_n[i]);
        }

        printf("Wideband data (offset = %.4f MHz) \n", opt_goff);
        printf("    wacc ushift: %d\n", opt_wshift);
        strcpy(fstr, "00000000");
        for(i=0; i<8; i++)
            if (opt_wpfb & (1<<i))
                fstr[7-i] = '1';
        printf("    wpfb dshift: %s\n", fstr);
        for(i=0; i<W_BINS; i++) {
            double  f;

            f = opt_adcfreq * ((double)i - W_BINS/2)/W_BINS + opt_goff;
            printf("%6d  %6.2f MHz  %08lx %9.4f dB   %08lx %9.4f dB\n",
                i-W_BINS/2, f, gm[beam].pola_w[i], pola_w[i], 
                gm[beam].polb_w[i], polb_w[i]);
        }
        printf("\nNarrowband data (mixer = %.3f MHz)\n", mix_freq());
        printf("    nacc ushift: %d\n", opt_nshift);
        strcpy(fstr, "0000000000000");
        for(i=0; i<13; i++)
            if (opt_npfb & (1<<i))
                fstr[12-i] = '1';
        printf("    npfb dshift: %s\n", fstr);
        for(i=0; i<N_BINS; i++) {
            double  f;

            f = (opt_adcfreq / N_DEC) * ((double)i - N_WIDTH/2 + 
                N_OFFSET)/N_WIDTH + mix_freq() + opt_goff;
            printf("%6d  %7.4f MHz  %08lx %9.4f dB   %08lx %9.4f dB\n",
                i-N_WIDTH/2+N_OFFSET, f, gm[beam].pola_n[i], 
                pola_n[i], gm[beam].polb_n[i], polb_n[i]);
        }
        printf("\n");
    }
}

//  Use onchip pattern generator in galfa to test data acquisition
//
void
patt_test(Ab **ab)
{
    galfa_pkt       gm[G_BEAMS];
    u_long          exp;
    int             i;
    int             beam;
    int             tseq, tseqn;
    int             ecnt=0;

    int             nacc = 860;         // # narrowband accumulations
    int             wacc = 192640;  // 385280;      // # wideband accumulations
    
    // Turn on pattern generator
    AbGkReg(ab, Gk_diag, 1);

    // Two dummy captures to make sure we're synced up
    printf("Syncing...\n");
    g_capture(ab, CAP_PFB, gm);
    g_capture(ab, CAP_PFB, gm);
    tseq = gm[0].misc & 0xffff;

    while (1) {
        g_capture(ab, CAP_PFB, gm);
        tseqn = gm[0].misc & 0xffff;
        tseq = (tseq+1) & 0xffff;
        if (tseq != tseqn) 
            printf("Unexpected seq: %d, expect: %d\n", tseqn, tseq);

        for(beam=0; beam<G_BEAMS; beam++) {
            if (!ab[beam])
                continue;
            for(i=0; i<W_BINS; i++) {
                exp = i*wacc >> 12;
                if (gm[beam].pola_w[i] != exp) {
                    printf("Polarity A WB error beam %d: bin %d read %08lx expected %08lx\n",
                        beam, i, gm[beam].pola_w[i], exp);
                    // if (++ecnt > 20) {
                    //     printf("Too many errors.\n");
                    //    exit(1);
                    // }
                }
            }

            for(i=0; i<W_BINS; i++) {
                exp = (i+W_BINS)*wacc >> 12;
                if (gm[beam].polb_w[i] != exp) {
                    printf("Polarity B WB error beam %d: bin %d read %08lx expected %08lx\n",
                        beam, i, gm[beam].polb_w[i], exp);
                    // if (++ecnt > 20) {
                    //     printf("Too many errors.\n");
                    //     exit(1);
                    // }
                }
            }

            for(i=0; i<N_BINS; i++) {
                exp = (i+N_OFFSET)*nacc;
                if (gm[beam].pola_n[i] != exp) {
                    printf("Polarity A NB error beam %d: bin %d read %08lx expected %08lx\n",
                        beam, i, gm[beam].pola_n[i], exp);
                    if (++ecnt > 20) {
                        printf("Too many errors.\n");
                        exit(1);
                    }
                }
            }

            for(i=0; i<N_BINS; i++) {
                exp = (i+N_OFFSET+N_WIDTH)*nacc;
                if (gm[beam].polb_n[i] != exp) {
                    printf("Polarity B NB error beam %d: bin %d read %08lx expected %08lx\n",
                        beam, i, gm[beam].polb_n[i], exp);
                    if (++ecnt > 20) {
                        printf("Too many errors.\n");
                        exit(1);
                    }
                }
            }
            printf("Sequence %d, beam %d\n", tseq, beam);
        }
    }
    exit(0);
}

//  Take ADC samples of a channel and make a graph of
//  power spectrum of read FFT of an ADC channel.
//
void
do_freq(Ab **abl)
{
    int             x, xs, i;
    s_char          *a0, *a1, *a2, *a3;
    int             border;
    pixmap          *gr;
    pixmap          *draw;
    pixmap          *grid;
    int             navg, tavg;

    double          *in;
    fftw_complex    *out;
    double          *pv;
    int             *ipv;
    double          *cpv;
    double          **pav;
    int             *max;
    fftw_plan       plan;

    pixel           bg  = COLOR(64,64,64);
    pixel           fg  = COLOR(0,255,0);
    pixel           gc  = COLOR(128,128,128);
    pixel           maxc  = COLOR(255,0,0);
    int             mark_f=0;
    double          mark_l;
    char            fstr[80];
    int             my;
    double          mf;

    int             mark_fix=0;
    int             ys=400;
    int             avg=opt_avg;
    double          ppdb = 5.0;     // pixels per dB
    Ab              *ab = abl[opt_beam];

    if (!ab) {
        printf("Beam %d does not exist\n", opt_beam);
        exit(0);
    }

    if (opt_ppdb > 0)
        ppdb = opt_ppdb;

    // Find largest power of 2 that fits on screen
    for(i=30; i>=0; i--) 
        if (fb->xs >> i)
            break;
    xs = 1 << i;
    border = (fb->xs - xs)/2;

    gr = pixmap_subset(fb, border, 50, fb->xs-2*border, ys);
    draw = pixmap_dup(gr);
    grid = pixmap_dup(gr);

    // Make background grid
    //
    pixmap_setcolor(grid, bg);
    for(i=0; i<xs; i+=xs/8) 
        pixmap_setcolor_rect(grid, gc, i, 0, 1, ys);
    pixmap_setcolor_rect(grid, gc, xs-1, 0, 1, ys);
    for(i=0; i<ys; i+= ppdb*10)
        pixmap_setcolor_rect(grid, gc, 0, i, xs, 1);
    pixmap_copy(gr, grid, 0, 0);

    // Prepare for FFTs, do FFTs twice the width of the screen
    // since we're just looking at power spectrum of real FFT
    // only N/2+1 values of the result are useful.
    //
    in = fftw_malloc(sizeof(double) * xs*2);
    out = fftw_malloc(sizeof(fftw_complex) * xs*2);
    pv = fftw_malloc(sizeof(double) * xs*2);
    ipv = fftw_malloc(sizeof(int) * xs*2);
    max = fftw_malloc(sizeof(int) * xs*2);
    for(i=0; i<xs*2; i++)
        max[i] = ys;
    pav = fftw_malloc(sizeof(double *) * avg);
    for(i=0; i<avg; i++)
        pav[i] = fftw_malloc(sizeof(double) * xs*2);
    plan = fftw_plan_dft_r2c_1d(xs*2, in, out, FFTW_ESTIMATE);
    tavg = 0;
    navg = 0;

    while (1) {
        while (kbhit()) {
            int ch;
            ch = readch();
            switch (ch) {
                // Make plot file
                //
                case 'p':   screen_print(fb);
                            break;

                // Exit program
                //
                case 0x03:
                case 'q':   release_lock();
                            gexit(1);

                // Toggle max-hold
                //
                case 'r':   opt_max = !opt_max;
                            if (opt_max) 
                                for(x=0; x<xs; x++)
                                    max[x] = ys;
                            break;

                // Manually move marker
                //
                case 'n':   if (--mark_f < 0)
                                mark_f = 0;
                            mark_fix = 1;
                            break;
                case 'm':   if (++mark_f >= xs)
                                mark_f = xs-1;
                            mark_fix = 1;
                            break;
                case 'b':   mark_fix = 0;
                            break;

                case 'w':   ++opt_mix;
                            g_set_shift(abl);
                            break;

                default:    // printf("Unknown key: '%c'\n", ch);
                            break;
            }
        }

        pixmap_copy(draw, grid, 0, 0);
        if (opt_lpf)
            adc_capture(ab, CAP_LPF, N_DEC-1, 0, &a0, &a1, &a2, &a3);
        else
            adc_capture(ab, CAP_ADC, 0, 0, &a0, &a1, &a2, &a3);

        switch (opt_input) {
            case 0:     break;
            case 1:     a0 = a1; break;
            case 2:     a0 = a2; break;
            default:    a0 = a3; break;
        }

        // Convert samples to [-1.0,1.0)
        for(i=0; i<xs*2; i++)
            in[i] = ((double)a0[i]) / 128.0;

        // Take an FFT
        fftw_execute(plan);

        cpv = pav[navg];
        if (++navg == avg)
            navg = 0;
        if (tavg < avg)
            tavg++;

        // Get power in dB, reference is arbitrary
        //
        for(i=0; i<=xs; i++) {
            cpv[i] = out[i][0]*out[i][0] + out[i][1]*out[i][1];
            cpv[i] /= (double) xs * xs;
            if (cpv[i] <= 0.0)
                cpv[i] = -100.0;
            else
                cpv[i] = 10.0 * log10(cpv[i]);
        }

        // Average history values.
        //
        for(x=0; x<=xs; x++) {
            double v = 0.0;
            for(i=0; i<tavg; i++)
                v += pav[i][x];
            pv[x] = v / (double) tavg;
        }

        // Find marker (highest peak)
        //
        if (mark_fix) {
            mark_l = pv[mark_f];
        } else {
            mark_l = pv[0];
            mark_f = 0;
            for(x=1; x<=xs; x++) 
                if (pv[x] > mark_l) {
                    mark_l = pv[x];
                    mark_f = x;
                }
        }

        // Convert dB value into pixel position
        //
        for(x=0; x<=xs; x++) 
            ipv[x] = - (int) (ppdb*pv[x] + 0.5);
            if (ipv[x] < 0)
                ipv[x] = 0;
            if (ipv[x] >= ys)
                ipv[x] = ys-1;

        // Calculate max-hold
        //
        if (tavg == avg) 
            for(x=0; x<=xs; x++)
                if (ipv[x] < max[x])
                    max[x] = ipv[x];

        // Draw trace
        //
        for(x=0; x<xs; x++) 
            segment_f(draw, fg, x, ipv[x], ipv[x+1]);
        if (opt_max)
            for(x=0; x<xs-1; x++) 
                segment_f(draw, maxc, x, max[x], max[x+1]);

        // Draw marker diamond
        //
        my = ipv[mark_f];
        if (my >= ys)
            my = ys-1;
        draw_marker(draw, mark_f, my);

        // Draw marker text
        //
        if (opt_lpf)
            mf = opt_adcfreq / N_DEC * 0.5 * ((double) mark_f) / 
                    ((double) xs) + mix_freq() + opt_goff;
        else
            mf = opt_adcfreq * 0.5 * ((double) mark_f) / ((double) xs) + 
                opt_goff;
        sprintf(fstr, "%sarker: %0.1f dBc @ %0.2f MHz", 
                mark_fix ? "Manual m" : "m", mark_l, mf);
        string(fstr, 14, fg, 192, draw, 10, 20);

        if (opt_lpf) {
            sprintf(fstr, "Mixer %.3f MHz", mix_freq() + opt_goff);
            string(fstr, 14, fg, 192, draw, 10, 36);
        }

        // Put pixmap in frame buffer
        //
        pixmap_copy(gr,draw,0,0);
    }

    // Free up FFT space
    fftw_destroy_plan(plan);
    fftw_free(in);
    fftw_free(out);
    for(i=0; i<avg; i++)
        fftw_free(pav[i]);
    fftw_free(pav);
    fftw_free(max);
    fftw_free(pv);
    fftw_free(ipv);
    pixmap_close();
}

//  Take ADC samples of a channel and make a graph of
//  power spectrum of a complex FFT of an ADC channel.
//
void
do_cfreq(Ab **abl)
{
    int             x, xs, i;
    s_char          *a0, *a1, *a2, *a3;
    int             border;
    pixmap          *gr;
    pixmap          *draw;
    pixmap          *grid;
    int             navg, tavg;

    fftw_complex    *in;
    fftw_complex    *out;
    double          *pv;
    int             *ipv;
    double          *cpv;
    double          **pav;
    fftw_plan       plan;
    int             *max;
    int             mark_f=0;
    double          mark_l;
    char            fstr[80];
    int             my;

    pixel           bg  = COLOR(64,64,64);
    pixel           fg  = COLOR(0,255,0);
    pixel           gc  = COLOR(128,128,128);
    pixel           maxc  = COLOR(255,0,0);

    int             mark_fix=0;
    int             ys=400;
    int             avg=opt_avg;
    double          ppdb = 5.0;     // pixels per dB
    Ab              *ab = abl[opt_beam];
    double          mf = 0.0;

    if (!ab) {
        printf("Beam %d does not exist\n", opt_beam);
        exit(0);
    }

    if (opt_ppdb > 0)
        ppdb = opt_ppdb;
    // Find largest power of 2 that fits on screen
    for(i=30; i>=0; i--) 
        if (fb->xs >> i)
            break;
    xs = 1 << i;
    border = (fb->xs - xs)/2;

    gr = pixmap_subset(fb, border, 50, fb->xs-2*border, ys);
    draw = pixmap_dup(gr);
    grid = pixmap_dup(gr);

    // Make background grid
    //
    pixmap_setcolor(grid, bg);
    for(i=0; i<xs; i+=xs/8) 
        pixmap_setcolor_rect(grid, gc, i, 0, 1, ys);
    pixmap_setcolor_rect(grid, gc, xs-1, 0, 1, ys);
    for(i=0; i<ys; i+= ppdb*10)
        pixmap_setcolor_rect(grid, gc, 0, i, xs, 1);
    pixmap_copy(gr, grid, 0, 0);

    // Prepare for FFTs, do FFTs twice the width of the screen
    // since we're just looking at power spectrum of real FFT
    // only N/2+1 values of the result are useful.
    //
    in = fftw_malloc(sizeof(fftw_complex) * xs);
    out = fftw_malloc(sizeof(fftw_complex) * xs);
    pv = fftw_malloc(sizeof(double) * xs);
    ipv = fftw_malloc(sizeof(int) * xs);
    pav = fftw_malloc(sizeof(double *) * avg);
    max = fftw_malloc(sizeof(double) * xs);
    for(i=0; i<xs; i++)
        max[i] = ys;
    for(i=0; i<avg; i++)
        pav[i] = fftw_malloc(sizeof(double) * xs);
    plan = fftw_plan_dft_1d(xs, in, out, FFTW_FORWARD, FFTW_ESTIMATE);
    tavg = 0;
    navg = 0;

    while (1) {
        while (kbhit()) {
            int ch;
            ch = readch();
            switch (ch) {
                // Make plot file
                //
                case 'p':   screen_print(fb);
                            break;

                // Exit program
                //
                case 0x03:
                case 'q':   release_lock();
                            gexit(1);

                // Toggle max-hold
                //
                case 'r':   opt_max = !opt_max;
                            if (opt_max) 
                                for(x=0; x<xs; x++)
                                    max[x] = ys;
                            break;

                // Manually move marker
                //
                case 'n':   if (--mark_f < 0)
                                mark_f = 0;
                            mark_fix = 1;
                            break;
                case 'm':   if (++mark_f >= xs)
                                mark_f = xs-1;
                            mark_fix = 1;
                            break;
                case 'b':   mark_fix = 0;
                            break;

                case 'w':   ++opt_mix;
                            g_set_shift(abl);
                            break;

                default:    // printf("Unknown key: '%c'\n", ch);
                            break;
            }
        }

        pixmap_copy(draw, grid, 0, 0);
        if (opt_lpf)
            adc_capture(ab, CAP_LPF, N_DEC-1, 0, &a0, &a1, &a2, &a3);
        else
            adc_capture(ab, CAP_ADC, 0, 0, &a0, &a1, &a2, &a3);

        if (opt_input) {
            a0 = a2;
            a1 = a3;
        }

        // Convert samples to [-1.0,1.0)
        for(i=0; i<xs; i++) {
            in[i][0] = ((double) ((double)a0[i])) / 128.0;
            in[i][1] = ((double) ((double)a1[i])) / 128.0;
        }

        // Take an FFT
        fftw_execute(plan);

        cpv = pav[navg];
        if (++navg == avg)
            navg = 0;
        if (tavg < avg)
            tavg++;

        // Get power in dB, reference is arbitrary
        for(i=0; i<xs; i++) {
            cpv[i] = out[i][0]*out[i][0] + out[i][1]*out[i][1];
            cpv[i] /= (double) xs*xs;
            if (cpv[i] <= 0.0)
                cpv[i] = -100.0;
            else
                cpv[i] = 10.0 * log10(cpv[i]);
        }

        // Average history values.
        //
        for(x=0; x<xs; x++) {
            register double v = 0;
            for(i=0; i<tavg; i++)
                v += pav[i][x];
            v = v / (double) tavg;
            if (x < xs/2)
                pv[x+xs/2] = v;
            else 
                pv[x-xs/2] = v;
        }

        // Find marker (highest peak), skip DC, not so interesting
        //
        if (mark_fix) {
            mark_l = pv[mark_f];
        } else {
            mark_l = pv[0];
            mark_f = 0;
            for(x=1; x<xs; x++) {
                if (pv[x] > mark_l) {
                    mark_l = pv[x];
                    mark_f = x;
                }
            }
        }

        // Convert dB value into pixel position and story in
        // history array for running average.
        //
        for(x=0; x<xs; x++) {
            register int     vv;
            vv = - (int) (ppdb*pv[x] + 0.5);
            if (vv < 0)
                vv = 0;
            if (vv >= ys)
                vv = ys-1;
            ipv[x] = vv;
        }

        // Calculate max-hold
        //
        if (tavg == avg) 
            for(x=0; x<=xs; x++)
                if (ipv[x] < max[x])
                    max[x] = ipv[x];

        // Draw trace
        //
        for(x=0; x<xs-1; x++) 
            segment_f(draw, fg, x, ipv[x], ipv[x+1]);
        if (opt_max)
            for(x=0; x<xs-1; x++) 
                segment_f(draw, maxc, x, max[x], max[x+1]);

        // Draw marker diamond
        //
        my = ipv[mark_f];
        if (my >= ys)
            my = ys-1;
        draw_marker(draw, mark_f, my);

        // Draw marker next
        //
        if (opt_lpf)
            mf = opt_adcfreq / N_DEC * ((double) (mark_f-xs/2)) / 
                    ((double) xs) + mix_freq() + opt_goff;
        else
            mf = opt_adcfreq * ((double) (mark_f-xs/2)) / ((double) xs) + 
                opt_goff;
        sprintf(fstr, "%sarker: %0.1f dBc @ %0.2f MHz", 
                mark_fix ? "Manual m" : "m", mark_l, mf);
        string(fstr, 14, fg, 192, draw, 10, 20);

        if (opt_lpf) {
            sprintf(fstr, "Mixer %.3f MHz", mix_freq() + opt_goff);
            string(fstr, 14, fg, 192, draw, 10, 36);
        }
    
        // Put pixmap in frame buffer
        //
        pixmap_copy(gr,draw,0,0);
    }

    // Free up FFT space
    fftw_destroy_plan(plan);
    fftw_free(in);
    fftw_free(out);
    for(i=0; i<avg; i++)
        fftw_free(pav[i]);
    fftw_free(pav);
    fftw_free(max);
    fftw_free(pv);
    fftw_free(ipv);
    pixmap_close();
}

//  Take ADC samples and do an oscilloscope graph
//  of 4-channel of ADC data.
//
void
do_graph(Ab **abl)
{
    int         x, i;
    s_char      *a0, *a1, *a2, *a3;
    pixmap      *pm_wave[2], *pm_wave_draw[2], *pm_wave_bg;
    pixmap      *pm_hist[2], *pm_hist_draw[2], *pm_hist_bg;
    int         xo, yo;
    int         hist0[256], hist1[256], hist2[256], hist3[256];
    s_char      **hhist0, **hhist1, **hhist2, **hhist3;
    int         max0, max1, max2, max3;
    int         navg, tavg;
    char        fstr[80];

    pixel       bg  = COLOR(96,96,96);
    pixel       lc  = COLOR(192,192,192);
    pixel       fg0 = COLOR(0,255,0);
    pixel       fg1 = COLOR(255,0,0);

    int         xs=256;
    int         wave_ys=256;
    int         hist_ys=128;
    int         wspac=10;

    double      sum0, sum1, sum2, sum3;
    double      ssq0, ssq1, ssq2, ssq3;
    double      p0, p1, p2, p3;
    int         tot0, tot1, tot2, tot3;
    Ab          *ab = abl[opt_beam];
    int         slen=ab->mbus_len/4;

    if (!ab) {
        printf("Beam %d does not exist\n", opt_beam);
        exit(0);
    }
    
    hhist0 = (s_char **) malloc(sizeof(s_char *) * opt_avg);
    hhist1 = (s_char **) malloc(sizeof(s_char *) * opt_avg);
    hhist2 = (s_char **) malloc(sizeof(s_char *) * opt_avg);
    hhist3 = (s_char **) malloc(sizeof(s_char *) * opt_avg);
    for(i=0; i<opt_avg; i++) {
        hhist0[i] = (s_char *) malloc(sizeof(s_char) * slen);
        hhist1[i] = (s_char *) malloc(sizeof(s_char) * slen);
        hhist2[i] = (s_char *) malloc(sizeof(s_char) * slen);
        hhist3[i] = (s_char *) malloc(sizeof(s_char) * slen);
    }

    // Clear the screen
    pixmap_setcolor(fb, C_BLACK);

    // Make pixmaps for four windows on screen
    xo = (fb->xs - (2*xs+wspac))/2,
    yo = (fb->ys - (wave_ys+hist_ys+wspac))/2, 
    pm_wave[0] = pixmap_subset(fb, xo, yo, xs, wave_ys);
    pm_wave[1] = pixmap_subset(fb, xo+xs+wspac, yo, xs, wave_ys);
    pm_hist[0] = pixmap_subset(fb, xo, yo+wave_ys+wspac, xs, hist_ys);
    pm_hist[1] = pixmap_subset(fb, xo+xs+wspac, yo+wave_ys+wspac, xs, hist_ys);

    // Off screen buffers for drawing and background
    pm_wave_draw[0] = pixmap_dup(pm_wave[0]);
    pm_wave_draw[1] = pixmap_dup(pm_wave[1]);
    pm_wave_bg = pixmap_dup(pm_wave[0]);
    pm_hist_draw[0] = pixmap_dup(pm_hist[0]);
    pm_hist_draw[1] = pixmap_dup(pm_hist[1]);
    pm_hist_bg = pixmap_dup(pm_hist[0]);

    // Put something in background
    pixmap_setcolor(pm_wave_bg, bg);
    pixmap_setcolor_rect(pm_wave_bg, lc, 0, 0, 
            pm_wave_bg->xs, 1);
    pixmap_setcolor_rect(pm_wave_bg, lc, 0, pm_wave_bg->ys/2, 
            pm_wave_bg->xs, 1);
    pixmap_setcolor_rect(pm_wave_bg, lc, 0, pm_wave_bg->ys-1, 
            pm_wave_bg->xs, 1);
    pixmap_setcolor_rect(pm_wave_bg, lc, 0, 0, 
            1, pm_wave_bg->ys);
    pixmap_setcolor_rect(pm_wave_bg, lc, pm_wave_bg->xs-1, 0, 
            1, pm_wave_bg->ys);
    pixmap_setcolor(pm_hist_bg, bg);
    pixmap_setcolor_rect(pm_hist_bg, lc, 0, 0, 
            pm_hist_bg->xs, 1);
    pixmap_setcolor_rect(pm_hist_bg, lc, 0, pm_hist_bg->ys-1, 
            pm_hist_bg->xs, 1);
    pixmap_setcolor_rect(pm_hist_bg, lc, 0, 0, 
            1, pm_hist_bg->ys);
    pixmap_setcolor_rect(pm_hist_bg, lc, pm_hist_bg->xs/2, 0, 
            1, pm_hist_bg->ys);
    pixmap_setcolor_rect(pm_hist_bg, lc, pm_hist_bg->xs-1, 0, 
            1, pm_hist_bg->ys);

    navg = 0;
    tavg = 0;

    while (1) {
        if (tavg < opt_avg)
            tavg++;

        while (kbhit()) {
            int ch;
            ch = readch();
            switch (ch) {
                // Make plot file
                //
                case 'p':   screen_print(fb);
                            break;

                // Exit program
                //
                case 0x03:
                case 'q':   release_lock();
                            gexit(1);

                case 'w':   ++opt_mix;
                            g_set_shift(abl);
                            break;

                default:    // printf("Unknown key: '%c'\n", ch);
                            break;
            }
        }

        // Copy backgrounds in drawing area
        //
        pixmap_copy(pm_wave_draw[0], pm_wave_bg, 0, 0);
        pixmap_copy(pm_wave_draw[1], pm_wave_bg, 0, 0);
        pixmap_copy(pm_hist_draw[0], pm_hist_bg, 0, 0);
        pixmap_copy(pm_hist_draw[1], pm_hist_bg, 0, 0);

        if (opt_lpf)
            adc_capture(ab, CAP_LPF, N_DEC-1, 0, &a0, &a1, &a2, &a3);
        else
            adc_capture(ab, CAP_ADC, 0, 0, &a0, &a1, &a2, &a3);

        // Feeble attempt to trigger off first channel
        i = 0;
        if (!opt_ovftrig) {
            for(i=2; i<slen-xs-2; i++)
                if (a0[i-2]>0 && a0[i-1]>0 && a0[i+1]<0 && a0[i+2]<0) 
                    break;
        }
        for(x=0; x<xs; x++) {
            segment(pm_wave_draw[0], fg1, x, a1[x+i]+128, a1[x+i+1]+128);
            segment(pm_wave_draw[0], fg0, x, a0[x+i]+128, a0[x+i+1]+128);
        }

        // Feeble attempt to trigger off third channel
        i = 0;
        if (!opt_ovftrig) {
            for(i=2; i<slen-xs-2; i++)
                if (a2[i-2]>0 && a2[i-1]>0 && a2[i+1]<0 && a2[i+2]<0) 
                    break;
        }
        for(x=0; x<xs; x++) {
            segment(pm_wave_draw[1], fg1, x, a3[x+i]+128, a3[x+i+1]+128);
            segment(pm_wave_draw[1], fg0, x, a2[x+i]+128, a2[x+i+1]+128);
        }

        // Copy samples into histogram history
        for(i=0; i<slen; i++) {
            hhist0[navg][i] = a0[i];
            hhist1[navg][i] = a1[i];
            hhist2[navg][i] = a2[i];
            hhist3[navg][i] = a3[i];
        }

        // Clear histogram
        for(i=0; i<256; i++) {
            hist0[i] = 0;
            hist1[i] = 0;
            hist2[i] = 0;
            hist3[i] = 0;
        }
        // Sum histogram
        for(x=0; x<tavg; x++) {
            register s_char *h0 = hhist0[x];
            register s_char *h1 = hhist1[x];
            register s_char *h2 = hhist2[x];
            register s_char *h3 = hhist3[x];
            for(i=0; i<slen; i++) {
                hist0[h0[i]+128]++;
                hist1[h1[i]+128]++;
                hist2[h2[i]+128]++;
                hist3[h3[i]+128]++;
            }
        }

        // Find max value
        // Calculate sum and sum-of-squares for mean and RMS
        //
        sum0 = sum1 = sum2 = sum3 = 0;
        ssq0 = ssq1 = ssq2 = ssq3 = 0;
        tot0 = tot1 = tot2 = tot3 = 0;
        max0 = max1 = max2 = max3 = 0;
        for(i=0; i<256; i++) {
            sum0 += ((double) (i-128)) * hist0[i];
            sum1 += ((double) (i-128)) * hist1[i];
            sum2 += ((double) (i-128)) * hist2[i];
            sum3 += ((double) (i-128)) * hist3[i];

            ssq0 += ((double) (i-128)) * (i-128) * hist0[i];
            ssq1 += ((double) (i-128)) * (i-128) * hist1[i];
            ssq2 += ((double) (i-128)) * (i-128) * hist2[i];
            ssq3 += ((double) (i-128)) * (i-128) * hist3[i];

            // These should all be the same and equal to
            // opt_avg * slen...
            // 
            tot0 += hist0[i];
            tot1 += hist1[i];
            tot2 += hist2[i];
            tot3 += hist3[i];

            if (hist0[i] > max0)
                max0 = hist0[i];
            if (hist1[i] > max1)
                max1 = hist1[i];
            if (hist2[i] > max2)
                max2 = hist2[i];
            if (hist3[i] > max3)
                max3 = hist3[i];
        }

        p0 = 1.0 / 256.0 * sqrt(ssq0 / tot0);
        p1 = 1.0 / 256.0 * sqrt(ssq1 / tot0);
        p2 = 1.0 / 256.0 * sqrt(ssq2 / tot0);
        p3 = 1.0 / 256.0 * sqrt(ssq3 / tot0);
        p0 = 10.0 * log10(1000.0 * p0 * p0 / 50.0);
        p1 = 10.0 * log10(1000.0 * p1 * p1 / 50.0);
        p2 = 10.0 * log10(1000.0 * p2 * p2 / 50.0);
        p3 = 10.0 * log10(1000.0 * p3 * p3 / 50.0);

        // Normalize histogram values
        for(i=0; i<256; i++) {
            hist0[i] = 127 - (hist0[i] * 120 / max0);
            hist1[i] = 127 - (hist1[i] * 120 / max1);
            hist2[i] = 127 - (hist2[i] * 120 / max2);
            hist3[i] = 127 - (hist3[i] * 120 / max3);
        }

        // Draw the histograms
        for(x=0; x<255; x++) {
            segment(pm_hist_draw[0], fg1, x, hist1[x], hist1[x+1]);
            segment(pm_hist_draw[0], fg0, x, hist0[x], hist0[x+1]);
            segment(pm_hist_draw[1], fg1, x, hist3[x], hist3[x+1]);
            segment(pm_hist_draw[1], fg0, x, hist2[x], hist2[x+1]);
        }

        sprintf(fstr, "mean: %0.2f mV, %0.2f mV",
                500.0 / 128.0 * sum0 / tot0,
                500.0 / 128.0 * sum1 / tot1);
        string(fstr, 14, fg0, 192, pm_wave_draw[0], 10, 20);
        sprintf(fstr, "RMS power: %0.2f dBm, %0.2f dBm", p0, p1);
        string(fstr, 14, fg0, 192, pm_wave_draw[0], 10, 36);

        sprintf(fstr, "mean: %0.2f mV, %0.2f mV",
                500.0 / 128.0 * sum2 / tot2,
                500.0 / 128.0 * sum3 / tot3);
        string(fstr, 14, fg0, 192, pm_wave_draw[1], 10, 20);
        sprintf(fstr, "RMS power: %0.2f dBm, %0.2f dBm", p2, p3);
        string(fstr, 14, fg0, 192, pm_wave_draw[1], 10, 36);

        // Copy drawings onto screen
        //
        pixmap_copy(pm_wave[0], pm_wave_draw[0], 0, 0);
        pixmap_copy(pm_wave[1], pm_wave_draw[1], 0, 0);
        pixmap_copy(pm_hist[0], pm_hist_draw[0], 0, 0);
        pixmap_copy(pm_hist[1], pm_hist_draw[1], 0, 0);

        if (++navg >= opt_avg)
            navg = 0;
    }
}

static void
sigexit(int sig)
{
    if (getpid() == galfa_pid) {
        printf("Starting orderly exit\n");
        release_lock();
        io_close();
        gexit(1);
    } else {
        printf("Thread exit\n");
        pthread_exit(NULL);
    }
}

void
release_exit(int n)
{
    release_lock();
    exit(n);
}

int
main(int ac, char **av)
{
    Ab              **ab;
    int             i, c, index, err=0;
    int             action = opti_none;
    int             diag;

    ab = AbOpen();
    if (!ab[0]) {
        fprintf(stderr, "No boards found...\n");
        exit(1);
    }

    get_lock();

    // Scan the options
    //
    while ((c=getopt_long_only(ac, av, "", lopts, &index)) != -1) {
        switch (c) {
            case opti_adc:
            case opti_rfft:
            case opti_cfft:
            case opti_scope:
            case opti_patt:
            case opti_dump:
            case opti_galfa:
            case opti_run:
            case opti_dac:
                action = c;
                break;

            case opti_newdac:
                opt_level = strtod(optarg, NULL);
                action = c;
                break;

            case opti_vnc:
                opt_vnc = 1;
                break;
            case opti_avg:
                opt_avg = strtol(optarg, NULL, 0);
                break;
            case opti_max:
                opt_max = 1;
                break;
            case opti_input:
                opt_input = strtol(optarg, NULL, 0);
                break;
            case opti_ppdb:
                opt_ppdb = strtod(optarg, NULL);
                break;
            case opti_adcfreq:
                opt_adcfreq = strtod(optarg, NULL);
                break;
            case opti_nshift:
                opt_nshift = strtol(optarg, NULL, 0) & G_MIX_NSHIFT;
                break;
            case opti_wshift:
                opt_wshift = strtol(optarg, NULL, 0) & G_MIX_WSHIFT; 
                break;
            case opti_npfb:
                opt_npfb = strtol(optarg, NULL, 0) & G_MIX_NPFB;
                break;
            case opti_wpfb:
                opt_wpfb = strtol(optarg, NULL, 0) & G_MIX_WPFB;
                break;
            case opti_beam:
                opt_beam = strtol(optarg, NULL, 0) & 0x7;
                break;
            case opti_mix:
                opt_mix = strtol(optarg, NULL, 0) & G_MIX_MASK;
                break;
            case opti_goff:
                opt_goff = strtod(optarg, NULL);
                break;
            case opti_ta:
                opt_ta = strtod(optarg, NULL);
                opt_ta_use = 1;
                break;
            case opti_tb:
                opt_tb = strtod(optarg, NULL);
                opt_tb_use = 1;
                break;
            case opti_lpf:
                opt_lpf = 1;
                break;
            case opti_ppsint:
                opt_ppsint = 1;
                break;
            case opti_fn:
                opt_fn = optarg;
                break;
            case opti_time:
                opt_time = strtol(optarg, NULL, 0);
                break;
            case opti_level:
                opt_level = strtod(optarg, NULL);
                break;
            case opti_sdiv:
                opt_sdiv = strtol(optarg, NULL, 0);
                break;
            case opti_mask:
                opt_mask = strtol(optarg, NULL, 0);
                break;
            case opti_ovftrig:
                opt_ovftrig = 1;
                break;
            case opti_sock:
                opt_sock = 0;
                break;
            case opti_nofits:
                opt_nofits = 1;
                break;
            case opti_nofix:
                opt_fix = 0;
                break;
            case opti_ref:
                opt_ref = strtod(optarg, NULL);
                break;
            case opti_lo2:
                opt_setlo2 = 1;
                opt_lo2 = strtod(optarg, NULL);
                break;
            case opti_scram:
                opt_scram = 1;
                break;
            default:
                err = 1;
                break;
        }
    }
    if (err) {
        usage(av[0]);
        release_exit(1);
    }

    // Reset the board, all of the gk registers are zero.
    //
    gk_reset(ab);
    g_set_shift(ab);

    diag = 0;
    if (opt_ta_use) {
        int     v;
        v = testfreq(opt_ta);
        AbGkReg(ab, Gk_talow, v & 0xffff);
        AbGkReg(ab, Gk_tahigh, (v>>16) & 0xffff);
        diag |= 2;
    }
    if (opt_tb_use) {
        int     v;
        v = testfreq(opt_tb);
        AbGkReg(ab, Gk_tblow, v & 0xffff);
        AbGkReg(ab, Gk_tbhigh, (v>>16) & 0xffff);
        diag |= 4;
    }
    // The overflow trigger features causes a board to hold
    // off capturing time domain samples until the ADC overflows.
    // This is data dependent and cannot be used across multiple
    // beams.  The feature currently only used on the 'old' 
    // single beam diagnostics, so it's not a problem today.
    if (opt_ovftrig)
        diag |= 8;
    diag_reg = diag;
    AbGkReg(ab, Gk_diag, diag_reg);

    if (opt_mask)
        AbGkReg(ab, Gk_adc_mask, opt_mask);

    // All beams PPS external
    for(i=0; i<G_BEAMS; i++) 
            AbGkRegOne(ab, i, Gk_ppsext, 1);

    // Beam 0 gets internal pps if instructed
    if (opt_ppsint)
        AbGkRegOne(ab, 0, Gk_ppsext, 0);

    // Try to terminate orderly on certain signals
    //
    signal(SIGINT, sigexit);
    signal(SIGTERM, sigexit);
    signal(SIGSEGV, sigexit);
    signal(SIGHUP, sigexit);
    signal(SIGQUIT, sigexit);
    signal(SIGILL, sigexit);
    signal(SIGFPE, sigexit);
    signal(SIGBUS, sigexit);

    if (opt_setlo2) 
        lo2_set(opt_lo2);
    else if (action == opti_run || action == opti_galfa) {
        printf("\n\nLO2 not set (-lo2=f), cannot correctly\n");
        printf("compute center frequency of spectra.\n\n");
    }

    if (opt_scram) 
        gscram_init();
    else if (action == opti_run || action == opti_galfa) {
        printf("\n\nScramnet not enabled (-scram), cannot correctly\n");
        printf("compute center frequency of spectra or record");
        printf("telescope information.\n\n");
    }

    // Do the non graphical things
    //
    switch (action) {
        case opti_none:
            printf("No primary operation specified.\n");
            usage(av[0]);
            release_exit(1);
        case opti_adc:
            adc_test(ab);
            release_exit(0);
        case opti_patt:
            patt_test(ab);
            release_exit(0);
        case opti_dump:
            galfa_dump(ab);
            release_exit(0);
        case opti_run:
            galfa_run(ab);
            release_exit(0);
        case opti_dac:
            set_levels(ab);
            release_exit(0);
        case opti_newdac:
            set_levels_new(ab);
            release_exit(0);
    }

    // Get setup for graphics
    //
    if (opt_vnc) {
        pixmap_init_vnc(&ac, av, 800,600);
        printf("Running in VNC frame buffer.\n");
    } else {
        pixmap_init();
        tty_to_raw();
    }
    if (FT_Init_FreeType( &library )) {
        fprintf(stderr, "Cannot init freetype library.\n");
        gexit(1);
    }
    if (FT_New_Face(library, "/etc/FreeSans.ttf", 0, &regface)) {
        fprintf(stderr, "Cannot open typeface.\n");
        gexit(1);
    }

    // Do graphical things
    //
    switch (action) {
        case opti_rfft:
            do_freq(ab);
            break;
        case opti_cfft:
            do_cfreq(ab);
            break;
        case opti_scope:
            do_graph(ab);
            break;
        case opti_galfa:
            galfa_scope(ab, gmode_wscope);
            break;
        default:
            break;
    }
    release_lock();
    gexit(0);
    return 0;
}

