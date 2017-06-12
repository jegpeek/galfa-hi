

#include "ab.h"
#include "pixmap.h"
#include <math.h>
#include <fftw3.h>
#include <sys/time.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

typedef signed char s_char;

// There are now version of the 2v1000 Xilinx code with two different
// PCI aperature sizes.  The original code has four 8kbyte buffers
// for collected data.  The newer version has four 16kbyte buffers
// and a new mode for aquiring word-oriented data as well as byte oriented
// data.
//
// Rather than use a constant for the size of the buffers, the ab.c
// code reads the PCI configuration register and records the aperature
// size in ab->mbus_len. So, these constants aren't used and xload
// will work with both versions of 2v1000 code.
//
// #define SAMP_LEN    16384           // Number of samples in mbuf
// #define SZ          (65536>>2)      // Number of words of PCI buffer mem

#define CAP_ADC     0               // Capture ADC samples in mbuf
#define CAP_PFB     1               // Capture PFB samples in mbuf

#define PFB_BINS    32
#define DEF_ADC_FREQ    100.0       // in MHz

int     opt_fftsz = 8192;           // FFT size of -yg mode
int     opt_avg = 5;                // averaging for freq displays
int     opt_max = 0;                // max hold on freq displays
int     opt_input = 0;              // ADC input
double  opt_ppdb = 0.0;             // pixels per dB option
double  adc_freq = DEF_ADC_FREQ;

static FT_Library   library;
static FT_Face      regface;

// Read framebuffer (or pixmap) and write raw image
// to a file as RGB bytes.
//
void
screen_print(pixmap *p)
{
    static int      fnum = 1;
    char            fn[80];
    struct stat     buf;
    FILE            *fp;
    u_char          pix[3];
    pixel           *pp;
    int             x, y;

    do 
        sprintf(fn, "/tmp/pic-%04d.img", fnum++);
    while (!stat(fn, &buf));
    printf("Writing %dx%d raw RGB image to %s.\n",
            p->xs, p->ys, fn);

    fp = fopen(fn, "wb");
    pp = p->buf;
    for(y=0; y<p->ys; y++) {
        for(x=0; x<p->xs; x++) {
            pix[0] = (pp[x] & 0xf800) >> 8;
            pix[1] = (pp[x] & 0x07e0) >> 3;
            pix[2] = (pp[x] & 0x001f) << 3;
            fwrite(pix, 3, 1, fp);
        }
        pp += p->stride;
    }
    fclose(fp);
}

//  Use freetype to render a string into a pixmap 
//
void
txt_str(char *cp, int sz, pixel c, alpha a, pixmap *pm, int x, int y)
{
    FT_GlyphSlot    slot;
 
    if (!cp)
        return;
                    
    if (FT_Set_Pixel_Sizes(regface, 0, sz)) {
        fprintf(stderr, "FT_Set_Pixel_Sizes error\n");
        gexit(1);
    }
    slot = regface->glyph;

    for( ; *cp; cp++) {
        if (FT_Load_Char( regface, *cp, FT_LOAD_RENDER ))
            continue;
        draw_text_color(pm, &slot->bitmap,
            x + slot->bitmap_left,
            y - slot->bitmap_top,
            c, a);
        x += slot->advance.x >> 6;
    }
}

