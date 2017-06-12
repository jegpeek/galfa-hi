;+
; NAME:
;   profinterp
;
; PURPOSE:
;   Interpolates a radial profile of the sort output by photo
;
; CALLING SEQUENCE:
;   profinterp,nprof,profmean,radius,maggies, [maggieserr=, profradius= $
;      proferr=, radiusscale=, maggiesscale=]
;
; INPUTS:
;   nprof - number of measured elements in the profile 
;   profmean - values (in maggies) in the profile [15]
;   radius - a set of values to interpolate to [N]
;   maggies - calculated maggies
;
; OPTIONAL INPUTS:
;   proferr - errors in profile
;   profradius - boundaries of annuli in profile (set to photo default
;                in arcsec)
;   radiusscale - asinh scale for radii
;   maggiesscale - asinh scale for maggieses
;
; OUTPUTS:
;   maggieserr - calculated error
;
; OPTIONAL INPUT/OUTPUTS:
;
; COMMENTS:
;   Set up for using the profMean in the tsObj files of the SDSS,
;   input and output in maggies (or any linear measure of surface 
;   brightness
;
; EXAMPLES:
;
; BUGS:
;   Slow.
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;   16-Jan-2002  Written by Mike Blanton, NYU
;-
;------------------------------------------------------------------------------
pro profinterp,nprof,profmean,radius,maggies,maggieserr=maggieserr, $
               profradius=profradius, proferr=proferr, $
               radiusscale=radiusscale, maggiesscale=maggiesscale

if(NOT keyword_set(radiusscale)) then radiusscale=0.05
if(NOT keyword_set(maggiesscale)) then maggiesscale=1.e-10
if(NOT keyword_set(profradius)) then $
  profradius=[0., 0.564190, 1.692569, 2.585442, 4.406462, $
              7.506054, 11.576202, 18.584032, 28.551561, $
              45.503910, 70.510155, 110.530769, 172.493530, $
              269.519104, 420.510529, 652.500061]*0.396

PI=3.14159265358979d

nprofiles=n_elements(nprof)
nrad=n_elements(profradius)
if(NOT keyword_set(proferr)) then proferr=dblarr(nrad-1l,nprofiles)
cumprof=dblarr(nrad,nprofiles)
cumprofvar=dblarr(nrad,nprofiles)
indx=lindgen(nrad-1l)
indxp1=lindgen(nrad-1l)+1l
profmean=reform(profmean,nrad-1l,nprofiles)
proferr=reform(proferr,nrad-1l,nprofiles)
cumprof[1l:nrad-1l,*]= $
  total(profmean[indx,*]*PI* $
        ((profradius[indxp1]^2-profradius[indx]^2)#replicate(1,nprofiles)), $
        1,/cumulative)
cumprofvar[1l:nrad-1l,*]= $
  total((proferr[indx,*]*PI* $
         ((profradius[indxp1]^2-profradius[indx]^2)# $
          replicate(1,nprofiles)))^2, $
        1,/cumulative)

aprofradius=asinh2(profradius[0:nrad-1]/radiusscale)
acumprof=asinh2(cumprof/maggiesscale)
acumprofvar=asinh2(cumprofvar/maggiesscale^2)

amaggies=dblarr(nprofiles)
avar=dblarr(nprofiles)
for i=0l, nprofiles-1l do begin
    amaggies[i]=spline(aprofradius,acumprof[*,i],asinh2(radius[i]/radiusscale))
    avar[i]=spline(aprofradius,acumprofvar[*,i],asinh2(radius[i]/radiusscale))
endfor

maggies=maggiesscale*sinh(amaggies)
var=maggiesscale^2*sinh(avar)
maggieserr=sqrt(var)

end
