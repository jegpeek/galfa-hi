pro todarrll, root, region, scans, proj, tdf=tdf
;+
; Name:
;   TODARRLL
; PURPOSE:
;   Generate a file that contains all Time Ordered Data (TOD) 
;   positions and all filenames associate to said positions.  
;   now using linked lists   
;
; CALLING SEQUENCE:
;   todarr, root, region, scans, proj
;
; INPUTS:
;   root -- The main directory in which the project directory
;             resides (e.g. '/dzd4/heiles/gsrdata/' )
;   region -- The name of the source as entered into BW_fm (e.g. 'lwa')
;   scans -- Number of days the project consists of
;   proj -- The Arecibo project code (e.g. 'a2050')
; 
; KEYWORDS PARAMETERS
;   tdf -- use the older two-digit formatting
; OUTPUTS:
;   NONE (files loaded with spectra)
;
; MODIFICATION HISTORY:
;   Initial Documentation Friday, August 9, 2005
;   Joshua E. Goldston, goldston@astro.berkeley.edu
;-

if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)' 
blvar = {ra_halfsec:fltarr(7), dec_halfsec:fltarr(7), fn:'null', day:0., utcstamp:0l}
pvar = llist_init(fcnl, blvar, q)
for i=0l, scans-1 do begin
    loop_bar, i, scans
    restore, root + proj + '/' + region + '/' + region + '_' + string(i, format=scnfmt) +'/' + '*.hdrs*'
    sz = size(mh.ra_halfsec)
    for k=0l, sz[2]-1 do begin
        llist_loop, fcnl, pvar, {ra_halfsec:float(mh[k].ra_halfsec), dec_halfsec:float(mh[k].dec_halfsec), fn:fn[k], day:float(i), utcstamp:mh[k].utcstamp}, q
    endfor
endfor
llist_read, fcnl, blvar, mht, q

save, mht, filename= root + proj + '/' + region + '/todarr.sav'

end