//  Current time as real number
//
double
rtime(void)
{
    struct timeval tv;

    gettimeofday(&tv, NULL);
    return ((double) tv.tv_sec) + ((double) tv.tv_usec)/1000000.0;
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

//  Do capture on PCI bus.  This might be ADC samples or PFB samples
//  or maybe something else selected by msel
//
void
adc_capture(Ab *ab, int msel, int dec_n, int dec_off, 
        u_char **a0, u_char **a1, u_char **a2, u_char **a3)
{
    int             j;

    for(j=0; j<ab->mbus_len/4; j++)
        ab->mbus[j] = 0;

    // Start capture
    ab->ctl[4] = (dec_off & 0xff) | ((dec_n & 0xff) << 8);
    ab->ctl[0] = 0x4 | ((msel & 0x3) << 3);
    ab->ctl[0] = 0x0 | ((msel & 0x3) << 3);

    // Wait for capture to finish 
    // printf("cap start\n");
    while (!(ab->ctl[2] & 0x8))
        ;
    // printf("cap stop\n");

    *a0 = ((u_char *) ab->mbus) + 0*ab->mbus_len/4;
    *a1 = ((u_char *) ab->mbus) + 1*ab->mbus_len/4;
    *a2 = ((u_char *) ab->mbus) + 2*ab->mbus_len/4;
    *a3 = ((u_char *) ab->mbus) + 3*ab->mbus_len/4;
}

//  Test virtex-2 blockrams mapped into the PCI address space.
//  
void
mbus_memtest(Ab *ab)
{
    int             i;
    int             pass;
    int             seed;
    int             v, rv;

    printf ("Testing %lu byte window\n", ab->mbus_len);
    for(pass=1; pass<=100000; pass++) {
        for(i=0; i<ab->mbus_len; i++) {
            ab->mbus[i] = 0;
        }
        for(i=0; i<ab->mbus_len; i++) {
            rv = ab->mbus[i];
            if (0 != rv) {
                fprintf(stderr, "Zero: pass:%d inx:%d r:%08x\n",
                        pass, i, rv);
            }
        }

        seed = time(0);
        srand(seed);
        for(i=0; i<ab->mbus_len; i++) {
            v = rand();
            ab->mbus[i] = v;
        }
        srand(seed);
        for(i=0; i<ab->mbus_len; i++) {
            rv = ab->mbus[i];
            v = rand();
            if (v != rv) {
                fprintf(stderr, "Err1: pass:%d inx:%d w:%08x r:%08x\n",
                        pass, i, v, rv);
            }
        }
        srand(seed);
        for(i=0; i<ab->mbus_len; i++) {
            rv = ab->mbus[i];
            v = rand();
            if (v != rv) {
                fprintf(stderr, "Err2: pass:%d inx:%d w:%08x r:%08x\n",
                        pass, i, v, rv);
            }
        }
        if ((pass%100) == 0)
            printf("Pass %d complete.\n", pass);
    }
}

//  Just grab 8k ADC samples and print them 
//
void
adc_test(Ab *ab)
{
    int             j;
    u_char          *adc0;
    u_char          *adc1;
    u_char          *adc2;
    u_char          *adc3;

    adc_capture(ab, CAP_ADC, 0, 0, &adc0, &adc1, &adc2, &adc3);
    for(j=0; j<ab->mbus_len/4; j++)
        printf("%3d %3d %3d %3d\n", adc0[j], adc1[j], adc2[j], adc3[j]);
    exit(0);
}

void
draw_marker(pixmap *draw, int mx, int my)
{
    pixel   white = COLOR(255,255,255);
    int     n = 5;
    int     i;

    for(i=0; i<n; i++) {
        pixmap_setcolor_rect(draw, white, mx+i,    my+n-i, 1, 1);
        pixmap_setcolor_rect(draw, white, mx-n+i,  my+i, 1, 1);
        pixmap_setcolor_rect(draw, white, mx-i,    my-n+i, 1, 1);
        pixmap_setcolor_rect(draw, white, mx+n-i,  my-i, 1, 1);
    }
}


#define BUFSZ   (4*(1<<20))

int 
doload(Ab *ab, int skip)
{
    Ab              *abt;
    u_char          *buf;
    int             sz, szt;
    int             err;

    if (!ab) {
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
    for(abt=ab; abt; abt=abt->next) {
        err |= AbLoad(abt, skip, buf, sz);
        pfb_reset(abt);
    }
    free(buf);
    return err;
}

static void inline
segment(pixmap *draw, pixel fg, int x, u_char p1, u_char p2)
{
    if (p1 < p2) 
        pixmap_setcolor_rect(draw, fg, x, p1, 1, p2-p1);
    else if (p1 > p2) 
        pixmap_setcolor_rect(draw, fg, x, p2, 1, p1-p2);
    else
        pixmap_setcolor_rect(draw, fg, x, p1, 1, 1);
}

static void inline
segment_f(pixmap *draw, pixel fg, int x, int p1, int p2)
{
    if (p1 < p2) 
        pixmap_setcolor_rect(draw, fg, x, p1, 1, p2-p1);
    else if (p1 > p2) 
        pixmap_setcolor_rect(draw, fg, x, p2, 1, p1-p2);
    else
        pixmap_setcolor_rect(draw, fg, x, p1, 1, 1);
}

//  Take ADC samples of a channel and make a graph of
//  power spectrum of read FFT of an ADC channel.
//
void
do_freq(Ab *ab)
{
    int             x, xs, i;
    u_char          *a0, *a1, *a2, *a3;
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
    double          t1, t2;
    int             mark_f=0;
    double          mark_l;
    char            fstr[80];
    int             my;

    int             mark_fix=0;
    int             loops=10000;
    int             ys=400;
    int             avg=opt_avg;
    double          ppdb = 5.0;     // pixels per dB

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

    t1 = rtime();
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
                case 'q':   gexit(1);

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

                default:    // printf("Unknown key: '%c'\n", ch);
                            break;
            }
        }

        pixmap_copy(draw, grid, 0, 0);
        adc_capture(ab, CAP_ADC, 0, 0, &a0, &a1, &a2, &a3);

        switch (opt_input) {
            case 0:     break;
            case 1:     a0 = a1; break;
            case 2:     a0 = a2; break;
            default:    a0 = a3; break;
        }

        // Convert samples to [-1.0,1.0)
        for(i=0; i<xs*2; i++)
            in[i] = ((double) (((int)a0[i]) - 128)) / 128.0;

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
            pv[x] = v / (double) tavg - 60.0;
        }

        // Find marker (highest peak), skip DC, not so interesting
        //
        if (mark_fix) {
            mark_l = pv[mark_f];
        } else {
            mark_l = pv[1];
            mark_f = 1;
            for(x=2; x<=xs; x++) 
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
        sprintf(fstr, "Marker: %0.1f dBc @ %0.2f MHz", 
                mark_l, adc_freq * 0.5 * ((double) mark_f) / ((double) xs));
        txt_str(fstr, 14, fg, 192, draw, 10, 20);

        // Put pixmap in frame buffer
        //
        pixmap_copy(gr,draw,0,0);
    }
    t2 = rtime();
    t1 = ((double)loops)/(t2-t1);
    printf("%g fps\n", t1);

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
do_cfreq(Ab *ab)
{
    int             x, xs, i;
    u_char          *a0, *a1, *a2, *a3;
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
    double          t1, t2;

    int             mark_fix=0;
    int             loops=10000;
    int             ys=400;
    int             avg=opt_avg;
    double          ppdb = 5.0;     // pixels per dB

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

    t1 = rtime();
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
                case 'q':   gexit(1);

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

                default:    // printf("Unknown key: '%c'\n", ch);
                            break;
            }
        }

        pixmap_copy(draw, grid, 0, 0);
        adc_capture(ab, CAP_ADC, 0, 0, &a0, &a1, &a2, &a3);

        if (opt_input) {
            a0 = a2;
            a1 = a3;
        }

        // Convert samples to [-1.0,1.0)
        for(i=0; i<xs; i++) {
            in[i][0] = ((double) (((int)a0[i]) - 128)) / 128.0;
            in[i][1] = ((double) (((int)a1[i]) - 128)) / 128.0;
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
            v = v / (double) tavg - 40.0;
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
                if (x == xs/2)
                    continue;
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
        sprintf(fstr, "%sarker: %0.1f dBc @ %0.2f MHz", 
                mark_fix ? "Manual m" : "m",
                mark_l,
                adc_freq * ((double) (mark_f-xs/2)) / ((double) xs));
        txt_str(fstr, 14, fg, 192, draw, 10, 20);

        // Put pixmap in frame buffer
        //
        pixmap_copy(gr,draw,0,0);
    }
    t2 = rtime();
    t1 = ((double)loops)/(t2-t1);
    printf("%g fps\n", t1);

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
do_graph(Ab *ab)
{
    int         x, i;
    u_char      *a0, *a1, *a2, *a3;
    pixmap      *pm_wave[2], *pm_wave_draw[2], *pm_wave_bg;
    pixmap      *pm_hist[2], *pm_hist_draw[2], *pm_hist_bg;
    int         xo, yo;
    int         hist0[256], hist1[256], hist2[256], hist3[256];
    u_char      **hhist0, **hhist1, **hhist2, **hhist3;
    int         max0, max1, max2, max3;
    int         navg, tavg;
    char        fstr[80];

    pixel       bg  = COLOR(96,96,96);
    pixel       lc  = COLOR(192,192,192);
    pixel       fg0 = COLOR(0,255,0);
    pixel       fg1 = COLOR(255,0,0);

    int         slen=ab->mbus_len/4;
    int         xs=256;
    int         wave_ys=256;
    int         hist_ys=128;
    int         wspac=10;

    double      sum0, sum1, sum2, sum3;
    double      ssq0, ssq1, ssq2, ssq3;
    double      p0, p1, p2, p3;
    int         tot0, tot1, tot2, tot3;
    
    hhist0 = (uchar **) malloc(sizeof(u_char *) * opt_avg);
    hhist1 = (uchar **) malloc(sizeof(u_char *) * opt_avg);
    hhist2 = (uchar **) malloc(sizeof(u_char *) * opt_avg);
    hhist3 = (uchar **) malloc(sizeof(u_char *) * opt_avg);
    for(i=0; i<opt_avg; i++) {
        hhist0[i] = (u_char *) malloc(sizeof(u_char) * slen);
        hhist1[i] = (u_char *) malloc(sizeof(u_char) * slen);
        hhist2[i] = (u_char *) malloc(sizeof(u_char) * slen);
        hhist3[i] = (u_char *) malloc(sizeof(u_char) * slen);
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
                case 'q':   gexit(1);

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

        adc_capture(ab, CAP_ADC, 0, 0, &a0, &a1, &a2, &a3);

        // Feeble attempt to trigger off first channel
        for(i=2; i<slen-xs-2; i++)
            if (a0[i-2]>128 && a0[i-1]>128 && a0[i+1]<128 && a0[i+2]<128) 
                break;
        for(x=0; x<xs; x++) {
            segment(pm_wave_draw[0], fg1, x, a1[x+i], a1[x+i+1]);
            segment(pm_wave_draw[0], fg0, x, a0[x+i], a0[x+i+1]);
        }

        // Feeble attempt to trigger off third channel
        for(i=2; i<slen-xs-2; i++)
            if (a2[i-2]>128 && a2[i-1]>128 && a2[i+1]<128 && a2[i+2]<128) 
                break;
        for(x=0; x<xs; x++) {
            segment(pm_wave_draw[1], fg1, x, a3[x+i], a3[x+i+1]);
            segment(pm_wave_draw[1], fg0, x, a2[x+i], a2[x+i+1]);
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
            register u_char *h0 = hhist0[x];
            register u_char *h1 = hhist1[x];
            register u_char *h2 = hhist2[x];
            register u_char *h3 = hhist3[x];
            for(i=0; i<slen; i++) {
                hist0[h0[i]]++;
                hist1[h1[i]]++;
                hist2[h2[i]]++;
                hist3[h3[i]]++;
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

#if 0
        {
            double      v0, v1, v2, v3;


            printf("m: %.2f %.2f %.2f %.2f  rms: %.2f %.2f %.2f %.2f\n",
                500.0 / 128.0 * sum0 / tot0,
                500.0 / 128.0 * sum1 / tot1,
                500.0 / 128.0 * sum2 / tot2,
                500.0 / 128.0 * sum3 / tot3,
                10.0 * log10(1000.0 * v0 * v0 / 50.0),
                10.0 * log10(1000.0 * v1 * v1 / 50.0),
                10.0 * log10(1000.0 * v2 * v2 / 50.0),
                10.0 * log10(1000.0 * v3 * v3 / 50.0));
                // v0 * 1000.0,
                // v1 * 1000.0,
                // v2 * 1000.0,
                // v3 * 1000.0);
            

        }
#endif

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
        txt_str(fstr, 14, fg0, 192, pm_wave_draw[0], 10, 20);
        sprintf(fstr, "RMS power: %0.2f dBm, %0.2f dBm", p0, p1);
        txt_str(fstr, 14, fg0, 192, pm_wave_draw[0], 10, 36);

        sprintf(fstr, "mean: %0.2f mV, %0.2f mV",
                500.0 / 128.0 * sum2 / tot2,
                500.0 / 128.0 * sum3 / tot3);
        txt_str(fstr, 14, fg0, 192, pm_wave_draw[1], 10, 20);
        sprintf(fstr, "RMS power: %0.2f dBm, %0.2f dBm", p2, p3);
        txt_str(fstr, 14, fg0, 192, pm_wave_draw[1], 10, 36);

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

//  This is the fancy one.  Take PFB data and plot 3 frequency
//  bins as a time domain o-scope graph.  Then... Take a
//  complex FFT of the 256 time samples for the freq BIN and
//  plot a spectrum analyzer type display for 3 freq bins.
//
void
do_pfb_graph(Ab *ab, int ax)
{
    int             xoff, a, j, x, xs;
    int             boff;
    int             xp;
    s_char          *p1_r, *p1_i, *p2_r, *p2_i;
    pixmap          *gr, *gr2;
    pixmap          *draw, *draw2;
    pixmap          *pbg, *pbg2;
    int             p1ra, p1rb, p1ia, p1ib;
    int             mark_f = 0;
    double          mark_l = 0.0;
    int             my;
    char            fstr[80];

    double          sum0, sum1;
    double          ssq0, ssq1;
    double          p0, p1;
    int             tot0, tot1;

    pixel           bg  = COLOR(96,96,96);
    pixel           lc  = COLOR(192,192,192);
    pixel           fg0 = COLOR(0,255,0);
    pixel           fg1 = COLOR(255,0,0);
    pixel           maxc= COLOR(255,0,0);

    double          t1, t2;
    fftw_complex    *in, *out;
    double          *pow;
    fftw_plan       plan;
    double          *cpv;
    double          *pv;
    double          **pav;
    int             *ipv;
    u_char          **hbr, **hbi; 
    u_char          *hbrp, *hbip;
    int             *hbrx, *hbix;
    int             *maxv[3];
    int             *max;
    double          mf, bin_center;

    int             navg, tavg;

    int             hist_mode=0;
    int             mark_fix=0;
    int             loops=10000;
    int             points=0;
    int             border=10;
    int             slen=ab->mbus_len/4;
    int             bins=PFB_BINS;
    int             wspac=260;      // x spacing from graph to graph
    int             hspac=140;      // y spacing from graph to graph
    double          ppdb = 4.0;     // pixels per dB
    int             ysg = 128;      // y size of scope graph
    int             ysf = 256;      // y size of freq graph
    int             xsg = 256;      // x size of graphs
    int             avg = opt_avg;  // FFTs to averages

    if (opt_ppdb > 0)
        ppdb = opt_ppdb;

    pixmap_setcolor(fb, C_BLACK);
    gr = pixmap_subset(fb, border, border, fb->xs-2*border, ysg);
    draw = pixmap_dup(gr);
    pbg = pixmap_dup(gr);

    pixmap_setcolor(pbg, C_BLACK);
    for(j=0; j<3; j++) {
        pixmap_setcolor_rect(pbg, bg, wspac*j, 0, xsg, ysg);
        pixmap_setcolor_rect(pbg, lc, wspac*j, 0, xsg, 1);
        pixmap_setcolor_rect(pbg, lc, wspac*j, 127, xsg, 1);
        pixmap_setcolor_rect(pbg, lc, wspac*j, 64, xsg, 1);
        pixmap_setcolor_rect(pbg, lc, wspac*j, 0, 1, ysg);
        pixmap_setcolor_rect(pbg, lc, wspac*j+xsg/2, 0, 1, ysg);
        pixmap_setcolor_rect(pbg, lc, wspac*j+xsg-1, 0, 1, ysg);
    }

    gr2 = pixmap_subset(fb, border, border+hspac, fb->xs-2*border, ysf);
    draw2 = pixmap_dup(gr2);
    pbg2 = pixmap_dup(gr2);

    pixmap_setcolor(pbg2, C_BLACK);
    for(j=0; j<3; j++) {
        pixmap_setcolor_rect(pbg2, bg, wspac*j, 0, xsg, ysf);
        pixmap_setcolor_rect(pbg2, lc, wspac*j, 0, xsg, 1);
        pixmap_setcolor_rect(pbg2, lc, wspac*j, 0, 1, ysf);
        pixmap_setcolor_rect(pbg2, lc, wspac*j+255, 0, 1, ysf);
        for(x=0; x<xsg; x+= (int) 10.0*ppdb) 
            pixmap_setcolor_rect(pbg2, lc, wspac*j, x, xsg, 1);
        for(x=0; x<xsg; x+=xsg/4)
            pixmap_setcolor_rect(pbg2, lc, wspac*j+x, 0, 1, ysf);
    }

    xs = slen/bins;       // That's all we've got...
    if (xs > 256)
        xs = 256;         // Ignore some data on big capture buffer
    if (xs != 256) {
        fprintf(stderr, "xs botch, it's not 256...\n");
        gexit(0);
    }

    in = fftw_malloc(sizeof(fftw_complex)*xs);
    out = fftw_malloc(sizeof(fftw_complex)*xs);
    pow = fftw_malloc(sizeof(double)*xs);
    plan = fftw_plan_dft_1d(xs, in, out, FFTW_FORWARD, FFTW_ESTIMATE);
    pv = fftw_malloc(sizeof(double)*xs);
    ipv = fftw_malloc(sizeof(int)*xs);
    pav = fftw_malloc(sizeof(double *)*avg*3);
    for(j=0; j<avg*3; j++) 
        pav[j] = fftw_malloc(sizeof(double) * xs);
    for(j=0; j<3; j++) {
        maxv[j] = fftw_malloc(sizeof(int)*xs);
        max = maxv[j];
        for(x=0; x<xs; x++)
            max[x] = ysf;
    }

    // Histogram history...
    //
    hbr = fftw_malloc(sizeof(s_char *)*avg*3);
    for(j=0; j<avg*3; j++) 
        hbr[j] = fftw_malloc(sizeof(s_char) * xs);
    hbi = fftw_malloc(sizeof(s_char *)*avg*3);
    for(j=0; j<avg*3; j++) 
        hbi[j] = fftw_malloc(sizeof(s_char) * xs);
    hbrx = fftw_malloc(sizeof(int) * 256);  // Number of sample values (8-bits)
    hbix = fftw_malloc(sizeof(int) * 256);

    tavg = 0;
    navg = 0;

    t1 = rtime();
    // for(loop=0; loop<loops; loop++) {
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
                case 'q':   gexit(1);

                // Move bins left or right
                //
                case 'x':
                case 'z':   if (ch == 'z')
                                ax = (ax+1)&0x1f;
                            else
                                ax = (ax-1)&0x1f;
                            tavg = 0;
                            navg = 0;
                            for(j=0; j<3; j++) {
                                max = maxv[j];
                                for(x=0; x<xs; x++)
                                    max[x] = ysf;
                            }
                            break;

                // Toggle max-hold
                //
                case 'r':   opt_max = !opt_max;
                            if (opt_max) 
                                for(j=0; j<3; j++) {
                                    max = maxv[j];
                                    for(x=0; x<xs; x++)
                                        max[x] = ysf;
                                }
                            break;

                // Manually move marker
                // (special wrap mode for multiple freq displays)
                case 'n':   if (--mark_f < 0)
                                mark_f = xs-1;
                            mark_fix = 1;
                            break;
                case 'm':   if (++mark_f >= xs)
                                mark_f = 0;
                            mark_fix = 1;
                            break;
                case 'b':   mark_fix = 0;
                            break;

                case 'h':   hist_mode = !hist_mode;
                            break;

                default:    // printf("Unknown key: '%c'\n", ch);
                            break;
            }
        }

        pixmap_copy(draw, pbg, 0, 0);
        pixmap_copy(draw2, pbg2, 0, 0);
        adc_capture(ab, CAP_PFB, 0, 0, (void *) &p1_r, (void *) &p1_i, 
                (void *) &p2_r, (void *) &p2_i);

        if (opt_input) {
            p1_r = p2_r;
            p1_i = p2_i;
        }

        if (tavg < avg)
            tavg++;

        for(boff=0; boff<3; boff++) {
            if (boff==2) {
                a = (ax-1) & 31;
                xoff = 0;
            } else {
                a = (ax+boff) & 31;
                xoff = (boff+1)*wspac;
            }

            // Store samples in histogram history arrays
            //
            hbrp = hbr[boff*avg + navg];
            hbip = hbi[boff*avg + navg];
            for(x=0; x<xs; x++) {
                xp = x*bins;
                hbrp[x] = p1_r[xp+a] + 128;
                hbip[x] = p1_i[xp+a] + 128;
            }

            max = maxv[boff];
            if (hist_mode) {
                int     hmaxr, hmaxi;

                // Do histogram drawing in upper window
                //
                // Add together all of the histogram history bins
                for(x=0; x<xs; x++) {
                    hbrx[x] = 0;
                    hbix[x] = 0;
                }

                for(j=0; j<tavg; j++) {
                    hbrp = hbr[boff*avg + j];
                    hbip = hbi[boff*avg + j];
                    for(x=0; x<xs; x++) {
                        hbrx[hbrp[x]]++;
                        hbix[hbip[x]]++;
                    }
                }
                // hbrx and hbix have histogram
                
                // Normalize histogram
                // Calculate sum and sum-of-squares for mean and RMS
                hmaxr=0; 
                hmaxi=0; 
                sum0 = sum1 = 0;
                ssq0 = ssq1 = 0;
                tot0 = tot1 = 0;
                for(x=0; x<xs; x++) {
                    sum0 += ((double) (x-128)) * hbrx[x];
                    sum1 += ((double) (x-128)) * hbix[x];
                    ssq0 += ((double) (x-128)) * (x-128) * hbrx[x];
                    ssq1 += ((double) (x-128)) * (x-128) * hbix[x];
                    tot0 += hbrx[x];
                    tot1 += hbix[x];

                    if (hbrx[x] > hmaxr) 
                        hmaxr = hbrx[x];
                    if (hbix[x] > hmaxi) 
                        hmaxi = hbix[x];
                }
                for(x=0; x<xs; x++) {
                    hbrx[x] = 127 - (hbrx[x] * 120 / hmaxr);
                    hbix[x] = 127 - (hbix[x] * 120 / hmaxi);
                }

#define PFB_GAIN 8

                p0 = 1.0 / 256.0 * sqrt(ssq0 / tot0) / PFB_GAIN;
                p1 = 1.0 / 256.0 * sqrt(ssq1 / tot1) / PFB_GAIN;
                p0 = 10.0 * log10(1000.0 * p0 * p0 / 50.0);
                p1 = 10.0 * log10(1000.0 * p1 * p1 / 50.0);

                for(x=0; x<xs-1; x++) {
                    segment(draw, fg1, x+xoff, hbix[x], hbix[x+1]);
                    segment(draw, fg0, x+xoff, hbrx[x], hbrx[x+1]);
                }

                sprintf(fstr, "mean: %0.2f mV, %0.2f mV",
                        500.0 / 128.0 * sum0 / tot0,
                        500.0 / 128.0 * sum1 / tot1);
                txt_str(fstr, 14, fg0, 192, draw, xoff+10, 20);
                sprintf(fstr, "RMS power: %0.2f dBm, %0.2f dBm", p0, p1);
                txt_str(fstr, 14, fg0, 192, draw, xoff+10, 36);

            } else {
                // Do oscope drawing for bin
                //
                for(x=0; x<xs-1; x++) {
                    xp = x*bins;
                    p1ra = (p1_r[xp+a]+128) >> 1;
                    p1ia = (p1_i[xp+a]+128) >> 1;

                    p1rb = (p1_r[xp+a+bins]+128) >> 1;
                    p1ib = (p1_i[xp+a+bins]+128) >> 1;

                    if (points) {
                        pixmap_setcolor_rect(draw, fg1, x+xoff, p1ia, 1, 1);
                        pixmap_setcolor_rect(draw, fg0, x+xoff, p1ra, 1, 1);
                    } else {
                        segment(draw, fg1, x+xoff, p1ia, p1ib);
                        segment(draw, fg0, x+xoff, p1ra, p1rb);
                    }
                }
            }

            // Take FFT of bin
            //
            for(x=0; x<xs; x++) {
                xp = x*bins;
                in[x][0] = ((double)p1_r[xp+a]) / 128.0;
                in[x][1] = ((double)p1_i[xp+a]) / 128.0;
            }
            fftw_execute(plan);
            for(x=0; x<xs; x++) {
                pow[x] = out[x][0]*out[x][0] + out[x][1]*out[x][1];
                if (pow[x] <= 0.0)
                    pow[x] = -100.0;
                else
                    pow[x] = 10.0*log10(pow[x]) - 45.0;
            }
            cpv = pav[navg + avg*boff];

            // Put dB values into history array for averaging,
            // swap around values so DC is in the middle and 
            // negative values are on the left.
            //
            for(x=0; x<xs; x++) {
                if (x < xs/2)
                    cpv[x+xs/2] = pow[x];
                else 
                    cpv[x-xs/2] = pow[x];
            }

            // Average history values
            //
            for(x=0; x<xs; x++) {
                register double v = 0.0;

                for(j=0; j<tavg; j++)
                    v += pav[j + avg*boff][x];
                pv[x] = v / ((double) tavg);
            }

            // Find marker (highest peak), skip DC, not so interesting
            // Only search for marker in middle graph
            //
            if (mark_fix) {
                mark_l = pv[mark_f];
            } else {
                if (boff==0) {
                    mark_l = pv[0];
                    mark_f = 0;
                    for(x=1; x<xs; x++) {
                        if (x == xs/2)
                            continue;
                        if (pv[x] > mark_l) {
                            mark_l = pv[x];
                            mark_f = x;
                        }
                    }
                } else
                    mark_l = pv[mark_f];
            }

            // Convert dB value into pixel position and store in
            // history array for running average.
            //
            for(x=0; x<xs; x++) {
                register int     vv;
                vv = - (int) (ppdb*pv[x] + 0.5);
                if (vv < 0)
                    vv = 0;
                if (vv >= ysf)
                    vv = ysf-1;
                ipv[x] = vv;
            }

            // Calculate max-hold
            //
            if (tavg == avg) 
                for(x=0; x<xs; x++)
                    if (ipv[x] < max[x])
                        max[x] = ipv[x];

            // Draw segments for freq display
            //
            for(x=0; x<xs-1; x++) 
                segment(draw2, fg0, x+xoff, ipv[x], ipv[x+1]);
            if (opt_max && tavg == avg) 
                for(x=0; x<xs-1; x++) 
                    segment(draw2, maxc, x+xoff, max[x], max[x+1]);

            // Put a little text label in freq bins
            //
            bin_center = adc_freq * ((double)(a-16))/((double)bins);
            sprintf(fstr, "Bin %d, %g MHz", a-16, bin_center);
            txt_str(fstr, 14, fg0, 192, draw2, 10+xoff, 20);

            // Draw marker next
            //
            mf = bin_center + (adc_freq / ((double) bins)) *
                    (((double) (mark_f-xs/2)) / ((double) xs)); 
            // This is for the left side of the -16 bin where there
            // is a plus/minus freq cross over in the middle of the bin
            //
            if (mf < -adc_freq/2.0)
                mf += adc_freq;
            sprintf(fstr, "%s: %0.1f dBc @ %0.2f MHz", 
                    mark_fix ? "M" : "m", mark_l, mf);
            txt_str(fstr, 14, fg0, 192, draw2, 10+xoff, 36);

            // Draw marker diamond
            //
            my = ipv[mark_f];
            if (my >= ysf)
                my = ysf-1;
            draw_marker(draw2, xoff+mark_f, my);
        }

        if (++navg == avg)
            navg = 0;
        pixmap_copy(gr,draw,0,0);
        pixmap_copy(gr2,draw2,0,0);
        // usleep(80000);
    }
    t2 = rtime();
    t1 = ((double)loops)/(t2-t1);
    printf("%g fps\n", t1);
    pixmap_close();

    fftw_destroy_plan(plan);
    fftw_free(in);
    fftw_free(out);
    fftw_free(pow);
    fftw_free(pv);
    fftw_free(ipv);
    for(j=0; j<avg*3; j++)
        fftw_free(pav[j]);
    fftw_free(pav);
    for(j=0; j<3; j++)
        fftw_free(maxv[j]);
}

// Take PFB data and plot 32-bin bar graph of PFB power
//
void
do_pfb_freq(Ab *ab)
{
    int             x, xs, i;
    s_char          *p1_r, *p1_i, *p2_r, *p2_i;
    int             border;
    pixmap          *gr;
    pixmap          *draw;
    pixmap          *grid;
    double          *pow;
    int             *cpv;
    double          p1r, p1i;


    pixel           bg  = COLOR(64,64,64);
    pixel           fg  = COLOR(0,255,0);
    pixel           gc  = COLOR(128,128,128);
    double          t1, t2;

    int             loops=10000;
    int             ys=400;
    double          ppdb = 8.0;     // pixels per dB

    int             segsize;        // size of segment
    int             bins = PFB_BINS;      // bins in PFB
    int             bufs = ab->mbus_len/4;    // samples in PCI memory

    if (opt_ppdb > 0)
        ppdb = opt_ppdb;
    pow = (double *) malloc(sizeof(double) * bufs);
    cpv = (int *) malloc(sizeof(int) * bufs);

    // Find largest power of 2 that fits on screen
    for(i=30; i>=0; i--) 
        if (fb->xs >> i)
            break;
    xs = 1 << i;
    border = (fb->xs - xs)/2;
    segsize = xs/bins;

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

    t1 = rtime();
    // for(loop=0; loop<loops; loop++) {
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
                case 'q':   gexit(1);

                default:    // printf("Unknown key: '%c'\n", ch);
                            break;
            }
        }

        pixmap_copy(draw, grid, 0, 0);
        adc_capture(ab, CAP_PFB, 0, 0, (void *) &p1_r, (void *) &p1_i, 
                (void *) &p2_r, (void *) &p2_i);

        if (opt_input) {
            p1_r = p2_r;
            p1_i = p2_i;
        }

        // Get power in dB, reference is arbitrary
        for(i=0; i<bufs; i++) {
            p1r = p1_r[i] / 128.0;
            p1i = p1_i[i] / 128.0;
            pow[i] = p1r*p1r + p1i*p1i;
            pow[i] = (pow[i] <= 0.0) ? -100.0 : 10.0*log10(pow[i])-3.1;
        }

        // Convert dB value into pixel position and story in
        // history array for running average.
        //
        for(i=0; i<=bufs; i++) {
            cpv[i] = - (int) (ppdb*pow[i] + 0.5);
            if (cpv[i] < 0)
                cpv[i] = 0;
            if (cpv[i] >= ys)
                cpv[i] = ys-1;
        }

        // Draw trace
        //
        for(x=0; x<bufs; x+=bins) 
            for(i=0; i<bins; i++)
                pixmap_setcolor_rect(draw, fg, i*segsize, cpv[x+i], segsize, 1);

        // Put pixmap in frame buffer
        //
        pixmap_copy(gr,draw,0,0);
    }
    t2 = rtime();
    t1 = ((double)loops)/(t2-t1);
    printf("%g fps\n", t1);

    pixmap_close();
    free(pow);
    free(cpv);
}

