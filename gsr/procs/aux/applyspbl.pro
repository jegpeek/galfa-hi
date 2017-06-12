pro applyspbl, data, utcs, spblfile, noblank=noblank, blankout=blankout
;+
; NAME:
;  APPLYSPBL
; PURPOSE:
;  A code to apply spectral blanking to a data file
;
; CALLING SEQUENCE:
;   applyspbl, data, mh.utcstamp, spblfile
;
; INPUTS:
;  DATA -- a [8192, 2, 7, N] data file
;  UTC -- The UTC times associated (N long) 
;  SPBLFILE -- the filename (full path) to the spbl file, no .sav or .fits
;
; KEYWORD PARAMETERS:
;  NOBLANK -- If set, do not fill blanked areas with NaNs
;  BLANKOUT -- If set, return an array matching data in size, but with 0s where 
;              data is good and 1 where data is blanked
; OUTPUTS:
;  NONE (updated data with spectra corrected
;-

restore, spblfile + '.sav'

; do any of the utcs correspond to the spblanked utcs?
wh = where((min(utcs) lt allutc) and (max(utcs) gt allutc), ct)
; make a list of positions that are blanked
if keyword_set(blankout) then blankout = data*0.
; if so, go look through them
;print, ct
if ct ne 0 then begin
	for i=0, ct-1 do begin
		; read in the fit that could match the input data
		bli = mrdfits(spblfile + '.fits', 1, hdr, row=wh[i], /sil)
		; does it match the input data?
		wheq = where(bli.utc eq utcs, cteq)
		; if so, remove the remspec from the appropriate beam and pol
		if cteq ne 0 then begin
		    ;print, 'SPBL: cteq=' + string(cteq)
		    ;only apply the effect if either noblank is unset and/or the method is not blanking 
			if (allmethod[wh[i]] ne 0) or (not keyword_set(noblank)) then data[*, bli.pol, bli.beam, wheq] =  dilshod(bli.fitp[0], bli.fitp, data[*, bli.pol, bli.beam, wheq], 2) 
			if keyword_set(blankout) then begin
				if bli.fitp[0] eq 0 then blankout[bli.fitp[1]:bli.fitp[2], bli.pol, bli.beam, wheq] = 1.
			endif
		endif
	endfor
endif
end