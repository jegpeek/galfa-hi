
#include "pixmap.h"
#include <stdio.h>
#include <stdarg.h>
#include <linux/fb.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <fcntl.h>

pixmap              *fb;                // the real frambuffer
uint32              _vidaddrmask;
uint32              _hwaccel = 0;

void
hw_init(void)
{ }

void
hw_copy_rect(pixel *dst, int dst_stride, pixel *src, int src_stride,
        int xs, int ys)
{ }

void
hw_setcolor_rect(pixel *p, int c, int xs, int ys, int stride)
{ }

void
msg(const char *fmt,...)
{
    char        str[512];
    va_list     arg;
    int         n;

    va_start(arg, fmt);
    n = vsnprintf(str, 512, fmt, arg);
    va_end(arg);

    fprintf(stderr, "%s", str);
}

// brk for allocating offscreen memory
//
static uint32       fb_brk = 640*480*2; 

// For mmx
typedef struct {
    long    cwd;
    long    swd;
    long    twd;
    long    fip;
    long    fcs;
    long    foo;
    long    fos;
    long    st_space[20];
    long    status;
} fsave_type;
    
void
pixmap_init(void)
{
    int     fbfd;
    struct fb_var_screeninfo finfo;

    fbfd = open("/dev/fb0", O_RDWR);
    if (fbfd < 0) {
        msg( "Cannot open /dev/fb0.\n");
        exit(1);
    }

    fb = (pixmap *) malloc(sizeof(pixmap));
    if (!fb) {
        msg( "Cannot malloc pixmap for frame buffer.\n");
        exit(1);
    }

    if ( ioctl(fbfd, FBIOGET_VSCREENINFO, &finfo) < 0 ) {
        // Make silly assumption...
        //
        msg("Cannot get frame buffer info.\n");
        fb->xs = 640;
        fb->ys = 480;
        fb->stride = 640;
    } else {
        fb->xs = finfo.xres;
        fb->ys = finfo.yres;
        fb->stride = finfo.xres;        // not correct!!
        if (finfo.bits_per_pixel != 16) 
            msg("Hey, not 16-bits per pixel: %d\n", finfo.bits_per_pixel);
    }
    msg("xres:   %d\n", fb->xs);
    msg("yres:   %d\n", fb->ys);
    msg("stride: %d\n", fb->stride);
    // Wrong, but let's me see offscreen allocations for 640x480 system
    // on hires screen, kind of cool, correct statement is commented out
    fb_brk = fb->ys * fb->stride * 2;
    //
    // fb_brk = 480 * fb->stride * 2; 

    fb->buf = mmap(NULL, (size_t) FBMEM_SIZE, PROT_READ | PROT_WRITE,
            MAP_SHARED, fbfd, (off_t) 0);
    if ((long) fb->buf == -1) {
        msg( "mmap() of fb failed.\n");
        exit(1);
    }

    _vidaddrmask = ((uint32) (fb->buf)) & VIDADDRMASK;
    _hwaccel = 0;
    close(fbfd);

    // Try to find graphics acceleration
    //
    hw_init();
}

// This seems to be the best choice for the VIA C3.
// len is measure in pixels. Must do a fnsave/frstor around
// this or bad things will happen to the fpu.
// 
static inline void
pixmap_memcpy(  volatile pixel *to_p, const pixel *from_p, int len)
{
    register int i;
    volatile register char *to   = (char *) to_p;
    const    register char *from = (char *) from_p;

    len *= sizeof(pixel);       // len is now in bytes

    // Copy 64-byte chunks
    i = len >> 6;   
    while (i--) {
        __asm__ __volatile__ (
            "  movq (%0), %%mm0\n"
            "  movq 8(%0), %%mm1\n"
            "  movq 16(%0), %%mm2\n"
            "  movq 24(%0), %%mm3\n"
            "  movq %%mm0, (%1)\n"
            "  movq %%mm1, 8(%1)\n"
            "  movq %%mm2, 16(%1)\n"
            "  movq %%mm3, 24(%1)\n"
            "  movq 32(%0), %%mm0\n"
            "  movq 40(%0), %%mm1\n"
            "  movq 48(%0), %%mm2\n"
            "  movq 56(%0), %%mm3\n"
            "  movq %%mm0, 32(%1)\n"
            "  movq %%mm1, 40(%1)\n"
            "  movq %%mm2, 48(%1)\n"
            "  movq %%mm3, 56(%1)\n"
                : : "r" (from), "r" (to) : "memory");
        from += 64;
        to += 64;
    }

    // Copy 0-7 8-byte chunks
    i = (len & 0x38) >> 3;
    while (i--) {
        __asm__ __volatile__ (
            "  movq (%0), %%mm0\n"
            "  movq %%mm0, (%1)\n"
                : : "r" (from), "r" (to) : "memory");
        to += 8;
        from += 8;
    }

    // Copy last 0-7 1-byte chunks
    i = len&7;
    while (i--)
        *to++ = *from++;
}

