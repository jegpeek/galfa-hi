;+
; NAME:
;   SPCOR
; PURPOSE:
;   To correct the fixed patten noise in GALFA data.
;
; CALLING SEQUENCE:
;   spcor, root, region, scans, proj, noaggr=noaggr, badrxfile=badrxfile, 
;   xingname=xingname, tdf=tdf, odf=odf, old_zg=old_zg, rficube=rficube, 
;   fn=fn, v1=v1, skiptest=skiptest, force1=force1, decrng=decrng
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
;                 full path here. ##### needed for v2?
;   BLANKFILE - put the full path to a file here that has utc times and beams
;   SPBLFILE  - 
;   xingname -- If this is not the first time through the loop, set this to the 
;               xingname from the XING run you want to use to iterate on.
;   tdf -- use the older two-digit formatting
;   odf -- use the older .sav data format
;   old_zg -- a keyword to use the old-style zero-gains procedure.
;      Otherwise, use the proposal of KD.
;   rficube -- an input of size [8192, 2, 7, scans] of 0s and 1s to reduce
;              the impact of RFI on the spectral fit. Currenly only functions in v1 
;   fn -- ?
;   v1 -- Use the old version of the procedure that does not account for dec variation
;         the LAB map, or the LSR smearing of the ripple
;   skiptest -- ?
;   force1 -- an array of 0s and 1s, used to force a single declination bin for some scans
;             the array should be scans elements long, with 1s set for scans that want
;             a single declination range.
;   forcecopy -- if a scan has too little data in it to make a useful spcor determination, use this
;             keyword to copy from another scan. The keyword should set to a [2,N] array, where you 
;             want to overwrite spcor data forcecopy[0,n] with spcor data forcecopy[1, n] for all N
;             entries. forcecopy only works if v1 is not set
;   decrng -- set this to force a particular dec range to fit the baseline ripple
;             dec variation. useful if some scans have strange forays
;             beyond the region of interest whose variations we are unintereste in.
;            either a 2 element array or a [2, scans] array
;   interav -- interactive fitting of the average spectrum for a across all beams. Currently only designed for use in the v2 version.
;   no6 -- don't solve using beam 6 data. This is for when you have both beam 6
;          pols bad.
;   nfourier -- normally 16. Can be set to 12 or 8.
;   eng -- an engineering mode with a stop after finding the average
; OUTPUTS:
;   NONE
;
; MODIFICATION HISTORY
;
;  Initial documentation, January 16, 2006
;  Modified for S1H compatability, July 12, 2006, Goldston Peek
;  Fixed the zogains with old_zg, April 12th, Peek
;  Made version 2 to deal with dec variations and high HI amplitudes, Feb 13th, JEGP
;  Added forcecopy, and ways to deal with shorter scans, March 14th, 2011, JEGP
;  Added blankfile keyword, April 29, 2014, JEGP
;  Added spblfile keyword, May 6, 2014, JEGP
;  Added and commented functionality for other spcor files JEGP June 2 2014
;  Added Engineering mode JEGP June25 2014
;  Joshua E. Goldston, goldston@astro.berkeley.edu
;-

pro spcor, root, region, scans, proj, noaggr=noaggr, badrxfile=badrxfile, blankfile=blankfile, spblfile=spblfile, xingname=xingname, tdf=tdf, odf=odf, old_zg=old_zg, rficube=rficube, fn=fn, v1=v1, force1=force1, forcecopy=forcecopy, decrng=decrng, bcut=bcut, ddec=ddec, interav=interav, no6=no6, nfourier=nfourier, eng=eng

if keyword_set(interav) then print, 'WAIT! There is an interactive part coming up in a minute or two, so if you would kindly stick around, I could use your help in fitting the overall fixed pattern noise. I will get right back to you...'
if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)'
if keyword_set(forcecopy) then begin
	szfc = size(forcecopy)
	if n_elements(forcecopy) eq 2 and szfc[0] eq 1 then forcecopy = reform(forcecopy, 2, 1)
