
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

#include "scram/gscram.h"
#include "galfa_sock/galfa_sock.h"
#include "galfa.h"

#include "fitsio.h"

// Datapath paramters to be recorded, these can change between
// between packets.
//
//      opt_adcfreq     ADC frequency in MHz (probabaly always 100MHz)
//      opt_mix         Mixer frequency, 5-bits, 2-s comp, -16..15
//                          center freq of narrowband spectrum is
//                          opt_mix * opt_adcfreq/32
//      opt_wshift      wide band up shift before power calculation,
//                          0..7, 3-bits
//      opt_nshift      narrow band up shift before power calculation,
//                          0..7, 3-bits
//      opt_wpfb        9-bit mask for wideband downshifts, LSB is
//                          output stage, MSB is input stage, 1 means
//                          downshift on input to stage, 0 means no shift
//      opt_npfb        13-bit mask for narrowband downshifts, LSB is
//                          output stage, MSB is input stage, 1 means
//                          downshift on input to stage, 0 means no shift
//
// g[0]->misc & 0xffff is sixteen bit sequence number, if this doesn't
// increment is means that something bad happened, got behind and dropped
// a packet, hardware failure, software bug, aliens, etc.  This is only
// true for beam 0.
//
// For each beam, there are overflow conditions. Two bits indicate 
// errors of various degrees:
//
//      0       0-15     errors in previous 1s
//      1       16-255   errors in previous 1s 
//      2       256-4095 errors in previous 1s
//      3       >=4096   errors in previous 1s
//
// err = (g[0]->misc >> 16) & 0xffff
//
// err[1:0]     wideband up shift saturation
// err[3:2]     wideband FFT overflow
// err[5:4]     narrowband up shift saturation
// err[7:6]     narrowband FFT overflow
// err[9:8]     narrowband lowpass filter saturation
// err[11:10]   narrowband mixer saturation
// err[13:12]   adc input saturation
//
// #define W_BINS 512
// g[i]->pola_w[W_BINS]
// g[i]->polb_w[W_BINS]     
//
// Wideband frequency bins for polarity A & B.
// pola_w[0] is centered at -opt_adcfreq/2.
// pola_w[128] is centered at 0 Hz.
// pola_w[255] is centered at opt_adcfreq/2 - opt_adcfreq/512
// Each value is a 32-bit unsigned value.  The
// maximum value (caclculating power of satutated
// value and accumulating) is W_MAX (0xd6ff2900)
// There is also a global option opt_goff that 
// (hopefully) holds the global frequency offset from all external
// mixing.  This should offset the narrowband frequencies.
//
// Power in dB is 10.0 * log10( val / W_MAX)
//
// #define N_BINS 7679
// g[i]->pola_n[N_BINS]
// g[i]->polb_n[N_BINS]
//
// Narrowband PFB is centered at opt_mix * opt_adc/32.0.  For 100MHz
// ADC clock, typical default is -18.75MHz.  This offset is applied
// to all narrowband frequency bins.
//
// Narrowband PFB is 8192 points decimated by N_DEC (14).  Width
// of PFB is opt_adcfreq / N_DEC.  257 frequency bins are dropped off
// the negative frequency side and 256 bins are dropped off the positive
// frequency side, leave 8192-257-256 = 7679 bins.
//
// The width of each narrow bin is opt_adcfreq / (14.0 * 8192).
//
// g[i]->pola_n[x] is centered at frequency 
//
//     (opt_adcfreq / 14)  * (x - 4096 + 129)/8192
//
// This makes g[i]->pola_n[3967] the center, 0Hz band.
//  
// The frequency of all of these bands is offset by the mixer
// frequency.  There is also a global option opt_goff that 
// (hopefully) holds the global frequency offset from all external
// mixing.  This should offset both wideband and narrowband frequencies.
//
// Each value is a 32-bit unsigned value.  The
// maximum value (caclculating power of satutated
// value and accumulating) is N_MAX (0xbc1f43e0)
//
// Power in dB is 10.0 * log10( val / N_MAX)
//

static  int         seq=0;
static  int         first=1;

static  fitsfile    *fptr;
static  int         status = 0;
static  int         row = 1;
static  int         xtime = 0;
static  int         errs = 0;

// OBSMODE LINE1
// OBS_NAME LINE2