void
pixmapa_draw_color(pixmap *pm, pixmapa *bm, int x, int y, pixel c, alpha a)
{
    int                 i, j;
    register    pixel   *pp;
    register    uint8   *bp;
    int                 xso, yso;
    int                 xe, ye;

    // Trivially non-overlapping
    if (bm->xs+x <= 0 || bm->ys+y <=0 || x >= pm->xs || y >= pm->ys)
        return;

    if (a == 255)
        a = 256;

    xso = 0;
    if (x<0) {
        xso = -x;
        x = 0;
    }

    yso = 0;
    if (y<0) {
        yso = -y;
        y = 0;
    }

    pp = pm->buf + x + pm->stride*y;
    bp = bm->buf + xso + bm->stride*yso;

    ye = MIN(bm->ys-yso, pm->ys-y);
    xe = MIN(bm->xs-xso, pm->xs-x);

    for(j=0; j<ye; j++) {
        for(i=0; i<xe; i++) 
            pp[i] = alpha_mix((bp[i]*a) >> 8, pp[i], c);
        pp += pm->stride;
        bp += bm->stride;
    }
}

void
pixmapa_draw_image(pixmap *pm, pixmapa *bm, int x, int y, pixmap *cpm, alpha a)
{
    int                 i, j;
    int                 xso, yso;
    int                 xe, ye;
    register    pixel   *pp;
    register    uint8   *bp;
    register    pixel   *cpp;

    // Trivially non-overlapping
    if (bm->xs+x <= 0 || bm->ys+y <=0 || x >= pm->xs || y >= pm->ys)
        return;

    if (a == 255)
        a = 256;

    xso = 0;
    if (x<0) {
        xso = -x;
        x = 0;
    }

    yso = 0;
    if (y<0) {
        yso = -y;
        y = 0;
    }

    pp = pm->buf + x + pm->stride*y;
    bp = bm->buf + xso + bm->stride*yso;
    cpp = cpm->buf + x + cpm->stride*y;

    ye = MIN(bm->ys-yso, pm->ys-y);
    xe = MIN(bm->xs-xso, pm->xs-x);

    for(j=0; j<ye; j++) {
        for(i=0; i<xe; i++) 
            pp[i] = alpha_mix((bp[i]*a) >> 8, pp[i], cpp[i]);
        pp += pm->stride;
        bp += bm->stride;
        cpp += cpm->stride;
    }
}

#ifdef PM_FONT
static inline void
ft2alpha(FT_Bitmap *bm, pixmapa *pa)
{
    pa->buf = bm->buffer;
    pa->xs = bm->width;
    pa->ys = bm->rows;
    pa->stride = bm->pitch;
}
#endif

void
pixmapa_set_rect(pixmapa *pa, uint8 v, int xo, int yo, int xs, int ys)
{
    register int        i;
    register uint8      *tb;

    if (xo < 0) {
        xs += xo;
        xo = 0;
    }
    if (yo < 0) {
        ys += yo;
        yo = 0;
    }
    if (xo+xs > pa->xs)
        xs = pa->xs - xo;
    if (yo+ys > pa->ys)
        ys = pa->ys - yo;

    if (xs <= 0 || ys <= 0)
        return;
    if (xo >= pa->xs || yo >= pa->ys)
        return;

    tb = &pa->buf[xo + pa->stride*yo];
    for(i=0; i<ys; i++) {
        memset(tb, v, xs);
        tb += pa->stride;
    }
}

void
pixmapa_set(pixmapa *pa, uint8 v)
{
    pixmapa_set_rect(pa, v, 0, 0, pa->xs, pa->ys);
}