endif

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
if (keyword_set(noaggr)) then restore, root + proj + '/' + region + '/aggr'+ xnus +'.sav' else aggr_spect, root, region, scans, proj, aggr, tdf=tdf, odf=odf, xingname=xingname, bcut=bcut
;if not keyword_set(skiptest) then begin
; Find the start times of each day of observing
times = gettimes(root, region, scans, proj, tdf=tdf)

; Find the zero-order gain ratios between the beams and days. 
; in the case where we don't need zero-order gain corrections, we set them to unity, but use
; the rxmultiplier output.
zogain, aggr, times, zogains, rxmultiplier, badrxfile=badrxfile, old_zg=old_zg

if keyword_set(xingarr) then zogains= zogains*0.+1.

;endif else begin
;restore, 'skiptest.sav'
;endelse

;endelse

; v1 mode: use the original, simpler version of spcor.
if keyword_set(v1) then begin    
	; Find the fixed pattern noise with fourier transform methods.

	if keyword_set(rficube) then find_fpn, aggr, zogains, rxmultiplier*rficube, fpn_sp, fn=fn, no6=no6, nfourier=nfourier else find_fpn, aggr, zogains, rxmultiplier, fpn_sp, fn=fn, no6=no6, nfourier=nfourier

	;if (not (keyword_set(spiter))) then iter = 0. else iter = spiter

	;Save this info to a file
	if keyword_set(rficube) then save, aggr, zogains, fpn_sp, rxmultiplier, rficube, file= root + proj + '/' + region + '/spcor'+ xnus +'.sav' else  save, aggr, zogains, fpn_sp, rxmultiplier, file= root + proj + '/' + region + '/spcor'+ xnus +'.sav' 

endif else begin

; SPCORv2 is the new version of SPCOR, which attempts to compensate for variable baseline ripple as a 
; function of declination, LSR correction and HI amplitude

if keyword_set(interav) then begin
	; the average spectrum, after zogains and rxm, across all beams, for a scan
	avscan = total(rebin(reform(zogains, 1, 7, scans), 8192, 7, scans)*total(aggr*rxmultiplier, 2)/2., 2)/7.
	avfit = avscan*0
	; this is just an overall value and six sines and six cosines, copied over from the standard xarr data.
	restore, getenv('GSRPATH') + 'savfiles/one_xarr_six.sav'
	for i=0, scans-1 do begin
		print, 'SCAN (' + string(i, f=scnfmt) + '/' + string(scans, f=scnfmt) + ') : Left click to select HI line bounds, middle click when you are done'
		wgt0 = avscan[*, i] ne 0
		blinter, avscan[*, i], wgt0, x01, string(i, f=scnfmt), LRval, pfit
		avfit[*, i] = pfit		
	endfor
endif


;if not keyword_set(hack2) then begin
;hack2=0
decinfo = fltarr(scans, 3) ; min,max, nbins
if not keyword_set(ddec) then ddec=2. ; ? the range we should split up into for dec in degrees. It is untested, but maybe a good guess
; find all the dec info
if keyword_set(decrng) then begin
    if n_elements(decrng) eq 2 then decrng = rebin(reform(decrng, 2, 1), 2, scans)
endif
restore, root + proj + '/' + region + '/todarr.sav'
if keyword_set(blankfile) then moveblanks, blankfile, mht 

for i=0, scans-1 do begin
    whs = where(mht.day eq i and mht.dec_halfsec[0] lt 50, ct)
                                ; find me all the dec range within the main bulk of the data
; NOTE - This proscriptions seems to fail sometimes - see merged/sct 145.
    if not (keyword_set(decrng)) then decinfo[i, 0] = (mht[whs[(sort(mht[whs].dec_halfsec[0]))]].dec_halfsec[0])[ct*0.001] else decinfo[i, 0] = decrng[0, i]
    if not (keyword_set(decrng)) then decinfo[i, 1] = (mht[whs[(sort(mht[whs].dec_halfsec[0]))]].dec_halfsec[0])[ct*0.999] else decinfo[i, 1] = decrng[1, i]
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


