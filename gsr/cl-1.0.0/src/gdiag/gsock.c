
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

#include "galfa_sock/galfa_sock.h"
#include "galfa.h"

#include <pthread.h>
#include <sys/socket.h>
#include <fcntl.h>
#include <errno.h>

// #define DEBUG

//
// I/O interface called from io.c.  Starts a thread to listen
// for a socket connection and communicates over the socket
// with a simple binary protocl to set parameters on the 
// spectrometer and send data to the controlling side once
// per second.
//

static int      galfa_serve_fd = 0;
static int      galfa_client_fd = 0;
static int      sm_state = 0;
static int      sm_pos = 0;

static int      send_enable = 0;
static int      send_cnt = 0;

// Thread to listen for new connection requests.  Only one
// active connection at a time.
//
static void *
g_connect(void *p)
{
    struct sockaddr_in      caddr, saddr;
    socklen_t               len;
    int                     fd, cnt, rv;

    // Create a socket
    //
    galfa_serve_fd = socket(AF_INET, SOCK_STREAM, 0);
    if (galfa_serve_fd < 0) {
        perror("Cannot create socket for listening.");
        gexit(1);
    }
    memset(&saddr, 0, sizeof(saddr));

    // Bind to a local TCP port (GALFA_PORT)
    //
    saddr.sin_family = AF_INET;
    saddr.sin_addr.s_addr = htonl(INADDR_ANY);
    saddr.sin_port = htons(GALFA_PORT);
    len = 1;
    setsockopt(galfa_serve_fd, SOL_SOCKET, SO_REUSEADDR, &len, sizeof(len));
    for(cnt=0; cnt<10; cnt++) {
        rv = bind(galfa_serve_fd, (struct sockaddr *) &saddr, sizeof(saddr));
        if (rv < 0)  {
            printf("Bind failed, 2s of patience... %d/10\n", cnt+1);
            sleep(2);
        } else
            break;
    }
    if (rv<0) {
        perror("bind failed, maybe another galfa process is running? ");
        gexit(1);
    }

    // Listen for connection request
    //
    rv = listen(galfa_serve_fd, 1);
    if (rv < 0) {
        perror("listen failed on listening socket");
        gexit(1);
    }

    // Handle connection requests, only one active connection
    // request at a time.
    //
    while (1) {
        len = sizeof(caddr);
        fd = accept(galfa_serve_fd, (struct sockaddr *) &caddr, &len);
        if (fd < 0) {
            perror("accept failed on listening socket");
            gexit(1);
        }
        if (galfa_client_fd > 0) {
            // Single client at time...
            //
            printf("Closing connection requested while another is active.\n");
            close(fd);
            continue;
        }
        sm_state = 0;
        sm_pos = 0;
        galfa_client_fd = fd;
        fcntl(galfa_client_fd, F_SETFL, O_NONBLOCK);
    }
    // not reached
    return NULL;
}

static void
write_block(void *pkt, u_long len)
{
    char        *ptr = (char *) pkt;
    int         rv;
    
    if (!galfa_client_fd)
        return;

    while (len > 0) {
        rv = write(galfa_client_fd, ptr, len);
        if (rv == 0) {
            // socket closed, no probem
            close(galfa_client_fd);
            send_enable = 0;
            send_cnt = 0;
            galfa_client_fd = 0;
            return;
        }
        if (rv < 0) {
            if (errno == EINTR || errno == EAGAIN) 
                continue;   // try again
            perror("Writing to socket borked");
            close(galfa_client_fd);
            send_enable = 0;
            send_cnt = 0;
            galfa_client_fd = 0;
            return;
        }
        len -= rv;
        ptr += rv;
    }
    return;
}

static void
gsock_send_packet(Ab **ab, void *pkt, u_long len)
{
    int     lenn = htonl(len);
    write_block(&lenn, 4);
    write_block(pkt, len);
}

static int
beam_mask(Ab **ab)
{
    int     mask = 0, i;
    
    for(i=0; i<G_BEAMS; i++)
        if (ab[i])
            mask |= (1 << i);
    return mask;
}

