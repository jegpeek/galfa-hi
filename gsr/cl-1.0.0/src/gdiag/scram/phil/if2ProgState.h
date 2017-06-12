/*
 *  include file for if2ProgState.h
 *  This is the state of if2Prog that can be run on vxWorks or sun os.
*/
#ifndef INCif2ProgStateh
#define INCif2ProgStateh
/*
 *   status word 1 for each mixer
*/
    typedef struct {
        unsigned int    synDest  :2;   /* 1-260to30,2-vlba/sb,3-mixers,0-fp*/
        unsigned int    mixerCfr :2;   /*mixFreq. 0,1,2,3->750,1250,1500,1750*/
        unsigned int    ampInpSrc:2;   /*0,1=syn,2=heliax,3=300 if*/
        unsigned int    ampExtMsk:7;
        unsigned int    unused   :19;
    } IF2_ST_STAT4;

/*
 *  if2 status. common status word
*/
typedef struct {
    unsigned int    ifInpFreq :2;   /*inp freq. 0,1,2,3->750nb,300,750,1500*/
    unsigned int    vlbaInpFrq:1;   /* 0-750,1:2000*/
    unsigned int    xferNormal:1;   /* 1-normal, 0-switched*/
    unsigned int    blank430  :1;   /* 1--> true, 0 false*/
    unsigned int    noiseSrcOn:1;   /* 1--> on, 0 off*/
    unsigned int    dualPol30 :1;   /* 30mhzIf 2 pol, 1-true, 0 - 4 polA*/
    unsigned int    vis30Mhz  :1;   /* 1--> greg, 0 ch*/
    unsigned int    calttlSrc :4;   /* 1-->8 cal ttl level source*/
    unsigned int    pwrMToIf  :1;   /* power meter swithed to IF input*/
    unsigned int    useAlfa   :1;   /* if set then ignore ifinpFreq */
    unsigned int    unused    :18;
    } IF2_ST_STAT1;

/*
 * synth state 
*/
typedef struct {
	double  freqHz[4];      /* to output*/
    double  ampDb[4];
	int		errLastIo[4];	/* ok or errnumber last i/o */		
	int		cumIoErrCnt[4]; /* count total errors each synth*/				
	} IF2_ST_SYN;
/*
 * power meter state
*/
typedef struct {
	float	pwrDbm[2];
	int     statLastRead;
	int		timeStamp;		/* last read*/
	} IF2_ST_PWRM;
/*
 * hp3488 state
*/
typedef struct {
	short   numslots[2];	/* in use*/
	short   slotOk[2];		/* bit 0->n 1 if slot ok to use*/
	unsigned short data[10];/* 0-4 polA, 5-9 polB*/
	int		errLastIo[2];  /* OK or error last i/o*/
	int		cumIoErrCnt[2];/* cumulative count of errors*/
	int		fill;
	} IF2_ST_3488;

/*
 * program state structure
*/
typedef struct {
	IF2_ST_SYN	synI;
	IF2_ST_PWRM pwrmI;
	IF2_ST_3488 st3488I; 	/* hp3488 board stat info*/
	IF2_ST_STAT4 stat4[4];	/* stat by mixer*/
	IF2_ST_STAT1 stat1;   	/* general status word*/
	int			 fill;		/* stay on 8 byte boundaries*/
	int          gain[2]; 	/* gain requested -11 30*/
	} IF2_PROG_STATE;
#endif
