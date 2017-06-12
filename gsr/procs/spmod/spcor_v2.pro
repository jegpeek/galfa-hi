;+
; NAME:
;   SPCOR
; PURPOSE:
;   To correct the fixed patten noise in GALFA data.
;
; CALLING SEQUENCE:
;   spcor, root, region, scans, proj, noaggr=noaggr,
;   badrxfile=badrxfile, spiter=spiter, xingname=xingname
; INPUTS:
;   root -- The main direcotry in which the project directory
;             resides (e.g. '/dzd4/heiles/gsrdata/' )
;   region -- The name of the source as entererd into BW_fm (e.g. 'lwa')
;   scans -- Number of days the project consists of
;   proj -- The Arecibo project code (e.g. 'a2050')
; KEYWORD PARAMETERS:
;   noaggr -- Set this if you already have an aggregate spectrum
;             file (aggr.sav).
;   badrxfile -- If you have your own file for bad receivers, put its
;                 full path here.
;   xingname -- If this is not the first time through the loop, set this to the 
;               xingname from the XING run you want to use to iterate on.
;   tdf -- use the older two-digit formatting
;   odf -- use the older .sav data format
;   old_zg -- a keyword to use the old-style zero-gains procedure.
;      Otherwise, use the proposal of KD.
;   rficube -- an input of size [8192, 2, 7, scans] of 0s and 1s to reduce
;      the impact of RFI on the spectral fit
;   decrng -- set this to force a particular dec range to fit the baseline ripple
;             dec variation. useful if some scans have strange forays
;             beyond the region of interest whose variations we are unintereste in.
; OUTPUTS:
;   NONE
;
; MODIFICATION HISTORY
;
;  Initial documentation, January 16, 2006
;  Modified for S1H compatability, July 12, 2006, Goldston Peek
;  Fixed the zogains with old_zg, April 12th, Peek
;  Made version 2 to deal with dec variations and high HI amplitudes, Feb 13th, JEGP
;  Joshua E. Goldston, goldston@astro.berkeley.edu
;-

pro spcor, root, region, scans, proj, noaggr=noaggr, badrxfile=badrxfile, xingname=xingname, tdf=tdf, odf=odf, old_zg=old_zg, rficube=rficube, fn=fn, v1=v1, skiptest=skiptest, hack2=hack2, force1=force1, decrng=decrng
if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)'
;if keyword_set(spiter) then begin
;    restore, root + proj + '/' + region + '/spcor_' + string(spiter-1, format='(I2.2)') + '.sav'
;    if keyword_set(xingname) then begin
    ; CURRENTLY ONLY WORKS FOR degree=0, no fourier, no daygain, no beamgain xgas.
;        restore,  root + proj + '/' + region + '/xga_' + xingname + '.sav'
;        xgagn = transpose(reform(fitsvars.f[0:scans*7.-1],scans, 7))
;        ozg = zogains
;        zogains = ozg/(1.+xgagn)
;    endif 
;endif else begin
;xnus is xingname w/ an underscore.

if not keyword_set(xingname) then xnus = '' else xnus = '_' + xingname
; Unless you already have the aggregate spectra saved, read in the aggregate spectra
if (keyword_set(noaggr)) then restore, root + proj + '/' + region + '/aggr'+ xnus +'.sav' else aggr_spect, root, region, scans, proj, aggr, tdf=tdf, odf=odf, xingname=xingname
if not keyword_set(skiptest) then begin
; Find the start times of each day of observing
    times = gettimes(root, region, scans, proj, tdf=tdf)

; Find the zero-order gain ratios between the beams and days. 
; in the case where we don't need zero-order gain corrections, we set them to unity, but use
; the rxmultiplier output.
zogain, aggr, times, zogains, rxmultiplier, badrxfile=badrxfile, old_zg=old_zg

if keyword_set(xingarr) then zogains= zogains*0.+1.

endif else begin
restore, 'skiptest.sav'
endelse

;endelse
if keyword_set(v1) then begin    
; Find the fixed pattern noise with fourier transform methods.

if keyword_set(rficube) then find_fpn, aggr, zogains, rxmultiplier*rficube, fpn_sp, fn=fn else find_fpn, aggr, zogains, rxmultiplier, fpn_sp, fn=fn

;if (not (keyword_set(spiter))) then iter = 0. else iter = spiter

;Save this info to a file
if keyword_set(rficube) then save, aggr, zogains, fpn_sp, rxmultiplier, rficube, file= root + proj + '/' + region + '/spcor'+ xnus +'.sav' else  save, aggr, zogains, fpn_sp, rxmultiplier, file= root + proj + '/' + region + '/spcor'+ xnus +'.sav' 

endif else begin
; SPCORv2 is the new version of SPCOR, which attempts to compensate for variable baseline ripple as a 
; function of declination

if not keyword_set(hack2) then begin
hack2=0
decinfo = fltarr(scans, 3) ; min,max, nbins
ddec=1. ; ? the range we should split up into for dec? untested, but maybe a good guess
; find all the dec info