#ifdef PM_FONT
void
draw_text_color(pixmap *pm, FT_Bitmap *bm, int x, int y, pixel c, alpha a)
{
    pixmapa        pa;

    ft2alpha(bm, &pa);
    pixmapa_draw_color(pm, &pa, x, y, c, a);
}
#endif

void
pixmapa_copy_rect(pixmapa *pad, pixmapa *pas, int sxo, int syo,
        int xs, int ys, int dxo, int dyo)
{
    int                     j;
    register uint8          *pas_t;
    register uint8          *pad_t;

    // Clip rect against source pixmap
    if (sxo < 0) {
        xs += sxo;
        dxo += sxo;
        sxo = 0;
    }
    if (syo < 0) {
        ys += syo;
        dyo += syo;
        syo = 0;
    }
    if (sxo+xs > pas->xs)
        xs = pas->xs - sxo;
    if (syo+ys > pas->ys)
        ys = pas->ys - syo;
    if (xs <= 0 || ys <= 0)
        return;
    if (sxo >= pas->xs || syo >= pas->ys)
        return;

    // Clip rect against dest pixmap
    if (dxo < 0) {
        xs += dxo;
        sxo -= dxo;
        dxo = 0;
    }
    if (dyo < 0) {
        ys += dyo;
        syo -= dyo;
        dyo = 0;
    }
    if (dxo+xs > pad->xs)
        xs = pad->xs - dxo;
    if (dyo+ys > pad->ys)
        ys = pad->ys - dyo;
    if (xs <= 0 || ys <= 0)
        return;
    if (dxo >= pad->xs || dyo >= pad->ys)
        return;

    pas_t = pas->buf + sxo + pas->stride*syo;
    pad_t = pad->buf + dxo + pad->stride*dyo;

    for(j=0; j<ys; j++) {
        memcpy(pad_t, pas_t, xs);
        pad_t += pad->stride;
        pas_t += pas->stride;
    }
}

void
pixmapa_copy(pixmapa *pad, pixmapa *pas, int x, int y)
{
    pixmapa_copy_rect(pad, pas, 0, 0, pas->xs, pas->ys, x, y);
}

#ifdef PM_FONT
void
draw_text_alpha(pixmapa *pa, FT_Bitmap *bm, int x, int y)
{
    pixmapa        ps;

    ft2alpha(bm, &ps);
    pixmapa_copy(pa, &ps, x, y);
}

void
draw_text_image(pixmap *pm, FT_Bitmap *bm, int x, int y, pixmap *cpm, alpha a)
{
    pixmapa        pa;

    ft2alpha(bm, &pa);
    pixmapa_draw_image(pm, &pa, x, y, cpm, a);
}
#endif

pixmap *
pixmap_extract(pixmap *src, int xoff, int yoff, int xs, int ys)
{
    int     j;
    pixmap  *pm;
    fsave_type      fsave;

    pm = pixmap_new(xs, ys);

    __asm__ __volatile__ ("fnsave %0 ; fwait" : "=m" (fsave));
    for(j=0; j<ys; j++)
        pixmap_memcpy(  pm->buf + pm->stride*j, 
                        src->buf + xoff + src->stride*(j+yoff), 
                        xs);
    __asm__ __volatile__ ("frstor %0" : : "m" (fsave));
    return pm;
}

pixmap *
pixmap_subset(pixmap *pm, int xo, int yo, int xs, int ys)
{
    pixmap  *pmr = pixmap_new(0,0);

    pmr->buf = pm->buf + xo + yo*pm->stride;
    pmr->xs = xs;
    pmr->ys = ys;
    pmr->stride = pm->stride;
    return pmr;
}

pixmap *
pixmap_dup(pixmap *src)
{
    return pixmap_extract(src, 0, 0, src->xs, src->ys);
}

// offscreen video memory, no such thing as free for now...
//
pixmap *
pixmapv_new(int xs, int ys)
{
    pixmap          *pm;
    int             stride;

    stride = (xs+0x7) & ~0x7;           // measured in x8 pixels
    pm = (pixmap *) malloc(sizeof(pixmap));
    if (!pm) {
        msg( "pixmap_new faied.\n");
        exit(1);
    }
    pm->buf = (pixel *) (fb_brk + ((uint32)fb->buf));
    pm->xs = xs;
    pm->ys = ys;
    pm->stride = stride;

    fb_brk += stride*ys*sizeof(pixel);
    if (stride > FBMEM_SIZE) {
        msg("pixmav_new: out of video memory.\n");
        exit(1);
    }
    return pm;
}

