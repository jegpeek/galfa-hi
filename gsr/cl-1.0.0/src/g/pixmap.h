
// #define PM_JPEG
// #define PM_FONT

typedef unsigned char uint8;
typedef unsigned short uint16;
typedef unsigned long uint32;
typedef char int8;
typedef short int16;
typedef long int32;

// 565 RGB only for now
typedef uint16 pixel;
typedef uint32 alpha;

#define FBMEM_SIZE      (1<<20)

#define RED_COMP(x)     (((x)>>8) & 0xf8)
#define GRN_COMP(x)     (((x)>>3) & 0xfc)
#define BLU_COMP(x)     (((x)<<3) & 0xfc)
#define COLOR(r,g,b)    ((((r)<<8)&0xf800) | (((g)<<3)&0x07e0) | (((b)>>3)&0x001f))

#define C_WHITE         COLOR(255,255,255)
#define C_BLACK         COLOR(0,0,0)
#define C_DGREY         COLOR(32,32,32)

#define MIN(x,y)        (((x)<(y)) ? (x) : (y))
#define MAX(x,y)        (((x)>(y)) ? (x) : (y))

typedef struct {
    int         xs;
    int         ys;
    int         stride;
    pixel       *buf;
} pixmap;
    
typedef struct {
    int         xs;
    int         ys;
    int         stride;
    uint8       *buf;
} pixmapa;
    

void    pixmap_init(void);
pixmap *pixmap_extract(pixmap *src, int xoff, int yoff, int xs, int ys);
pixmap *pixmap_subset(pixmap *pm, int xo, int yo, int xs, int ys);
pixmap *pixmap_dup(pixmap *src);
pixmap *pixmap_new(int xs, int ys);
void    pixmap_free(pixmap *pm);
void    pixmap_copy(pixmap *pmd, pixmap *pms, int xo, int yo);
void    pixmap_setcolor(pixmap *pm, pixel c);
#ifdef PM_JPEG
pixmap *pixmap_readjpeg(char *fn);
pixmap *pixmap_jpeg(char *buf, int len);
pixmap *pixmapv_readjpeg(char *fn);
#endif
pixmapa *pixmapa_new(int xs, int ys);
pixmapa *pixmapa_readbmp(char *fn);
void    pixmapa_free(pixmapa *pm);
pixmapa *pixmapa_fuzzy_new(int xs, int ys, int border);
int     pixmap_cmp(pixmap *pa, pixmap *pb);

void    pixmapa_draw_color(pixmap *pm, pixmapa *bm, int x, int y,
                pixel c, alpha a);
void    pixmapa_draw_image(pixmap *pm, pixmapa *bm, int x, int y,
                pixmap *cpm, alpha a);
#ifdef PM_FONT
void    draw_text_color(pixmap *pm, FT_Bitmap *bm, int x, int y, 
                pixel c, alpha a);
void    draw_text_image(pixmap *pm, FT_Bitmap *bm, int x, int y, 
                pixmap *cpm, alpha a);
#endif


void    pixmap_copy_rect(pixmap *pmd, pixmap *pms, int sxo, int syo, 
                int xs, int ys, int dxo, int dyo);
void    pixmap_setcolor_rect(pixmap *pm, pixel c, int xo, int yo, 
                int xs, int ys);

pixmap *pixmapv_new(int xs, int ys);

void    pixmapa_copy_rect(pixmapa *pad, pixmapa *pas, int sxo, int syo,
                int xs, int ys, int dxo, int dyo);
void    pixmapa_copy(pixmapa *pad, pixmapa *pas, int x, int y);
#ifdef PM_FONT
void    draw_text_alpha(pixmapa *pa, FT_Bitmap *bm, int x, int y);
#endif
void    pixmapa_set_rect(pixmapa *pa, uint8 v, int xo, int yo, int xs, int ys);
void    pixmapa_set(pixmapa *pa, uint8 v);


static inline pixel
alpha_mix(alpha a, pixel bg, pixel fg)
{
    uint32      rf, gf, bf;
    uint32      rb, gb, bb;
    pixel       p;

    if (a == 255)
        a = 256;

    rf = RED_COMP(fg);
    gf = GRN_COMP(fg);
    bf = BLU_COMP(fg);

    rb = RED_COMP(bg);
    gb = GRN_COMP(bg);
    bb = BLU_COMP(bg);
    
    rf = (rb*(256-a) + rf*a) >> 8;
    gf = (gb*(256-a) + gf*a) >> 8;
    bf = (bb*(256-a) + bf*a) >> 8;

    p = COLOR(rf, gf, bf);
    return p;
}


extern pixmap               *fb;            // the real frambuffer
extern uint32               _vidaddrmask;
extern uint32               _hwaccel;

#define VIDADDRMASK         0xff000000
#define VIDMEM(x)           ((((uint32) (x)) & VIDADDRMASK) == _vidaddrmask)
#define HWACCEL(x)          (_hwaccel && VIDMEM(x))
