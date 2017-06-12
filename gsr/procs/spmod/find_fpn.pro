;+
; NAME:
;   FIND_FPN
; PURPOSE:
;   To determine the fixed pattern noise as a function of beam and day 
;
; CALLING SEQUENCE:
;  find_fpn, aggr, zogains, rxmultiplier, fpn_sp
; INPUTS:
;   aggr -- the aggregate spectrum, as in aggr.sav
;   zogains -- the gains for each day
;   rxmultiplier -- An array to correct for bad rxs
; KEYWORD PARAMETERS:
;  fn -- a given filename for the spcor xinv file
;  no6 -- use a spcor xinv file designed not to use the beam 6 data
;  nfourier -- the number of fourier components to use, default is 16
; OUTPUTS:
;  fpn_sp -- The fitted fixed pattern noise
;
; MODIFICATION HISTORY:
;  Initial documentation, January 16, 2006
;  Joshua E. Goldston, goldston@astro.berkeley.edu
;  Added and commented functionality for other spcor files JEGP June 2 2014
;-

pro find_fpn, aggr, zogains, rxmultiplier, fpn_sp, fn=fn, no6=no6, nfourier=nfourier

sz = size(aggr)
if sz[0] eq 3 then sz[4] = 1
fpn_sp= fltarr(8192, 7, sz[4])

;get xarr, xinv, fpn, hnum, versiondate
if keyword_set(fn) then restore, fn else begin

	if keyword_set(no6) and not keyword_set(nfourier) then restore, getenv('GSRPATH') + 'savfiles/sixteen_xinv_no6.sav'

	if not keyword_set(no6) and keyword_set(nfourier) then begin
		if nfourier eq 16 then restore, getenv('GSRPATH') + 'savfiles/spcor_xinv.sav'
		if nfourier eq 12 then restore, getenv('GSRPATH') + 'savfiles/twelve_xinv.sav'
		if nfourier eq 8 then restore, getenv('GSRPATH') + 'savfiles/eight_xinv.sav'
	endif

	if keyword_set(no6) and keyword_set(nfourier) then begin
		if nfourier eq 16 then restore, getenv('GSRPATH') + 'savfiles/sixteen_xinv_no6.sav'
		if nfourier eq 12 then restore, getenv('GSRPATH') + 'savfiles/twelve_xinv_no6.sav'
		if nfourier eq 8 then restore, getenv('GSRPATH') + 'savfiles/eight_xinv_no6.sav'
	endif

	if not keyword_set(no6) and not keyword_set(nfourier) then restore, getenv('GSRPATH') + 'savfiles/spcor_xinv.sav'

endelse

; mask for zeroes
mask = fltarr(8192, 7, sz[4]) + 1.
whmask = where(total(aggr, 2) eq 0., whma)
if whma ne 0 then mask[whmask] = 0.

; gain multiplier
zogm = reform(rebin(reform(zogains, 1, 1, 7, sz[4]), 8192, 2, 7, sz[4]))

; The average spectrum for each day
avg = total(total(aggr*rxmultiplier*zogm, 2), 2)/total(total(rxmultiplier, 2), 2)

; difference between a beam and the average spectrum for that day
subtr = total(aggr*rxmultiplier*zogm, 2)/2. - reform(rebin(reform(avg, 8192, 1, sz[4]), 8192, 7, sz[4]))
for k=0, sz[4]-1 do begin
    Yarr = reform(subtr[*,*,k], 7.*8192.)
    a = Yarr#xinv
    afpn = a
    afpn[0:hnum*2-1]=0.
    fpn_sp[*,*,k] = reform(xarr##afpn, 8192, 7)*mask[*,*,k]
    !p.multi=[0,1,7]
endfor


end


