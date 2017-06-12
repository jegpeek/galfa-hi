
#include <string.h>
#include <mshmLib.h>
#include <execshm.h>
#include <wappshm.h>
#include <alfashm.h>

#define FLIP(x) flip_data( &(x), sizeof(x))

flip_agc( agc )
SCRM_B_AGC *agc;
{
  FLIP(agc->st.secMLastTick);
  FLIP(agc->st.auxReq[0]);
  FLIP(agc->st.auxReq[1]);
  FLIP(agc->st.auxReq[2]);
  FLIP(agc->st.cblkMCur.dat.modeAz);
  FLIP(agc->st.cblkMCur.dat.modeCh);
  FLIP(agc->st.cblkMCur.dat.modeGr);
  FLIP(agc->st.cblkMCur.dat.posAz);
  FLIP(agc->st.cblkMCur.dat.posCh);
  FLIP(agc->st.cblkMCur.dat.posGr);
  FLIP(agc->st.cblkMCur.dat.statAz);
  FLIP(agc->st.cblkMCur.dat.timeMs);
  FLIP(agc->st.fblkMCur.dat.azI.ampStat);
  FLIP(agc->st.fblkMCur.dat.azI.equipStat);
  FLIP(agc->st.fblkMCur.dat.azI.motorStat);
  FLIP(agc->st.fblkMCur.dat.chI.ampStat);
  FLIP(agc->st.fblkMCur.dat.chI.equipStat);
  FLIP(agc->st.fblkMCur.dat.chI.motorStat);
  FLIP(agc->st.fblkMCur.dat.grI.ampStat);
  FLIP(agc->st.fblkMCur.dat.grI.equipStat);
  FLIP(agc->st.fblkMCur.dat.grI.motorStat);
  FLIP(agc->st.mPosDataReq[0]);
  FLIP(agc->st.mPosDataReq[1]);
  FLIP(agc->st.mPosDataReq[2]);
  FLIP(agc->st.masterMode);
  FLIP(agc->st.posErr.aoCurSec.req.posTTD[0]);
  FLIP(agc->st.posErr.aoCurSec.req.posTTD[1]);
  FLIP(agc->st.posErr.aoCurSec.req.posTTD[2]);
  FLIP(agc->st.posErr.aoCurSec.req.timeMs);
  FLIP(agc->st.posErr.aoPrevSec.req.posTTD[0]);
  FLIP(agc->st.posErr.aoPrevSec.req.posTTD[1]);
  FLIP(agc->st.posErr.aoPrevSec.req.posTTD[2]);
  FLIP(agc->st.posErr.conPosDifRd[0]);
  FLIP(agc->st.posErr.conPosDifRd[1]);
  FLIP(agc->st.posErr.conPosDifRd[2]);
  FLIP(agc->st.posErr.reqPosDifRd[0]);
  FLIP(agc->st.posErr.reqPosDifRd[1]);
  FLIP(agc->st.posErr.reqPosDifRd[2]);
  FLIP(agc->st.posErr.yAoReq[0]);
  FLIP(agc->st.posErr.yAoReq[1]);
  FLIP(agc->st.posErr.yAoReq[2]);
  FLIP(agc->st.posErr.yVtx[0]);
  FLIP(agc->st.posErr.yVtx[1]);
  FLIP(agc->st.posErr.yVtx[2]);
}

flip_tt(  tt )
SCRM_B_TT *tt;
{
  FLIP(tt->st.slv[0].inpMsg.devStat);
  FLIP(tt->st.slv[0].inpMsg.position);
  FLIP(tt->st.slv[1].inpMsg.devStat);
  FLIP(tt->st.slv[1].inpMsg.position);
  FLIP(tt->st.slv[2].inpMsg.devStat);
  FLIP(tt->st.slv[2].inpMsg.position);
  FLIP(tt->st.slv[3].inpMsg.devStat);
  FLIP(tt->st.slv[3].inpMsg.position);

  FLIP(tt->st.slv[0].data.val[TTT_GSIND_TT_DI_UIO3]); /* 15, IlKey */
}

