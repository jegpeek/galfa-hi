function labregion, x, y, labfile, lab = lab, radec = radec, epoch = epoch
;+
; NAME:
;   LABREGION
; PURPOSE:
;   To return the expected spectrum of a region as per the 
;   LAB survey.
;
; CALLING SEQUENCE:
;   spectrum = LDSREGION(x, y [, lds = lds, radec = radec])
;
; INPUTS:
;   X -- l or RA
;   Y -- b or Dec
; KEYWORD PARAMETERS:
;   LDS -- If set, is the LDS in [720, 361, 151], where 151 is the 
;          +/- ~75 km/s range 
;   RADEC -- If set, X and Y are taken to be RA and Dec, otherwise
;            taken as L and B
;
; MODIFICATION HISTORY:
;
;       Mon Apr 25 2005, Joshua Goldston <goldston@astro>
;-


; If radec is set then convert ra and dec into l and b
if (keyword_set(radec)) then begin
    if radec eq 1. then begin
; If epoch is set, use that epoch, else use 2000
        if keyword_set(epoch) then glactc, x, y, epoch, l, b, 1 else  glactc, x, y, 2000, l, b, 1 
    endif
endif 
if (not keyword_set(lab)) then restore, labfile

; If radec is not set then set l and b
if (not keyword_set(radec)) then begin
    l = x
    b = y
endif

outsp = fltarr(151)
for i=0l, n_elements(l)-1 do outsp = outsp + interpolate(lab, replicate(interpol(findgen(720), findgen(720)/2, l[i]), 151), replicate(interpol(findgen(361), findgen(361)/2.-90., b[i]), 151), findgen(151))
spectrum = outsp/n_elements(l)

return, spectrum

end



