;+
; NAME:
;   SPFIX
; PURPOSE:
;    Given gain corrections, aggregate data and a soultion for fixed pattern noise, 
;    corrects a set of data
;
; CALLING SEQUENCE:
;   spfix, data, day, zogains, fpn_sp   
; INPUTS:
;   data -- the data to be corrected, in [8192, 2, 7, N] format
;   day -- the day number of the data in question (0, 1, ... , scans -1)   
;   zogains -- the gains to use or -99 if using v2
;   fpn_sp  -- the fixed pattern noise to remove, or FPN structure if v2
;   dec  -- set to the associated decs if v2, else do not set
; KEYWORD PARAMETERS:
;  NONE
;
; OUTPUTS:
;   NONE
;
; MODIFICATION HISTORY
;
;  Initial documentation, January 16, 2006
;  Added SPCORV2 code, along with mh input - Feb 17th, 2009
;
;  Joshua E. Goldston, goldston@astro.berkeley.edu
;-


pro spfix, data, day, zogains, fpn_sp, dec, vlsr

if n_elements(zogains) ne 1 then begin
sz = size(data)
;zpd = rebin(zapped[*, *, *, day], 8192, 2, 7, sz[4])
zgns = rebin(float(reform(zogains[*, day], 1, 1, 7, 1)),  8192, 2, 7, sz[4])
fp =  rebin(reform(fpn_sp[*,*,day], 8192, 1, 7, 1), 8192, 2, 7, sz[4])

; note that the data returned here do not make sense unless integrated over polarization.
data = temporary((data)*zgns - fp)

endif else begin

sz = size(data)
;zpd = rebin(zapped[*, *, *, day], 8192, 2, 7, sz[4])
zgns = rebin(float(reform(fpn_sp.(day).zgn, 1, 1, 7, 1)),  8192, 2, 7, sz[4])
dl = n_elements(fpn_sp.(day).decs)
if dl gt 1 then begin
    decpos = interpol(findgen(dl), fpn_sp.(day).decs, dec) 
    fp = interpolate(fpn_sp.(day).fpn, rebin(reform(findgen(8192), 8192, 1, 1), 8192, 7, sz[4]), rebin(reform(findgen(7), 1, 7, 1), 8192, 7, sz[4]), rebin(reform(decpos, 1, 1, sz[4]), 8192, 7, sz[4]))
endif else begin 
    decpos = fltarr(n_elements(dec))
      fp = rebin(reform(fpn_sp.(day).fpn, 8192, 7, 1), 8192, 7, sz[4])
  endelse
if n_elements(vlsr) eq 0 then vlsr = fltarr(sz[4])
for i=0, sz[4]-1 do fp[*, *,i] = shift(fp[*, *, i], [vlsr[i]/0.184, 0])
    if tag_exist(fpn_sp.(day), 'av') then data = temporary((data)*zgns - rebin(reform(fp, 8192, 1, 7, sz[4]), 8192, 2, 7, sz[4])- rebin(reform(fpn_sp.(day).av, 8192, 1, 1, 1), 8192, 2, 7, sz[4])) else data = temporary((data)*zgns - rebin(reform(fp, 8192, 1, 7, sz[4]), 8192, 2, 7, sz[4]))

endelse




end
