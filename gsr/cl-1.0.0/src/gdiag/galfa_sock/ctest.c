
//
// Jeff Mock
// 2030 Gough St.
// San Francisco, CA 94109
//
// jeff@mock.com
// (c) 2004
//

#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <unistd.h>
#include <getopt.h>
#include <errno.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/select.h>
#include <netdb.h>

#include "galfa_sock.h"

//
// Simple C program to test galfa socket protocol
// Command like options exercise most the protcol commands.
// The perl program gtest is a more exhaustive test of the
// interface.
//


#define TIMEOUT         4           // normal timeout for galfa reads
#define TIMEOUT_DAC     25          // Calibrating levels can take longer

enum {
    opti_galfa,
    opti_port,
    opti_settings,
    opti_dac,
    opti_levels,
    opti_data,
    opti_abort,
};

static struct option lopts[] = {
    { "galfa",          1, 0, opti_galfa },
    { "port",           1, 0, opti_port },
    { "settings",       0, 0, opti_settings },
    { "dac",            1, 0, opti_dac },
    { "levels",         0, 0, opti_levels },
    { "data",           1, 0, opti_data },
    { "abort",          1, 0, opti_abort },
    { NULL,             0, 0, 0 },
};

void
usage(char *prog)
{
    printf("\nUsage: %s [options]\n\n", prog);
    printf("    -galfa=name    Attach to specified galfa\n");
    printf("    -port=n        Attach to galfa on port n\n");
    printf("    -settings      Print out current galfa settings\n");
    printf("    -dac=n         Set galfa levels to n ADC rms units\n");
    printf("    -levels        Get galfa signal levels\n");
    printf("    -data=n        Get n seconds of data from galfa\n");
    printf("    -abort=n       Get n seconds of data followed by abort\n");
    printf("\n");
}

// values for commandline options
//
char *      opt_galfa = "seti3.mock.com";
int         opt_port = 1420;


// send len bytes to the socket
//
void
write_socket(int fd, void *ptr, int len)
{
    u_char              *nptr = (u_char *) ptr;
    int                 r;

    while (len > 0) {
        r = write(fd, nptr, len);
        if (r<0) {
            if (errno==EAGAIN || errno==EINTR)
                continue;
            perror("socket croaked");
            exit(1);
        }
        len -= r;
        nptr += len;
    }
}

// Wait with timeout until input is available on 
// a socket
//
int 
sock_canread(int fd, int timeout)
{
    fd_set              rset;
    struct timeval      tv;
    int                 r;

    tv.tv_sec = timeout;
    tv.tv_usec = 0;

    FD_ZERO(&rset);
    FD_SET(fd, &rset);

    r = select(fd+1, &rset, NULL, NULL, &tv);
    if (r<0) {
        perror("select failed");
        exit(1);
    }
    return r;
} 

// Read n bytes from a socket or die with a timeout.
//
void
read_socket(int fd, void *ptr, int len)
{
    u_char              *nptr = (u_char *) ptr;
    int                 r;

    while (len > 0) {
        if (!sock_canread(fd, TIMEOUT)) {
            fprintf(stderr, "Socket timed out on read.\n");
            exit(1);
        }
        // r = read(fd, nptr, len);
        r = recv(fd, nptr, len, MSG_WAITALL);
        // printf("Read %d %d\n", r, len);
        if (r<0) {
            if (errno==EAGAIN || errno==EINTR)
                continue;
            perror("socket croaked");
            exit(1);
        }
        len -= r;
        nptr += len;
    }
}
        
// Open a socket to a host:port
//
int
open_socket(char *host, int port)
{
    int                 fd;
    struct sockaddr_in  saddr;
    struct hostent      *hent;

    fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd == -1) {
        perror("Cannot create socket");
        exit(1);
    }

    if ((hent = gethostbyname(host)) == NULL) {
        perror("Cannot lookup host");
        exit(1);
    }
    bzero(&saddr, sizeof(saddr));
    saddr.sin_family = hent->h_addrtype;
    bcopy(hent->h_addr, &saddr.sin_addr, hent->h_length);
    saddr.sin_port = htons(port);

    if (connect(fd, (void *) &saddr, sizeof(saddr)) == -1) {
        perror("Connection to galfa failed");
        exit(1);
    }
    return fd;
}

// Send a packet to galfa, 4-byte len followed by structure
// Everything is in network byte order
//
void
galfa_sendpkt(int fd, void *pkt, int len)
{
    int                 hlen = htonl(len);

    write_socket(fd, &hlen, 4);
    write_socket(fd, pkt, len);
}

