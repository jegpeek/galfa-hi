
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


#include "scram/gscram.h"
#include "galfa_sock/galfa_sock.h"
#include "galfa.h"

pixel col_bg  = COLOR(96,96,96);
pixel col_hc  = COLOR(128,128,128);
pixel col_lc  = COLOR(192,192,192);
pixel col_fg0 = COLOR(0,255,0);
pixel col_fg1 = COLOR(255,255,0);
pixel col_fg2 = COLOR(0,160,0);
pixel col_err = COLOR(255,0,0);

static pixmap *title = NULL;
static pixmap *title_draw = NULL;

typedef struct {
    int         bins;
    int         width;
    int         height;
    pixmap      *bg;
    pixmap      *draw;
    pixmap      *screen;
    double      *pola;
    double      *polb;
    int         *pola_i;
    int         *polb_i;
    u_long      *pola_src;
    u_long      *polb_src;

    double      scale;
    int         draw_order;
    int         mark_fix;
    double      mark_l;
    int         mark_f;
    int         mark_y;
    int         x2;
    double      linmax;
} g_window;

u_char   dacs_read=0;

static void
read_dac_file(void)
{
    int         fd;

    if ((fd = open("/tmp/dac", O_RDONLY)) < 0) 
        printf("Cannot read DAC setttings, usings zero's...\n");
    else {
        read(fd, g_dac, 14);
        close(fd);
    }
    dacs_read = 1;
}

double 
mix_freq(void)
{
    double  v=0.0;
#ifdef NEW_MIXER
    int     x;

    x = opt_mix & 0x1f;
    if (x > 15)
        x = x-32;    
    v = opt_adcfreq * ((double) x)/32.0;
#else
    switch(opt_mix) {
        case MIX_NEG:    v = -opt_adcfreq/4.0; break;
        case MIX_DC:     v = 0.0; break;
        case MIX_POS:    v = opt_adcfreq/4.0; break;
    }
#endif
    return v;
}

// Draw background for narrowband window
//
static void
ns_draw_bg(g_window *win, pixel bg, pixel lc, int linear)
{
    int     i;
    pixel   col;

    pixmap_setcolor(win->bg, bg);
    for(i=0; i<win->bg->xs; i+=win->bg->xs/8) 
        pixmap_setcolor_rect(win->bg, lc, i, 0, 1, win->bg->ys);
    pixmap_setcolor_rect(win->bg, lc, win->bg->xs-1, 0, 1, win->bg->ys);
    if (linear) 
        for(i=0; i<win->bg->ys; i+= win->bg->ys/8)
            pixmap_setcolor_rect(win->bg, lc, 0, i, win->bg->xs, 1);
    else 
        for(i=0; i<win->bg->ys; i+= opt_ppdb*10.0) {
            col = lc;
            if (i==0 && opt_ref!=0.0)
                col = col_err;
            pixmap_setcolor_rect(win->bg, col, 0, i, win->bg->xs, 1);
        }
}

// Draw background for wideband window
//
static void
ws_draw_bg(g_window *win, pixel bg, pixel lc, pixel hc, int linear)
{
    double          f_min, f_max;
    int             fi_min, fi_max;
    int             i;
    double          n_center = 0.0;
    pixel           col;


    n_center = mix_freq();
    pixmap_setcolor(win->bg, bg);
    // Mark width of narrowband transform in wideband
    f_min = n_center - 0.5 * opt_adcfreq / N_DEC;
    f_max = n_center + 0.5 * opt_adcfreq / N_DEC;

    fi_min = win->bg->xs * f_min / opt_adcfreq + win->bg->xs/2 + 0.5;
    fi_max = win->bg->xs * f_max / opt_adcfreq + win->bg->xs/2 + 0.5;

    // Draw the highlight for the narrowband spectrum
    if (win->x2) {
        pixmap_setcolor_rect(win->bg, hc, fi_min*2, 0, 2*(fi_max-fi_min), 
            win->bg->ys);
        if (fi_min*2 < 0)
            pixmap_setcolor_rect(win->bg, hc, fi_min*2+win->bg->xs, 0, 
                2*(fi_max-fi_min), win->bg->ys);
        if (fi_max*2 > win->bg->xs)
            pixmap_setcolor_rect(win->bg, hc, fi_min*2-win->bg->xs, 0, 
                2*(fi_max-fi_min), win->bg->ys);
    } else {
        pixmap_setcolor_rect(win->bg, hc, fi_min, 0, fi_max-fi_min, 
            win->bg->ys);
        if (fi_min < 0)
            pixmap_setcolor_rect(win->bg, hc, fi_min+win->bg->xs, 0, 
                fi_max-fi_min, win->bg->ys);
        if (fi_max > win->bg->xs)
            pixmap_setcolor_rect(win->bg, hc, fi_min-win->bg->xs, 0, 
                fi_max-fi_min, win->bg->ys);
    }
    for(i=0; i<win->bg->xs; i+=win->bg->xs/8) 
        pixmap_setcolor_rect(win->bg, lc, i, 0, 1, win->bg->ys);
    pixmap_setcolor_rect(win->bg, lc, win->bg->xs-1, 0, 1, win->bg->ys);
    if (linear) 
        for(i=0; i<win->bg->ys; i+= win->bg->ys/8)
            pixmap_setcolor_rect(win->bg, lc, 0, i, win->bg->xs, 1);
    else
        for(i=0; i<win->bg->ys; i+= opt_ppdb*10.0) {
            col = lc;
            if (i==0 && opt_ref!=0.0)
                col = col_err;
            pixmap_setcolor_rect(win->bg, col, 0, i, win->bg->xs, 1);
        }
}