if keyword_set(interav) then begin
	for i=0, scans-1 do begin
		fpn.(i).av = avfit[*, i]
	endfor
endif
;endif else restore, 'fpn.sav'

; ENGINEERING MODE
if keyword_set(eng) then stop

; fill it with fpn_sp data
; the maximum K*km/s allow in our data, from LAB
cutoff=150.
; minimum number of spectra allowed per decbin
nspcut = 200.
;read in LAB data
restore, getenv('GSRPATH') + 'savfiles/labAO.sav'
for i=0, scans-1 do begin
; giant HACK!!!
    whp = where(mht.day eq i, secs)
    ; get only data with amplitude below a certain threshold
    outcol = interpolate(column, mht[whp].ra_halfsec[0]*15.*2, (mht[whp].dec_halfsec[0]+1.5)*2 )
    decpos = ((((mht[whp].dec_halfsec[0]-decinfo[i,0])/(decinfo[i,1]-decinfo[i,0]))*decinfo[i,2]) > 0) < (decinfo[i,2] -1)
    wh=[0]
    rn = [0]
    mxregs = 0
    for q=0, decinfo[i, 2]-1 do begin
        whdp = where(floor(decpos) eq q, ndpq)
        ocwh = outcol(whdp)
          ; now we need to find nreg contiguous regions with at least a total of nspcut
          ; seconds
        dt = mht[whp[whdp]].utcstamp-shift(mht[whp[whdp]].utcstamp, 1)
        ; maxima in dt (gt 1) are the first elements in groups.
        whst = where((dt gt 5) or (dt lt (-5)), ng) ; using 5 here to avoid issues with 
        ; time glitches
        ; the lt is for the first elements, which should be -lots
        if ng gt 1 then lengths  = [whst[1:*], n_elements(whdp)]- whst else lengths = n_elements(whdp)
        bigs = where(lengths gt 20) ; otherwise the fits will just be crazy
        ; now we need to select which of these we will include in our fit
        ; we will do this by finding the average column in the first 200 seconds
        ; of each region
        ocav = fltarr(n_elements(bigs))
        for rg=0, n_elements(bigs)-1 do begin
            whreg = whst[bigs[rg]] + findgen(lengths[bigs[rg]])
            ; the average of the lowest nspcut values 
            ocav[rg] = mean(  ocwh[whreg[[(sort(ocwh[whreg]))[0:(nspcut-1) < (n_elements(whreg)-1)]]]])
        endfor
        ; now we sort the regions by outcol and select as many as we 
        ; need to reach the number of seconds we require
        srt = sort(ocav)
        ttl = total((lengths[bigs])[srt], /cum)
        regnum = (where(ttl ge nspcut))[0]+1
        mxregs = max([mxregs, regnum])
        for rgg=0, regnum-1 do begin
        ; ugliest line of code ever written? perhaps.
            if rgg ne regnum-1 then begin
                wh = [wh, whp[whdp[whst[bigs[srt[rgg]]]+findgen(lengths[bigs[srt[rgg]]])]]]
                rn = [rn, fltarr(lengths[bigs[srt[rgg]]])+rgg]
            endif else begin
            ; number of remaining integrations needed:
                if rgg eq 0 then nrem = nspcut else nrem = nspcut - ttl[rgg-1]
            ; where is the dimmest integration?
                mn = min(ocwh[whst[bigs[srt[rgg]]]+findgen(lengths[bigs[srt[rgg]]])], mnpos)
                closest = sort((sort(abs(findgen(lengths[bigs[srt[rgg]]])-mnpos)))[0:nrem-1])
                wh = [wh, whp[whdp[whst[bigs[srt[rgg]]]+closest]]]
                rn = [rn, fltarr(nrem)+rgg]
            endelse
        endfor
 
   endfor
   	if n_elements(wh) eq 1 then begin
   		if (keyword_set(forcecopy) eq 0) then print, 'No SPCOR generated for scan' + string(i) +': please use forcecopy'
   		if (keyword_set(forcecopy) eq 1) then begin
   			fcs = where(forcecopy[0, *] eq i, ct)
   			if ct eq 0 then print, 'No SPCOR generated for scan ' + string(i) +': please set forcecopy for ' + string(i)
			if ct ne 0 then print, 'No SPCOR generated for scan ' + string(i) +': using spcor from scan '+ string( forcecopy[1, fcs[0]])
		endif
   		continue
 	endif	
 	wh = wh[1:*]
    rn = rn[1:*]
