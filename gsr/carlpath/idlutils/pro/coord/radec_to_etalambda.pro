;+
; NAME:
;   radec_to_etalambda
; PURPOSE:
;   convert from RA, Dec to eta, lambda (SDSS survey coordinates)
; CALLING SEQUENCE:
;   radec_to_etalambda, ra,dec,eta,lambda,stripenumber=stripenumber
; INPUTS:
;   ra      RA (deg), J2000
;   dec     Dec (deg), J2000
; OUTPUTS:
;   eta     SDSS survey coordinate eta (deg)
;   lambda  SDSS survey coordinate lambda (deg)
; OPTIONAL OUTPUTS:
;   stripenumber   SDSS survey stripe number (integer)
; BUGS:
;   Location of the survey center is hard-wired (in etalambda_to_radec.pro);
;     it should be read from astrotools.
; REVISION HISTORY:
;   2001-Jul-21  written by Hogg (NYU)
;-
pro radec_to_etalambda, ra,dec,eta,lambda,stripenumber=stripenumber
  etalambda_to_radec, 0.0D,0.0D,racen,deccen
  r2d= 180.0D/double(!PI)

; basic transformation
  eta= r2d*atan(sin(dec/r2d),cos(dec/r2d)*cos((ra-racen)/r2d))-deccen
  stripenumber= floor((eta+58.75D)/2.5D)
  lambda= r2d*asin(cos(dec/r2d)*sin((ra-racen)/r2d))

; all the sign-flipping crap
  bad= where(eta LT -90.0D OR eta GT 90.0D,nbad)
  if nbad GT 0 then begin
    eta[bad]= eta[bad]+180.0D
    lambda[bad]= 180.0D -lambda[bad]
  endif
  bad= where(eta GT 180.0D,nbad)
  if nbad GT 0 then eta[bad]= eta[bad]-360.0
  bad= where(lambda GT 180.0D,nbad)
  if nbad GT 0 then lambda[bad]= lambda[bad]-360.0
  bad= where(stripenumber LT 0,nbad)
  if nbad GT 0 then stripenumber[bad]= stripenumber[bad]+144
  return
end

