;+
; NAME:
;  AGGR_SPECT
; PURPOSE:
;  To aggregate all the spectra in a given region into a frequncy, pol, beam, day 
;  array, after the stage zero reduction [8192, 2, 7, scans]
;
; CALLING SEQUENCE:
;  aggr_spect, root, region, scans, proj, aggr, tdf=tdf, odf=odf, xingname=xingname
;
; INPUTS:
;   root -- The main directory in which the project directory
;             resides (e.g. '/dzd4/heiles/gsrdata/' )
;   region -- The name of the source as entered into BW_fm (e.g. 'lwa')
;   scans -- Number of days the project consists of
;   proj -- The Arecibo project code (e.g. 'a2050')
;
; KEYWORDS:
;   tdf -- use the older two-digit formatting
;   odf -- use the older .sav data format
;   xingname -- use the corf from previous xing run.
;   bcut -- set if you want to use no data below a certain b value.
; OUTPUTS:
;   aggr -- The aggregated array
;
; MODIFICATION HISTORY:
;  Initial Documentation Friday, December 2, 2005
;  Modified for S1H compatability, July 12, 2006, Goldston Peek
;  Modified to add ability to use previous xingarr, killed stops and split (?) October 18th, 2006, JEGP
;  Modified to make readfits silent, Jan 17, 2013, JEGP
;  Joshua E. Goldston, goldston@astro.berkeley.edu 
;-

pro aggr_spect, root, region, scans, proj, aggr,  tdf=tdf, odf=odf, xingname=xingname, bcut=bcut
if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)' 

path = root + proj + '/' + region + '/'

if keyword_set(xingname) then begin
    restore, path + 'xingarr_' + xingname +'.sav'
    restore, path + 'todarr.sav'
endif

aggr = fltarr(8192, 2, 7, scans)
q=0.

for i=q, scans -1 do begin
    restore, root + '/' + proj + '/' + region + '/' + region +  '_' +  string(i, format=scnfmt)+ '/' + '*hdrs*'
    fns = fn(uniq(fn, sort(fn)))
    n=0.
    specttemp = fltarr(2,7, 8192)
    for j = 0, n_elements(fns) -1 do begin
        loop_bar, j, n_elements(fns)
        restore, fns[j]
        fname = STRMID(fns[j],0, strlen(fn[j])-4)+'.fits'
        if not(keyword_set(odf)) then outdata = readfits(fname, hdr, /sil)
        mm = where(finite(outdata,/nan), ct)
        
        if (ct ne 0) then outdata(mm)=0.0

        sz = size(outdata)
        if keyword_set(xingname) then whf = where(mht.fn eq fns[j])
        if keyword_set(xingname) then outdata = temporary(outdata)/rebin(reform(corf[*, whf], 1, 1, 7, sz[4]), 8192, 2, 7, sz[4])
        whcal = where(mh.obsmode ne 'CAL     ', ct)
        if keyword_set(bcut) then begin
           glactc, mh.ra_halfsec[0], mh.dec_halfsec[0], 2000, l, b, 1
           whcal = where((mh.obsmode ne 'CAL     ') and (abs(b) gt bcut), ct)
        endif
        if ct ne 0 then begin
            temp = total(outdata[*,*,*,whcal], 4)
            ; does the following line do anything??
            ;outdataref = reform(outdata, sz[1], sz[2], sz[3]*sz[4])
            if (keyword_set(stops) and n_elements(where(finite(temp) eq 0.)) ne 1) then stop
            n = n+n_elements(whcal)
            specttemp = temp + specttemp
        endif
    endfor

	if n eq 0 then begin
		print, "scan fails to meet bcut criterion -- failing safe and using last scan"
		whcal = where(mh.obsmode ne 'CAL     '); and (abs(b) gt bcut), ct)	
	    temp = total(outdata[*,*,*,whcal], 4)
		n = n+n_elements(whcal)
        specttemp = temp + specttemp
	endif

    specttemp = specttemp/n
    aggr[*, *, *,i] = specttemp
endfor
if not keyword_set(xingname) then xnus = '' else xnus = '_' + xingname
save, aggr, filename= root +'/'+ proj + '/' + region + '/aggr'+ xnus +'.sav'

end
