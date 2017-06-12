

#include "ab.h"
#include "pixmap.h"
#include <math.h>
#include <fftw3.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>
#include <getopt.h>

#include "galfa_sock/galfa_sock.h"
#include "galfa.h"

static char *lockfn = "/tmp/galfa.lock";
int     galfa_pid;

//
void
get_lock(void)
{
    struct stat     sbuf;
    FILE            *fp;
    int             opid;
    char            fnproc[80];


    galfa_pid = getpid();
    if (!stat(lockfn, &sbuf)) {
        // Lock file exists, figure out what process has it.
        fp = fopen(lockfn, "r");
        if (fscanf(fp, "%d", &opid) != 1) {
            printf("Hmm, bogus lock file gnarling things up: %s\n", lockfn);
            exit(1);
        }
        fclose(fp);

        // Figure out if process holding lock is still running
        sprintf(fnproc, "/proc/%d", opid);
        if (!stat(fnproc, &sbuf)) {
            // /proc for process exists
            printf("Galfa appears to already be running, pid %d\n", opid);
            exit(1);
        } else {
            printf("Deleting stale lock file from pid %d.\n", opid);
            if (unlink(lockfn)) {
                printf("Cannot delete stale lock %s\n", lockfn);     
                exit(1);
            }
        }
    }
        
    fp = fopen(lockfn, "w");
    if (fp == NULL) {
        printf("Cannot create lock file.\n");
        exit(1);
    }
    fprintf(fp, "%d\n", galfa_pid);
    fclose(fp);
}

//
void
release_lock(void)
{
    if (unlink(lockfn)) 
        printf("Cannot delete lock file.\n");
}
        

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
string(char *cp, int sz, pixel c, alpha a, pixmap *pm, int x, int y)
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

//  Do capture on PCI bus.  This might be ADC samples or PFB samples
//  or maybe something else selected by msel
//
//  This is the 'old' way to capture and is used by the 'old' 
//  diagnostics for looking at data in scope mode and such.
//  The galfa code uses a different mechanism for capturing 
//  data.  Well, same mechanism, better code...
//
void
adc_capture(Ab *ab, int msel, int dec_n, int dec_off, 
        s_char **a0, s_char **a1, s_char **a2, s_char **a3)
{
    u_long      ctl0;
    int         to=0;

    // Start capture
    ctl0 = ab->ctl[0] & 0xffffffa3;

    // for(j=0; j<ab->mbus_len/4; j++)
    //     ab->mbus[j] = 0;

    // Start capture
    ab->ctl[4] = (dec_off & 0xff) | ((dec_n & 0xff) << 8);
    ab->ctl[0] = ctl0 | 0x4 | ((msel & 0x3) << 3);
    ab->ctl[0] = ctl0 | 0x0 | ((msel & 0x3) << 3);

    // Wait for capture to finish 
    while (!(ab->ctl[2] & 0x8)) {
        if (to++ == 100000) {
            to = 0;
            if (kbhit())
                break;
        }
    }        

    *a0 = ((s_char *) ab->mbus) + 0*ab->mbus_len/4;
    *a1 = ((s_char *) ab->mbus) + 1*ab->mbus_len/4;
    *a2 = ((s_char *) ab->mbus) + 2*ab->mbus_len/4;
    *a3 = ((s_char *) ab->mbus) + 3*ab->mbus_len/4;
}

static void
set_mix(Ab **ab)
{
#ifdef NEW_MIXER
    AbGkReg(ab, Gk_nmixer, opt_mix & 0x1f);
#else
    int     v=0;
    switch(opt_mix) {
        case MIX_NEG:   v = 0x2; break;
        case MIX_DC:    v = 0x1; break;
        case MIX_POS:   v = 0x0; break;
    }
    AbGkReg(ab, Gk_mixer, v);
#endif
}

void
g_set_shift(Ab **ab)
{
    AbGkReg(ab, Gk_nshift, opt_nshift);
    AbGkReg(ab, Gk_wshift, opt_wshift);
    AbGkReg(ab, Gk_n_pshift, opt_npfb);
    AbGkReg(ab, Gk_w_pshift, opt_wpfb);
    set_mix(ab);
}

// Take a shift vector (like for the PFBs) and 
// add or subtract the number of shifts and distribute
// the shifts throughout the vector.  This is not 
// numerically throught-out, it just seems reasonable
// to evenly distribute the shifts throughout the vector
//
int
g_vec_add(int vec, int wid, int val)
{
    int         i;
    int         cnt;
    int         ts;
    double      as, spb;
    int         rs;

    for(cnt=0, i=0; i<wid; i++)
        if (vec & (1<<i))
            cnt++;
    cnt += val;
    if (cnt < 0)
        cnt = 0;
    if (cnt > wid)
        cnt = wid;

    ts = 0;
    rs = 0;
    spb = (double) cnt / (double) wid;
    as = 0.0;
    for(i=0; i<wid; i++) {
        as += spb;
        if (as >= 0.5) {
            rs |= (1<<i);
            as -= 1.0;
        }
    }
    return  rs;
}

//  Routines for galfa capture in a non-blocking fashion.
//  
void
g_capture_start(Ab **ab, int msel)
{
    u_long      ctl0;
    int         i;

    for(i=0; i<G_BEAMS; i++) {
        if (ab[i]) {
            // Start capture
            ctl0 = ab[i]->ctl[0] & 0xffffffa3;

            ab[i]->ctl[4] = 0; 
            ab[i]->ctl[0] = ctl0 | 0x044 | ((msel & 0x3) << 3); 
            ab[i]->ctl[0] = ctl0 | 0x040 | ((msel & 0x3) << 3);
        }
    }
}

int
g_capture_complete(Ab **ab)
{
    return (ab[0]->ctl[2] & 0x8) != 0;
}

void 
g_capture_copy(Ab **ab, galfa_pkt *g)
{
    int         i;
    
    for(i=0; i<G_BEAMS; i++) {
        if (ab[i]) {
            // Maybe this should be some more efficient PCI oriented copy?
            g[i] = *((galfa_pkt *) ab[i]->mbus);
        }
    }
}

void
g_capture(Ab **ab, int msel, galfa_pkt *g)
{
    int     i;
    char    xa[G_BEAMS];
    int     err=0;

    g_capture_start(ab, msel);
    while (!g_capture_complete(ab))
        ;

    // Paranoid sanity check 
    xa[0] = 0;
    for(i=1; i<G_BEAMS; i++) {
        xa[i] = 0;
        if (ab[i])
            if ((ab[i]->ctl[2] & 0x8) == 0)
                xa[i] = 1;
    }
    for(i=0; i<G_BEAMS; i++)
        if (xa[i]) {
            printf("g_capture botch, beam %d capture not complete.\n", i);
            err = 1;
        }
    // if (err)
    //     gexit(1);
    // End paranoid check

    g_capture_copy(ab, g);
}