flip_pnt( pnt )
SCRM_B_PNT *pnt;
{
  FLIP(pnt->st.x.pl.curP.pnt.pos.c1);
  FLIP(pnt->st.x.pl.curP.pnt.pos.c2);
  FLIP(pnt->st.x.pl.curP.pnt.pos.cs);
  FLIP(pnt->st.x.pl.curP.pnt.pos.st);
  FLIP(pnt->st.x.pl.curP.raDecAppV[0]);
  FLIP(pnt->st.x.pl.curP.raDecAppV[1]);
  FLIP(pnt->st.x.pl.curP.raDecAppV[2]);
  FLIP(pnt->st.x.pl.curP.raDecTrueV[0]);
  FLIP(pnt->st.x.pl.curP.raDecTrueV[1]);
  FLIP(pnt->st.x.pl.curP.raDecTrueV[2]);

  FLIP(pnt->st.x.pl.curP.corAzRd);
  FLIP(pnt->st.x.pl.curP.corZaRd);
  FLIP(pnt->st.x.pl.curP.modelCorAzRd);
  FLIP(pnt->st.x.pl.curP.modelCorZaRd);

  FLIP(pnt->st.x.pl.curP.raJ);
  FLIP(pnt->st.x.pl.curP.decJ);

  FLIP(pnt->st.x.pl.curP.pnt.off.c1);
  FLIP(pnt->st.x.pl.curP.pnt.off.c2);
  FLIP(pnt->st.x.pl.curP.pnt.off.st);
  FLIP(pnt->st.x.pl.curP.pnt.off.cs);

  FLIP(pnt->st.x.pl.curP.pnt.rate.c1);
  FLIP(pnt->st.x.pl.curP.pnt.rate.c2);
  FLIP(pnt->st.x.pl.curP.pnt.rate.st);
  FLIP(pnt->st.x.pl.curP.pnt.rate.cs);

  FLIP(pnt->st.x.pl.curP.pnt.rateDur);
  FLIP(pnt->st.x.pl.curP.pnt.rateStDayNum);

  FLIP(pnt->st.x.pl.tm.secMidD);
  FLIP(pnt->st.x.pl.tm.lmstRd);

  FLIP(pnt->st.x.pl.tm.dayNum);
  FLIP(pnt->st.x.pl.tm.mjd);
  FLIP(pnt->st.x.pl.tm.astFrac);
  FLIP(pnt->st.x.pl.tm.ut1Frac);
  FLIP(pnt->st.x.pl.tm.year);
  FLIP(pnt->st.x.pl.req.master);
  FLIP(pnt->st.x.pl.req.trackTol);
  FLIP(pnt->st.x.pl.req.wrapReq);
  
  flip_uintbits(&pnt->st.x.statWd); /* all bit fields are :1 */
  FLIP(pnt->st.x.pl.req.reqState);
  FLIP(pnt->st.x.pl.curP.helioVelProj);
  FLIP(pnt->st.x.pl.curP.geoVelProj);
}

