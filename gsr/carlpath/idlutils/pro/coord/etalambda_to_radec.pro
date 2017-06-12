;+
; NAME:
;   etalambda_to_radec
; PURPOSE:
;   convert from eta, lambda (SDSS survey coordinates) to RA, Dec
; CALLING SEQUENCE:
;   etalambda_to_radec, eta,lambda,ra,dec
; INPUTS:
;   eta     SDSS survey coordinate eta (deg)
;   lambda  SDSS survey coordinate lambda (deg)
; OUTPUTS:
;   ra      RA (deg), J2000
;   dec     Dec (deg), J2000
; BUGS:
;   Location of the survey center is hard-wired, not read from astrotools.
; REVISION HISTORY:
;   2001-Jul-21  written by Hogg (NYU)
;-
pro etalambda_to_radec, eta,lambda,ra,dec
  racen= 185.0D  ; deg
  deccen= 32.5D  ; deg
  r2d= 180.0D/double(!PI)
  dec= r2d*asin(cos(lambda/r2d)*sin((eta+deccen)/r2d))
  ra= r2d*atan(sin(lambda/r2d),cos(lambda/r2d)*cos((eta+deccen)/r2d))+racen
end
