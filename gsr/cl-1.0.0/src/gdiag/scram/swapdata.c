
/* genereic routines for big endian/little endian swapping */

double swapd( d )
double *d;
{
  union {
    double d;
    unsigned char c[sizeof(double)];
  }u;
  unsigned char t;

  u.d = *d;

  t = u.c[0];
  u.c[0] = u.c[7];
  u.c[7] = t;

  t = u.c[1];
  u.c[1] = u.c[6];
  u.c[6] = t;

  t = u.c[2];
  u.c[2] = u.c[5];
  u.c[5] = t;

  t = u.c[3];
  u.c[3] = u.c[4];
  u.c[4] = t;

  return(u.d);
}

/* return but dont swap */

long swapl(l)
long *l;
{
  union {
    long l;
    unsigned char c[4];
  }u;
  unsigned char temp;

  u.l = *l;
  temp = u.c[0];
  u.c[0] = u.c[3];
  u.c[3] = temp;

  temp = u.c[1];
  u.c[1] = u.c[2];
  u.c[2] = temp;

  return(u.l);
}

int swapi(l)
int *l;
{
  union {
    int l;
    unsigned char c[4];
  }u;
  unsigned char temp;

  u.l = *l;
  temp = u.c[0];
  u.c[0] = u.c[3];
  u.c[3] = temp;

  temp = u.c[1];
  u.c[1] = u.c[2];
  u.c[2] = temp;

  return(u.l);
}

unsigned short swaps(s)
unsigned short *s;
{
  union {
    unsigned s;
    unsigned char c[2];
  }u;
  unsigned char temp;

  u.s = *s;
  temp = u.c[0];
  u.c[0] = u.c[1];
  u.c[1] = temp;

  return(u.s);
}

in_swapus(s)
unsigned short *s;
{
  union SWAPS {
    unsigned short *s;
    unsigned char c[2];
  }*u;
  unsigned char t;

  u = (union SWAPS *)s;
  
  t = u->c[0];
  u->c[0] = u->c[1];
  u->c[1] = t;
}

in_swapf(f)
float *f;
{
  union SWAPF {
    float f;
    unsigned char c[4];
  }*u;
  unsigned char t;

  u = (union SWAPF *)f;
  
  t = u->c[0];
  u->c[0] = u->c[3];
  u->c[3] = t;

  t = u->c[1];
  u->c[1] = u->c[2];
  u->c[2] = t;
}

in_swaps(s)
short *s;
{
  union SWAPS {
    short s;
    unsigned char c[2];
  }*u;
  unsigned char t;

  u = (union SWAPS *)s;
  
  t = u->c[0];
  u->c[0] = u->c[1];
  u->c[1] = t;

}

in_swapd(d)
double *d;
{
  union SWAPD {
    double d;
    unsigned char c[4];
  }*u;
  unsigned char t;

  u = (union SWAPD *)d;
  
  t = u->c[0];
  u->c[0] = u->c[7];
  u->c[7] = t;

  t = u->c[1];
  u->c[1] = u->c[6];
  u->c[6] = t;

  t = u->c[2];
  u->c[2] = u->c[5];
  u->c[5] = t;

  t = u->c[3];
  u->c[3] = u->c[4];
  u->c[4] = t;
}

in_swapl(ll)
long *ll;
{
  union SWAPLL {
    long l;
    unsigned char c[4];
  }*u;
  unsigned char t;

  u = (union SWAPLL *)ll;
  
  t = u->c[0];
  u->c[0] = u->c[3];
  u->c[3] = t;

  t = u->c[1];
  u->c[1] = u->c[2];
  u->c[2] = t;
}

in_swapi(ii)
int *ii;
{
  union SWAPII {
    int i;
    unsigned char c[4];
  }*u;
  unsigned char t;

  u = (union SWAPII *)ii;
  
  t = u->c[0];
  u->c[0] = u->c[3];
  u->c[3] = t;

  t = u->c[1];
  u->c[1] = u->c[2];
  u->c[2] = t;
}


int set_swapd( p, d )
double *p;
double d;
{
  union {
    double d;
    unsigned char c[sizeof(double)];
  }u;
  unsigned char t;

  u.d = d;

  t = u.c[0];
  u.c[0] = u.c[7];
  u.c[7] = t;

  t = u.c[1];
  u.c[1] = u.c[6];
  u.c[6] = t;

  t = u.c[2];
  u.c[2] = u.c[5];
  u.c[5] = t;

  t = u.c[3];
  u.c[3] = u.c[4];
  u.c[4] = t;

  *p = u.d;
  return(0);
}

int set_swapi(p, l)
int *p;
int l;
{
  union {
    int l;
    unsigned char c[4];
  }u;
  unsigned char temp;

  u.l = l;
  temp = u.c[0];
  u.c[0] = u.c[3];
  u.c[3] = temp;

  temp = u.c[1];
  u.c[1] = u.c[2];
  u.c[2] = temp;

  *p = u.l;
  return(0);
}
