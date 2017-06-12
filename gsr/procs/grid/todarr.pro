pro todarr, root, region, scans, proj, tdf=tdf
;+
; Name:
;   TODARR
; PURPOSE:
;   Generate a file that contains all Time Ordered Data (TOD) 
;   positions and all filenames associate to said positions.  
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
for i=0, scans-1 do begin
    loop_bar, i, scans
    restore, root + proj + '/' + region + '/' + region + '_' + string(i, format=scnfmt) +'/' + '*.hdrs*'
    if (i eq 0) then begin
        sz = size(mh.ra_halfsec)
        mht = replicate( {ra_halfsec:fltarr(7), dec_halfsec:fltarr(7), fn:'null', day:0., utcstamp:0l}, sz[2])
        mht.ra_halfsec = mh.ra_halfsec
        mht.dec_halfsec = mh.dec_halfsec
        mht.utcstamp = mh.utcstamp
        mht.fn = fn
        mht.day = i
    endif else begin
        sz = size(mh.ra_halfsec)
        mht1 = replicate( {ra_halfsec:fltarr(7), dec_halfsec:fltarr(7), fn:'null', day:0., utcstamp:0l}, sz[2])
        mht1.ra_halfsec = mh.ra_halfsec
        mht1.dec_halfsec = mh.dec_halfsec
        mht1.fn = fn
        mht1.utcstamp = mh.utcstamp
        mht1.day = i
        mht = [temporary(mht), mht1]
    endelse
endfor

save, mht, filename= root + proj + '/' + region + '/todarr.sav'

end