//  Print PFB captured data as ascii
//
void
do_pfb_test(Ab *ab)
{
    int             i;
    int             pos;
    double          r1, i1;
    double          pow1;
    double          r2, i2;
    double          pow2;
    s_char          *p1_r;
    s_char          *p1_i;
    s_char          *p2_r;
    s_char          *p2_i;

    adc_capture(ab, CAP_PFB, 0, 0, (void *) &p1_r, (void *) &p1_i, 
            (void *) &p2_r, (void *) &p2_i);

    for(i=0; i<ab->mbus_len/4; i++) {
        if (i && (i&31)==0)
            printf("\n");
        r1 = ((double)p1_r[i]) / 128.0;
        i1 = ((double)p1_i[i]) / 128.0;
        pow1 = r1*r1 + i1*i1;
        pow1 = (pow1 <= 0.0) ? -100.0 : 10.0*log10(pow1)-3.0;

        r2 = ((double)p2_r[i]) / 128.0;
        i2 = ((double)p2_i[i]) / 128.0;
        pow2 = r2*r2 + i2*i2;
        pow2 = (pow2 <= 0.0) ? -100.0 : 10.0*log10(pow2)-3.0;

        pos = (i & 31) - 16;
        printf("%3d %02x %02x %02x %02x   %g dB %g dB\n", 
                pos,
                p1_r[i] & 0xff,
                p1_i[i] & 0xff,
                p2_r[i] & 0xff,
                p2_i[i] & 0xff,
                pow1, pow2
        );
    }
    exit(0);
}