static void
process_cmd(Ab **ab, galfa_cmd *cmd, int *redraw) 
{
    struct timeval  tv;
    int             i;
    gettimeofday(&tv, NULL);
    int             cmdw = ntohl(cmd->cmd);

#ifdef DEBUG
    printf("Command %d\n", cmdw);
#endif
    switch (cmdw) {
        case GALFA_CMD_GETPARAM:
            cmd->mix = htonl(opt_mix & G_MIX_MASK);
            cmd->wshift = htonl(opt_wshift);
            cmd->nshift = htonl(opt_nshift);
            cmd->wpfb = htonl(opt_wpfb);
            cmd->npfb = htonl(opt_npfb);
            cmd->beam = htonl(beam_mask(ab));
            cmd->time1 = htonl((long) tv.tv_sec);
            cmd->time2 = htonl((long) tv.tv_usec);
            cmd->response = htonl(GALFA_RESP_GETPARAM);
            cmd->version = htonl(GALFA_VERSION);
            for(i=0; i<G_BEAMS*2; i++) {
                cmd->dac[i] = htonl((u_long) g_dac[i]);
                cmd->rms[i] = htonl(g_rms[i]);
            }

            // Send packet back to sender
            gsock_send_packet(ab, cmd, sizeof(galfa_cmd));
            break;

        case GALFA_CMD_SETPARAM:
            opt_mix = ntohl(cmd->mix) & G_MIX_MASK; 
            opt_wshift = ntohl(cmd->wshift) & G_MIX_WSHIFT;
            opt_nshift = ntohl(cmd->nshift) & G_MIX_NSHIFT;
            opt_wpfb = ntohl(cmd->wpfb) & G_MIX_WPFB;
            opt_npfb = ntohl(cmd->npfb) & G_MIX_NPFB;
            g_set_shift(ab);
            *redraw = 1;
            break;

        case GALFA_CMD_SETDAC:
            // Stop sending data 
            send_enable = 0;
            send_cnt = 0;

            // Calibrate the levels (set the dacs)
            opt_level = ntohl(cmd->cnt);
            set_levels_new(ab);

            cmd->mix = htonl(opt_mix);
            cmd->wshift = htonl(opt_wshift);
            cmd->nshift = htonl(opt_nshift);
            cmd->wpfb = htonl(opt_wpfb);
            cmd->npfb = htonl(opt_npfb);
            cmd->beam = htonl(beam_mask(ab));
            cmd->time1 = htonl((long) tv.tv_sec);
            cmd->time2 = htonl((long) tv.tv_usec);
            cmd->response = htonl(GALFA_RESP_SETDAC);
            cmd->version = htonl(GALFA_VERSION);
            for(i=0; i<G_BEAMS*2; i++) {
                cmd->dac[i] = htonl((u_long) g_dac[i]);
                cmd->rms[i] = htonl(g_rms[i]);
            }

            gsock_send_packet(ab, cmd, sizeof(galfa_cmd));
            *redraw = 1;
            break;

        case GALFA_CMD_GETLEVEL:
            // Stop sending data 
            send_enable = 0;
            send_cnt = 0;

            get_sock_levels_new(ab);
            cmd->mix = htonl(opt_mix);
            cmd->wshift = htonl(opt_wshift);
            cmd->nshift = htonl(opt_nshift);
            cmd->wpfb = htonl(opt_wpfb);
            cmd->npfb = htonl(opt_npfb);
            cmd->beam = htonl(beam_mask(ab));
            cmd->time1 = htonl((long) tv.tv_sec);
            cmd->time2 = htonl((long) tv.tv_usec);
            cmd->response = htonl(GALFA_RESP_GETLEVEL);
            cmd->version = htonl(GALFA_VERSION);
            for(i=0; i<G_BEAMS*2; i++) {
                cmd->dac[i] = htonl((u_long) g_dac[i]);
                cmd->rms[i] = htonl(g_rms[i]);
            }

            gsock_send_packet(ab, cmd, sizeof(galfa_cmd));
            *redraw = 1;
            break;

        case GALFA_CMD_GETDATA:
            send_enable = 1;
            send_cnt = ntohl(cmd->cnt);
            break;

        case GALFA_CMD_ABORT:
            // Stop sending data 
            send_enable = 0;
            send_cnt = 0;
            break;

        default:
            printf("Bad command from socket: %u.\n", cmd->cmd);
            break;
    }
}