// Draw a g_window object
//
void
plot_window(g_window *win, int *ppos, int domarker, int *pscale, int linear)
{
    int         i;
    double      *pola;
    double      *polb;
    int         *pola_i;
    int         *polb_i;
    int         pos = *ppos;
    int         scale = *pscale;
    double      xsc = 0.0;
    int         bin_start;
    int         bin_end;



    pola = win->pola;
    polb = win->polb;
    pola_i = win->pola_i;
    polb_i = win->polb_i;

    if (pos<0 || scale==0)
        pos = 0;
    if (pos + win->width*scale > win->bins) {
        pos = win->bins - win->width*scale;
        if (pos < 0) {
            pos = 0;
            scale = 0;
        }
    }
    *ppos = pos;
    *pscale = scale;
        
    if (scale == 0) {
        bin_start = 0;
        bin_end = win->bins;
        xsc = (double) win->bins / (double) win->width;
    } else {
        bin_start = pos;
        bin_end = pos + win->width*scale;
        xsc = (double) scale;
    }
        
    for(i=0; i<win->bins; i++) {
        pola[i] = (double) win->pola_src[i];
        polb[i] = (double) win->polb_src[i];
        if (pola[i] <= 0.5)
            pola[i] = 0.5;
        if (polb[i] <= 0.5)
            polb[i] = 0.5;
    }
    if (win->bins == W_BINS && opt_fix) {
        // Remove DC, fs/2, &fs/4 components of wideband 
        // because they're so ugly...
        pola[win->bins/2] = pola[win->bins/2-1];
        polb[win->bins/2] = polb[win->bins/2-1];
        pola[0] = pola[1];
        polb[0] = polb[1];
        pola[win->bins/4] = pola[win->bins/4-1];
        polb[win->bins/4] = polb[win->bins/4-1];
        pola[3*win->bins/4] = pola[3*win->bins/4-1];
        polb[3*win->bins/4] = polb[3*win->bins/4-1];
    }

    for(i=0; i<win->bins; i++) {
        pola[i] = pola[i] / win->scale; 
        polb[i] = polb[i] / win->scale; 

        if (!linear) {
            if (pola[i] <= 0.0)
                pola[i] = -200.0;
            else 
                pola[i] = 10.0 * log10(pola[i]);
            if (polb[i] <= 0.0)
                polb[i] = -200.0;
            else 
                polb[i] = 10.0 * log10(polb[i]);
        }
    }

    // Copy background in drawing area
    pixmap_copy(win->draw, win->bg, 0, 0);

    // Calculate integer pixel positions
    //
    if (linear) {
        double  sc = 0.0;
        for(i=0; i< win->bins; i++) {
            if (pola[i] > sc)
                sc = pola[i];
            if (polb[i] > sc)
                sc = polb[i];
        }
        win->linmax = sc * win->scale;
        sc *= 1.05;

        for(i=0; i < win->bins; i++) {
            pola_i[i] = (int) (win->bg->ys - pola[i]/sc*win->bg->ys + 0.5);
            if (pola_i[i] < 0)
                pola_i[i] = 0;
            if (pola_i[i] >= win->draw->ys)
                pola_i[i] = win->draw->ys-1;
            polb_i[i] = (int) (win->bg->ys - polb[i]/sc*win->bg->ys + 0.5);
            if (polb_i[i] < 0)
                polb_i[i] = 0;
            if (polb_i[i] >= win->draw->ys)
                polb_i[i] = win->draw->ys-1;
        }
    } else {
        for(i=0; i < win->bins; i++) {
            pola_i[i] = - (int) ((pola[i]-opt_ref)*opt_ppdb + 0.5);
            if (pola_i[i] < 0)
                pola_i[i] = 0;
            if (pola_i[i] >= win->draw->ys)
                pola_i[i] = win->draw->ys-1;
            polb_i[i] = - (int) ((polb[i]-opt_ref)*opt_ppdb + 0.5);
            if (polb_i[i] < 0)
                polb_i[i] = 0;
            if (polb_i[i] >= win->draw->ys)
                polb_i[i] = win->draw->ys-1;
        }
    }

    // Find marker (highest peak)
    //
    if (domarker) {
        if (win->mark_fix) {
            if (win->mark_f < bin_start)
                win->mark_f = bin_start;
            if (win->mark_f >= bin_end)
                win->mark_f = bin_end-1;
        } else {
            if (win->draw_order) {   
                // look in polb
                win->mark_l = polb[bin_start];
                win->mark_f = 0;
                for(i=bin_start; i < bin_end; i++) 
                    if (polb[i] > win->mark_l) {
                        win->mark_l = polb[i];
                        win->mark_f = i;
                    }
            } else {
                // look in pola
                win->mark_l = pola[bin_start];
                win->mark_f = 0;
                for(i=bin_start; i < bin_end; i++) 
                    if (pola[i] > win->mark_l) {
                        win->mark_l = pola[i];
                        win->mark_f = i;
                    }
            }
        }
        if (win->draw_order) {
            win->mark_l = polb[win->mark_f];
            win->mark_y = polb_i[win->mark_f];
        } else {
            win->mark_l = pola[win->mark_f];
            win->mark_y = pola_i[win->mark_f];
        }
        if (win->mark_y >= win->draw->ys)
            win->mark_y = win->draw->ys-1;
    }

    // win->x2 isn't used anymore It used to be useful when
    // the wideband tranform was 256-points and it was 
    // displayed in a 512-pixel window.  Now that the wideband
    // is 512-points, the number of pixels is always <= the
    // number of bins.
    //
    if (win->x2) {
        for(i=0; i<win->width-1; i++) {
            if (win->draw_order) {
                segment_f(win->draw, col_fg0, i*2, pola_i[i],
                    (pola_i[i]+pola_i[i+1])/2);
                segment_f(win->draw, col_fg0, i*2+1, 
                    (pola_i[i]+pola_i[i+1])/2, pola_i[i+1]);
                segment_f(win->draw, col_fg1, i*2, polb_i[i],
                    (polb_i[i]+polb_i[i+1])/2);
                segment_f(win->draw, col_fg1, i*2+1, 
                    (polb_i[i]+polb_i[i+1])/2, polb_i[i+1]);
            } else {
                segment_f(win->draw, col_fg1, i*2, polb_i[i],
                    (polb_i[i]+polb_i[i+1])/2);
                segment_f(win->draw, col_fg1, i*2+1, 
                    (polb_i[i]+polb_i[i+1])/2, polb_i[i+1]);
                segment_f(win->draw, col_fg0, i*2, pola_i[i],
                    (pola_i[i]+pola_i[i+1])/2);
                segment_f(win->draw, col_fg0, i*2+1, 
                    (pola_i[i]+pola_i[i+1])/2, pola_i[i+1]);
            }
        }
        if (domarker)
            draw_marker(win->draw, win->mark_f*2, win->mark_y);
    } else {
        int mid = (N_BINS-1)/2;
        for(i=bin_start; i<bin_end-1; i++) {
            register int x = (int) ((double) (i-bin_start) / xsc + 0.5);
            if (win->draw_order) {
                segment_f(win->draw, col_fg0, x, pola_i[i], pola_i[i+1]);
                segment_f(win->draw, col_fg1, x, polb_i[i], polb_i[i+1]);
            } else {
                segment_f(win->draw, col_fg1, x, polb_i[i], polb_i[i+1]);
                segment_f(win->draw, col_fg0, x, pola_i[i], pola_i[i+1]);
            }
            

        }

        // Little visual pic to mark the middle (DC) bin
        if (mid>bin_start && mid<bin_end-1) {
            register int x = (int) ((double) (mid-bin_start) / xsc + 0.5);
            segment_f(win->draw, col_err, x, pola_i[mid-1], pola_i[mid]);
            segment_f(win->draw, col_err, x, pola_i[mid+1], pola_i[mid]);
            segment_f(win->draw, col_err, x, polb_i[mid-1], polb_i[mid]);
            segment_f(win->draw, col_err, x, polb_i[mid+1], polb_i[mid]);
        }

        if (domarker)
            draw_marker(win->draw, (int) ((double) (win->mark_f-pos)/xsc + 0.5),
                    win->mark_y);
    }
}

