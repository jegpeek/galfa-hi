;+
; NAME:
;   maggies2lups
;
; PURPOSE:
;
; CALLING SEQUENCE:
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; OUTPUTS:
;
; OPTIONAL INPUT/OUTPUTS:
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
;   28-Mar-2002  Written by Mike Blanton, NYU
;-
;------------------------------------------------------------------------------
function maggies2lups,maggies,bvalues=bvalues

if(NOT keyword_set(bvalues)) then $
  bvalues=[1.4e-10, 0.9e-10, 1.2e-10, 1.8e-10, 7.4e-10]

nb=n_elements(maggies)
nmaggies=long(n_elements(maggies)/nb)
maggies=reform(maggies,nb,nmaggies)
lups=dblarr(nb,nmaggies)
for b=0L, nb-1L do begin
  lups[b,*]=2.5*alog10(1.0/bvalues[b])- $
      asinh2(0.5*maggies[b,*]/bvalues[b])/(0.4*alog(10.));
endfor
return,lups

end