// These are the HDFITS columns I sorta understand.
//
// DATA         The 7679 narrowband bins
// CRVAL1       Center frequency
// CDELT1       Frequency interval
// CRPIX1       Pixel of center frequency
// CRVAL2A      real source RA
// CRVAL3A      real source DEC
// CRVAL2B      real source AZ
// CRVAL3B      real source ZA
// CRVAL4       Polarization (-1 -2 ?)
// BANDWID      Bandwidth of spectrum
// RESTFREQ     Rest freq at band center
// FRONTEND     ALFA
// IFVAL        which polarization (0 1)
// ALFA_ANG     rotation of alfa receiver
// OBSMODE      observation mode
// OBS_NAME     observation mode
// EQUINOX      J2000
// 
// These are extra columns I added for my stuff
//
// G_WIDE       The 512 wideband bins
// G_ERR        12-bits of error described above for wide/narrow datapath
// G_SEQ        sequence number 
// G_BEAM       ALFA beam number 0-6
// G_WSHIFT     wideband shift before accumulator
// G_NSHIFT     narrowband shift before accumulator
// G_WPFB       8-bit downshift mask for wide PFB
// G_NPFB       13-bit downshfit mask for narrow PFB
// G_MIX        FPGA mixer frequency for narrowband
// G_EXT        external mixer frequency (sum of all external mixers)
// G_ADC        ADC frequency
// G_WCENTER    Center freq for wideband
// G_WBAND      Bandidth of wideband
// G_WDELT      Frequency interval for wideband
// G_DAC        DAC settings for analog mixer
// G_TIME       Unix time of PPS
// G_LO1        1st LO on platform
// G_LO2        2nd LO in galfa rack
// G_POSTM      Timestamp for ra/dec pos
// G_AZZATM     Timestamp for az/za pos
//

static  char        tcols = 38;
static  char        *ttype[] = {
    "DATA", 
    "CRVAL1", 
    "CDELT1", 
    "CRPIX1",
    "CRVAL2A",
    "CRVAL3A",
    "CRVAL2B",
    "CRVAL3B",
    "CRVAL4",
    "BANDWID",
    "RESTFREQ",
    "FRONTEND",
    "IFVAL",
    "ALFA_ANG",
    "OBSMODE",
    "OBS_NAME",
    "OBJECT",
    "EQUINOX",

    "G_WIDE",
    "G_ERR",
    "G_SEQ",
    "G_BEAM",
    "G_WSHIFT",
    "G_NSHIFT",
    "G_WPFB",
    "G_NPFB",
    "G_MIX",
    "G_EXT",
    "G_ADC",
    "G_WCENTER",
    "G_WBAND",
    "G_WDELT",
    "G_DAC",
    "G_TIME",
    "G_LO1",
    "G_LO2",
    "G_POSTM",
    "G_AZZATM",
};

static  char        *tform[] = {
    "7679V", 
    "1D",
    "1D",
    "1D",
    "1D",
    "1D",
    "1D",
    "1D",
    "1D",
    "1D",
    "1D",
    "8A",
    "1B",
    "1D",
    "8A",
    "8A",
    "16A",
    "1D",


    "512V",
    "1U",
    "1U",
    "1B",
    "1B",
    "1B",
    "1U",
    "1U",
    "1D",
    "1D",
    "1D",
    "1D",
    "1D",
    "1D",
    "1B",
    "2V",
    "1D",
    "1D",
    "1D",
    "1D",
};

// The column numbers
enum {
    col_data=1,
    col_crval1,
    col_cdelt1,
    col_crpix1,
    col_crval2a,
    col_crval3a,
    col_crval2b,
    col_crval3b,
    col_crval4,
    col_bandwid,
    col_restfreq,
    col_frontend,
    col_ifval,
    col_alfa_ang,
    col_obsmode,
    col_obs_name,
    col_object,
    col_equinox,

    col_g_wide,
    col_g_err,
    col_g_seq,
    col_g_beam,
    col_g_wshift,
    col_g_nshift,
    col_g_wpfb,
    col_g_npfb,
    col_g_mix,
    col_g_ext,
    col_g_adc,
    col_g_wcenter,
    col_g_wband,
    col_g_wdelt,
    col_g_dac,
    col_g_time,
    col_g_lo1,
    col_g_lo2,
    col_g_postm,
    col_g_azzatm,
} g_colname;

