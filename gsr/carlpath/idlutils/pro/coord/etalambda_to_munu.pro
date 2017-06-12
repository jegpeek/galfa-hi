;+
; NAME:
;   etalambda_to_munu
; PURPOSE:
;   convert from eta, lambda (SDSS survey coordinates) to GC coords
; CALLING SEQUENCE:
;   etalambda_to_munu, eta,lambda, mu,nu, stripe
; INPUTS:
;   eta     SDSS survey coordinate eta (deg)
;   lambda  SDSS survey coordinate lambda (deg)
; OUTPUTS:
;   mu      Survey great circle longitude (deg)
;   nu      Survey great circle latitude (deg)
; BUGS:
;   Location of the survey center is hard-wired, not read from astrotools.
; REVISION HISTORY:
;   2002-Feb-20  written by Blanton (NYU)
;-
pro etalambda_to_munu, eta,lambda,mu,nu,stripe
  racen= 185.0D  ; deg
  deccen= 32.5D  ; deg

  ; set stripe
  x1=-sin(lambda)
  y1=-sin(lambda)
  r2d= 180.0D/double(!PI)
  dec= r2d*asin(cos(lambda/r2d)*sin((eta+deccen)/r2d))
  ra= r2d*atan(sin(lambda/r2d),cos(lambda/r2d)*cos((eta+deccen)/r2d))+racen
end
