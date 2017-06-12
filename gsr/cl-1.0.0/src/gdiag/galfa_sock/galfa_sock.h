//
//  Socket interface structures for galfa
//

// Jeff Mock
// 2030 Gough St.
// San Francisco, CA 94109
// jeff@mock.com
// (c) 2004
//
// The protocol consists of two structures, each composed just
// of u_int32_t, so it's easy to use the protocol from a variety
// of languages. 
//
// Data is sent over a single bidirectional TCP socket in network 
// byte order.
//
// A packet is sent as a 4-byte len followed by one of these
// structures.  
//
// The magic field contains a constant that says
// this is galfa data.  The version field masked with GALFA_VERSION_MASK
// tells you the major portion of the protocal version. A mismatch
// of the major protocol says that the two sides are too far
// out of date (the structures are different in a significant way)
//
// The galfa_cmd struct is sent by the host side to provide a command
// to the spectrometer.  The spectrometer can send this structure
// back with the response field fand other data files filled-in
// as appropriate.
//
// The galfa_data struct is only sent from the spectrometer to the host
//
// The hosts connects to galfa on port 1420.
//
// When connected galfa doesn't send anything to the host until
// requested.
//
// The "cmd" field in the galfa_cmd packet causes the following
// actions:
//
//      GALFA_CMD_GETPARAM
//          galfa fills in the cmd structure with current
//          operating parameters and sends packet back to 
//          to host with response field set to GALFA_RESP_GETPARAM.
//          The 14 "level" are the RMS levels from the last time
//          either a CMD_GETLEVEL or CMD_SETDAC was issued.
//
//      GALFA_CMD_SETPARAM
//          galfa sets operating parameters according to structure.
//          The following fields are set in galfa:
//              mix
//              wshift
//              nshift
//              wpfb
//              npfb
//
//      GALFA_CMD_SETDAC
//          Galfa calibrates input levels to "cnt" RMS DAC units.
//          This takes about 10s and galfa sends a galfa_cmd packet
//          back with a GALFA_RESP_SETDAC response code.  If 
//          data capture is currently active it is aborted.
//          The actual RMS levels are in the "levels" field as 
//          RMS ADC units * 1000.
//
//      GALFA_CMD_GETLEVEL
//          Galfa reads the actualy RMS input levels and sends
//          back a GALFA_RESP_GETLEVEL response.  This only
//          takes about 100ms, much faster than setting levels.
//          Any active capture is aborted.
//
//      GALFA_CMD_GETDATA
//          Galfa sends data for "cnt" seconds.  It can take
//          up to 1s before the first data item is sent.  If
//          "cnt" is zero then data is sent once a second until
//          an abort ir sent or the socket is closed.
//
//      GALFA_CMD_ABORT
//          Galfa aborts and data capture in progress.  Galfa
//          might send an additional 1s of data after receiving
//          this command.
//

//



#ifndef __GALFA_SOCK_H_
#define __GALFA_SOCK_H_

#include <sys/types.h>

#define GALFA_WIDE512               // Wideband has 512 points

#define GALFA_PORT              1420

#define GALFA_BEAMS             7
#define GALFA_MAGIC             0xdeadbeef
#define GALFA_VERSION           0x00000101
#define GALFA_VERSION_MASK      0x0000ff00

#define GALFA_CMD_GETPARAM      1
#define GALFA_CMD_SETPARAM      2
#define GALFA_CMD_GETDATA       3
#define GALFA_CMD_ABORT         4
#define GALFA_CMD_SETDAC        5
#define GALFA_CMD_GETLEVEL      6

#define GALFA_RESP_GETPARAM     100
#define GALFA_RESP_SETDAC       101
#define GALFA_RESP_GETLEVEL     102
#define GALFA_RESP_GETDATA      103


// These are copied from galfa.h, both files have to change
// if these names change.
//
// These are from the perl script vcalc in gk/src in the chip
// source files.  It is a calculation for the datapath of the
// maximum accumulated value for an integration.
//
#ifdef GALFA_WIDE512
#define GALFA_W_MAX           ((u_int32_t) 0x5e0fa1f0)
#else
#define GALFA_W_MAX           ((u_int32_t) 0xd6ff2900)
#endif
#define GALFA_N_MAX           ((u_int32_t) 0xbc1f43e0)
//
#ifdef GALFA_WIDE512
#define GALFA_W_BINS    512
#define GALFA_N_BINS    7679
#define GALFA_N_OFFSET  257         // number of bins dropped on left side
#else
#define GALFA_W_BINS    256
#define GALFA_N_BINS    7935
#define GALFA_N_OFFSET  129         // number of bins dropped on left side
#endif
#define GALFA_N_WIDTH   8192        // actual narrow width before truncation
#define GALFA_N_DEC     14          // decimation of narrowband transform


typedef struct {
    u_int32_t       magic;          // Magic number says galfa packet
    u_int32_t       version;        // major/minor version
    u_int32_t       cmd;            // command from host
    u_int32_t       response;       // galfa response
    u_int32_t       cnt;            // count parameter for GETDATA
    u_int32_t       mix;            // 0..31 digital mix
    u_int32_t       wshift;         // 3-bit accumulator up shift (0-7)
    u_int32_t       nshift;         // 3-bit accumulator up shift (0-7)
    u_int32_t       wpfb;           // 9-bit wide FFT shift mask
    u_int32_t       npfb;           // 13-bit narrow FFT shift mask
    u_int32_t       beam;           // 7-bit mask of active beams
    u_int32_t       time1;          // tv_sec of unix time
    u_int32_t       time2;          // tv_usec of unix time
    u_int32_t       dac[14];        // values of level dacs
    u_int32_t       rms[14];        // RMS level of signal in ADC units*1000
} galfa_cmd;


typedef struct {
    u_int32_t       magic;          // Magic number says galfa packet
    u_int32_t       version;        // major/minor version
    u_int32_t       cmd;            // command from host
    u_int32_t       response;       // galfa response
    u_int32_t       error;
    u_int32_t       time1;
    u_int32_t       time2;
    u_int32_t       seq;            // 16-bit sequence # from hardware
    u_int32_t       beam;
    u_int32_t       polarity;
    u_int32_t       ndata[GALFA_N_BINS];    // narrowband bins
    u_int32_t       wdata[GALFA_W_BINS];    // wideband bins
} galfa_data;

#endif