// Print out values for the tdiff PPS measurement
//
// Warning...  there's a problem not solved by this
// problem of a wrap-around of the timing numbers.  The
// 8-bit timing number nominally varies from 0x08 - 0x48.
// This is in half ADC clocks.  Sometimes you might see a 
// 0x49 or very rarely a 0x07, but 0x08-0x48 is the normal
// range.  If you are lucky, it is possible for the PPS
// edge to sit on the edge of wrap-around and flip between
// depending on how pps is resynced to the adc clock.  This
// is not necessarily an error or bad, you just need to 
// take into account this wraparound effect (the PFB32 has 
// a block size of 32 ADC clocks or 64 (0x40) tdiff counts.
//
void
do_tdiff(Ab *ab)
{
    u_long  v;
    int     pps_enabled;
    int     tdiff;
    int     i, t;

    double  tns;

    int     w1ptr = 0;
    int     w1n = 0;
    double  *w1;
    int     w1size = 256;
    double  w1min = 1000.0, w1max = 0.0;
    double  w1avg;

    w1 = (double *) malloc(sizeof(double) * w1size);

    for(t=1; t<=3600; t++) {    // one hour
        v = ab->ctl[0];
        pps_enabled = (v & 0x800000);
        tdiff = (v >> 24) & 0xff;

        // Time delay in ns.
        tns = ((double) tdiff) * 1000.0 / (2.0 * adc_freq);

        w1[w1ptr++] = tns;
        if (w1ptr >= w1size)
            w1ptr = 0;
        if (w1n < w1size)
            w1n++;
        w1avg = 0.0;
        for(i=0; i<w1n; i++)
            w1avg += w1[i];
        w1avg = w1avg / ((double) w1n);
        if (w1n == w1size) {
            if (w1avg > w1max)
                w1max = w1avg;
            if (w1avg < w1min)
                w1min = w1avg;
        }
        

        printf("%5d %s: 0x%02x %.2f ns", 
            t, pps_enabled ? "PPS Enabled" : "PPS Disabled", tdiff, w1avg);
        if (w1n == w1size)
            printf(" [%.2f ns, %.2f ns]\n", w1min, w1max);
        else
            printf(" (%d/%d)\n", w1n, w1size);

        sleep(1);
    }
    exit(0);
}