restore, root + proj + '/' + region + '/todarr.sav'
for i=0, scans-1 do begin
    whs = where(mht.day eq i, ct)
    ; find me all the dec range within the main bulk of the data
    if not (keyword_set(decrng)) then decinfo[i, 0] = (mht[whs[(sort(mht[whs].dec_halfsec[0]))]].dec_halfsec[0])[ct*0.001] else decinfo[i, 0] = decrng[0]
       if not (keyword_set(decrng)) then decinfo[i, 1] = (mht[whs[(sort(mht[whs].dec_halfsec[0]))]].dec_halfsec[0])[ct*0.999] else decinfo[i, 1] = decrng[1]
    decinfo[i,2] = ceil((decinfo[i,1] -decinfo[i,0])/ddec)
endfor

; set force1 for togs data - allows us to make sure that it isn't confused by weird forays in
; dec.
if keyword_set(force1) then begin
    for i=0, scans-1 do begin
    decinfo[i, 2] = decinfo[i, 2]*(1-force1[i]) + force1[i]
    endfor
endif

; build a big ol' structure
make_fpn_array, decinfo[*, 2], region, fpn

endif else restore, 'fpn.sav'

; fill it with fpn_sp data
; the maximum K*km/s allow in our data, from LAB
cutoff=150.
; minimum number of spectra allowed per decbin
nspcut = 200.
;read in LAB data
restore, getenv('GSRPATH') + 'savfiles/labAO.sav'
for i=hack2, scans-1 do begin
; giant HACK!!!
    whp = where(mht.day eq i, secs)
    ; get only data with amplitude below a certain threshold
    outcol = interpolate(column, mht[whp].ra_halfsec[0]*15.*2, (mht[whp].dec_halfsec[0]+1.5)*2 )
    decpos = ((((mht[whp].dec_halfsec[0]-decinfo[i,0])/(decinfo[i,1]-decinfo[i,0]))*decinfo[i,2]) > 0) < (decinfo[i,2] -1)
    wh=[0]
    for q=0, decinfo[i, 2]-1 do begin
        whdp = where(floor(decpos) eq q, ndpq)
        ocwh = outcol(whdp)
        whh = where((outcol lt cutoff) and (floor(decpos) eq q) , ct)
    ; if fewer than half of the points make the cut, just use the better half
        if ct lt nspcut then wh = [wh, whp[whdp((sort(ocwh))[0:(nspcut-1) < (ndpq-1)])]] else wh = [wh, whp[whh]]
    endfor
    wh = wh[1:*]
; the files where these data exist
    fns = mht[wh].fn
    ; unique file names of above
    ufn = fns(uniq(fns, sort(fns)))
    ; the aggregate spectra from these points, separated by dec
    ag1 = fltarr(8192, 2, 7, decinfo[i, 2])
    ; how many spectra have been added to each dec range
    nsp = fltarr(decinfo[i, 2])
    for j=0, n_elements(ufn)-1 do begin
        ; load in the files, both mh and fits
        restore, ufn[j]
        fits = readfits(strmid(ufn[j],0, strlen(ufn[j])-3)+'fits')    
        ; where these data are located in the mht file
        whinfile = wh[where(ufn[j] eq mht[wh].fn)]
        ; all the relevant UTCSTAMPS
        utcs = mht[whinfile].utcstamp
        ; and what dec # they are at
        whdec = ((((mht[whinfile].dec_halfsec[0]-decinfo[i,0])/(decinfo[i,1]-decinfo[i,0]))*decinfo[i,2]) > 0) < (decinfo[i,2] -1)
        for k=0, n_elements(utcs)-1 do begin
            whpos = where(utcs[k] eq mh.utcstamp)
            ; find which dec bin it should go in
            ag1[*,*,*,whdec[k]] = ag1[*,*,*,whdec[k]] + fits[*, *, *, whpos]
            nsp[whdec[k]] = nsp[whdec[k]]+1.
        endfor
    endfor
    ; get to a reasonable level
    ag1 = ag1/rebin(reform(nsp, 1,1, 1, decinfo[i,2]), 8192, 2, 7, decinfo[i,2])
    if decinfo[i,2] eq 1 then ag1 = reform(ag1, 8192, 2, 7, 1)
    find_fpn, ag1, rebin(reform(zogains[*, i], 7, 1), 7, decinfo[i,2]), rebin(reform(rxmultiplier[*,*, *, i], 8192, 2, 7, 1), 8192, 2, 7, decinfo[i,2]), fpn_sp, fn=fn
    ; the bin centers, not edges
    fpn.(i).decs = (findgen(decinfo[i, 2])+0.5)/decinfo[i,2]*(decinfo[i,1]-decinfo[i,0])+decinfo[i,0]
    fpn.(i).rxg = rxmultiplier[0, *, *, i]
    fpn.(i).zgn = zogains[*, i]
    fpn.(i).fpn = fpn_sp
endfor
; this is so we can tell other programs to use the advanced version...
zogains = -99
save, aggr, zogains, fpn, rxmultiplier, file= root + proj + '/' + region + '/spcor'+ xnus +'.sav' 

endelse

end