; the files where these data exist
    fns = mht[wh].fn
    ; unique file names of above
    ufn = fns(uniq(fns, sort(fns)))
    ; the aggregate spectra from these points, separated by dec
    ag1 = reform(fltarr(8192, 2, 7, decinfo[i, 2], mxregs), 8192, 2, 7, decinfo[i, 2], mxregs)
                                ; aggregate offset
    offset = reform(fltarr(decinfo[i, 2], mxregs), decinfo[i, 2], mxregs)
	; how many non-blanked spectra are there in each dec range?
    nsp = reform(fltarr(8192, 2, 7, decinfo[i, 2], mxregs), 8192, 2, 7, decinfo[i, 2], mxregs)
    ; how many spectra have been added to each dec range
    nspnorm = fltarr(decinfo[i, 2], mxregs)
    for j=0, n_elements(ufn)-1 do begin
        ; load in the files, both mh and fits
        restore, ufn[j]
        fits = readfits(strmid(ufn[j],0, strlen(ufn[j])-3)+'fits')
		szfits = size(fits)
        if keyword_set(spblfile) then spblanker, fits, mh, spblfile, spblank134 else spblank134 = fltarr(szfits[1], szfits[3], szfits[4]) 
        spblank = rebin(reform(spblank134, szfits[1], 1, szfits[3], szfits[4]), szfits[1], 2, szfits[3], szfits[4])
        ; where these data are located in the mht file
        whinfile = wh[where(ufn[j] eq mht[wh].fn)]
        ; all the relevant UTCSTAMPS
        utcs = mht[whinfile].utcstamp        
        ; and what dec # they are at
        whdec = ((((mht[whinfile].dec_halfsec[0]-decinfo[i,0])/(decinfo[i,1]-decinfo[i,0]))*decinfo[i,2]) > 0) < (decinfo[i,2] -1)
        ; and what reg # do they occupy
        whreg = rn[where(ufn[j] eq mht[wh].fn)]
        for k=0, n_elements(utcs)-1 do begin
            whpos = where(utcs[k] eq mh.utcstamp)
            ; find which dec bin it should go in
            ag1[*,*,*,whdec[k], whreg[k]] = ag1[*,*,*,whdec[k], whreg[k]] + fits[*, *, *, whpos]*(1-spblank[*, *, *, whpos])
            offset[whdec[k], whreg[k]] = offset[whdec[k], whreg[k]] + mh[whpos].vlsr[0]
            nsp[*, *, *, whdec[k], whreg[k]] = nsp[*, *, *, whdec[k], whreg[k]]+(1-spblank[*, *, *, whpos])
            nspnorm[ whdec[k], whreg[k]] = nspnorm[ whdec[k], whreg[k]] +1.
        endfor
    endfor
    ; can't have zeroes in the denominator; that just will not do
	wh0 = where(nsp eq 0, ct0)
	if ct0 ne 0 then begin
		print, 'sub region has channels that are blanked throughout. omitting these regions'
		; avoid total chaos
		nsp[wh0] = max(nsp)
		; find all the bad regions and decs
		nspbad = nsp*0
		nspbad[wh0] = 1
		nspbaddecreg = total(total(total(nspbad, 1), 1), 1) ne 0
		whnspbaddecreg = where(nspbaddecreg eq 1)
		; set all the overall scalings of these fits to zero
		nspnorm[whnspbaddecreg] = 0.	
	endif	
    ; get to a reasonable level
    ag1 = ag1/nsp;rebin(reform(nsp, 1,1, 1, decinfo[i,2], mxregs), 8192, 2, 7, decinfo[i,2], mxregs)
    
    wf0 = where(finite(ag1) eq 0, ctwf0)
    if ctwf0 ne 0 then ag1[wf0] = 0.
  ;  save, ag1, f= 'ag1_' + string(i, f='(I2.2)') + '.sav'
    offset = offset/nspnorm
    wf0 = where(finite(offset) eq 0, ctwf0)
    if ctwf0 ne 0 then offset[wf0] = 0.
    allfpn = reform(fltarr(8192, 7, decinfo[i, 2]),8192, 7, decinfo[i, 2])
    nf = reform(fltarr( decinfo[i,2], mxregs), decinfo[i,2], mxregs)
    avgaggr = fltarr(8192, 7, 2, decinfo[i,2])
    for nrg=0, mxregs-1 do begin