pixmap *
pixmap_new(int xs, int ys)
{
    pixmap  *pm;
    int     bs;

    bs = xs*ys*sizeof(pixel);
    pm = (pixmap *) malloc(sizeof(pixmap) + bs);
    if (!pm) {
        msg( "pixmap_new faied.\n");
        exit(1);
    }
    pm->buf = (pixel *) (((char *)pm) + sizeof(pixmap));
    pm->xs = xs;
    pm->ys = ys;
    pm->stride = xs;

    return pm;
}

void
pixmap_free(pixmap *pm)
{
    free((void *)pm);
}

pixmapa *
pixmapa_new(int xs, int ys)
{
    pixmapa    *pm;
    int             bs;

    bs = xs*ys*sizeof(uint8);
    pm = (pixmapa *) malloc(sizeof(pixmapa) + bs);
    if (!pm) {
        msg( "pixmap_new faied.\n");
        exit(1);
    }
    pm->buf = (uint8 *) (((char *)pm) + sizeof(pixmapa));
    pm->xs = xs;
    pm->ys = ys;
    pm->stride = xs;

    return pm;
}

// Rectangular alpha map that fades to transparent at edges
pixmapa *
pixmapa_fuzzy_new(int xs, int ys, int border)
{
    pixmapa    *pa;
    int             am;
    int             b, x, y;

    if (border > xs/2)
        border = xs/2;
    if (border > ys/2)
        border = ys/2;
    pa = pixmapa_new(xs, ys);
    memset(pa->buf, 0xff, xs*ys);
    for(b=0; b<border; b++) {
        am = (b*255)/border;
        for(x=b; x<xs-b; x++) {
            pa->buf[x + b*xs] = am;
            pa->buf[x + (ys-b-1)*xs] = am;
        }
        for(y=b; y<ys-b; y++) {
            pa->buf[b + y*xs] = am;
            pa->buf[(xs-b-1) + y*xs] = am;
        }
    }
    return pa;
}

void
pixmapa_free(pixmapa *pm)
{
    free((void *)pm);
}

void
pixmap_copy_rect(pixmap *pmd, pixmap *pms, int sxo, int syo, 
        register int xs, int ys, int dxo, int dyo)
{
    int                     j;
    fsave_type              fsave;
    register pixel          *pms_t;
    register pixel          *pmd_t;

    // Clip rect against source pixmap
    if (sxo < 0) {
        xs += sxo;
        dxo += sxo;
        sxo = 0;
    }
    if (syo < 0) {
        ys += syo;
        dyo += syo;
        syo = 0;
    }
    if (sxo+xs > pms->xs)
        xs = pms->xs - sxo;
    if (syo+ys > pms->ys)
        ys = pms->ys - syo;
    if (xs <= 0 || ys <= 0)
        return;
    if (sxo >= pms->xs || syo >= pms->ys)
        return;

    // Clip rect against dest pixmap
    if (dxo < 0) {
        xs += dxo;
        sxo -= dxo;
        dxo = 0;
    }
    if (dyo < 0) {
        ys += dyo;
        syo -= dyo;
        dyo = 0;
    }
    if (dxo+xs > pmd->xs)
        xs = pmd->xs - dxo;
    if (dyo+ys > pmd->ys)
        ys = pmd->ys - dyo;
    if (xs <= 0 || ys <= 0)
        return;
    if (dxo >= pmd->xs || dyo >= pmd->ys)
        return;

    pms_t = pms->buf + sxo + pms->stride*syo;
    pmd_t = pmd->buf + dxo + pmd->stride*dyo;

    if (HWACCEL(pms_t) && VIDMEM(pmd_t)) {
        hw_copy_rect(pmd_t, pmd->stride, pms_t, pms->stride, xs, ys);
    } else {
        __asm__ __volatile__ ("fnsave %0 ; fwait" : "=m" (fsave));
        for(j=0; j<ys; j++) {
            pixmap_memcpy(pmd_t, pms_t, xs);
            pmd_t += pmd->stride;
            pms_t += pms->stride;
        }
        __asm__ __volatile__ ("frstor %0" : : "m" (fsave));
    }
}