// Put status messages up for narrowband window
//
static void
narrow_msg(pixmap *draw, int xs, int pos, int seq, int scale)
{
    double          f_start;
    double          f_stop;
    double          f_center;
    double          f_width;
    char            fstr[80];
    double          n_center = 0.0;
    double          bin_width;
    int             i;

    // If scramnet gave us LO1 and LO2 was specified on command line
    // compute new offset frequency
    //
    if (scram_lo1 > 0.0 && opt_lo2 > 0.0) 
        opt_goff = scram_lo1 - opt_lo2;

    // Width of a narrowband frequency bin
    bin_width = opt_adcfreq / (N_DEC * N_WIDTH);
    n_center = mix_freq();

    // Put up message info
    pixmap_setcolor(draw, C_BLACK);

    if (scale == 0) {
        pos = 0;
        scale = 1;
        xs = N_BINS;
    }

    // Mix freq is center freq of bin (N_BINS-1)/2
    // (assuming that N_OFFSET = (N_WIDTH-N_BINS+1)/2 and N_BINS is odd
    // and N_WIDTH is even. phew.
    //
    // f_start and f_stop are set to center freq of fist bin
    // and last bin in the display
    f_start = bin_width * (pos - (N_BINS-1)/2);
    f_stop =  bin_width * (pos+xs*scale - 1 - (N_BINS-1)/2);

    // The frequency range makes more sense if it covers the
    // left edge of the first bin to the right edge of the last bin.
    // So, we scoot the start/stop freqs by half a bin.
    f_start -= 0.5*bin_width;
    f_stop += 0.5*bin_width;

    f_center = f_start + (f_stop - f_start)/2.0;
    f_width = f_stop - f_start;

    // Offset freqs by mixer and global offset
    f_start += n_center + opt_goff;
    f_stop += n_center + opt_goff;
    f_center += n_center + opt_goff;

    sprintf(fstr, "%0.4f MHz", f_start);
    string("Start", 14, col_lc, 255, draw, 0, 16*1);
    string(fstr, 14, col_lc, 255, draw, 90, 16*1);

    sprintf(fstr, "%0.4f MHz", f_stop);
    string("Stop", 14, col_lc, 255, draw, 0, 16*2);
    string(fstr, 14, col_lc, 255, draw, 90, 16*2);

    sprintf(fstr, "%0.4f MHz", f_center);
    string("Center", 14, col_lc, 255, draw, 
            draw->xs/2, 16*1);
    string(fstr, 14, col_lc, 255, draw, 
            draw->xs/2+90, 16*1);

    sprintf(fstr, "%0.4f MHz", f_width);
    string("Width", 14, col_lc, 255, draw, 
            draw->xs/2, 16*2);
    string(fstr, 14, col_lc, 255, draw, 
            draw->xs/2+90, 16*2);

    sprintf(fstr, "%d", seq & 0xffff);
    string("Seq #", 14, col_lc, 255, draw, 0, 16*3);
    string(fstr, 14, col_lc, 255, draw, 90, 16*3);

    sprintf(fstr, "%d", opt_nshift);
    string("nacc ushift", 14, col_lc, 255, draw, 0, 16*4);
    string(fstr, 14, col_lc, 255, draw, 90, 16*4);

    sprintf(fstr, "%.4f MHz", n_center);
    string("Mixer", 14, col_lc, 255, draw, draw->xs/2, 16*3);
    string(fstr, 14, col_lc, 255, draw, draw->xs/2+90, 16*3);

    string("npfb dshift", 14, col_lc, 255, draw, draw->xs/2, 16*4);
    strcpy(fstr, "0000000000000");
    for(i=0; i<13; i++)
        if (opt_npfb & (1<<i))
            fstr[12-i] = '1';
    string(fstr, 14, col_lc, 255, draw, draw->xs/2+90, 16*4);
}


static void
wide_msg(pixmap *draw, int seq)
{
    char            fstr[80];
    double          n_center = 0.0;
    int             i;
    
    // If scramnet gave us LO1 and LO2 was specified on command line
    // compute new offset frequency
    //
    if (scram_lo1 > 0.0 && opt_lo2 > 0.0) 
        opt_goff = scram_lo1 - opt_lo2;

    n_center = mix_freq();
    pixmap_setcolor(draw, C_BLACK);

    sprintf(fstr, "%d", seq & 0xffff);
    string("Seq #", 14, col_lc, 255, draw, 0, 20+16*0);
    string(fstr, 14, col_lc, 255, draw, 100, 20+16*0);

    sprintf(fstr, "%d", opt_wshift);
    string("wacc ushift", 14, col_lc, 255, draw, 0, 20+16*1);
    string(fstr, 14, col_lc, 255, draw, 100, 20+16*1);

    sprintf(fstr, "%0.4f MHz", opt_goff);
    string("wide center", 14, col_lc, 255, draw, 0, 20+16*2);
    string(fstr, 14, col_lc, 255, draw, 100, 20+16*2);

    sprintf(fstr, "%0.4f MHz", opt_adcfreq);
    string("wide span", 14, col_lc, 255, draw, 0, 20+16*3);
    string(fstr, 14, col_lc, 255, draw, 100, 20+16*3);

    sprintf(fstr, "%0.4f MHz", n_center + opt_goff);
    string("narrow center", 14, col_lc, 255, draw, draw->xs/2, 20+16*0);
    string(fstr, 14, col_lc, 255, draw, draw->xs/2+100, 20+16*0);

    sprintf(fstr, "%0.4f MHz", (double) N_BINS / (double) N_WIDTH *
            opt_adcfreq / N_DEC);
    string("narrow span", 14, col_lc, 255, draw, draw->xs/2, 20+16*1);
    string(fstr, 14, col_lc, 255, draw, draw->xs/2+100, 20+16*1);

    string("wpfb dshift", 14, col_lc, 255, draw, draw->xs/2, 20+16*2);
    strcpy(fstr, "000000000");
    for(i=0; i<9; i++)
        if (opt_wpfb & (1<<i))
            fstr[8-i] = '1';
    string(fstr, 14, col_lc, 255, draw, draw->xs/2+100, 20+16*2);
}