static int fnum=0;
static int file_secs=0;
static int tot_secs = 0;

static struct tm    start_tm;
static int          got_start_tm=0;

int
gfits_open(Ab **ab)
{
    int             i;
    char            fn[120];
    char            fnp[120];
    char            ft[120];
    time_t          t;
    struct stat     buf;
    int             beams=0;

    double          lat = 18.3435001;
    double          lng = -66.7533035;
    double          elev = 496.0;
    long            g_version = G_VERSION;

    if (!dacs_read) {
        printf("Botch: dac file not read?\n");
        gexit(1);
    }

    for(i=0; i<G_BEAMS; i++)
        if (ab[i])
            beams++;

    // If no filename is specifed, make up an impressive looking name
    // Only get the start date once, this way if we wrap around 
    // midnight we keep the same name for the run.
    //
    if (!got_start_tm) {
        got_start_tm = 1;
        time(&t);
        localtime_r(&t, &start_tm);   // Hopefully AST at arecibo...
    }

    strftime(fnp, 120, "/dump/galfa.%Y%m%d", &start_tm);
    do {
        sprintf(fn, "%s.%s.%04d.fits", fnp, opt_fn, fnum++);
    } while (!stat(fn, &buf));
    strftime(ft, 120, "%Y-%m-%dT%T", &start_tm);
    
    printf("Creating FITS file %s.\n", fn);
    fits_create_file(&fptr, fn, &status);

    // Gratuitous primary HDU
    //
    fits_create_img(fptr, BYTE_IMG, 0, NULL, &status);
    fits_update_key(fptr, TSTRING, "TELESCOP", "ARECIBO 305m", NULL, &status);
    fits_update_key(fptr, TSTRING, "ORIGIN", "NAIC", NULL, &status);
    fits_update_key(fptr, TSTRING, "HISTORY", "BDFITS GALFA data", NULL, 
            &status);

    // Binary table for galfa data
    //
    row = 1;
    fits_create_tbl(fptr, BINARY_TBL, 0, tcols, ttype, tform, NULL,
        "GXFITS", &status);
    fits_update_key(fptr, TSTRING, "DATE-OBS", ft , NULL, &status);
    fits_update_key(fptr, TSTRING, "OBS_ID", "Diag", NULL, &status);
    fits_update_key(fptr, TSTRING, "BACKEND", "GALFA", NULL, &status);
    fits_update_key(fptr, TLONG, "G_BEAMS", &beams, NULL, &status);
    fits_update_key(fptr, TDOUBLE, "SITELAT", &lat, NULL, &status);
    fits_update_key(fptr, TDOUBLE, "SITELONG", &lng, NULL, &status);
    fits_update_key(fptr, TDOUBLE, "SITEELEV", &elev, NULL, &status);
    fits_update_key(fptr, TLONG, "VERSION", &g_version, NULL, &status);
    fits_report_error(stdout, status);
    return status;
}

// These are the things I know from scramnet.
//
// double  scram_ra;               // radians
// double  scram_dec;              // radians
// double  scram_radec_tm;         // seconds after midnight
// double  scram_lo1;              // MHz
// double  scram_alfapos;          // degrees
// double  scram_az;               // degrees
// double  scram_za;               // degress
// double  scram_azza_tm;          // seconds after midnight
// char    scram_obsmode[256];     // drift, cal, etc

