

#define NEW_MIXER                   // 32-point mixer

#define WIDE512                     // 512-point wideband

#define DEF_ADC_FREQ    100.0       // in MHz
#define G_BEAMS         7           // you get it...

// These are from the perl script vcalc in gk/src in the chip
// source files.  It is a calculation for the datapath of the 
// maximum accumulated value for an integration.
//
#ifdef WIDE512
#define W_MAX           ((u_long) 0x5e0fa1f0)
#else
#define W_MAX           ((u_long) 0xd6ff2900)
#endif
#define N_MAX           ((u_long) 0xbc1f43e0)

#ifdef WIDE512
#define W_BINS          512
#define N_BINS          7679
#define N_OFFSET        257         // number of bins dropped on left side
#else
#define W_BINS          256
#define N_BINS          7935
#define N_OFFSET        129         // number of bins dropped on left side
#endif

#define N_WIDTH         8192        // actual narrow width before truncation
#define N_DEC           14          // decimation of narrowband transform

// #define N_CENTER        0.0         // Center freq of narrowband
// #define N_CENTER        (-opt_adcfreq/4)

#define G_MIX_MASK      0x1f
#define G_MIX_WSHIFT    0x7
#define G_MIX_NSHIFT    0x7
#ifdef WIDE512
#define G_MIX_WPFB      0x1ff
#else
#define G_MIX_WPFB      0xff
#endif
#define G_MIX_NPFB      0x1fff

// Version number for FITS file
//
#define G_VERSION       20041103

// 64kbyte packet from galfa, this is how it appears in PCI address space
//
typedef struct {
    u_long      pola_w[W_BINS];
    u_long      misc;
    u_long      pola_n[N_BINS];
    u_long      polb_w[W_BINS];
    u_long      dummy;              // actually same as misc
    u_long      polb_n[N_BINS];
} galfa_pkt;


#define CAP_ADC     0               // Capture ADC samples in mbuf
#define CAP_PFB     1               // Capture PFB samples in mbuf
#define CAP_LPF     2               // Capture LPF samples in mbuf

extern int     opt_vnc;             // Act as VNC server
extern int     opt_avg;             // averaging for freq displays
extern int     opt_max;             // max hold on freq displays
extern int     opt_nshift;          // narrowband upshift
extern int     opt_wshift;          // wideband upshift
extern int     opt_input;           // ADC input
extern double  opt_ppdb;            // pixels per dB option
extern double  opt_adcfreq;
extern int     opt_beam;
extern int     opt_mix;
extern double  opt_goff;
extern int     opt_npfb;
extern int     opt_wpfb;
extern char    *opt_fn;
extern double  opt_level;
extern int     opt_sdiv;
extern int     opt_time;
extern int     opt_mask;
extern int     opt_ovftrig;
extern int     opt_sock;
extern int     opt_nofits;
extern double  opt_ref;
extern int     opt_fix;

extern int     galfa_pid;
extern int     diag_reg;
extern double  opt_lo2;

#define MIX_NEG 1
#define MIX_POS 2
#define MIX_DC  3

// display modes for galfa scope
//
enum {
    gmode_wscope,
    gmode_nscope,
    gmode_wmulti,
    gmode_nmulti,
    gmode_last,
};

// For freetype
//
extern FT_Library   library;
extern FT_Face      regface;

// Level setting DACs
extern u_char   g_dac[14];
extern u_long   g_rms[14];
extern u_char   dacs_read;

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

// util.c
//
typedef signed char s_char;
void screen_print(pixmap *p);
void string(char *cp, int sz, pixel c, alpha a, pixmap *pm, int x, int y);
void draw_marker(pixmap *draw, int mx, int my);
void adc_capture(Ab *ab, int msel, int dec_n, int dec_off, 
        s_char **a0, s_char **a1, s_char **a2, s_char **a3);
void g_set_shift(Ab **ab);
void g_capture_start(Ab **ab, int msel);
int  g_capture_complete(Ab **ab);
void g_capture_copy(Ab **ab, galfa_pkt *g);
void g_capture(Ab **ab, int msel, galfa_pkt *g);
int  g_vec_add(int vec, int wid, int val);
void get_lock(void);
void release_lock(void);

// The 2v6000 registers (the Gk registers), up to 16 16-bit
// write-only registers.  This should match the verilog for
// the register definitions in galfa/gk/gk.v
//
#define     Gk_wshift           0
#define     Gk_nshift           1
#define     Gk_diag             2
#define     Gk_mixer            3   // bit-0 is bypass, bit-1 is sign
#define     Gk_led3             4
#define     Gk_nmixer           5   // 5-bits for new mixer
#define     Gk_talow            6
#define     Gk_tahigh           7
#define     Gk_tblow            8
#define     Gk_tbhigh           9
#define     Gk_ppsext           10
#define     Gk_n_pshift         11  // 13-bits
#define     Gk_w_pshift         12  // 8-bits
#define     Gk_adc_mask         13  // 8-bits


// gscope.c
//
void galfa_scope(Ab **ab, int mode);
void galfa_run(Ab **ab);
// void set_mix(Ab **ab);
double mix_freq(void);

// io.c
int io_open(Ab **ab);
int io_write(Ab **ab, galfa_pkt **g, struct timeval *tv);
int io_close(void);

// gfits.c
int gfits_open(Ab **ab);
int gfits_write(Ab **ab, galfa_pkt **g, struct timeval *tv);
int gfits_close(void);

// levels.c
void set_levels(Ab **ab);
void set_levels_new(Ab **ab);
void get_sock_levels_new(Ab **ab);

void gsock_open(Ab **ab);
void gsock_write(Ab **ab, galfa_pkt **g, struct timeval *tv);
void gsock_close(void);
galfa_cmd *gsock_listen(Ab **ab, int *redraw);

// main.c
void release_exit(int n);

// lo2.c
void lo2_set(double opt_lo2);