flip_tie( tie )
SCRM_B_TIE *tie;
{
  FLIP(tie->st.slv[0].inpMsg.devStat);
  FLIP(tie->st.slv[0].inpMsg.ldCell1);
  FLIP(tie->st.slv[0].inpMsg.ldCell2);
  FLIP(tie->st.slv[0].inpMsg.position);
  flip_uintbits(&tie->st.slv[0].statWd);
  FLIP(tie->st.slv[0].data.val[TTT_GSIND_GEN_SAFETY]);
  FLIP(tie->st.slv[0].data.val[TTT_GSIND_GEN_FAULTS]);
  FLIP(tie->st.slv[0].ioFail );
  FLIP(tie->st.slv[0].tickMsg.timeMs );

  FLIP(tie->st.slv[1].inpMsg.devStat);
  FLIP(tie->st.slv[1].inpMsg.ldCell1);
  FLIP(tie->st.slv[1].inpMsg.ldCell2);
  FLIP(tie->st.slv[1].inpMsg.position);
  flip_uintbits(&tie->st.slv[1].statWd);
  FLIP(tie->st.slv[1].data.val[TTT_GSIND_GEN_SAFETY]);
  FLIP(tie->st.slv[1].data.val[TTT_GSIND_GEN_FAULTS]);
  FLIP(tie->st.slv[1].ioFail );
  FLIP(tie->st.slv[1].tickMsg.timeMs );

  FLIP(tie->st.slv[2].inpMsg.devStat);
  FLIP(tie->st.slv[2].inpMsg.ldCell1);
  FLIP(tie->st.slv[2].inpMsg.ldCell2);
  FLIP(tie->st.slv[2].inpMsg.position);
  flip_uintbits(&tie->st.slv[2].statWd);
  FLIP(tie->st.slv[2].data.val[TTT_GSIND_GEN_SAFETY]);
  FLIP(tie->st.slv[2].data.val[TTT_GSIND_GEN_FAULTS]);
  FLIP(tie->st.slv[2].ioFail );
  FLIP(tie->st.slv[2].tickMsg.timeMs );
}

flip_if1( if1 )
SCRM_B_IF1 *if1;
{
  FLIP(if1->st.rfFreq);
  generic_bitflip(&if1->st.stat1, "5,3,1,1,1,1,1,9,9,1");
  generic_bitflip(&if1->st.stat2, "4,4,4,4,1,1,1,1,4,1,3,1,1,2");
  FLIP(if1->st.synI.freqHz[0]);
  FLIP(if1->st.synI.freqHz[1]);
  FLIP(if1->st.synI.ampDb[0]);
  FLIP(if1->st.synI.ampDb[1]);

  FLIP(if1->st.pwrmI.pwrDbm[1]);
  FLIP(if1->st.pwrmI.pwrDbm[0]);

  FLIP(if1->st.if1FrqMhz);
  FLIP(if1->st.lbnFbFreq);
}

flip_if2( if2)
SCRM_B_IF2 *if2;
{
  FLIP( if2->st.gain[0] );
  FLIP( if2->st.gain[1] );

  FLIP( if2->st.synI.freqHz[0] );
  FLIP( if2->st.synI.freqHz[1] );
  FLIP( if2->st.synI.freqHz[2] );
  FLIP( if2->st.synI.freqHz[3] );

  FLIP( if2->st.pwrmI.pwrDbm[0] );
  FLIP( if2->st.pwrmI.pwrDbm[1] );
  generic_bitflip( &if2->st.stat1,    "2,1,1,1,1,1,1,4,1,19");

  generic_bitflip( &if2->st.stat4[0], "2,2,2,7,19" );
  generic_bitflip( &if2->st.stat4[1], "2,2,2,7,19" );
  generic_bitflip( &if2->st.stat4[2], "2,2,2,7,19" );
  generic_bitflip( &if2->st.stat4[3], "2,2,2,7,19" );
}

flip_exec( exec)
struct EXECSHM *exec;
{
  struct WAPPSTATUS *ws;
  int i;

  FLIP(exec->velocity);
  FLIP(exec->ra);
  FLIP(exec->dec);
  FLIP(exec->off1);
  FLIP(exec->off2);
  FLIP(exec->centfreq);
  FLIP(exec->restfreq1);
  FLIP(exec->restfreq2);
  FLIP(exec->restfreq3);
  FLIP(exec->restfreq4);

  FLIP(exec->corr_estart);
  FLIP(exec->corr_dumplen);
  FLIP(exec->corr_icyc);
  FLIP(exec->corr_blank);

  FLIP(exec->repeat);
  FLIP(exec->total_repeats);
  FLIP(exec->secsp_repeat);
  FLIP(exec->secs_remain);
  FLIP(exec->total_remain);
  FLIP(exec->ison);