static void
scr_title(Ab **ab, char *cp, int beam, galfa_pkt *gm, int linear)
{
    char    fstr[80];
    char    fstr1[80];
    int     i, j, t, err=0;
    int     errx[8];

    pixmap_setcolor(title_draw, C_BLACK);
    sprintf(fstr1, cp, beam);
    sprintf(fstr, "%s%s", fstr1, linear ? " (L)" : "");
    string(fstr, 20, col_lc, 255, title_draw, 10, 24);
    
    for(j=0; j<8; j++)
        errx[j] = 0;
    err = 0;

    for(i=0; i<G_BEAMS; i++) {
        if (ab[i]) {
            err |= (gm[i].misc >> 16) & 0xffff;
            for(j=0; j<8; j++) {
                t = (((gm[i].misc >> 16) & 0xffff) >> (j*2)) & 0x3;
                if (t>errx[j])
                    errx[j] = t;
            }
        }
    }
            
    if (err) {
        sprintf(fstr, "Error: A%d Narrow MLFS=%d%d%d%d, Wide FS=%d%d",
            errx[6],
            errx[5],
            errx[4],
            errx[3],
            errx[2],
            errx[1],
            errx[0]
        );
        string(fstr, 14, col_err, 255, title_draw, 10, 44);
    }
    if (scram_radec_tm) {
        int         rah, ram, ras, rats;
        double      ra;
        int         dech, decm, decs, dects;
        double      dec;

        ra = scram_ra * (24.0 * 3600.0) / (2.0 * M_PI);
        rah = ra / 3600.0;
        ra -= rah * 3600;
        ram = ra / 60.0;
        ra -= ram * 60;
        ras = ra;
        rats =  10.0 * (ra - (double) ras) + 0.5;
        if (rats > 9) rats = 9;

        dec = scram_dec * (360.0 * 60.0 * 60.0) / (2.0 * M_PI);
        dech = dec / 3600.0;
        dec -= dech * 3600;
        decm = dec / 60.0;
        dec -= decm * 60;
        decs = dec;
        dects =  10.0 * (dec - (double) decs) + 0.5;
        if (dects > 9) dects = 9;

        sprintf(fstr, "RaJ %02d:%02d:%02d.%d  DecJ %02d:%02d:%02d.%d",
            rah, ram, ras, rats,
            dech, decm, decs, dects);
        string(fstr, 14, col_lc, 255, title_draw, 10, 62);
    }

    if (opt_lo2 > 0.0 && scram_lo1 > 0.0) {
        sprintf(fstr, "LO1 %.2f MHz LO2 %.2f MHz",
            scram_lo1, opt_lo2);
        string(fstr, 14, col_lc, 255, title_draw, 10, 80);
    }
        
    pixmap_copy(title, title_draw, 0, 0);
}