;        if decinfo[i,2] eq 1 then ag1_tmp = reform(ag1[*, *, *, , 8192, 2, 7, 1)
        agtmp = ag1[*, *, *, *, nrg]
        find_fpn, agtmp, rebin(reform(zogains[*, i], 7, 1), 7, decinfo[i,2]), rebin(reform(rxmultiplier[*,*, *, i], 8192, 2, 7, 1), 8192, 2, 7, decinfo[i,2]), fpn_sp, fn=fn, no6=no6, nfourier=nfourier
        for gg = 0, decinfo[i, 2]-1 do begin
            if max(agtmp[*, *, *, gg]) ne 0 then begin
                for ff=0, 6 do begin
                    allfpn[*, ff, gg] = allfpn[*, ff, gg] + shift(fpn_sp[*, ff, gg], (-1)*offset[gg, nrg]/0.18403)*nspnorm[ gg,nrg]
					avgaggr[*, ff, *, gg] = avgaggr[*, ff, *, gg] + shift(agtmp[*, *, ff, gg], (-1)*offset[gg, nrg]/0.18403)*nspnorm[gg,nrg]
                endfor
            endif
        endfor
    endfor
    allfpn = allfpn/rebin(reform(total(nspnorm, 2), 1, 1, decinfo[i, 2]), 8192, 7, decinfo[i, 2])
	avgaggr = avgaggr/rebin(reform(total(nspnorm, 2), 1, 1, 1, decinfo[i, 2]), 8192, 7, 2, decinfo[i, 2])
	fpn.(i).aggr = avgaggr
    ; the bin centers, not edges
    fpn.(i).decs = (findgen(decinfo[i, 2])+0.5)/decinfo[i,2]*(decinfo[i,1]-decinfo[i,0])+decinfo[i,0]
    fpn.(i).rxg = rxmultiplier[0, *, *, i]
    fpn.(i).zgn = zogains[*, i]
    fpn.(i).fpn = allfpn
    ; test allfpn for NaN's and warn user if they are present
    anynan = where(finite(allfpn,/nan), ctc)
    if (ctc ne 0) then print,'NaN fpn values detected for scan,',i
endfor
; this is so we can tell other programs to use the advanced version...
zogains = -99

if (keyword_set(forcecopy) and (keyword_set(v1) ne 1)) then begin
	szfc = size(forcecopy)
	for j = 0, szfc[2]-1 do begin
		decinfo[forcecopy[0, j], *] = decinfo[forcecopy[1, j], *]
	endfor
	fpnorg = fpn
	make_fpn_array, decinfo[*, 2], region, fpn
	for i=0, scans-1 do begin
		wh = where(i eq forcecopy[0, *], ct)
		if ct ne 0 then begin
			fpn.(i) = fpnorg.(forcecopy[1, wh[0]])
			; zogains[*, i] = zogains[*, forcecopy[1, wh[0]]]
			; I am leaving rxmultiplier alone -- is this a good idea??
		endif else begin
			fpn.(i) = fpnorg.(i)
		endelse	
	endfor
endif

save, aggr, zogains, fpn, rxmultiplier, file= root + proj + '/' + region + '/spcor'+ xnus +'.sav' 

endelse

end



