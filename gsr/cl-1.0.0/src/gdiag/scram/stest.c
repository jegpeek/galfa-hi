
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

main()
{
    struct SCRAMNET *scram;
    char    name[256];
    double  az, za;
    long    t, th, ts, tm;
    double  ra, dec;

    scram = init_scramread(NULL);
    while(1) {
        if (read_scram(scram)) {
            if (strcmp(scram->in.magic, "PNT") == 0) {
                getnameinfo(&scram->from, sizeof(struct sockaddr_in), 
                    name, 256, NULL, 0, 0);
                printf("Read %s from %s, time=%f\n", 
                    scram->in.magic, name, 
                    scram->pntData.st.x.pl.tm.secMidD);
    
                t =  scram->pntData.st.x.pl.tm.secMidD;
                th = t / 3600;
                t -= th * 3600;
                tm = t / 60;
                t -= tm * 60;
                ts = t;
                printf("   %02d:%02d:%02d\n", th, tm, ts);
                ra = scram->pntData.st.x.pl.curP.raJ;
                dec = scram->pntData.st.x.pl.curP.decJ;
                
                ra *= 360 / C_2PI;
                dec *= 360 / C_2PI;
                printf("   ra: %f, dec: %f\n", ra, dec);

                ra *= 3600.0 * 24.0 / 360.0;
                th = ra / 3600.0;
                ra -= th*3600;
                tm = ra / 60.0;
                ra -= tm*60;
                printf("   rax:  %02d:%02d:%02.2f\n", th, tm, ra);
                
                dec *= 3600.0 * 24.0 / 360.0;
                th = dec / 3600.0;
                dec -= th*3600;
                tm = dec / 60.0;
                dec -= tm*60;
                printf("   decx: %02d:%02d:%02.2f\n", th, tm, dec);

                // printf("   geo vel proj: %f\n",
                //     scram->pntData.st.x.pl.curP.geoVelProj);
                // printf("   helio vel proj: %f\n",
                //     scram->pntData.st.x.pl.curP.helioVelProj);
            } else if (strcmp(scram->in.magic, "IF1") == 0) {
                getnameinfo(&scram->from, sizeof(struct sockaddr_in), 
                    name, 256, NULL, 0, 0);
                printf("Read %s from %s\n", scram->in.magic, name);
                printf("    1st LO: %.2f MHz\n", 
                    scram->if1Data.st.synI.freqHz[0] / 1000000.0);
            } else if (strcmp(scram->in.magic, "ALFASHM") == 0) {
                getnameinfo(&scram->from, sizeof(struct sockaddr_in), 
                    name, 256, NULL, 0, 0);
                printf("Read %s from %s\n", scram->in.magic, name);
                printf("    alfa pos: %f\n", scram->alfa.motor_status);
            } else if (strcmp(scram->in.magic, "AGC") == 0) {
                getnameinfo(&scram->from, sizeof(struct sockaddr_in), 
                    name, 256, NULL, 0, 0);
                az = scram->agcData.st.cblkMCur.dat.posAz;
                za = scram->agcData.st.cblkMCur.dat.posGr;

                az /= 10000.0;
                za /= 10000.0;
                printf("Read %s from %s\n", scram->in.magic, name);
                printf("    Az: %.4f, Gr: %.4f   @ %d\n", az, za,
                        scram->agcData.st.cblkMCur.dat.timeMs);
                printf("    velAz: %d, velGr: %d\n",
                        scram->agcData.st.cblkMCur.dat.velAz, 
                        scram->agcData.st.cblkMCur.dat.velGr);
            } else if (strcmp(scram->in.magic, "EXECSHM") == 0) {
                getnameinfo(&scram->from, sizeof(struct sockaddr_in), 
                    name, 256, NULL, 0, 0);
                printf("Read %s from %s\n", scram->in.magic, name);
                printf("    obs_mode: %s.\n", scram->exec.obs_mode);    
            } else {
                getnameinfo(&scram->from, sizeof(struct sockaddr_in), 
                    name, 256, NULL, 0, 0);
                // printf("Read %s from %s\n", scram->in.magic, name);
            }
        } else
            printf("xxx\n");
    }
}