void
pixmap_copy(pixmap *pmd, pixmap *pms, int xo, int yo)
{
    pixmap_copy_rect(pmd, pms, 0, 0, pms->xs, pms->ys, xo, yo);
}

// Returns true is two pixmaps have the same image
//
int
pixmap_cmp(pixmap *pa, pixmap *pb)
{
    int i,j;

    if (pa->xs != pb->xs)
        return 0;
    if (pa->ys != pb->ys)
        return 0;

    for(j=0; j<pa->ys; j++)
        for(i=0; i<pa->xs; i++)
            if (pa->buf[i + j*pa->stride] != pb->buf[i + j*pb->stride])
                return 0;
    return 1;
}

void
pixmap_setcolor_rect(pixmap *pm, pixel c, int xo, int yo, int xs, int ys)
{
    fsave_type          fsave;
    register int        i;
    register pixel      *tb, *tbd;

    if (xo < 0) {
        xs += xo;
        xo = 0;
    }
    if (yo < 0) {
        ys += yo;
        yo = 0;
    }
    if (xo+xs > pm->xs)
        xs = pm->xs - xo;
    if (yo+ys > pm->ys)
        ys = pm->ys - yo;

    if (xs <= 0 || ys <= 0)
        return;
    if (xo >= pm->xs || yo >= pm->ys)
        return;

    tbd = tb = &pm->buf[xo + pm->stride*yo];
    if (HWACCEL(tb)) {
        hw_setcolor_rect(tb, c, xs, ys, pm->stride);
    } else {
        for(i=0; i<xs; i++)
            tb[i] = c;
        __asm__ __volatile__ ("fnsave %0 ; fwait" : "=m" (fsave));
        for(i=1; i<ys; i++) {
            tbd += pm->stride;
            pixmap_memcpy( tbd, tb, xs );
        }
        __asm__ __volatile__ ("frstor %0" : : "m" (fsave));
    }
}

void
pixmap_setcolor(pixmap *pm, pixel c)
{
    pixmap_setcolor_rect(pm, c, 0, 0, pm->xs, pm->ys);
}

struct bmp_header {
    uint32  size;
    uint32  res1;
    uint32  dataoff;
};

struct bmp_infoheader {
    uint32  infosize;
    uint32  xs;
    uint32  ys;
    uint16  planes;
    uint16  bpp;
    uint32  comp;
    uint32  imgsize;
    uint32  xppm;
    uint32  yppm;
    uint32  ncolors;
    uint32  impcolors;
};

static void
pdie(char *fn, char *cp)
{
    msg( "BMP %s: %s\n", fn, cp);
    exit(1);
}

// Not very rigorous.  Reads a BMP file, must be an 8-bit uncompresses
// greyscale BMP file with no colormap.  Badly behaved on broken BMP
// files.
//
pixmapa *
pixmapa_readbmp(char *fn)
{
    FILE                    *fp;
    uint16                  sig;
    struct bmp_header       hdr;
    struct bmp_infoheader   info;
    pixmapa            *pa;
    int                     i;
    char                    fnx[80];

    fp = fopen(fn, "rb");
    if (!fp) {
        sprintf(fnx, "/usr/%s", fn);
        fp = fopen(fnx, "rb");
        if (!fp)
            pdie(fn, "Cannot open file.");
    }

    fread(&sig, 2, 1, fp);
    if (sig != 0x4d42)
        pdie(fn, "Bad sig");
    fread(&hdr, sizeof(hdr), 1, fp);
    fread(&info, sizeof(info), 1, fp);

    if (info.xs==0 || info.ys==0) 
        pdie(fn, "zero area");
    if (info.bpp !=8 )
        pdie(fn, "bad bpp"); 
    if (info.comp != 0) 
        pdie(fn, "bad compression");
    if (info.ncolors!=0) 
        pdie(fn, "no grey scale");

    pa = pixmapa_new(info.xs, info.ys);
    fseek(fp, hdr.dataoff, SEEK_SET);
    for(i=0; i<info.ys; i++)
        fread(pa->buf + (info.ys-i-1)*pa->xs, 1, info.xs, fp);
    fclose(fp);
    return pa;
}

