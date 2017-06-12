
//  This is totally arecibo specific.  
//
//  The observatory sends out once-per-second multicast packets
//  with telescope information.
//  
//  This is a wrapper for code lifted from /share/wappsrc and
//  ~phil that reads these packets and places them in C 
//  structures.
//

#include <stdio.h>
#include <time.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>

#include <mshmLib.h>
#include <execshm.h>
#include <wappshm.h>
#include <alfashm.h>
#include <scram.h>

#include <pthread.h>

// Turning this on sometimes causes packet loss
// #define SCRAM_DEBUG

//  Exported global data
//
double  scram_ra;               // radians
double  scram_dec;              // radians
double  scram_radec_tm;         // seconds after midnight
double  scram_lo1;              // MHz
double  scram_alfapos;          // degrees
double  scram_az;               // degrees
double  scram_za;               // degress
double  scram_azza_tm;          // seconds after midnight
char    scram_obsmode[256];     // drift, cal, etc
char    scram_obsname[256];     // drift, cal, etc
char    scram_object[256];      // drift, cal, etc

//  Listen for multicast packets, extract information interesting
//  to galfa and put in in global variables for display and FITS
//  file writing.
//
static void *
gscram_thread(void *data)
{
    struct SCRAMNET *scram;

    scram = init_scramread(NULL);
    while(1) {
        if (read_scram(scram)) {
#ifdef SCRAM_DEBUG
            printf("Got %s\n", scram->in.magic);
#endif
            if (strcmp(scram->in.magic, "PNT") == 0) {
                scram_radec_tm = (double) scram->pntData.st.x.pl.tm.secMidD;
                scram_ra = scram->pntData.st.x.pl.curP.raJ;
                scram_dec = scram->pntData.st.x.pl.curP.decJ;
#if 0
                printf("   ra: %f, dec: %f\n", scram_ra, scram_dec);
#endif
            } else if (strcmp(scram->in.magic, "IF1") == 0) {
                scram_lo1 = scram->if1Data.st.synI.freqHz[0] / 1000000.0;
#if 0
                printf("    1st LO: %.2f MHz\n", scram_lo1);
#endif
            } else if (strcmp(scram->in.magic, "ALFASHM") == 0) {
                scram_alfapos = scram->alfa.motor_position;
#if 0
                printf("    alfa pos: %f\n", scram_alfapos);
#endif
            } else if (strcmp(scram->in.magic, "AGC") == 0) {
                scram_az = scram->agcData.st.cblkMCur.dat.posAz / 10000.0;
                scram_za = scram->agcData.st.cblkMCur.dat.posGr / 10000.0;
                scram_azza_tm = scram->agcData.st.cblkMCur.dat.timeMs / 1000.0;
#if 0
                printf("    Az: %.4f, Gr: %.4f   @ %d\n", scram_az, scram_za,
                        scram_azza_tm);
#endif
            } else if (strcmp(scram->in.magic, "EXECSHM") == 0) {
                strncpy(scram_obsmode, scram->exec.line1, 256);
                scram_obsmode[255] = 0;
                strncpy(scram_obsname, scram->exec.line2, 256);
                scram_obsname[255] = 0;
                strncpy(scram_object, scram->exec.source, 256);
                scram_object[255] = 0;
            } 
        }
    }
}


//  Start a thread that listens for multicast messages
//  with the scramnet telescope information.
//
void
gscram_init(void)
{
    static pthread_t mythread;

    pthread_create(&mythread, NULL, gscram_thread, NULL);
}