// Non-blocking check to see if there is a command
// on the socket. Read the command and behave appropriately.
//
galfa_cmd *
gsock_listen(Ab **ab, int *redraw)
{
    static int          sm_len = 0;
    static galfa_cmd    sm_cmd;
    int                 n;

    if (!galfa_client_fd)
        return NULL;

    switch (sm_state) {
        // Reading len of packet
        case 0:     
            n = read(galfa_client_fd, ((char *) &sm_len) + sm_pos, 
                    4-sm_pos);
            if (n == 0) {
                // Socket closed
                close(galfa_client_fd);
                send_enable = 0;
                send_cnt = 0;
                galfa_client_fd = 0;
                return NULL;
            }
            if (n < 0) {
                if (errno == EINTR || errno == EAGAIN)
                    return NULL;
                printf("Socket borked...\n");
                close(galfa_client_fd);
                send_enable = 0;
                send_cnt = 0;
                galfa_client_fd = 0;
                return NULL;
            }
            sm_pos += n;
            if (sm_pos==4) {
                sm_pos = 0;
                sm_state = 1;
                sm_len = ntohl(sm_len);
                if (sm_len != sizeof(galfa_cmd)) {
                    printf("cmd packet wrong size: %d\n", sm_len);
                    close(galfa_client_fd);
                    send_enable = 0;
                    send_cnt = 0;
                    galfa_client_fd = 0;
                    return NULL;
                }
            }

        // Reading the command packet
        case 1:     
            n = read(galfa_client_fd, ((char *) &sm_cmd) + sm_pos, 
                    sizeof(sm_cmd)-sm_pos);
            if (n == 0) {
                // Socket closed
                close(galfa_client_fd);
                send_enable = 0;
                send_cnt = 0;
                galfa_client_fd = 0;
                return NULL;
            }
            if (n < 0) {
                if (errno == EINTR || errno == EAGAIN)
                    return NULL;
                printf("Socket borked...\n");
                close(galfa_client_fd);
                send_enable = 0;
                send_cnt = 0;
                galfa_client_fd = 0;
                return NULL;
            }
            sm_pos += n;
            if (sm_pos==sizeof(sm_cmd)) {
                sm_pos = 0;
                sm_state = 0;
                if (ntohl(sm_cmd.magic) != GALFA_MAGIC) {
                    printf("Magic number in packet mismatch packet.\n");
                    close(galfa_client_fd);
                    send_enable = 0;
                    send_cnt = 0;
                    galfa_client_fd = 0;
                    return NULL;
                }
                if (ntohl(sm_cmd.version) != GALFA_VERSION) {
                    printf("Command version mismatch: %08x != %08x.\n",
                        ntohl(sm_cmd.version), GALFA_VERSION);
                    close(galfa_client_fd);
                    send_enable = 0;
                    send_cnt = 0;
                    galfa_client_fd = 0;
                    return NULL;
                }
                process_cmd(ab, &sm_cmd, redraw);
            }
    }
    return NULL;
}


// Called at the beginning of the program, start a thread
// to listen for connections.
//
void
gsock_open(Ab **ab)
{
    static pthread_t       listen_thread;

    pthread_create(&listen_thread, NULL, g_connect, NULL);
}

// Send 1s of galfa data to the socket if appropriate
// Nominally this will send 14-packets to the host, 1 packet
// for each polarity.  If there are fewer boards installed
// then fewer packets are sent.  Host should prepare accordingly
// and check beam and polarity field of each packet.
//
void
gsock_write(Ab **ab, galfa_pkt **g, struct timeval *tv)
{
    static galfa_data   d;
    int                 i, j;

    if (!send_enable)
        return;
    if (send_cnt && --send_cnt == 0)
            send_enable = 0;

    d.magic = htonl(GALFA_MAGIC);
    d.version = htonl(GALFA_VERSION);
    d.cmd = htonl(0);
    d.response = htonl(GALFA_RESP_GETDATA);
    d.time1 = htonl(tv->tv_sec);
    d.time2 = htonl(tv->tv_usec);
    d.seq = htonl(g[0]->misc & 0xffff);

    for(i=0; i<G_BEAMS; i++) {
        if (!ab[i])
            continue;
        d.beam = htonl(i);

        // Send a packet for polarity A
        d.polarity = htonl(0);
        for(j=0; j<GALFA_N_BINS; j++)
            d.ndata[j] = htonl(g[i]->pola_n[j]);
        for(j=0; j<GALFA_W_BINS; j++)
            d.wdata[j] = htonl(g[i]->pola_w[j]);
        gsock_send_packet(ab, &d, sizeof(d));

        // Send a packet for polarity B
        d.polarity = htonl(1);
        for(j=0; j<GALFA_N_BINS; j++)
            d.ndata[j] = htonl(g[i]->polb_n[j]);
        for(j=0; j<GALFA_W_BINS; j++)
            d.wdata[j] = htonl(g[i]->polb_w[j]);
        gsock_send_packet(ab, &d, sizeof(d));
    }
}

void
gsock_close(void)
{
    printf("gsock_close()....\n");
    if (galfa_serve_fd)
        close(galfa_serve_fd);
    printf("gsock_close() done...\n");
}