//  Plot galfa packets in interesting ways
//
void
galfa_scope(Ab **ab, int mode)
{
    galfa_pkt       gm[G_BEAMS];
    galfa_pkt       *gmp[G_BEAMS];
    int             gwrite = 1;
    int             linear = 0;
    int             redraw_bg = 0;

    struct timeval  tv;
    char            fstr[80];
    int             redraw;
    int             last_seq=0;
    double          f_mark;
    double          n_center = 0.0;

    int             border=8;
    int             i;
    int             l=0;

    pixmap          *logo, *logo_dest=0;
    pixmap          *egg, *egg_dest=0;

    // wideband scope parameters
    g_window        ws_win;

    // narrowband scope parameters
    g_window        ns_win;
    pixmap          *ns_ov, *ns_ov_draw;
    pixmap          *ns_msg, *ns_msg_draw;
    int             n_pos=0;
    int             n_scale=1;
    int             w_pos=0;
    int             w_scale=1;

    // multi-beam parameters
    g_window        mw_win[G_BEAMS];    // wideband windows
    g_window        mn_win[G_BEAMS];    // narrowband windows
    pixmap          *mn_ov=0, *mn_ov_draw=0;
    pixmap          *m_msg, *m_msg_draw;

    read_dac_file();

    for(i=0; i<G_BEAMS; i++)
        gmp[i] = ab[i] ? &gm[i] : NULL;
        
    // Clear the screen
    pixmap_setcolor(fb, C_BLACK);

    // Stuff for drawing title message
    title = pixmap_subset(fb, border, border, 286, 84);
    title_draw = pixmap_dup(title);


    logo = pixmap_readjpeg("/etc/alfalogo.jpg");
    if (logo) 
        logo_dest = pixmap_subset(fb, fb->xs - border - logo->xs, 
            fb->ys - border - logo->ys,  logo->xs, logo->ys);
    else 
        printf("Cannot read logo!\n");

    egg = pixmap_readjpeg("/var/egg.jpg");
    if (egg) 
        egg_dest = pixmap_subset(fb, fb->xs - border - egg->xs, 
            fb->ys - border - egg->ys - 50,  egg->xs, egg->ys);

    // Make drawing stuff for the wideband scope
    //
    ws_win.bins = W_BINS;
    ws_win.width = 512;
    ws_win.height = 296;
    ws_win.pola = malloc(sizeof(double) * W_BINS);                
    ws_win.polb = malloc(sizeof(double) * W_BINS);                
    ws_win.pola_i = malloc(sizeof(int) * W_BINS);                
    ws_win.polb_i = malloc(sizeof(int) * W_BINS);                
    ws_win.screen = pixmap_subset(fb, (fb->xs-ws_win.width)/2, 
        (fb->ys-ws_win.height)/2, ws_win.width, ws_win.height);
    ws_win.draw = pixmap_dup(ws_win.screen);
    ws_win.bg = pixmap_dup(ws_win.screen);
    ws_win.mark_fix = 0;
    ws_win.draw_order = 0;
    ws_win.scale = (double) W_MAX;
    ws_win.pola_src = gm[opt_beam].pola_w;
    ws_win.polb_src = gm[opt_beam].polb_w;
    ws_win.x2 = 0;
    ws_draw_bg(&ws_win, col_bg, col_lc, col_hc, linear);

    // Make drawing stuff for the narrowband scope
    //
    ns_win.width = (fb->xs - 2*border) | 1;
    ns_win.height = 344;
    ns_win.bins = N_BINS;
    ns_win.pola = malloc(sizeof(double) * N_BINS);                
    ns_win.polb = malloc(sizeof(double) * N_BINS);                
    ns_win.pola_i = malloc(sizeof(int) * N_BINS);                
    ns_win.polb_i = malloc(sizeof(int) * N_BINS);                
    ns_win.screen = pixmap_subset(fb, (fb->xs-ns_win.width)/2, 100,
        ns_win.width, ns_win.height);
    ns_win.draw = pixmap_dup(ns_win.screen);
    ns_win.bg = pixmap_dup(ns_win.screen);
    ns_win.mark_fix = 0;
    ns_win.draw_order = 0;
    ns_win.scale = (double) N_MAX;
    ns_win.pola_src = gm[opt_beam].pola_n;
    ns_win.polb_src = gm[opt_beam].polb_n;
    ns_win.x2 = 0;
    ns_msg = pixmap_subset(fb, (fb->xs-ns_win.width)/2, 
        100+border+ns_win.height, 500, 100);
    ns_ov = pixmap_subset(fb, (fb->xs-ns_win.width)/2 + ns_win.width - 200, 
        50, 200, 32);
    ns_draw_bg(&ns_win, col_bg, col_lc, linear);
    ns_msg_draw = pixmap_dup(ns_msg);
    ns_ov_draw = pixmap_dup(ns_ov);

    // Make drawing stuff for multi-beam views
    //
    for(i=0; i<G_BEAMS; i++) {
        int     xs = 256;
        int     ys = 160;
        int     xo=0, yo=0;

        //
        //     2   1
        //   3   0   6
        //     4   5
        //
        switch (i) {
            case 0:     xo = (fb->xs - xs)/2;
                        yo = (fb->ys - ys)/2;
                        break;
            case 1:     xo = (fb->xs + border)/2;
                        yo = (fb->ys - ys)/2 - ys - border;
                        break;
            case 2:     xo = (fb->xs + border)/2 - xs - border;
                        yo = (fb->ys - ys)/2 - ys - border;
                        break;
            case 3:     xo = (fb->xs - xs)/2 - xs - border;
                        yo = (fb->ys - ys)/2;
                        break;
            case 4:     xo = (fb->xs + border)/2 - xs - border;
                        yo = (fb->ys - ys)/2 + ys + border;
                        break;
            case 5:     xo = (fb->xs + border)/2;
                        yo = (fb->ys - ys)/2 + ys + border;
                        break;
            case 6:     xo = (fb->xs - xs)/2 + xs + border;
                        yo = (fb->ys - ys)/2;
                        break;
        }
        yo += 46;

        mw_win[i].width = xs;
        mw_win[i].height = ys;
        mw_win[i].bins = W_BINS;
        mw_win[i].pola = malloc(sizeof(double) * W_BINS);                
        mw_win[i].polb = malloc(sizeof(double) * W_BINS);                
        mw_win[i].pola_i = malloc(sizeof(int) * W_BINS);                
        mw_win[i].polb_i = malloc(sizeof(int) * W_BINS);                
        mw_win[i].screen = pixmap_subset(fb, xo, yo, xs, ys);
        mw_win[i].draw = pixmap_dup(mw_win[i].screen);
        mw_win[i].bg = pixmap_dup(mw_win[i].screen);
        mw_win[i].mark_fix = 0;
        mw_win[i].draw_order = 0;
        mw_win[i].scale = (double) W_MAX;
        mw_win[i].pola_src = gm[i].pola_w;
        mw_win[i].polb_src = gm[i].polb_w;
        mw_win[i].x2 = 0;
        ws_draw_bg(&mw_win[i], col_bg, col_lc, col_hc, linear);

        mn_win[i].width = xs;
        mn_win[i].height = ys;
        mn_win[i].bins = N_BINS;
        mn_win[i].pola = malloc(sizeof(double) * N_BINS);                
        mn_win[i].polb = malloc(sizeof(double) * N_BINS);                
        mn_win[i].pola_i = malloc(sizeof(int) * N_BINS);                
        mn_win[i].polb_i = malloc(sizeof(int) * N_BINS);                
        mn_win[i].screen = pixmap_subset(fb, xo, yo, xs, ys);
        mn_win[i].draw = pixmap_dup(mn_win[i].screen);
        mn_win[i].bg = pixmap_dup(mn_win[i].screen);
        mn_win[i].mark_fix = 0;
        mn_win[i].draw_order = 0;
        mn_win[i].scale = (double) N_MAX;
        mn_win[i].pola_src = gm[i].pola_n;
        mn_win[i].polb_src = gm[i].polb_n;
        mn_win[i].x2 = 0;
        ns_draw_bg(&mn_win[i], col_bg, col_lc, linear);

        if (i==1) {
            int t = xo + xs + border;
            mn_ov = pixmap_subset(fb, t, yo, fb->xs-t-border, 32);
            mn_ov_draw = pixmap_dup(mn_ov);
        }
    }
    m_msg = pixmap_subset(fb, fb->xs/2-100, border, fb->xs/2+100, 80);
    m_msg_draw = pixmap_dup(m_msg);

    // Set upshift for transforms in xilinx chip
    //
    g_set_shift(ab);

    if (io_open(ab)) {
        printf("Not writing FITS file.\n");
        gwrite = 0;
    }

    // Big main loop
    //
    g_capture_start(ab, CAP_PFB);
    while (1) {
        redraw = 0;
        redraw_bg = 0;
        while (kbhit()) {
            int ch;
            ch = readch();
            switch (ch) {

                // Make plot file
                case 'p':   screen_print(fb);
                            break;

                // toggle through viewing modes
                case 'a':   if (++mode >= gmode_last)
                                mode = gmode_wscope;
                            pixmap_setcolor(fb, C_BLACK);
                            redraw = 1;
                            break;
                
                // toggle through viewing modes
                case 'A':   if (--mode < 0)
                                mode = gmode_nmulti;
                            pixmap_setcolor(fb, C_BLACK);
                            redraw = 1;
                            break;
                
                // toggle linear display mode
                case 'h':   linear = !linear;
                            redraw_bg = 1;
                            break;
                
                // view more dynamic range
                case 'c':   if (linear)
                                break;
                            if ((opt_ppdb -= 0.2) < 1.0)
                                opt_ppdb = 1.0;
                            redraw_bg = 1;
                            break;

                // view less dynamic range
                case 'v':   if (linear)
                                break;
                            if ((opt_ppdb += 0.2) > 20.0)
                                opt_ppdb = 20.0;
                            redraw_bg = 1;
                            break;

                // toggle through mixer frequencies
                case 'w':   ++opt_mix;
                            g_set_shift(ab);
                            redraw_bg = 1;
                            break;
                case 'W':   --opt_mix;
                            g_set_shift(ab);
                            redraw_bg = 1;
                            break;
    
    
                // view a particular beam
                case '0':
                case '1':
                case '2':
                case '3':
                case '4':
                case '5':
                case '6':   if (ab[ch-'0']) {
                                opt_beam = ch - '0';
                                if (mode == gmode_wmulti) {
                                    pixmap_setcolor(fb, C_BLACK);
                                    mode = gmode_wscope;
                                }
                                if (mode == gmode_nmulti) {
                                    pixmap_setcolor(fb, C_BLACK);
                                    mode = gmode_nscope;
                                }
                                // Make sure scrolling windows don't fall off
                                // end of display
                                if (mode == gmode_nscope) 
                                    if (n_pos > N_BINS-ns_win.width*n_scale)   
                                        n_pos = N_BINS-ns_win.width*n_scale;
                                if (mode == gmode_nmulti) 
                                    if (n_pos > N_BINS-mn_win[0].width*n_scale) 
                                        n_pos = N_BINS-mn_win[0].width*n_scale;
                                ws_win.pola_src = gm[opt_beam].pola_w;
                                ws_win.polb_src = gm[opt_beam].polb_w;
                                ns_win.pola_src = gm[opt_beam].pola_n;
                                ns_win.polb_src = gm[opt_beam].polb_n;
                                redraw = 1;
                            }
                            break;

                case '[':   opt_ref -= 10.0;
                            if (opt_ref < -90.0)
                                opt_ref = -90.0;
                            redraw_bg = 1;
                            break;
        
                case ']':   opt_ref += 10.0;
                            if (opt_ref > 0.0)
                                opt_ref = 0.0;
                            redraw_bg = 1;
                            break;

                case '(':   // Enable PFB mode
                            AbGkReg(ab, Gk_diag, diag_reg & ~0x30);
                            break;

                case ')':   // Bypass PFBs (they just become FFTs)
                            AbGkReg(ab, Gk_diag, diag_reg | 0x30);
                            break;

                // quit program
                case 0x03:
                case 'q':   if (gwrite)
                                io_close();
                            release_lock();
                            gexit(1);

                default:    // printf("Unknown key: '%c'\n", ch);
                            break;
            }
            if (mode==gmode_wscope) switch(ch) {

                // Change drawing order for polarizations
                case 'o':   ws_win.draw_order = !ws_win.draw_order;
                            redraw = 1;
                            break;

                // descrease shift
                case 'z':   if (--opt_wshift < 0)
                                opt_wshift = 0;
                            g_set_shift(ab);
                            redraw = 1;
                            break;

                // increase shift
                case 'x':   if (++opt_wshift > 7)
                                opt_wshift = 7;
                            g_set_shift(ab);
                            redraw = 1;
                            break;

                // move marker left
                case 'n':   if (--ws_win.mark_f < 0)
                                ws_win.mark_f = 0;
                            ws_win.mark_fix = 1;
                            redraw = 1;
                            break;

                // move marker right
                case 'm':   if (++ws_win.mark_f >= W_BINS)
                                ws_win.mark_f = W_BINS-1;
                            ws_win.mark_fix = 1;
                            redraw = 1;
                            break;

                // auto place marker at peak
                case 'b':   ws_win.mark_fix = 0;
                            redraw = 1;
                            break;

                // decrease downshift of PFB
                case 'd':   opt_wpfb = g_vec_add(opt_wpfb, 9, -1);
                            g_set_shift(ab);
                            redraw = 1;
                            break;

                // increase downshift of PFB
                case 'f':   opt_wpfb = g_vec_add(opt_wpfb, 9, 1);
                            g_set_shift(ab);
                            redraw = 1;
                            break;

            }
            if (mode==gmode_wmulti) switch(ch) {

                // Change drawing order for polarizations
                case 'o':   for(i=0; i<G_BEAMS; i++)
                                mw_win[i].draw_order = !mw_win[i].draw_order;
                            redraw = 1;
                            break;

                // descrease shift
                case 'z':   if (--opt_wshift < 0)
                                opt_wshift = 0;
                            g_set_shift(ab);
                            redraw = 1;
                            break;

                // increase shift
                case 'x':   if (++opt_wshift > 7)
                                opt_wshift = 7;
                            g_set_shift(ab);
                            redraw = 1;
                            break;

                // decrease downshift of PFB
                case 'd':   opt_wpfb = g_vec_add(opt_wpfb, 9, -1);
                            g_set_shift(ab);
                            redraw = 1;
                            break;

                // increase downshift of PFB
                case 'f':   opt_wpfb = g_vec_add(opt_wpfb, 9, 1);
                            g_set_shift(ab);
                            redraw = 1;
                            break;
            }
            if (mode==gmode_nscope) switch(ch) {

                // Change drawing order for polarizations
                case 'o':   ns_win.draw_order = !ns_win.draw_order;
                            redraw = 1;
                            break;

                // descrease shift
                case 'z':   if (--opt_nshift < 0)
                                opt_nshift = 0;
                            g_set_shift(ab);
                            redraw = 1;
                            break;

                // increase shift
                case 'x':   if (++opt_nshift > 7)
                                opt_nshift = 7;
                            g_set_shift(ab);
                            redraw = 1;
                            break;

                // move marker left
                case 'n':   --ns_win.mark_f;
                            ns_win.mark_fix = 1;
                            redraw = 1;
                            break;

                // move marker right
                case 'm':   ++ns_win.mark_f;
                            ns_win.mark_fix = 1;
                            redraw = 1;
                            break;

                // auto place marker at peak
                case 'b':   ns_win.mark_fix = 0;
                            redraw = 1;
                            break;

                // scroll window left
                case ',':   if ((n_pos--) < 0)   
                                n_pos = 0;
                            redraw = 1;
                            break;

                // scrool window right
                case '.':   if ((n_pos++) > N_BINS-ns_win.width*n_scale) 
                                n_pos = N_BINS-ns_win.width*n_scale;
                            redraw = 1;
                            break;

                // scroll window left a lot
                case '<':   if ((n_pos-= ns_win.width*n_scale/8) < 0)   
                                n_pos = 0;
                            redraw = 1;
                            break;

                // scrool window right a lot
                case '>':   if ((n_pos+= ns_win.width*n_scale/8) > 
                                    N_BINS-ns_win.width*n_scale)
                                n_pos = N_BINS-ns_win.width*n_scale;
                            redraw = 1;
                            break;

                case 'k':   if (n_scale == 0)
                                n_scale = (N_BINS / ns_win.width) & ~1;
                            else if ((n_scale-=2) < 1)
                                n_scale = 1;
                            redraw = 1;
                            break;
    
                case 'l':   if (n_scale != 0)
                                n_scale += 2;
                            redraw = 1;
                            break;

                case 'K':   n_scale = 1;
                            redraw = 1;
                            break;

                case 'L':   n_scale = 0;
                            redraw = 1;
                            break;

                // decrease downshift of PFB
                case 'd':   opt_npfb = g_vec_add(opt_npfb, 13, -1);
                            g_set_shift(ab);
                            redraw = 1;
                            break;

                // increase downshift of PFB
                case 'f':   opt_npfb = g_vec_add(opt_npfb, 13, 1);
                            g_set_shift(ab);
                            redraw = 1;
                            break;
            }
            if (mode==gmode_nmulti) switch(ch) {

                // Change drawing order for polarizations
                case 'o':   for(i=0; i<G_BEAMS; i++)
                                mn_win[i].draw_order = !mn_win[i].draw_order;
                            redraw = 1;
                            break;

                // descrease shift
                case 'z':   if (--opt_nshift < 0)
                                opt_nshift = 0;
                            g_set_shift(ab);
                            redraw = 1;
                            break;

                // increase shift
                case 'x':   if (++opt_nshift > 7)
                                opt_nshift = 7;
                            g_set_shift(ab);
                            redraw = 1;
                            break;

                // scroll window left
                case ',':   if ((n_pos--) < 0)   
                                n_pos = 0;
                            redraw = 1;
                            break;

                // scrool window right
                case '.':   if ((n_pos++) > N_BINS-mn_win[0].width*n_scale)   
                                n_pos = N_BINS-mn_win[0].width*n_scale;
                            redraw = 1;
                            break;

                // scroll window left a lot
                case '<':   if ((n_pos-= mn_win[0].width*n_scale/8) < 0)   
                                n_pos = 0;
                            redraw = 1;
                            break;

                // scrool window right a lot
                case '>':   if ((n_pos += mn_win[0].width*n_scale/8) > 
                                    N_BINS-mn_win[0].width*n_scale)
                                n_pos = N_BINS-mn_win[0].width*n_scale;
                            redraw = 1;
                            break;

                case 'k':   if (n_scale == 0)
                                n_scale = (N_BINS / mn_win[0].width) & ~1;
                            else if ((n_scale-=2) < 1)
                                n_scale = 1;
                            redraw = 1;
                            break;
    
                case 'l':   if (n_scale != 0)
                                n_scale += 2;
                            redraw = 1;
                            break;

                case 'K':   n_scale = 1;
                            redraw = 1;
                            break;

                case 'L':   n_scale = 0;
                            redraw = 1;
                            break;

                // decrease downshift of PFB
                case 'd':   opt_npfb = g_vec_add(opt_npfb, 13, -1);
                            g_set_shift(ab);
                            redraw = 1;
                            break;

                // increase downshift of PFB
                case 'f':   opt_npfb = g_vec_add(opt_npfb, 13, 1);
                            g_set_shift(ab);
                            redraw = 1;
                            break;
            }
        }

        if (g_capture_complete(ab)) {
            gettimeofday(&tv, NULL);

            // The passed value is the best knowledge about when the
            // next integration began (and the computer is notified that
            // the spectrometer boards have transferred the previous seconds
            // data).  Subtract one to get the time that integration began.
            //
            // To the best of this computers knowledge, this is when the
            // integration began.  Well, this is the best knowledge about
            // when the PPS occured that began the integration.  The integration
            // began about 5ms after the PPS (5*14*8192 100MHz clocks).
            //
            // Assume that PPS is locked to the beginning of the UTC second.
            // This computer's clock is probably +/-10ms (?).  The timestamping
            // can be -0/+many milliseconds.  So it's probably best to take
            // the following tv timeval, round to the nearest second, and
            // assuming PPS is locked to UTC seconds (and good carma) the
            // result of the rounding is the second in which the integration
            // began (actually about 5ms after the second).
            //
            tv.tv_sec--;

            AbGkRegOne(ab, 0, Gk_led3, l);
            l = !l;
            g_capture_copy(ab,gm);
            g_capture_start(ab, CAP_PFB);
            redraw = 1;

            last_seq = (last_seq+1) & 0xffff;
            if (last_seq != (gm[0].misc & 0xffff))  {
                // printf("Seq mismatch, expected %d, got %lu\n", 
                //     last_seq, gm[0].misc & 0xffff);
            } else {
                // Write out data
                //
                if (gwrite)
                    if (io_write(ab, gmp, &tv)) {
                        release_lock(); 
                        gexit(0);
                    }
            }
            last_seq = gm[0].misc & 0xffff;
            // printf("overflow: %04x\n", (gm[0].misc >> 16) & 0xffff);
        }

        if (opt_sock) 
            gsock_listen(ab, &redraw_bg);

        if (redraw_bg) {
            ws_draw_bg(&ws_win, col_bg, col_lc, col_hc, linear);
            ns_draw_bg(&ns_win, col_bg, col_lc, linear);
            for(i=0; i<G_BEAMS; i++) {
                ws_draw_bg(&mw_win[i], col_bg, col_lc, col_hc,
                    linear);
                ns_draw_bg(&mn_win[i], col_bg, col_lc, linear);
            }
            redraw = 1;
        }

        if (!redraw) {
            // usleep(20000);
            continue;
        }

        n_center = mix_freq();
        switch (mode) {
            case gmode_wscope:
                w_scale = 1;
                plot_window(&ws_win, &w_pos, 1, &w_scale, linear);

                // Add marker text
                f_mark = opt_adcfreq * ((double) ws_win.mark_f - 
                        W_BINS/2) / W_BINS;
                f_mark += opt_goff;
                if (linear) {
                    sprintf(fstr, "Polarization %s %smarker %g @ %.2f Mhz",
                        ws_win.draw_order ? "B" : "A",
                        ws_win.mark_fix ? "manual ":"", 
                        ws_win.linmax, f_mark);
                    string(fstr, 14, ws_win.draw_order ? col_fg1 : col_fg0, 
                        192, ws_win.draw, 10, 20);
                } else {
                    sprintf(fstr, "Polarization %s %smarker %.2f dB @ %.2f Mhz",
                        ws_win.draw_order ? "B" : "A",
                        ws_win.mark_fix ? "manual ":"", ws_win.mark_l, f_mark);
                    string(fstr, 14, ws_win.draw_order ? col_fg1 : col_fg0, 
                        192, ws_win.draw, 10, 20);
                }

                // Copy drawing onto screen
                pixmap_copy(ws_win.screen, ws_win.draw, 0, 0);

                // Message window
                wide_msg(m_msg_draw, gm[0].misc);
                pixmap_copy(m_msg, m_msg_draw, 0, 0);

                // Put up title
                scr_title(ab,  "Wideband beam %d", opt_beam, gm, linear);
                break;

            case gmode_nscope:
                plot_window(&ns_win, &n_pos, 1, &n_scale, linear);

                // Add marker text
                f_mark = (opt_adcfreq / (N_DEC*N_WIDTH)) * 
                        (ns_win.mark_f - (N_BINS-1)/2);
                f_mark += n_center + opt_goff;
                if (linear) {
                    sprintf(fstr, "Polarization %s %smarker %g @ %.4f Mhz",
                        ns_win.draw_order ? "B" : "A",
                        ns_win.mark_fix ? "manual " : "", 
                        ns_win.linmax, f_mark);
                    string(fstr, 14, ns_win.draw_order ? col_fg1 : col_fg0, 
                        192, ns_win.draw, 10, 20);
                } else {
                    sprintf(fstr, "Polarization %s %smarker %.2f dB @ %.4f Mhz",
                        ns_win.draw_order ? "B" : "A",
                        ns_win.mark_fix ? "manual " : "", ns_win.mark_l, 
                        f_mark);
                    string(fstr, 14, ns_win.draw_order ? col_fg1 : col_fg0, 
                        192, ns_win.draw, 10, 20);
                }

                // Copy onto screen
                pixmap_copy(ns_win.screen, ns_win.draw, 0, 0);

                // Make overview window
                pixmap_setcolor(ns_ov_draw, col_bg);
                pixmap_setcolor_rect(ns_ov_draw, col_fg2,
                        ns_ov_draw->xs * n_pos / N_BINS,
                        ns_ov_draw->ys/2,
                        n_scale==0 ? ns_ov_draw->xs :
                            ns_ov_draw->xs * ns_win.width * n_scale / N_BINS, 
                        ns_ov_draw->ys/2);
                pixmap_setcolor_rect(ns_ov_draw, col_lc, 0, ns_ov_draw->ys/4, 1,
                        ns_ov_draw->ys - ns_ov_draw->ys/4);
                pixmap_setcolor_rect(ns_ov_draw, col_lc, ns_ov_draw->xs/2,
                        ns_ov_draw->ys - ns_ov_draw->ys/4, 1, ns_ov_draw->ys/4);
                pixmap_setcolor_rect(ns_ov_draw, col_lc, ns_ov_draw->xs-1, 
                        ns_ov_draw->ys/4, 1, ns_ov_draw->ys - ns_ov_draw->ys/4);
                pixmap_setcolor_rect(ns_ov_draw, col_lc, 0, ns_ov_draw->ys-1, 
                        ns_ov_draw->xs, 1);
                pixmap_copy(ns_ov, ns_ov_draw, 0, 0);

                // Put text in msg window
                narrow_msg(ns_msg_draw, ns_win.screen->xs, n_pos, gm[0].misc,
                    n_scale);
                pixmap_copy(ns_msg, ns_msg_draw, 0, 0);

                // Put up title
                scr_title(ab,  "Narrowband beam %d", opt_beam, gm, linear);
                break;

            case gmode_wmulti:
                for(i=0; i<G_BEAMS; i++)
                    if (ab[i]) {
                        w_scale = 2;
                        plot_window(&mw_win[i], &w_pos, 0, &w_scale, linear);
                        sprintf(fstr, "Beam %d", i);
                        string(fstr, 14, col_lc, 192, mw_win[i].draw, 10, 20);
                    }
                for(i=0; i<G_BEAMS; i++)
                    if (ab[i])
                        pixmap_copy(mw_win[i].screen, mw_win[i].draw, 0, 0);
                    else
                        pixmap_copy(mw_win[i].screen, mw_win[i].bg, 0, 0);

                // Message window
                wide_msg(m_msg_draw, gm[0].misc);
                pixmap_copy(m_msg, m_msg_draw, 0, 0);

                // Put up title
                scr_title(ab,  "Wideband multibeam", 0, gm, linear);
                break;

            case gmode_nmulti:
                for(i=0; i<G_BEAMS; i++)
                    if (ab[i]) {
                        plot_window(&mn_win[i], &n_pos, 0, &n_scale, linear);
                        sprintf(fstr, "Beam %d", i);
                        string(fstr, 14, col_lc, 192, mn_win[i].draw, 10, 20);
                    }
                for(i=0; i<G_BEAMS; i++)
                    if (ab[i])
                        pixmap_copy(mn_win[i].screen, mn_win[i].draw, 0, 0);
                    else
                        pixmap_copy(mn_win[i].screen, mn_win[i].bg, 0, 0);

                // Make overview window
                pixmap_setcolor(mn_ov_draw, col_bg);
                pixmap_setcolor_rect(mn_ov_draw, col_fg2,
                        mn_ov_draw->xs * n_pos / N_BINS,
                        mn_ov_draw->ys/2,
                        n_scale==0 ? mn_ov_draw->xs :
                            mn_ov_draw->xs * mn_win[0].width * n_scale / N_BINS,
                        mn_ov_draw->ys/2);
                pixmap_setcolor_rect(mn_ov_draw, col_lc, 0, mn_ov_draw->ys/4, 1,
                        mn_ov_draw->ys - mn_ov_draw->ys/4);
                pixmap_setcolor_rect(mn_ov_draw, col_lc, mn_ov_draw->xs/2,
                        mn_ov_draw->ys - mn_ov_draw->ys/4, 1, mn_ov_draw->ys/4);
                pixmap_setcolor_rect(mn_ov_draw, col_lc, mn_ov_draw->xs-1, 
                        mn_ov_draw->ys/4, 1, mn_ov_draw->ys - mn_ov_draw->ys/4);
                pixmap_setcolor_rect(mn_ov_draw, col_lc, 0, mn_ov_draw->ys-1, 
                        mn_ov_draw->xs, 1);
                pixmap_copy(mn_ov, mn_ov_draw, 0, 0);

                // Put up message info
                narrow_msg(m_msg_draw, mn_win[0].screen->xs, n_pos, 
                    gm[0].misc, n_scale);
                pixmap_copy(m_msg, m_msg_draw, 0, 0);

                // Put up title
                scr_title(ab,  "Narrowband multibeam", 0, gm, linear);
                break;
            
            default:
                printf("Got in an unknown mode: %d.\n", mode);
                if (gwrite)
                    io_close();
                release_lock();
                gexit(1);
        }
        if (logo)
            pixmap_copy(logo_dest, logo, 0, 0);
        if (egg)
            pixmap_copy(egg_dest, egg, 0, 0);
    }
}