//  Print PFB captured data as ascii
//
void
do_pfby_test(Ab *ab, int bin)
{
    int             i;
    s_char          *p1_r, *p1_i, *p2_r, *p2_i;

    adc_capture(ab, CAP_PFB, PFB_BINS-1, bin, (void *) &p1_r, (void *) &p1_i, 
            (void *) &p2_r, (void *) &p2_i);

    for(i=0; i<ab->mbus_len/4; i++) 
        printf("%4d %4d %4d %4d %4d\n", i, p1_r[i], p1_i[i], p2_r[i], p2_i[i]);
    exit(0);
}

void
do_pfby_graph(Ab *ab, int ax)
{
    int             j, x, my;
    char            fstr[80];
    int             navg, tavg;
    s_char          *p1_r, *p1_i, *p2_r, *p2_i;

    fftw_complex    *in, *out;
    double          *pow;
    fftw_plan       plan;
    double          *cpv;
    double          *pv;
    int             *ipv;
    double          **pav1, **pav2;
    int             *max1, *max2;
    int             disp_f;

    double          bin_center;
    double          bin_width;
    double          bin_res;

    pixmap          *pm_gr, *pm_draw;
    pixmap          *pm_title, *pm_spec1, *pm_spec2, *pm_stat, *pm_ov;
    pixmap          *pm_spec_bg;

    pixel           col_bg  = COLOR(96,96,96);
    pixel           col_lc  = COLOR(192,192,192);
    pixel           col_fg0 = COLOR(0,255,0);
    pixel           col_fg1 = COLOR(0,160,0);
    pixel           col_maxc = COLOR(255,0,0);

    int             bins = PFB_BINS;
    int             fft_sz=8192;
    int             border=10;
    int             mark_f = 0;
    double          mark_l = 0.0;
    double          mark_l1 = 0.0;
    double          mark_l2 = 0.0;
    int             mark_fix=0;
    int             winwidth=512;
    int             specheight=190;
    double          ppdb = 2.5;     // pixels per dB

    fft_sz = opt_fftsz;
    winwidth = (fb->xs - 2*border) & ~7;
    if (fft_sz < winwidth)
        fft_sz = winwidth;

    if (opt_ppdb > 0)
        ppdb = opt_ppdb;
    // Allocate pixmaps for display pieces
    //
    pixmap_setcolor(fb, C_BLACK);
    pm_gr = pixmap_subset(fb, (fb->xs-winwidth)/2, border, winwidth, 600);
    pm_draw = pixmap_dup(pm_gr);
    pm_title = pixmap_subset(pm_draw, 0, 0, 410, 36);
    pm_ov = pixmap_subset(pm_draw, winwidth-200, 10, 200, 32);
    pm_spec1 = pixmap_subset(pm_draw, 0, 50, winwidth, specheight);
    pm_spec2 = pixmap_subset(pm_draw, 0, 50+specheight+10, 
                    winwidth, specheight);
    pm_stat = pixmap_subset(pm_draw, 0, 50+specheight*2+20,
                    winwidth, 100);
    pm_spec_bg = pixmap_dup(pm_spec1);

    // Draw background images
    //
    pixmap_setcolor_rect(pm_spec_bg, col_bg, 0, 0, winwidth, specheight);
    pixmap_setcolor_rect(pm_spec_bg, col_lc, 0, 0, winwidth, 1);
    pixmap_setcolor_rect(pm_spec_bg, col_lc, 0, 0, 1, specheight);
    pixmap_setcolor_rect(pm_spec_bg, col_lc, winwidth-1, 0, 1, specheight);
    for(x=0; x<winwidth; x+= (int) 10.0*ppdb) 
        pixmap_setcolor_rect(pm_spec_bg, col_lc, 0, x, winwidth, 1);
    for(x=0; x<winwidth; x+=winwidth/8)
        pixmap_setcolor_rect(pm_spec_bg, col_lc, x, 0, 1, specheight);

    // Allocate buffers for FFTs and averages
    //
    in = fftw_malloc(sizeof(fftw_complex)*fft_sz);
    out = fftw_malloc(sizeof(fftw_complex)*fft_sz);
    plan = fftw_plan_dft_1d(fft_sz, in, out, FFTW_FORWARD, FFTW_ESTIMATE);
    pow = fftw_malloc(sizeof(double)*fft_sz);
    pv = fftw_malloc(sizeof(double)*fft_sz);
    ipv = fftw_malloc(sizeof(int)*fft_sz);

    pav1 = fftw_malloc(sizeof(double *)*opt_avg);
    for(x=0; x<opt_avg; x++) 
        pav1[x] = fftw_malloc(sizeof(double) * fft_sz);
    pav2 = fftw_malloc(sizeof(double *)*opt_avg);
    for(x=0; x<opt_avg; x++) 
        pav2[x] = fftw_malloc(sizeof(double) * fft_sz);

    max1 = fftw_malloc(sizeof(double)*fft_sz);
    for(x=0; x<fft_sz; x++)
            max1[x] = specheight;
    max2 = fftw_malloc(sizeof(double)*fft_sz);
    for(x=0; x<fft_sz; x++)
            max2[x] = specheight;

    tavg = 0;
    navg = 0;
    disp_f = (fft_sz - winwidth)/2;

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
                case 'q':   gexit(1);

                // Move bins left or right
                //
                case 'x':
                case 'z':   if (ch == 'z')
                                ax = (ax+1)&0x1f;
                            else
                                ax = (ax-1)&0x1f;
                            tavg = 0;
                            navg = 0;
                            for(x=0; x<fft_sz; x++) {
                                max1[x] = specheight;
                                max2[x] = specheight;
                            }
                            break;

                // Toggle max-hold
                //
                case 'r':   opt_max = !opt_max;
                            if (opt_max) 
                                for(x=0; x<fft_sz; x++) {
                                    max1[x] = specheight;
                                    max2[x] = specheight;
                                }
                            break;

                // Manually move marker
                case 'n':   if (--mark_f < 0)
                                mark_f = 0;
                            mark_fix = 1;
                            break;
                case 'm':   if (++mark_f >= winwidth)
                                mark_f = winwidth-1;
                            mark_fix = 1;
                            break;
                case 'b':   mark_fix = 0;
                            break;

                // Scroll window within FFT
                //
                case '>':   disp_f -= winwidth/4;
                            if (mark_fix)
                                mark_f += 7;
                case '.':   if (--disp_f < 0)
                                disp_f = 0;
                            if (mark_fix)
                                if (++mark_f >= winwidth)
                                    mark_f = winwidth-1;
                            break;

                case '<':   disp_f += winwidth/4;
                            if (mark_fix)
                                mark_f -= 7;
                case ',':   if (++disp_f > (fft_sz-winwidth))
                                disp_f = fft_sz - winwidth;
                            if (mark_fix)
                                if (--mark_f < 0)
                                    mark_f = 0;
                            break;

                default:    // printf("Unknown key: '%c'\n", ch);
                            break;
            }
        }

        pixmap_copy(pm_spec1, pm_spec_bg, 0, 0);
        pixmap_copy(pm_spec2, pm_spec_bg, 0, 0);
        pixmap_setcolor(pm_title, C_BLACK);
        pixmap_setcolor(pm_stat, C_BLACK);
        pixmap_setcolor(pm_ov, C_BLACK);

        // Get some PFB data
        //
        adc_capture(ab, CAP_PFB, bins-1, ax, (void *) &p1_r, (void *) &p1_i, 
                (void *) &p2_r, (void *) &p2_i);

        if (tavg < opt_avg)
            tavg++;

        // Take FFT of bin
        //
        for(x=0; x<fft_sz; x++) {
            in[x][0] = ((double)p1_r[x]) / 128.0;
            in[x][1] = ((double)p1_i[x]) / 128.0;
        }
        fftw_execute(plan);
        for(x=0; x<fft_sz; x++) {
            pow[x] = out[x][0]*out[x][0] + out[x][1]*out[x][1];
            if (pow[x] <= 0.0)
                pow[x] = -100.0;
            else
                pow[x] = 10.0*log10(pow[x]) - 75.0;
        }
        cpv = pav1[navg];

        // Put dB values into history array for averaging,
        // swap around values so DC is in the middle and 
        // negative values are on the left.
        //
        for(x=0; x<fft_sz; x++) {
            if (x < fft_sz/2)
                cpv[x+fft_sz/2] = pow[x];
            else 
                cpv[x-fft_sz/2] = pow[x];
        }

        // Average history values
        //
        for(x=0; x<fft_sz; x++) {
            register double v = 0.0;
            for(j=0; j<tavg; j++)
                v += pav1[j][x];
            pv[x] = v / ((double) tavg);
        }

        // Find marker (highest peak), skip DC, not so interesting
        // Only search for marker in middle graph
        //
        if (!mark_fix) {
            mark_l = pv[disp_f];
            mark_f = 0;
            for(x=0; x<winwidth; x++) {
                if (pv[x+disp_f] > mark_l) {
                    mark_l = pv[x+disp_f];
                    mark_f = x;
                }
            }
        }
        mark_l1 = pv[mark_f + disp_f];

        // Convert dB value into pixel position and store in
        // history array for running average.
        //
        for(x=0; x<fft_sz; x++) {
            register int     vv;
            vv = - (int) (ppdb*pv[x] + 0.5);
            if (vv < 0)
                vv = 0;
            if (vv >= specheight)
                vv = specheight-1;
            ipv[x] = vv;
        }

        // Calculate max-hold
        //
        if (tavg == opt_avg) 
            for(x=0; x<fft_sz; x++)
                if (ipv[x] < max1[x])
                    max1[x] = ipv[x];

        // Draw segments for freq display
        //
        for(x=0; x<winwidth-1; x++) 
            segment(pm_spec1, col_fg0, x, ipv[x+disp_f], ipv[x+1+disp_f]);
        if (opt_max && tavg == opt_avg) 
            for(x=0; x<winwidth-1; x++) 
                segment(pm_spec1, col_maxc,x, max1[x+disp_f], max1[x+1+disp_f]);

        // Draw marker diamond
        //
        my = ipv[mark_f+disp_f];
        if (my >= specheight)
            my = specheight-1;
        draw_marker(pm_spec1, mark_f, my);

        // Take FFT of bin
        //
        for(x=0; x<fft_sz; x++) {
            in[x][0] = ((double)p2_r[x]) / 128.0;
            in[x][1] = ((double)p2_i[x]) / 128.0;
        }
        fftw_execute(plan);
        for(x=0; x<fft_sz; x++) {
            pow[x] = out[x][0]*out[x][0] + out[x][1]*out[x][1];
            if (pow[x] <= 0.0)
                pow[x] = -100.0;
            else
                pow[x] = 10.0*log10(pow[x]) - 75.0;
        }
        cpv = pav2[navg];

        // Put dB values into history array for averaging,
        // swap around values so DC is in the middle and 
        // negative values are on the left.
        //
        for(x=0; x<fft_sz; x++) {
            if (x < fft_sz/2)
                cpv[x+fft_sz/2] = pow[x];
            else 
                cpv[x-fft_sz/2] = pow[x];
        }

        // Average history values
        //
        for(x=0; x<fft_sz; x++) {
            register double v = 0.0;
            for(j=0; j<tavg; j++)
                v += pav2[j][x];
            pv[x] = v / ((double) tavg);
        }
        mark_l2 = pv[mark_f + disp_f];

        // Convert dB value into pixel position and store in
        // history array for running average.
        //
        for(x=0; x<fft_sz; x++) {
            register int     vv;
            vv = - (int) (ppdb*pv[x] + 0.5);
            if (vv < 0)
                vv = 0;
            if (vv >= specheight)
                vv = specheight-1;
            ipv[x] = vv;
        }

        // Calculate max-hold
        //
        if (tavg == opt_avg) 
            for(x=0; x<fft_sz; x++)
                if (ipv[x] < max2[x])
                    max2[x] = ipv[x];

        // Draw segments for freq display
        //
        for(x=0; x<winwidth-1; x++) 
            segment(pm_spec2, col_fg0, x, ipv[x+disp_f], ipv[x+1+disp_f]);
        if (opt_max && tavg == opt_avg) 
            for(x=0; x<winwidth-1; x++) 
                segment(pm_spec2, col_maxc,x, max2[x+disp_f], max2[x+1+disp_f]);

        // Draw marker diamond
        //
        my = ipv[mark_f+disp_f];
        if (my >= specheight)
            my = specheight-1;
        draw_marker(pm_spec2, mark_f, my);

        bin_center = adc_freq * ((double)(ax-16))/((double)bins);
        bin_width = adc_freq / bins;
        bin_res = adc_freq/bins/fft_sz;

        sprintf(fstr, "Bin %d, Center %g MHz, Width %g MHz",
            ax-16, bin_center, bin_width);
        txt_str(fstr, 14, C_WHITE, 255, pm_title, 0, 16*1);
        if (bin_res*1000000.0 < 1000.0)
            sprintf(fstr, "%d-pt FFT, %g Hz resolution",     
                    fft_sz, bin_res * 1000000.0);
        else if (bin_res < 1.0)
            sprintf(fstr, "%d-pt FFT, %g kHz resolution", 
                    fft_sz, bin_res * 1000.0);
        else
            sprintf(fstr, "%d-pt FFT, %g MHz resolution", 
                    fft_sz, bin_res );
        txt_str(fstr, 14, C_WHITE, 255, pm_title, 0, 16*2);


        // Markers in windows
        //
        sprintf(fstr, "%solarization A: %0.1f dBc @ %0.4f MHz", 
                mark_fix ? "p" : "P", mark_l1,
                bin_center - bin_width/2.0 + (mark_f+disp_f)*bin_res);
        txt_str(fstr, 14, col_fg0, 192, pm_spec1, 8, 20);

        sprintf(fstr, "%solarization B: %0.1f dBc @ %0.4f MHz", 
                mark_fix ? "p" : "P", mark_l2,
                bin_center - bin_width/2.0 + (mark_f+disp_f)*bin_res);
        txt_str(fstr, 14, col_fg0, 192, pm_spec2, 8, 20);

        sprintf(fstr, "%0.4f MHz", 
                bin_center - bin_width/2.0 + disp_f*bin_res);
        txt_str("Start", 14, col_lc, 255, pm_stat, 0, 16*1);
        txt_str(fstr, 14, col_lc, 255, pm_stat, 50, 16*1);

        sprintf(fstr, "%0.4f MHz", 
                bin_center - bin_width/2.0 + (winwidth+disp_f)*bin_res);
        txt_str("Stop", 14, col_lc, 255, pm_stat, 0, 16*2);
        txt_str(fstr, 14, col_lc, 255, pm_stat, 50, 16*2);

        sprintf(fstr, "%0.4f MHz",
                bin_center - bin_width/2.0 + (winwidth/2 + disp_f)*bin_res);
        txt_str("Center", 14, col_lc, 255, pm_stat, winwidth/2, 16*1);
        txt_str(fstr, 14, col_lc, 255, pm_stat, winwidth/2+50, 16*1);

        sprintf(fstr, "%0.4f MHz", bin_res*winwidth);
        txt_str("Width", 14, col_lc, 255, pm_stat, winwidth/2, 16*2);
        txt_str(fstr, 14, col_lc, 255, pm_stat, winwidth/2+50, 16*2);


        // World view graph of bin
        //
        pixmap_setcolor(pm_ov, col_bg);

        pixmap_setcolor_rect(pm_ov, col_fg1, 
            pm_ov->xs * disp_f / fft_sz,
            pm_ov->ys/2, 
            pm_ov->xs * winwidth / fft_sz, pm_ov->ys/2);

        pixmap_setcolor_rect(pm_ov, col_lc, 0, pm_ov->ys/4, 1, 
            pm_ov->ys - pm_ov->ys/4);
        pixmap_setcolor_rect(pm_ov, col_lc, pm_ov->xs/2, 
            pm_ov->ys - pm_ov->ys/4, 1, pm_ov->ys/4);
        pixmap_setcolor_rect(pm_ov, col_lc, pm_ov->xs-1, pm_ov->ys/4, 1, 
            pm_ov->ys - pm_ov->ys/4);
        pixmap_setcolor_rect(pm_ov, col_lc, 0, pm_ov->ys-1, pm_ov->xs, 1);

        

        pixmap_copy(pm_gr, pm_draw, 0, 0);
        if (++navg == opt_avg)
            navg = 0;
    }
}