int
gfits_write(Ab **ab, galfa_pkt **g, struct timeval *tv)
{
    int     i;
    int     err;
    int     pol;
    char    fstr[80];

    double  adc_hz = 1000000.0 * opt_adcfreq;
    double  mix_f = 1000000.0 * mix_freq();
    double  n_bin = adc_hz / (N_WIDTH * N_DEC);
    double  w_bin = adc_hz / W_BINS;
    int     center_bin = N_WIDTH/2 - N_OFFSET + 1;  // fortran style 1-based
    double  bandwidth = adc_hz / ((double) N_DEC) * 
                ((double) N_BINS) / ((double) N_WIDTH);
    double  center_f;
    char    *frontend = "ALFA";
    char    *obsmode = scram_obsmode;
    char    *obsname = scram_obsname;
    char    *object = scram_object;
    double  equinox = 2000.0;
    u_long  tm[2];

    double  act_ra = 0.0;
    double  act_dec = 0.0;
    double  act_az = 0.0;
    double  act_za = 0.0;
    double  alfa_ang = 0.0;
    double  act_lo1 = 0.0;
    double  act_lo2 = 0.0;
    double  postm = 0.0;
    double  azzatm = 0.0;
    double  wcenter = 0.0;

    tm[0] = tv->tv_sec;
    tm[1] = tv->tv_usec;


    // actual ra/dec
    act_ra = scram_ra * 24.0 / (2.0 * M_PI);        // hours
    act_dec = scram_dec * 360.0 / (2.0 * M_PI);     // degrees

    // actual az/za
    act_az = scram_az;                              // degrees
    act_za = scram_za;                              // degrees

    // alfa angle (this is probable wrong, I haven't seen it move yet)
    alfa_ang = scram_alfapos;                       // degrees

    // LO's
    act_lo1 = scram_lo1 * 1000000.0;                // Hz
    act_lo2 = opt_lo2 * 1000000.0;                  // Hz

    // time for position values
    postm = scram_radec_tm / 3600.0;                // hours
    azzatm = scram_azza_tm / 3600.0;                // hours

    // If scramnet gave us LO1 and LO2 was specified on command line
    // compute new offset frequency
    //
    if (scram_lo1 > 0.0 && opt_lo2 > 0.0) 
        opt_goff = scram_lo1 - opt_lo2;
    center_f = mix_f + 1000000.0 * opt_goff;

    wcenter = opt_goff * 1000000.0;

    // The tv parameter is the time when the packet came available.
    // This is pps+latency for the beginning of the next block.  THe
    // beginning time for this block of data is 1s before this time
    // value (minus system latency if you want to be picky).
    //
    if (first) {
        seq = g[0]->misc & 0xffff;
        first = 0;
        printf("Writing beams [");
        for(i=0; i<G_BEAMS; i++)
            if (g[i])
                printf("%d", i);
        printf("]\n");

        strcpy(fstr, "0000000000000");
        for(i=0; i<13; i++)
            if (opt_npfb & (1<<i))
                fstr[12-i] = '1';
        printf("nshift: %d, npfb: %s\n", opt_nshift, fstr);
        strcpy(fstr, "000000000");
        for(i=0; i<9; i++)
            if (opt_wpfb & (1<<i))
                fstr[8-i] = '1';
        printf("wshift: %d, wpfb: %s\n", opt_wshift, fstr);
        printf("digital mix %.3f MHz\n", mix_freq());
        printf("external mix %.3f MHz\n", opt_goff);
        printf("\n");
        return 0;
    }


    seq = (seq+1) & 0xffff;
    if (seq != (g[0]->misc & 0xffff)) {
        printf("ERROR: Misses sequence, expected %d, got %lu.\n",
            seq, g[0]->misc & 0xffff);
        errs++;
        seq = g[0]->misc & 0xffff;
    }

    xtime++;
    if ((xtime % 5) == 0)
        printf("%ds\n", xtime);
    
    for(i=0; i<G_BEAMS; i++) if (g[i]) {
        err = (g[i]->misc >> 16) & 0xffff;
        if (err & 0x3fff) {
            printf("Overflow beam %d: A%d Narrow MLFS=%d%d%d%d, Wide FS=%d%d\n",
                i, 
                (err>>12) & 0x3,
                (err>>10) & 0x3,
                (err>>8) & 0x3,
                (err>>6) & 0x3,
                (err>>4) & 0x3,
                (err>>2) & 0x3,
                (err>>0) & 0x3 );
        }

        // Write two rows, one for each polarization
        //

        // First polparity
        //
        fits_write_col(fptr, TULONG, col_data, row, 1, N_BINS, g[i]->pola_n, 
            &status);
        fits_write_col(fptr, TDOUBLE, col_crval1, row, 1, 1, &center_f, 
            &status);
        fits_write_col(fptr, TDOUBLE, col_cdelt1, row, 1, 1, &n_bin, &status);
        fits_write_col(fptr, TLONG, col_crpix1, row, 1, 1, &center_bin, 
            &status);
        fits_write_col(fptr, TDOUBLE, col_crval2a, row, 1,1, &act_ra, &status);
        fits_write_col(fptr, TDOUBLE, col_crval3a, row, 1,1, &act_dec, &status);
        fits_write_col(fptr, TDOUBLE, col_crval2b, row, 1,1, &act_az, &status);
        fits_write_col(fptr, TDOUBLE, col_crval3b, row, 1,1, &act_za, &status);
        pol = -2;
        fits_write_col(fptr, TLONG, col_crval4, row, 1, 1, &pol, &status);
        fits_write_col(fptr, TDOUBLE, col_bandwid, row, 1, 1, &bandwidth,
            &status);
        fits_write_col(fptr, TDOUBLE, col_restfreq, row, 1, 1, &center_f,
            &status);
        fits_write_col(fptr, TSTRING, col_frontend, row, 1, 1, &frontend,
            &status);
        fits_write_col(fptr, TSTRING, col_obsmode, row, 1, 1, &obsmode,
            &status);
        fits_write_col(fptr, TSTRING, col_obs_name, row, 1, 1, &obsname,
            &status);
        fits_write_col(fptr, TSTRING, col_object, row, 1, 1, &object,
            &status);
        fits_write_col(fptr, TDOUBLE, col_equinox, row, 1,1, &equinox, &status);
        pol = 0;
        fits_write_col(fptr, TLONG, col_ifval, row, 1, 1, &pol, &status);

        fits_write_col(fptr, TULONG, col_g_wide, row, 1, W_BINS, g[i]->pola_w, 
            &status);
        fits_write_col(fptr, TLONG, col_g_err, row, 1, 1, &err, &status);
        fits_write_col(fptr, TLONG, col_g_seq, row, 1, 1, &seq, &status);
        fits_write_col(fptr, TLONG, col_g_beam, row, 1, 1, &i, &status);
        fits_write_col(fptr, TLONG, col_g_wshift, row, 1, 1, &opt_wshift, 
            &status);
        fits_write_col(fptr, TLONG, col_g_nshift, row, 1, 1, &opt_nshift, 
            &status);
        fits_write_col(fptr, TLONG, col_g_wpfb, row, 1, 1, &opt_wpfb, 
            &status);
        fits_write_col(fptr, TLONG, col_g_npfb, row, 1, 1, &opt_npfb, 
            &status);
        fits_write_col(fptr, TDOUBLE, col_g_mix, row, 1, 1, &mix_f, &status);
        fits_write_col(fptr, TDOUBLE, col_g_ext, row, 1, 1, &wcenter, &status);
        fits_write_col(fptr, TDOUBLE, col_g_adc, row, 1, 1, &adc_hz, &status);
        fits_write_col(fptr, TDOUBLE, col_g_wcenter, row, 1, 1, &wcenter, 
            &status);
        fits_write_col(fptr, TDOUBLE, col_g_wband, row, 1, 1, &adc_hz, &status);
        fits_write_col(fptr, TDOUBLE, col_g_wdelt, row, 1, 1, &w_bin, &status);
        fits_write_col(fptr, TBYTE, col_g_dac, row, 1, 1, g_dac + i*2, 
            &status);
        fits_write_col(fptr, TULONG, col_g_time, row, 1, 2, &tm, &status);

        fits_write_col(fptr, TDOUBLE, col_g_lo1, row, 1, 1, &act_lo1, &status);
        fits_write_col(fptr, TDOUBLE, col_g_lo2, row, 1, 1, &act_lo2, &status);
        fits_write_col(fptr, TDOUBLE, col_alfa_ang, row, 1, 1, &alfa_ang, 
            &status);
        fits_write_col(fptr, TDOUBLE, col_g_postm, row, 1, 1, &postm, &status);
        fits_write_col(fptr, TDOUBLE, col_g_azzatm, row, 1,1, &azzatm, &status);
        row++;

        // Second polarity
        //
        fits_write_col(fptr, TULONG, col_data, row, 1, N_BINS, g[i]->polb_n, 
            &status);
        fits_write_col(fptr, TDOUBLE, col_crval1, row, 1, 1, &center_f, 
            &status);
        fits_write_col(fptr, TDOUBLE, col_cdelt1, row, 1, 1, &n_bin, &status);
        fits_write_col(fptr, TLONG, col_crpix1, row, 1, 1, &center_bin, 
            &status);
        fits_write_col(fptr, TDOUBLE, col_crval2a, row, 1,1, &act_ra, &status);
        fits_write_col(fptr, TDOUBLE, col_crval3a, row, 1,1, &act_dec, &status);
        fits_write_col(fptr, TDOUBLE, col_crval2b, row, 1,1, &act_az, &status);
        fits_write_col(fptr, TDOUBLE, col_crval3b, row, 1,1, &act_za, &status);
        pol = -1;
        fits_write_col(fptr, TLONG, col_crval4, row, 1, 1, &pol, &status);
        fits_write_col(fptr, TDOUBLE, col_bandwid, row, 1, 1, &bandwidth,
            &status);
        fits_write_col(fptr, TDOUBLE, col_restfreq, row, 1, 1, &center_f,
            &status);
        fits_write_col(fptr, TSTRING, col_frontend, row, 1, 1, &frontend,
            &status);
        fits_write_col(fptr, TSTRING, col_obsmode, row, 1, 1, &obsmode,
            &status);
        fits_write_col(fptr, TSTRING, col_obs_name, row, 1, 1, &obsname,
            &status);
        fits_write_col(fptr, TSTRING, col_object, row, 1, 1, &object,
            &status);
        fits_write_col(fptr, TDOUBLE, col_equinox, row, 1,1, &equinox, &status);
        pol = 1;
        fits_write_col(fptr, TLONG, col_ifval, row, 1, 1, &pol, &status);

        fits_write_col(fptr, TULONG, col_g_wide, row, 1, W_BINS, g[i]->polb_w, 
            &status);
        fits_write_col(fptr, TLONG, col_g_err, row, 1, 1, &err, &status);
        fits_write_col(fptr, TLONG, col_g_seq, row, 1, 1, &seq, &status);
        fits_write_col(fptr, TLONG, col_g_beam, row, 1, 1, &i, &status);
        fits_write_col(fptr, TLONG, col_g_wshift, row, 1, 1, &opt_wshift, 
            &status);
        fits_write_col(fptr, TLONG, col_g_nshift, row, 1, 1, &opt_nshift, 
            &status);
        fits_write_col(fptr, TLONG, col_g_wpfb, row, 1, 1, &opt_wpfb, 
            &status);
        fits_write_col(fptr, TLONG, col_g_npfb, row, 1, 1, &opt_npfb, 
            &status);
        fits_write_col(fptr, TDOUBLE, col_g_mix, row, 1, 1, &mix_f, &status);
        fits_write_col(fptr, TDOUBLE, col_g_ext, row, 1, 1, &wcenter, &status);
        fits_write_col(fptr, TDOUBLE, col_g_adc, row, 1, 1, &adc_hz, &status);
        fits_write_col(fptr, TDOUBLE, col_g_wcenter, row, 1, 1, &wcenter, 
            &status);
        fits_write_col(fptr, TDOUBLE, col_g_wband, row, 1, 1, &adc_hz, &status);
        fits_write_col(fptr, TDOUBLE, col_g_wdelt, row, 1, 1, &w_bin, &status);
        fits_write_col(fptr, TBYTE, col_g_dac, row, 1, 1, g_dac + i*2+1, 
            &status);
        fits_write_col(fptr, TULONG, col_g_time, row, 1, 2, &tm, &status);
        fits_write_col(fptr, TDOUBLE, col_g_lo1, row, 1, 1, &act_lo1, &status);
        fits_write_col(fptr, TDOUBLE, col_g_lo2, row, 1, 1, &act_lo2, &status);
        fits_write_col(fptr, TDOUBLE, col_alfa_ang, row, 1, 1, &alfa_ang, 
            &status);
        fits_write_col(fptr, TDOUBLE, col_g_postm, row, 1, 1, &postm, &status);
        fits_write_col(fptr, TDOUBLE, col_g_azzatm, row, 1,1, &azzatm, &status);
        row++;
    }
    fits_report_error(stdout, status);

    if (opt_time && ++tot_secs == opt_time) {
        gfits_close();
        printf("%d total seconds written.\n", tot_secs);
        return 1;
    }

    if (opt_sdiv && ++file_secs == opt_sdiv) {
        file_secs = 0;
        gfits_close();
        gfits_open(ab);
    }
    return status;
}

int
gfits_close(void)

{
    fits_close_file(fptr, &status);
    fits_report_error(stdout, status);
    if (!status) 
        printf("%d rows written to FITS file.\n", row-1);
    if (errs)
        printf("%d total sequence ERRORs\n", errs);
    return status;
}