#ifdef PM_JPEG
pixmap *
pixmapv_readjpeg(char *fn)
{
    pixmap  *pt, *p;

    pt = pixmap_readjpeg(fn);
    p = pixmapv_new(pt->xs, pt->ys);
    pixmap_copy(p, pt, 0, 0);
    pixmap_free(pt);
    return p;
}

pixmap *
pixmap_readjpeg(char *fn)
{
    struct jpeg_decompress_struct       cinfo;
    struct jpeg_error_mgr               jerr;
    FILE                                *fp;
    JSAMPARRAY                          buf;
    int                                 i, stride;
    uint8                               *pa;
    pixmap                              *pm;
    char                                fnx[80];

    fp = fopen(fn, "rb");
    if (!fp) {
        sprintf(fnx, "/usr/%s", fn);
        fp = fopen(fnx, "rb");
        if (!fp) {
            msg( "Cannot open %s.\n", fn);
            exit(1);
        }
    }

    cinfo.err = jpeg_std_error(&jerr);
    jpeg_create_decompress(&cinfo);
    jpeg_stdio_src(&cinfo, fp);
    jpeg_read_header(&cinfo, TRUE);
    cinfo.out_color_space = JCS_RGB;
    
    jpeg_start_decompress(&cinfo);
    stride = cinfo.output_width * cinfo.output_components;
    buf = (*cinfo.mem->alloc_sarray) ((j_common_ptr) &cinfo, 
            JPOOL_IMAGE, stride, 1);

    pm = pixmap_new(cinfo.output_width, cinfo.output_height);

    while (cinfo.output_scanline < cinfo.output_height) {
        jpeg_read_scanlines(&cinfo, buf, 1);
        pa = buf[0];
        for(i=0; i<stride; i+=3)
            pm->buf[ (cinfo.output_scanline-1) * pm->stride + i/3] =
                COLOR(pa[i+0], pa[i+1], pa[i+2]);
    }
    
    jpeg_finish_decompress(&cinfo);
    jpeg_destroy_decompress(&cinfo);
    fclose(fp);
    return pm;
}


METHODDEF(void)
j_init_source (j_decompress_ptr cinfo)
{
}

METHODDEF(void)
j_skip_input_data (j_decompress_ptr cinfo, long n)
{
}

METHODDEF(boolean)
j_fill_input_buffer (j_decompress_ptr cinfo)
{
    msg( "This shouldn't happen...\n");
    exit(1);
}
         
METHODDEF(void)
j_term_source (j_decompress_ptr cinfo)
{                                 
      /* no work necessary here */
}  

// Decompress jpeg from pointer to jpeg data
//
pixmap *
pixmap_jpeg(char *dbuf, int len)
{
    struct jpeg_decompress_struct       cinfo;
    struct jpeg_error_mgr               jerr;
    JSAMPARRAY                          buf;
    int                                 i, stride;
    uint8                               *pa;
    pixmap                              *pm;
    struct jpeg_source_mgr              src_rec;

    cinfo.err = jpeg_std_error(&jerr);
    jpeg_create_decompress(&cinfo);

    cinfo.src = &src_rec;
    src_rec.init_source = j_init_source;
    src_rec.fill_input_buffer = j_fill_input_buffer;
    src_rec.skip_input_data = j_skip_input_data;
    src_rec.resync_to_restart = jpeg_resync_to_restart;
    src_rec.term_source = j_term_source;
    src_rec.bytes_in_buffer = len;
    src_rec.next_input_byte = dbuf;

    jpeg_read_header(&cinfo, TRUE);
    cinfo.out_color_space = JCS_RGB;
    
    jpeg_start_decompress(&cinfo);
    stride = cinfo.output_width * cinfo.output_components;
    buf = (*cinfo.mem->alloc_sarray) ((j_common_ptr) &cinfo, 
            JPOOL_IMAGE, stride, 1);

    pm = pixmap_new(cinfo.output_width, cinfo.output_height);

    while (cinfo.output_scanline < cinfo.output_height) {
        jpeg_read_scanlines(&cinfo, buf, 1);
        pa = buf[0];
        for(i=0; i<stride; i+=3)
            pm->buf[ (cinfo.output_scanline-1) * pm->stride + i/3] =
                COLOR(pa[i+0], pa[i+1], pa[i+2]);
    }
    
    jpeg_finish_decompress(&cinfo);
    jpeg_destroy_decompress(&cinfo);
    return pm;
}
#endif

