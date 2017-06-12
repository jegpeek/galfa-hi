

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

#define SAMP_LEN    8192            // Number of samples in mbuf
#define SZ          (32768>>2)      // Number of words of PCI buffer mem

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

    for(j=0; j<SAMP_LEN; j++)
        ab->mbus[j] = 0;

    // Start capture
    ab->ctl[4] = (dec_off & 0xff) | ((dec_n & 0xff) << 8);
    ab->ctl[0] = 0x4 | ((msel & 0x3) << 3);
    ab->ctl[0] = 0x0 | ((msel & 0x3) << 3);

    // Wait for capture to finish 
    while (ab->ctl[2] & 0x8)
        ;

    *a0 = ((u_char *) ab->mbus) + 0*SAMP_LEN;
    *a1 = ((u_char *) ab->mbus) + 1*SAMP_LEN;
    *a2 = ((u_char *) ab->mbus) + 2*SAMP_LEN;
    *a3 = ((u_char *) ab->mbus) + 3*SAMP_LEN;
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


int
bitrev(int n, int bits)
{
    register int u;

    u = n&1;
    while(--bits) {
        n >>= 1;
        u <<= 1;
        u += n&1;
    }
    return(u);
}

void
do_pfby_graph(Ab *ab)
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

    winwidth = (fb->xs - 2*border) & ~7;

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
        adc_capture(ab, CAP_PFB, 0, 0, (void *) &p1_r, (void *) &p1_i, 
                (void *) &p2_r, (void *) &p2_i);

        if (tavg < opt_avg)
            tavg++;





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
    int             do_vnc=0;

    ab = AbOpen();
    if (!ab) {
        fprintf(stderr, "No boards found...\n");
        exit(1);
    }

    if (do_vnc) {
        pixmap_init_vnc(&ac, av, 800,600);
        printf("Running in VNC frame buffer.\n");
    } else {
        pixmap_init();
        tty_to_raw();
    }

    pixmap_setcolor(fb, C_BLACK);
    if (FT_Init_FreeType( &library )) {
        fprintf(stderr, "Cannot init freetype library.\n");
        gexit(1);
    }
    if (FT_New_Face(library, "/etc/FreeSans.ttf", 0, &regface)) {
        fprintf(stderr, "Cannot open typeface.\n");
        gexit(1);
    }

    do_pfby_graph(ab, 0);
    gexit(0);
}




