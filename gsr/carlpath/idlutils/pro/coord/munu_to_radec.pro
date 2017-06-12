;+
; NAME:
;   munu_to_radec
; PURPOSE:
;   convert from GC coords to ra,dec
; CALLING SEQUENCE:
;   munu_to_radec, mu,nu, stripe, ra, dec
; INPUTS:
;   mu      Survey great circle longitude (deg)
;   nu      Survey great circle latitude (deg)
; OUTPUTS:
;   ra      Eq. 2000 coords (deg)
;   dec
; BUGS:
;   Location of the survey center is hard-wired, not read from astrotools.
; REVISION HISTORY:
;   2002-Feb-20  written by Blanton (NYU)
;-
pro munu_to_radec, mu,nu,stripe,ra,dec
  racen= 185.0D  ; deg
  deccen= 32.5D  ; deg
  r2d= 180.0D/double(!PI)
  d2r= 1.D/r2d

  ; set anode
  anode=95.D
  stripe_to_incl,stripe,incl

  x2=cos((mu-anode)*d2r)*cos(nu*d2r)
  y2=sin((mu-anode)*d2r)*cos(nu*d2r)
  z2=sin(nu*d2r)
  x1 = x2;
  y1 = y2*cos(incl*d2r) - z2*sin(incl*d2r);
  z1 = y2*sin(incl*d2r) + z2*cos(incl*d2r);

  ra = r2d*atan(y1,x1)+anode;
  dec = r2d*asin(z1);
  atbound2,dec,ra

end
