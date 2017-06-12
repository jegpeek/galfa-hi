;+
; NAME:
;   SPFIX1
; PURPOSE:
;    Given gain corrections, aggregate data and a soultion for fixed pattern noise, 
;    corrects a set of data. Same as SPFIX, but for a single data point.
;
; CALLING SEQUENCE:
;   spfix, data, day, zogains, fpn_sp   
; INPUTS:
;   data -- the data to be corrected, in [8192, 2] format
;   day -- the day number of the data in question (0, 1, ... , scans -1)   
;   zogains -- the gains to use or -99 if using v2
;   fpn_sp  -- the fixed pattern noise to remove, or FPN structure if v2
;   dec -- set to associated decs if v2, else do not set
; KEYWORD PARAMETERS:
;  NONE
;
; OUTPUTS:
;   NONE
;
; MODIFICATION HISTORY
;
;  Initial documentation, August 6, 2006
;  Added SPCORv2 code, along with mh input - Feb 17th, 2009
;  Joshua E. Goldston, goldston@astro.berkeley.edu
;-


pro spfix1, data, day, beam, zogains, fpn_sp, dec, vlsr


if n_elements(zogains) ne 1 then begin 
zgns = zogains[beam, day]
fp = rebin(reform( fpn_sp[*,beam,day], 8192, 1), 8192, 2)

; note that the data returned here do not make sense unless integrated over polarization.
data = (data)*zgns - fp
endif else begin

sz = size(data)
;zpd = rebin(zapped[*, *, *, day], 8192, 2, 7, sz[4])
zgns = fpn_sp.(day).zgn[beam]
dl = n_elements(fpn_sp.(day).decs)
if n_elements(dl) gt 1 then begin
    decpos = interpol(findgen(dl), fpn_sp.(day).decs, dec)
    fp = rebin(interpolate(fpn_sp.(day).fpn, findgen(8192), fltarr(8192) + beam, fltarr(8192) + decpos), 8192, 2)
endif else begin
    fp = rebin(fpn_sp.(day).fpn[*, beam], 8192, 2)
endelse
if n_elements(vlsr eq 0) then vlsr = 0.
fp = shift(fp, [vlsr/0.184, 0])
data = temporary((data)*zgns - fp)
endelse

end
