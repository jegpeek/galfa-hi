function ldsregion, x, y, ldsfile, lds = lds, radec = radec, epoch = epoch
;+
; NAME:
;   LDSREGION
; PURPOSE:
;   To return the expected spectrum of a region as per the 
;   Leiden-Dwingaloo survey.
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

; If radec is not set then set l and b
if (not keyword_set(radec)) then begin
    l = x
    b = y
endif

; Nearest neighbor in the lds to each point by index 
; (lind = L*2., bind = b*2 +180)
lind_nn = round(l*2.)
bind_nn = round((b+90)*2.)

if (not keyword_set(lds)) then restore, ldsfile

; if we're at 360 degrees, set it to 0 degrees
if max(lind_nn) eq 720. then lind_nn[where(lind_nn eq 720)] = 0

mask = fltarr(720, 361)

; an array that is unique for each element
ids = lind_nn + 0.0001*bind_nn

; independant elements
indl = lind_nn(uniq(ids, sort(ids)))
indb = bind_nn(uniq(ids, sort(ids)))

for i=0, n_elements(indl) -1 do mask[indl[i], indb[i]] = n_elements(where(ids eq indl[i] + indb[i]+0.0001))

;for i = 0, n_elements(lind_nn) - 1 do mask[lind_nn[i], bind_nn[i]] = mask[lind_nn[i], bind_nn[i]] + 1.

;stop

spectrum = total(total( rebin(reform(mask, 720, 361, 1), 720, 361, 151)*lds, 1, /nan),1, /nan)/total(mask)

return, spectrum

end