// Get a packet from galfa or die with a timeout
//
// Data is stored in static location, not thread safe, data
// is overwitten on following call. galfa_data is the
// largest thing returned.
//
void *
galfa_recvpkt(int fd)
{
    int                 hlen, len;
    static galfa_data   gdata;
    
    bzero(&gdata, sizeof(gdata));
    read_socket(fd, (void *) &hlen, 4);
    len = ntohl(hlen);
    
    if (len<16 || len>sizeof(gdata)) {
        fprintf(stderr, "Unexpected packet size from galfa: %d\n", len);
        exit(1);
    }
    read_socket(fd, (void *) &gdata, len);

    if (ntohl(gdata.magic) != GALFA_MAGIC) {
        fprintf(stderr, "Bad magic number from galfa: %08x\n", 
            ntohl(gdata.magic));
        exit(1);
    }
    if ((ntohl(gdata.version) & GALFA_VERSION_MASK) != 
                (GALFA_VERSION & GALFA_VERSION_MASK)) {
        fprintf(stderr, "Bad version number from galfa: %08x\n", 
            ntohl(gdata.version));
        exit(1);
    }
    return &gdata;
}

// Get current settings from galfa
//
galfa_cmd *
galfa_getparams(int fd)
{
    galfa_cmd           gcmd;
    galfa_cmd           *resp;

    bzero(&gcmd, sizeof(gcmd));
    gcmd.magic = htonl(GALFA_MAGIC);
    gcmd.version = htonl(GALFA_VERSION);
    gcmd.cmd = htonl(GALFA_CMD_GETPARAM);

    galfa_sendpkt(fd, &gcmd, sizeof(gcmd));
    resp = (galfa_cmd *) galfa_recvpkt(fd);
    
    if (htonl(resp->response) != GALFA_RESP_GETPARAM) {
        fprintf(stderr, "Unexpected response to getparams: %d\n", 
            htonl(resp->response));
        exit(1);
    }
    return resp;
}

// Calibrate the DACs
//
galfa_cmd *
galfa_setdacs(int fd, int val)
{
    galfa_cmd           gcmd;
    galfa_cmd           *resp;

    printf("Settings dacs\n");
    bzero(&gcmd, sizeof(gcmd));
    gcmd.magic = htonl(GALFA_MAGIC);
    gcmd.version = htonl(GALFA_VERSION);
    gcmd.cmd = htonl(GALFA_CMD_SETDAC);
    gcmd.cnt = htonl(val);

    galfa_sendpkt(fd, &gcmd, sizeof(gcmd));
    if (!sock_canread(fd, TIMEOUT_DAC)) {
        fprintf(stderr, "Timeout waiting on dac calibration\n");
        exit(1);
    }
    resp = (galfa_cmd *) galfa_recvpkt(fd);
    
    if (htonl(resp->response) != GALFA_RESP_SETDAC) {
        fprintf(stderr, "Unexpected response to setdac: %d\n", 
            htonl(resp->response));
        exit(1);
    }
    return resp;
}

// Get levels
//
galfa_cmd *
galfa_getlevels(int fd)
{
    galfa_cmd           gcmd;
    galfa_cmd           *resp;

    bzero(&gcmd, sizeof(gcmd));
    gcmd.magic = htonl(GALFA_MAGIC);
    gcmd.version = htonl(GALFA_VERSION);
    gcmd.cmd = htonl(GALFA_CMD_GETLEVEL);

    galfa_sendpkt(fd, &gcmd, sizeof(gcmd));
    resp = (galfa_cmd *) galfa_recvpkt(fd);
    
    if (htonl(resp->response) != GALFA_RESP_GETLEVEL) {
        fprintf(stderr, "Unexpected response to getlevel: %d\n", 
            htonl(resp->response));
        exit(1);
    }
    return resp;
}

// Get data from galfa
//
void
galfa_getdata(int fd, int secs)
{
    galfa_cmd           gcmd;
    galfa_data          *resp;

    bzero(&gcmd, sizeof(gcmd));
    gcmd.magic = htonl(GALFA_MAGIC);
    gcmd.version = htonl(GALFA_VERSION);
    gcmd.cmd = htonl(GALFA_CMD_GETDATA);
    gcmd.cnt = htonl(secs);

    galfa_sendpkt(fd, &gcmd, sizeof(gcmd));
    while (1) {
        resp = (galfa_data *) galfa_recvpkt(fd);
    
        if (htonl(resp->response) != GALFA_RESP_GETDATA) {
            fprintf(stderr, "Unexpected response to getdata: %d\n", 
                htonl(resp->response));
            exit(1);
        }

        if (htonl(resp->beam) == 0 && htonl(resp->polarity) == 0)
            printf("\n");
        printf("Data for beam %d, polarity %d, seq %d, time %d %d\n",
            htonl(resp->beam),
            htonl(resp->polarity),
            htonl(resp->seq),
            htonl(resp->time1),
            htonl(resp->time2));
    }
}

