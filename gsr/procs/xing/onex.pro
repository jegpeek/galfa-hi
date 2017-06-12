pro onex, root, region, scans, proj, xingname, badrxfile=badrxfile, tdf=tdf, odf=odf,  no_spcor=no_spcor
;+
; Name:
;   ONEX 
; PURPOSE:
;   A code to get xing data for just one day's observations, and for a single number for each beam.
;
; CALLING SEQUENCE:
;    onex, root, region, scans, proj, 
;    badrxfile=badrxfile, tdf=tdf, odf=odf, 
;    xingname=xingname,  no_spcor=no_spcor
;
; INPUTS:
;   root -- The main directory in which the project directory
;             resides (e.g. '/dzd4/heiles/gsrdata/' )
;   region -- The name of the source as entered into BW_fm (e.g. 'lwa')
;   scans -- Number of days the project consists of
;   proj -- The Arecibo project code (e.g. 'a2050')
;   xingname -- the name of the OUTPUT. This code does not support multiple
;               xing iterations (yet).
; KEYWORDS PARAMETERS
;   tdf -- use the older two-digit formatting
;   odf -- set if using .sav as main data structure (pre- gsr 2.2)
;   badrxfile -- Any file of badrx's
;   no_spcor -- if set, don't use any spcor
;
; OUTPUTS:
;
; MODIFICATION HISTORY:
;   Initial Documentation, Dec 11, 2007
;   Joshua E. G. Peek, goldston@astro.berkeley.edu
;-

if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)' 
path = root + proj + '/' + region + '/'
restore, path + 'todarr.sav'
; if we have spcor, load it
if not keyword_set(no_spcor) then begin
    restore, root + proj + '/' + region + '/spcor.sav'
    spdat= { zogains:zogains, fpn_sp:fpn_sp}
endif
restore, path + 'aggr.sav'
; if we have spcor, apply it
if not keyword_set(no_spcor) then begin
for i=0, 6 do begin
    dt = reform(aggr[*, *, i])
    spfix1, dt, 0, i, spdat.zogains, spdat.fpn_sp
    aggr[*, *, i] = dt
endfor
endif
; if we have badrx's, apply them
if keyword_set(badrxfile) then begin
    whichrx, mht[0].utcstamp, rxgood, badrxfile=badrxfile
endif else begin
    rxgood = fltarr(2, 7)+1
endelse

; total over beams!
totspect = total(aggr*rebin(reform(rxgood, 1, 2, 7), 8192, 2, 7), 2)/rebin(reform(total(rxgood, 1), 1, 7), 8192, 7)
av = total(totspect, 2)/7.

; the correction factor
corf1 = fltarr(7)
for i=0, 6 do begin
        corf1[i] = arb_spect_rat(findgen(8192), totspect[*, i], findgen(8192), av)
endfor
sz = size(mht)
corf = rebin(corf1, 7, sz[1])
degree = 0
daygain = 0
beamgain=0
appl_xing='none'
save, corf, degree, daygain, beamgain, xingname, appl_xing, f=path + 'xingarr_' + xingname +'.sav'

end