  FLIP(exec->map_x);
  FLIP(exec->map_y);
  for( i=0; i<4; i++ ) 
    FLIP(exec->destfreq[i]);

/* wapp status information */

/*
  for( i=0; i<4; i++ ) {
    ws = &exec->wapp[i];
    FLIP(ws->power[0]);
    FLIP(ws->power[1]);
    FLIP(ws->step[0]);
    FLIP(ws->step[1]);
    FLIP(ws->amax);
    FLIP(ws->astep);
    FLIP(ws->aval);
    FLIP(ws->bval);
    FLIP(ws->bw);
  }
*/
  FLIP(exec->scan);
  FLIP(exec->send_count);
}

flip_data( v, n )
void *v;
int n;
{
  switch(n) {
    case 1:
      break;
    case 2:
      in_swaps(v);
      break;
    case 4:
      in_swapf(v);
      break;
    case 8:
      in_swapd(v);
      break;
    default:
      printf("flip_data:cant flip %d bytes\n", n );
      break;
  }
}

/* handle bit fields when all are :1 */

flip_uintbits( u )
unsigned int *u;
{
  unsigned int bit;
  unsigned int ret;
  int i;

  in_swapf(u);

  bit = *u;
  ret = 0;

  for( i=0; i< 32; i++ ) {
    ret <<= 1; 
    ret |= (bit & 1);
    bit >>= 1;
  }

  *u = ret;
}

/*

There is no -in general- way to bit flip bit fields from Sun to gcc linux.
So I do this for now.

The string defines how many bits and fields from left to right:
So if Phil defines:

typedef struct {
  unsigned int    synDest  :2;
  unsigned int    mixerCfr :2;
  unsigned int    ampInpSrc:2;
  unsigned int    ampExtMsk:7;
  unsigned int    unused   :19;
} IF2_ST_STAT4;


The string is

"2,2,2,7,19"

*/

generic_bitflip( pvalue, str )
unsigned int *pvalue;
char *str;
{
  char *delim = ",";
  char *tok, *tokst;
  unsigned int new, lmask, v, num, index, value, shift;
  unsigned int all = 0xffffffff;

  value = *pvalue;
  flip_data( &value, sizeof(unsigned int)); 
  tokst = (char *)malloc( strlen(str)+1);
  memcpy( tokst, str, strlen(str)+1 );

  tok = strtok( tokst, delim );
  index = 0;
  new = 0;
  while( tok ) {
    num = atoi(tok); 
 
    lmask = all >> ( 32 - num );
    lmask = lmask << index;

    if( index + num > 16 ) {
      shift = 2*(index-16)+num;
      v = value << shift;
    } else {
      shift = 32-index-index-num;
      v = value >> shift;
    }

    v = lmask & v;
    new = v | new;

    index += num;

    tok = strtok(NULL, delim);
  }

  free(tokst);
  *pvalue = new;
}

flip_wapp(wapp)
struct WAPPSHM *wapp;
{
  FLIP(wapp->bw);
  FLIP(wapp->mode);
  FLIP(wapp->running);
  FLIP(wapp->num_lags);
  FLIP(wapp->attena[0]);
  FLIP(wapp->attenb[0]);
  FLIP(wapp->attena[1]);
  FLIP(wapp->attenb[1]);
  FLIP(wapp->power[0]);
  FLIP(wapp->power[1]);
  FLIP(wapp->power[2]);
  FLIP(wapp->power[3]);
}

flip_alfa(alfa)
struct ALFASHM *alfa;
{
  int i, n;

  n = sizeof(alfa->bias_voltages)/sizeof(float);

  for( i=0; i<n; i++ ) 
    FLIP(alfa->bias_voltages[i]);

  n = sizeof(alfa->other_voltages)/sizeof(float);

  for( i=0; i<n; i++ ) 
    FLIP(alfa->other_voltages[i]);

  FLIP(alfa->vacuum);
  FLIP(alfa->motor_position);
}