// Get data from galfa, abort, sleep, get more data
//
void
galfa_abort(int fd, int secs)
{
    galfa_cmd           gcmd;
    galfa_data          *resp;
    galfa_cmd           *settings;
    int                 i;
    int                 beams = 0;

    settings = galfa_getparams(fd);
    for(i=0; i<GALFA_BEAMS; i++)
        if ( (1<<i) & ntohl(settings->beam))
            beams++;
    printf("%d beams in galfa.\n", beams);

    while (1) {
        bzero(&gcmd, sizeof(gcmd));
        gcmd.magic = htonl(GALFA_MAGIC);
        gcmd.version = htonl(GALFA_VERSION);
        gcmd.cmd = htonl(GALFA_CMD_GETDATA);
        gcmd.cnt = htonl(secs);
        galfa_sendpkt(fd, &gcmd, sizeof(gcmd));

        for(i=0; i<secs*beams*2; i++) {
            resp = (galfa_data *) galfa_recvpkt(fd);
        
            if (htonl(resp->response) != GALFA_RESP_GETDATA) {
                fprintf(stderr, "Unexpected response to getdata: %d\n", 
                    htonl(resp->response));
                exit(1);
            }

            if (htonl(resp->beam) == 0 && htonl(resp->polarity) == 0) 
                printf("\n");
            printf("Data for beam %d, polarity %d, seq %d, time %d %d\n",
                htonl(resp->beam),
                htonl(resp->polarity),
                htonl(resp->seq),
                htonl(resp->time1),
                htonl(resp->time2));
        }

        bzero(&gcmd, sizeof(gcmd));
        gcmd.magic = htonl(GALFA_MAGIC);
        gcmd.version = htonl(GALFA_VERSION);
        gcmd.cmd = htonl(GALFA_CMD_ABORT);
        galfa_sendpkt(fd, &gcmd, sizeof(gcmd));

        printf("Aborting, sleep...\n");
        if (sock_canread(fd, 5)) {
            fprintf(stderr, "Hmm, spurious stuff from galfa after about.\n");
            exit(1);
        }
    }
}


// Print out response packet
//
void
galfa_printpkt(galfa_cmd *gcmd)
{
    int                 i;

    printf("Galfa packet\n");
    printf("    magic             %08x\n", ntohl(gcmd->magic));
    printf("    version           %08x\n", ntohl(gcmd->version));
    printf("    cmd               %d\n", ntohl(gcmd->cmd));
    printf("    response          %d\n", ntohl(gcmd->response));
    printf("    cnt               %d\n", ntohl(gcmd->cnt));
    printf("rw  mix               %d\n", ntohl(gcmd->mix));
    printf("rw  wshift            %d\n", ntohl(gcmd->wshift));
    printf("rw  nshift            %d\n", ntohl(gcmd->nshift));
    printf("rw  wpfb              %03x\n", ntohl(gcmd->wpfb));
    printf("rw  npfb              %04x\n", ntohl(gcmd->npfb));
    printf("    beam              %02x\n", ntohl(gcmd->beam));
    printf("    time1             %d\n", ntohl(gcmd->time1));
    printf("    time2             %d\n", ntohl(gcmd->time2));

    printf("    dac               ");
    for(i=0; i<14; i++)
        printf("%d ", ntohl(gcmd->dac[i]));
    printf("\n");

    printf("    rms               ");
    for(i=0; i<14; i++)
        printf("%d ", ntohl(gcmd->rms[i]));
    printf("\n\n");
}

int
main(int ac, char **av)
{
    int                 c, index;
    int                 err = 0;
    int                 fd;
    int                 level=0;
    int                 secs=0;
    int                 action=0;
    galfa_cmd           *gcmd;

    while ((c=getopt_long_only(ac, av, "", lopts, &index)) != -1) {
        switch (c) {
            case opti_galfa:
                opt_galfa = optarg;
                break;

            case opti_port:
                opt_port = strtol(optarg, NULL, 0);
                break;

            case opti_settings:
            case opti_levels:
                action = c;
                break;

            case opti_dac:
                action = c;
                level = strtol(optarg, NULL, 0);
                break;

            case opti_data:
                action = c;
                secs = strtol(optarg, NULL, 0);
                break;

            case opti_abort:
                action = c;
                secs = strtol(optarg, NULL, 0);
                break;

            default:
                err = 1;
                break;
        }
    }
    if (err || action==0) {
        usage(av[0]);
        exit(1);
    }

    fd = open_socket(opt_galfa, opt_port);    
    switch(action) {
        case opti_settings:
            gcmd = galfa_getparams(fd);
            galfa_printpkt(gcmd);
            break;

        case opti_levels:
            gcmd = galfa_getlevels(fd);
            galfa_printpkt(gcmd);
            break;

        case opti_dac:
            gcmd = galfa_setdacs(fd, level);
            galfa_printpkt(gcmd);
            break;

        case opti_data:
            galfa_getdata(fd, secs);
            break;

        case opti_abort:
            galfa_abort(fd, secs);
            break;
    }
    close(fd);
    return 0;
}

