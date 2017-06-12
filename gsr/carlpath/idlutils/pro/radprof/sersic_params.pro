;+
; NAME:
;   sersic
;
; PURPOSE:
;   Convolves a radial profile with seeing (expressed as a sum of
;   gaussians) assuming axisymmetry
;
; CALLING SEQUENCE:
;   profmeansee=convolve_radial(nprof, profmean, seeing_width, $
;                               [seeing=, seegrid=, /setseegrid])
;
; INPUTS:
;   nprof - number of entries to use in profmean [N]
;   profmean - radial profile [15,N]
;   seeing_width - absolute width of seeing [N]
;
; OPTIONAL INPUTS:
;   seeing - relative widths and amplitudes of seeing gaussians
;   setseegrid - if set, reset the seegrid
;
; OUTPUTS:
;
; OPTIONAL INPUT/OUTPUTS:
;   seegrid - matrix of seeing_width and radius
;
; COMMENTS:
;
; EXAMPLES:
;
; BUGS:
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;   23-Mar-2002  Written by Mike Blanton, NYU
;-
;------------------------------------------------------------------------------
pro sersic_params,amp,nsersic,r0,maggies=maggies,r50=r50,r90=r90,radius_vals=radius_vals,petromaggies=petromaggies,petror50=petror50,petror90=petror90,petrorad=petrorad,profradius=profradius

PI=3.14159265358979

; set radii
if(NOT keyword_set(profradius)) then $
  profradius=[0., 0.564190, 1.692569, 2.585442, 4.406462, $
              7.506054, 11.576202, 18.584032, 28.551561, $
              45.503910, 70.510155, 110.530769, 172.493530, $
              269.519104, 420.510529, 652.500061]*0.396
if(NOT keyword_set(radius_vals)) then $
  radius_vals=exp(alog(r0*0.03)+(alog(r0*100000.)-alog(r0*0.03))* $
                  dindgen(1000)/1000.)
nrad=n_elements(radius_vals)
i=lindgen(nrad-1L)
ip1=i+1L
dradius_vals=dblarr(nrad)
dradius_vals[i]=radius_vals[ip1]-radius_vals[i]
dradius_vals[nrad-1L]=radius_vals[nrad-1L]-radius_vals[nrad-2L]

; get profile and cumulative flux
sersic_vals=sersic(radius_vals,amp,nsersic,r0)
cummaggies=total(2.*PI*radius_vals*dradius_vals*sersic_vals,/double, $
                 /cumulative)

; Obtain total versions of r50, r90, etc
maggies=cummaggies[nrad-1L]
r50indx=where(cummaggies[i] lt 0.5*maggies and cummaggies[ip1] gt 0.5*maggies)
r50s=(0.5*maggies-cummaggies[r50indx])/ $
  (cummaggies[r50indx+1L]-cummaggies[r50indx])
r50=radius_vals[r50indx]+(radius_vals[r50indx+1L]-radius_vals[r50indx])*r50s
r90indx=where(cummaggies[i] lt 0.9*maggies and cummaggies[ip1] gt 0.9*maggies)
r90s=(0.9*maggies-cummaggies[r90indx])/ $
  (cummaggies[r90indx+1L]-cummaggies[r90indx])
r90=radius_vals[r90indx]+(radius_vals[r90indx+1L]-radius_vals[r90indx])*r90s

; Obtain petro versions of r50, r90, etc
avgsb=cummaggies/(PI*radius_vals^2)
petroradindx=where(sersic_vals[i]/avgsb[i] gt 0.2 and $
                   sersic_vals[ip1]/avgsb[ip1] lt 0.2)
petroradindx=petroradindx[0]
petrorad=radius_vals[petroradindx]
petroap=2.*petrorad
petroapindx=where(radius_vals[i] lt petroap and radius_vals[ip1] gt petroap)
petroapindx=petroapindx[0]
petromaggies=cummaggies[petroapindx]
petror50indx=where(cummaggies[i] lt 0.5*petromaggies and $
                   cummaggies[ip1] gt 0.5*petromaggies)
petror50s=(0.5*petromaggies-cummaggies[petror50indx])/ $
  (cummaggies[petror50indx+1L]-cummaggies[petror50indx])
petror50=radius_vals[petror50indx]+$
  (radius_vals[petror50indx+1L]-radius_vals[petror50indx])*petror50s
petror90indx=where(cummaggies[i] lt 0.9*petromaggies and $
                   cummaggies[ip1] gt 0.9*petromaggies)
petror90s=(0.9*petromaggies-cummaggies[petror90indx])/ $
  (cummaggies[petror90indx+1L]-cummaggies[petror90indx])
petror90=radius_vals[petror90indx]+ $
  (radius_vals[petror90indx+1L]-radius_vals[petror90indx])*petror90s

end