int
main(int ac, char **av)
{
    Ab              *ab;
    int             i, v;
    int             pfb_bin=0;

    int             g_mbus_memtest=0;
    int             g_adc_test=0;
    int             g_do_pfb_test=0;
    int             g_do_freq=0;
    int             g_do_cfreq=0;
    int             g_do_graph=0;
    int             g_do_pfb_freq=0;
    int             g_do_pfb_graph=0;
    int             g_do_tdiff=0;
    int             g_pfb_reset=0;
    int             g_do_skip=0;

    int             g_do_pfby_test=0;
    int             g_do_pfby_graph=0;
    int             g_do_vnc=0;

    ab = AbOpen();
    if (!ab) {
        fprintf(stderr, "No boards found...\n");
        exit(1);
    }

    for(i=1; i<ac; i++)
        if (av[i][0] == '-') 
            switch(av[i][1]) {
                case 'V':
                    g_do_vnc = 1;
                    break;

                case 'R':
                    g_pfb_reset = 1;
                    break;
                    
                case 's':  
                    if (i+1<ac)
                        adc_freq = strtod(av[++i], 0);
                    break;

                case 'P':  
                    if (i+1<ac)
                        opt_ppdb = strtod(av[++i], 0);
                    break;

                case 'n':  
                    if (i+1<ac) 
                        opt_avg = strtol(av[++i], 0, 0);
                    break;

                case 'F':  
                    if (i+1<ac) 
                        opt_fftsz = strtol(av[++i], 0, 0);
                    if (opt_fftsz < 512)
                        opt_fftsz = 512;
                    if (opt_fftsz > 8192)
                        opt_fftsz = 8192;
                    break;

                case 'i':
                    if (i+1<ac)
                        opt_input = strtol(av[++i], 0, 0);
                    break;

                case 'r':
                    opt_max = 1;
                    break;

                case 'p':   
                    AbPrint(ab);
                    exit(0);

                case 't':
                    g_do_tdiff = 1;
                    break;

                case 'd':
                    g_do_skip = 1;
                    break;

                case 'l':
                    v = doload(ab, g_do_skip);
                    exit(v);

                case 'm':
                    g_mbus_memtest = 1;
                    break;

                case 'a':
                    g_adc_test = 1;
                    break;
                    
                case 'f':
                    g_do_freq = 1;
                    break;
                    
                case 'c':
                    g_do_cfreq = 1;
                    break;
                    
                case 'g':
                    g_do_graph = 1;
                    break;

                case 'x':
                    switch (av[i][2]) {
                        case 'a':   g_do_pfb_test = 1;
                                    break;
                                        
                        case 'f':   g_do_pfb_freq = 1;
                                    break;

                        case 'g':   pfb_bin = 0;
                                    g_do_pfb_graph = 1;
                                    break;
                                        
                        default:    fprintf(stderr, "Unknown pfb: -x%c\n",
                                            av[i][2]);
                                    break;
                    }
                    break;

                case 'y':
                    switch (av[i][2]) {
                        case 'a':   pfb_bin = 0;
                                    if (i+1<ac)
                                        pfb_bin = strtol(av[++i], 0, 0);
                                    g_do_pfby_test = 1;
                                    break;
                                        
                        case 'g':   pfb_bin = 0;
                                    g_do_pfby_graph = 1;
                                    break;
                                        
                        default:    fprintf(stderr, "Unknown pfby: -y%c\n",
                                            av[i][2]);
                                    break;
                    }
                    break;
            }

    if (opt_avg < 1)
        opt_avg = 1;

    // Text only tests
    //
    if (g_mbus_memtest)
        mbus_memtest(ab);
    if (g_adc_test)
        adc_test(ab);
    if (g_do_pfb_test)
        do_pfb_test(ab);
    if (g_do_tdiff)
        do_tdiff(ab);
    if (g_pfb_reset) {
        pfb_reset(ab);
        exit(0);
    }
    if (g_do_pfby_test)
        do_pfby_test(ab, pfb_bin+16);

    // Graphical tests
    //
    if (g_do_freq || g_do_cfreq || g_do_graph || g_do_pfb_freq || 
            g_do_pfb_graph || g_do_pfby_graph) {
        if (g_do_vnc) {
            pixmap_init_vnc(&ac, av, 800,600);
            printf("Running in VNC frame buffer.\n");
        } else {
            pixmap_init();
            tty_to_raw();
        }
        // pixmap_setcolor(fb, C_BLACK);
        if (FT_Init_FreeType( &library )) {
            fprintf(stderr, "Cannot init freetype library.\n");
            gexit(1);
        }
        if (FT_New_Face(library, "/etc/FreeSans.ttf", 0, &regface)) {
            fprintf(stderr, "Cannot open typeface.\n");
            gexit(1);
        }

        if (g_do_freq)
            do_freq(ab);
        if (g_do_cfreq)
            do_cfreq(ab);
        if (g_do_graph)
            do_graph(ab);
        if (g_do_pfb_freq)    
            do_pfb_freq(ab);
        if (g_do_pfb_graph)
            do_pfb_graph(ab, pfb_bin+16);
        if (g_do_pfby_graph)
            do_pfby_graph(ab, pfb_bin+16);

        gexit(0);
    }

    printf("\n");
    printf("Usage: xload \n");
    printf("   -V     Be a VNC server instead of using framebuffer.\n");
    printf("   -s f   Use floating f as ADC samplerate (in MHz).\n");
    printf("   -P f   Set pixels per dB for log scales\n");
    printf("   -F n   Set FFT size of -yg mode (512 - 8192)\n");
    printf("   -R     Send reset to 2v4000\n");
    printf("   -p     Print board information\n");
    printf("   -l     Load Xilinx parts from standard input\n");
    printf("   -m     Memory test PCI memory aperature\n");
    printf("   -t     Test PPS tdiff function\n");
    printf("   -a     Print ADC samples as ascii\n");
    printf("   -f     Plot real power FFT of first channel of ADC\n");
    printf("   -c     Plot complex power FFT for first two channels of ADC\n");
    printf("   -g     Plot oscillosope graph of ADCs\n");
    printf("   -xa    Print PFB bins as ascii\n");
    printf("   -xf    Plot power of 32 PFB bins\n");
    printf("   -xg    Plot freq bins n-1,n,n+1 as graph and 256-pt complex fft\n");
    printf("   -ya n  Print 8k samples of PFB bin-n as ascii\n");
    printf("   -yg    Plot 8k fft of one PFB bin\n");
    printf("   -n n   Number of frames to average for frequency/hist display\n");
    printf("   -r     Add red max-hold line for frequency display\n");
    printf("   -i n   Select different input ADC for processing\n");
    printf("\n");
    printf("Press 'q' during operation to quit program\n");
    printf("Press 'p' during operation to create raw image file in /tmp\n");
    printf("Press 'r' during operation to toggle max-hold\n");
    printf("Press 'z/x' during operation to change bin in -xg mode\n");
    printf("Press 'm/n/b' during operation to manually move marker\n");
    printf("Press '<>' during -yg to scroll FFT window (shift for faster)\n");
    printf("Press  h  during -xg mode to turn top graph into histogram\n");
    printf("\n");
    return 0;
}