//  Write galfa packets in a FITS file
//
void
galfa_run(Ab **ab)
{
    galfa_pkt       gm[G_BEAMS];
    galfa_pkt       *gmp[G_BEAMS];

    struct timeval  tv;
    int             last_seq=0;
    int             i;
    int             l = 0;
    int             redraw=0;

    read_dac_file();
    g_set_shift(ab);
    for(i=0; i<G_BEAMS; i++)
        gmp[i] = ab[i] ? &gm[i] : NULL;

    if (io_open(ab))
        exit(1);

    g_capture_start(ab, CAP_PFB);
    while (1) {
        if (g_capture_complete(ab)) {
            gettimeofday(&tv, NULL);

            // The passed value is the best knowledge about when the
            // next integration began (and the computer is notified that
            // the spectrometer boards have transferred the previous seconds
            // data).  Subtract one to get the time that integration began.
            //
            // To the best of this computers knowledge, this is when the
            // integration began.  Well, this is the best knowledge about
            // when the PPS occured that began the integration.  The integration
            // began about 5ms after the PPS (5*14*8192 100MHz clocks).
            //
            // Assume that PPS is locked to the beginning of the UTC second.
            // This computer's clock is probably +/-10ms (?).  The timestamping
            // can be -0/+many milliseconds.  So it's probably best to take
            // the following tv timeval, round to the nearest second, and
            // assuming PPS is locked to UTC seconds (and good carma) the
            // result of the rounding is the second in which the integration
            // began (actually about 5ms after the second).
            //
            tv.tv_sec--;

            AbGkRegOne(ab, 0, Gk_led3, l);
            l = !l;
            g_capture_copy(ab,gm);
            g_capture_start(ab, CAP_PFB);

            last_seq = (last_seq+1) & 0xffff;
            if (last_seq != (gm[0].misc & 0xffff))  {
                // io_write will do the complaining...
                //
                // printf("Seq mismatch, expected %d, got %lu\n", 
                //     last_seq, gm[0].misc & 0xffff);
            } else {
                // Write out data
                //
                if (io_write(ab, gmp, &tv))
                    exit(1);
            }
            last_seq = gm[0].misc & 0xffff;
        }

        if (opt_sock)
            gsock_listen(ab, &redraw);

        usleep(20000);
    }
    if (!io_close())
        printf("Acquisition completed normally.\n");
    
    exit(0);
}

