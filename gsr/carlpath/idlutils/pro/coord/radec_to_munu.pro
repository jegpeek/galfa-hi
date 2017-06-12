;+
; NAME:
;   radec_to_munu
; PURPOSE:
;   convert from ra, dec (SDSS survey coordinates) to GC coords
; CALLING SEQUENCE:
;   radec_to_munu, ra,dec, mu,nu, stripe
; INPUTS:
;   ra      Eq. 2000 coords (deg)
;   dec
; OUTPUTS:
;   mu      Survey great circle longitude (deg)
;   nu      Survey great circle latitude (deg)
; BUGS:
;   Location of the survey center is hard-wired, not read from astrotools.
;   Incredible hack to get stripe and inclination
; REVISION HISTORY:
;   2002-Feb-20  written by Blanton (NYU)
;-
pro radec_to_munu, ra,dec,mu,nu,stripe,setstripe=setstripe
  racen= 185.0D  ; deg
  deccen= 32.5D  ; deg
  r2d= 180.0D/double(!PI)
  d2r= 1.D/r2d

  ; set anode
  anode=95.D
  radec_to_etalambda,ra,dec,eta,lambda
	if(n_elements(setstripe) gt 0) then begin
	  stripe=long(ra-ra)+setstripe  
	endif else begin
    eta_to_stripe,eta,lambda,stripe
	endelse
  stripe_to_incl,stripe,incl

  x1=cos((ra-anode)*d2r)*cos(dec*d2r)
  y1=sin((ra-anode)*d2r)*cos(dec*d2r)
  z1=sin(dec*d2r)
  x2 = x1
  y2 = y1*cos(incl*d2r) + z1*sin(incl*d2r)
  z2 =-y1*sin(incl*d2r) + z1*cos(incl*d2r)

  mu = r2d*atan(y2,x2)+anode;
  nu = r2d*asin(z2);
  atbound2,nu,mu

end
