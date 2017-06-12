
/* wapp state broadcasted shared memory */

struct WAPPSHM {
  char project_id[8];   /*  from exec used to choos file */
  char wapp[8];         /* machine name */
  char config[24];      /* string from gui */
  float bw;             /* MHz */
  float power[4];       /* the 4 power values last computed */
  int mode;             /* bit 0 isalfa, bit 1 is spectral line */
  int bits;             /* 16 or 32 bits */
  int channelafirst;    /* true if channel a is first */
  int bins;             /* number of bins in folding mode */
  float dump_ival;      /* in seconds */
  int running;          /* true if running */
  float samp_time;      /* lowest level integration time in micro seconds */
  int num_lags;         /* number of lags this mode */
  int attena[2];        /* two atten values for AFLA mode */         
  int attenb[2];        
  int countdown;        /* seconds */
  int total;            /* seconds */
  char file[128];       /* current filename */
};


