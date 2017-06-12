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
function sersic,radius_vals,amp,nsersic,r0

exponent=(radius_vals/r0)^(1./nsersic)
val=dblarr(n_elements(radius_vals))
indx=where(exponent lt 1.e+30,count)
if(count gt 0) then val[indx]=amp*exp(-exponent[indx])
return,val

end
