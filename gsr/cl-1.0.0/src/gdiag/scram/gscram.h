
//  Call gscram_init and it will start a thread that will listen
//  for multicast packets and fill in these fields as it sees them.
//

extern double  scram_ra;               // radians
extern double  scram_dec;              // radians
extern double  scram_radec_tm;         // seconds after midnight
extern double  scram_lo1;              // MHz
extern double  scram_alfapos;          // degrees
extern double  scram_az;               // degrees
extern double  scram_za;               // degress
extern double  scram_azza_tm;          // seconds after midnight
extern char    scram_obsmode[256];     // drift, cal, etc
extern char    scram_obsname[256];     // drift, cal, etc
extern char    scram_object[256];      // Bxxxx-xxx

void gscram_init(void);
