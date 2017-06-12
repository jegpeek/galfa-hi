
/* executive shared memory, state of observation, structure */
/* lots more to be added here                               */

struct EXECSHM {

  char source[128];   /* source name as requested by user */
  char obs_mode[128]; /* specific obs mode, runcor, on, onoff, mapping, ... */
  char obs_type[128]; /* line pulsar contin radar */
  char receiver[128]; /* requested receiver */
  char backends[128]; /* tcl list of enabled backends */
  char ifconfig[128]; /* either line or pulsar, depending on how the IF is configed */
  char catalog[256];  /* current catalog name */
  double velocity;    /* last requested velocity */
  char veltype[128];  /* last velocity type */
  char velframe[128]; /* last velocity frame */
  double ra;
  double dec;
  char epoch[48];
  double off1;
  double off2;
  char off_units[48];

  char line1[80]; /* requested lines */
  char line2[80]; /* requested lines */
  char line3[80]; /* requested lines */
  char line4[80]; /* requested lines */

  double centfreq; /* requested center rest frequency */
  double restfreq1; /* requested rest frequency */
  double restfreq2; 
  double restfreq3; 
  double restfreq4; 

/* interim correlator */
  int corr_estart;
  int corr_dumplen;
  int corr_icyc;
  int corr_blank;
  char corr_enable[128];
  char corr_config[128];
  char corr_bw[128];
  char corr_lags[128];
  char corr_wapp[128];

/* display information */

  int repeat;
  int total_repeats;
  int secsp_repeat; /* seconds per repeat */
  int secs_remain;
  int total_remain; /* total seconds remaining, all loops */
  int ison;        /* is the "on" position */

  char project_id[48];
  char observers[80];
  char work_directory[80];

/* mapping information */
  int map_x;
  int map_y;

/* IFLO configuration */

   double destfreq[4]; /* destination center frequency for IFLO config */

/* wapp status information */

   /*
  struct WAPPSTATUS {
    char   status[48];
    double power[2];
    double step[2];
    double amax;
    double astep;
    double aval;
    double bval;
    double bw; * bandwidth chosen used to compute freq *
  } wapp[4];
*/

  int scan;  /* scan number returned from vxw */
  unsigned int send_count; /* arbitrary counter that increments after send */
  char lastcal[128];  /* last corcal measurment */
  char rcvpower[128]; /* last receiver power string */
  double wind_speed;
  double wind_direction;

};

/* shared type definitions betweed tk_scram and exec_shm */

/* use the ones defined by yacc:  y.tab.h
#define CHARSTAR 1
#define INTEGER  2
#define DOUBLE   3
#define FLOAT    4
*/

struct SCRAMTABLE {
  char *name;                     /* name of the variable */
  int type;
  int size;
  void *pointer;                  /* pointer to the data */
  void (*conv)(char *, void *);   /* routine to make a string from pointer */
};

