;+
; NAME:
;   LSFXPT
; PURPOSE:
;   To generate the fits for varying gain parameters.
;
; CALLING SEQUENCE:
;    lsfxpt, root, region, scans, proj, degree, xarrall, yarrall, $
;    xingname, daygain=daygain, beamgain=beamgain, fourier=fourier, big=big, tdf=tdf, time=time
; INPUTS:
;   root -- The main direcotry in which the project directory
;             resides (e.g. '/dzd4/heiles/gsrdata/' )
;   region -- The name of the source as entererd into BW_fm (e.g. 'lwa')
;   scans -- Number of days the project consists of
;   proj -- The Arecibo project code (e.g. 'a2050')
;   degree -- The degree of polynomial fit desired. Set to -1 if
;             no RA dependant polynomial fit is desired.
;   xingname -- The name for the XING reduction in process. NOT the name for 
;               previous reductions.
; KEYWORD PARAMETERS:
;
;   daygain -- set this keyword (to 1) if you want to have independent fits 
;              to each day's gain.
;   beamgain -- set this keyword (to 1) if you want to have independant zeroeth 
;               order fits to the gain of each beam
;
;   big -- Set this keyword to never compute the full X matrix, and just output the yxt and xtx
;          matrices. Good if (days*crossingpoints) > 5 million
;   tdf -- use the older two-digit formatting
; OUTPUTS:
;   Xarrall -- The X parameter in the LSF
;   Yarrall -- The Y parameter in the LSF
;
; MODIFICATION HISTORY
;
;  Initial documentation, July 22, 2005
;  Modified to version 2.0 Ocotober 15, 2005
;  Modified to deal with SIGAB = 0., March 1, 2006 (Kevin)
;  Implemented big keyword, and internal transposition.
;  added appl_xing to save file oct 26, 2006, JEG Peek
;  re-added blankfile keyword, Feb 1, 2011, K.Douglas
;  Joshua E. Goldston, goldston@astro.berkeley.edu
;-

pro lsfxpt, root, region, scans, proj, degree, xarrall, yarrall, xingname, daygain=daygain, beamgain=beamgain, fourier=fourier, tdf=tdf, big=big, time=time, blankfile=blankfile

if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)' 

;BLANKS!!???

;filenames =  root + proj + '/' + region + '/xing/'+ region + 'auto_f.sav'
; code for no polynomial gain
if (degree lt 0) then degree = -1

; whether the keywords are set
kwsdg = keyword_set(daygain)
kwsbg = keyword_set(beamgain)

;for i = 0l, scans-2 do begin
;    for j = i+1, scans-1 do begin 
;        filenames = [filenames, root + proj + '/' + region + '/xing/'+ region + string(i, format='(I2.2)') + '-'+  string(j, format='(I2.2)')  + '_f.sav']
;    endfor
;endfor
filenames = file_search(root + proj + '/' + region + '/xing/', '*_f.sav*')

nf = 0.
if keyword_set(fourier) then begin
	if max(fourier ne [0.,-1]) then nf = fourier[1] - fourier[0]+1.
endif
if keyword_set(fourier) then begin
	if max(fourier ne [0.,-1]) then fmodes = fourier[0] + findgen(nf)
endif
if (not keyword_set(fourier)) then fourier = [0.,-1]

beamname = strarr(7 + kwsdg*scans + scans*7*(degree+1) +2*scans*7*(nf)) 
dayname = strarr(7 + kwsdg*scans + scans*7*(degree+1) +2*scans*7*(nf))
fitname = strarr(7 + kwsdg*scans + scans*7*(degree+1) +2*scans*7*(nf))
ordername = strarr(7 + kwsdg*scans + scans*7*(degree+1) +2*scans*7*(nf)) 

if (kwsbg) then begin
    for i=0, 6 do begin
        beamname[i] = string(i, format='(I1)')
        dayname[i] = 'N/A'
        fitname[i] = 'flat'
        ordername[i] = '0'
    endfor
endif
if (kwsdg) then begin
    for i=7*kwsbg, 7*kwsbg+scans-1 do begin
        beamname[i] = 'N/A'
        dayname[i] = string(i-7, format=scnfmt)
        fitname[i] = 'flat'
        ordername[i] = '0'
    endfor
endif
for i=7*kwsbg + kwsdg*scans, 7*kwsbg + kwsdg*scans + scans*7*(degree+1) -1 do begin
    j = i - (7*kwsbg + kwsdg*scans)
    beamname[i] = string(floor(j/(scans*(degree+1))), format='(I2)')
    dayname[i] = string(floor(j/(degree+1) mod scans), format=scnfmt)
    fitname[i] = 'polynomial'
    ordername[i] = string(floor(j mod (degree+1)), format='(I2)')
endfor

for i = 7*kwsbg + kwsdg*scans + scans*7*(degree+1), 7*kwsbg + kwsdg*scans + scans*7*(degree+1) + scans*7*(nf) -1 do begin
    j = i -(7*kwsbg +kwsdg*scans + scans*7*(degree+1))
    beamname[i] = string(floor(j/(scans*nf)), format='(I2)')
    dayname[i] = string(floor(j/nf) mod scans, format=scnfmt)
    fitname[i] = 'Cosine'
    ordername[i] = string(floor(j mod (nf))+fourier[0], format='(I2)')
endfor

for i = 7*kwsbg + kwsdg*scans + scans*7*(degree+1) + scans*7*(nf), 7*kwsbg + kwsdg*scans + scans*7*(degree+1) + 2*scans*7*(nf) -1 do begin
    j = i - ( 7*kwsbg + kwsdg*scans + scans*7*(degree+1) + scans*7*(nf))
    beamname[i] = string(floor(j/(scans*nf)), format='(I2)')
    dayname[i] = string(floor(j/nf) mod scans, format=scnfmt)
    fitname[i] = 'Sine'
    ordername[i] = string(floor(j mod (nf))+fourier[0], format='(I2)')
endfor

;mra = fltarr(scans)
;dra = fltarr(scans)

for i=0l, scans -1 do begin
    loop_bar, i, scans
    restore, root + proj + '/' + region + '/' + region + '_' + string(i, format=scnfmt) +'/' + '*.hdrs*'
    sz = size(mh)
    ha = mh.lst_meanstamp-mh.ra_halfsec[0]
    medianha =  median(ha)
    lastpt = max(where(abs(medianha - ha) lt 0.01))
    if not keyword_set(time) then makdom, mh[0:lastpt].ra_halfsec[0], mdst else makdom, double(mh.utcstamp), mdst, time=time
    if (i eq 0) then mdsts = replicate(mdst, scans)
    if (i ne 0) then mdsts[i] = mdst
endfor

minrange = min(mdsts.rng)*2
maxrange = max(mdsts.rng)*2.

npp = ceil((max([fourier, degree])*2.+1.)*maxrange/minrange)*2.

if keyword_set(time) then pinpoints = min(mdsts.ctr-mdsts.rng) + findgen(npp)/(npp-1)*(max(mdsts.ctr+mdsts.rng) - min(mdsts.ctr-mdsts.rng)) else pinpoints = (min(mdsts.ctr-mdsts.rng) + findgen(npp)/(npp-1)*(max(mdsts.ctr+mdsts.rng) - min(mdsts.ctr-mdsts.rng)) + 24) mod 24

;pinpoints = (hira + findgen(npp)/(npp)*(min(dra)*2.)) mod 24

; These are the arrays we need for computing x transpose * x and y * transpose x
if keyword_set(big) then begin
    xtx = fltarr(7*kwsbg + kwsdg*scans + scans*7*(degree+1) +2*scans*7*(nf),7*kwsbg + kwsdg*scans + scans*7*(degree+1) +2*scans*7*(nf))
    ytx = fltarr(7*kwsbg + kwsdg*scans + scans*7*(degree+1) +2*scans*7*(nf))
    totsig = 0
    nsig = 0
endif

; deal with the outx vs xfit confusion
newver=0

for k = 0l, n_elements(filenames)-1 do begin
    loop_bar, k, n_elements(filenames)
    restore, filenames[k]
	if (n_elements(outx) eq 0) or (newver eq 1) then begin
		outx=xfit
    	newver=1
    endif
    if (outx[0].scan1 gt (scans-1)) or (outx[0].scan2 gt (scans-1)) then continue
    wh = where((outx.scan1 le (scans-1) and (outx.scan2 le (scans-1))), ct)
    outx = outx[wh]
	; get rid of any outx where sigab[1] is negative
	whpos = where(outx.sigab[1] ge 0)
	outx = outx[whpos]
    ; clean up outx
    if keyword_set(blankfile) then removeblanks,blankfile, outx
    if n_elements(outx) gt 1 then begin
        medgain = median(outx.gainr)
        medsig = median(outx.sigab[1])
    endif else begin
    	; if outx = 0., get out of this loop
    	if n_elements(size(outx)) eq 3 then continue
        medgain = outx.gainr
        medsig = outx.sigab[1]
    endelse
    wh = where((finite(outx.gainr) gt 0 ) and (finite(outx.sigab[1]) ne 0 ) and (outx.gainr gt medgain/10.) and (outx.gainr lt medgain*10.) and (outx.sigab[1] gt medsig/10.) and (outx.sigab[1] lt medsig*10.), ctgood)
    if (ctgood eq 0) then print, 'skipping ' + filenames[k] +' : No good xing points'
    if (ctgood eq 0) then continue
    outx=outx[wh]

    ; zany hack - make one day very bright as a test
;    zd = 138.
;    whs1 = where(outx.scan1 eq zd, ct)
;    if ct ne 0 then outx[whs1].gainr = outx[whs1].gainr*2
;   whs2 = where(outx.scan2 eq zd, ct)
;    if ct ne 0 then outx[whs2].gainr = outx[whs2].gainr*0.5

    sz = size(outx)
    ; 7 for beam gain
    ; scans for overall gain for a day (if set)
    ; scans*beams for short time-scale fluctuations.
    ; See page 64 of notebook-1 for setup
    Xarr = fltarr(7*kwsbg + kwsdg*scans + scans*7*(degree+1) +2*scans*7*(nf) , sz[1])
    rax1 = dblarr(sz[1])
    rax2 = dblarr(sz[1])
    decx = dblarr(sz[1])
    for i = 0l, sz[1] -1 do begin
        if not keyword_set(time) then begin
            rax1[i] = outx[i].xra
            rax2[i] = outx[i].xra
        endif else begin
            rax1[i] = outx[i].time1
            rax2[i] = outx[i].time2
        endelse
        decx[i] = outx[i].xdec
        if (kwsbg) then Xarr[outx[i].beam1, i] = Xarr[outx[i].beam1, i] + 1
        if (kwsbg) then Xarr[outx[i].beam2, i] = Xarr[outx[i].beam2, i] - 1
        if (kwsdg) then Xarr[7*kwsbg + outx[i].scan1, i] = Xarr[7*kwsbg + outx[i].scan1, i] + 1
        if (kwsdg) then Xarr[7*kwsbg + outx[i].scan2, i] = Xarr[7*kwsbg + outx[i].scan2, i] - 1

        for j=0l, degree do begin
               

            Xarr[7*kwsbg + kwsdg*scans + (degree+1)*scans*outx[i].beam1 + (degree+1)*outx[i].scan1 + j, i] =  Xarr[7*kwsbg + kwsdg*scans + (degree+1)*scans*outx[i].beam1 + (degree+1)*outx[i].scan1+ j, i] + locdom(mdsts[outx[i].scan1], rax1[i], /time)^j
        

            Xarr[7*kwsbg + kwsdg*scans + (degree+1)*scans*outx[i].beam2 + (degree+1)*outx[i].scan2 + j, i] =  Xarr[7*kwsbg + kwsdg*scans + (degree+1)*scans*outx[i].beam2 + (degree+1)*outx[i].scan2+ j, i] - locdom(mdsts[outx[i].scan2], rax2[i], /time)^j


        endfor
        for j=0l, nf-1 do begin
            ; Cosine terms
         
            Xarr[7*kwsbg + kwsdg*scans + scans*7*(degree+1) + nf*scans*outx[i].beam1 + nf*outx[i].scan1 + j, i] = Xarr[7*kwsbg + kwsdg*scans + scans*7*(degree+1) + nf*scans*outx[i].beam1 + nf*outx[i].scan1 + j, i] + cos(fmodes[j]*!pi*locdom(mdsts[outx[i].scan1], rax1[i], /time))*(fmodes[j] ne 0.)

            Xarr[7*kwsbg + kwsdg*scans + scans*7*(degree+1) + nf*scans*outx[i].beam2 + nf*outx[i].scan2 + j, i] = Xarr[7*kwsbg + kwsdg*scans + scans*7*(degree+1) + nf*scans*outx[i].beam2 + nf*outx[i].scan2 + j, i] - cos(fmodes[j]*!pi*locdom(mdsts[outx[i].scan2], rax2[i], /time))*(fmodes[j] ne 0.)

            ; Sine terms
            Xarr[7*kwsbg + kwsdg*scans + scans*7*(degree+1) + scans*7*(nf) + nf*scans*outx[i].beam1 + nf*outx[i].scan1 + j, i] = Xarr[7*kwsbg + kwsdg*scans + scans*7*(degree+1) + nf*scans*outx[i].beam1 + nf*outx[i].scan1 + j, i] + sin(fmodes[j]*!pi*locdom(mdsts[outx[i].scan1], rax1[i], /time))
        
            Xarr[7*kwsbg + kwsdg*scans + scans*7*(degree+1) + scans*7*(nf) + nf*scans*outx[i].beam2 + nf*outx[i].scan2 + j, i] = Xarr[7*kwsbg + kwsdg*scans + scans*7*(degree+1) + nf*scans*outx[i].beam2 + nf*outx[i].scan2 + j, i] - sin(fmodes[j]*!pi*locdom(mdsts[outx[i].scan2], rax2[i], /time))

        endfor

     endfor
    ; ############# HACK TO CHECK DEAL WITH GAINS ON ZERO ##############
    ; ############# HACK COMMENTED OUT #######################################

	; ############# HACK TO CHECK SIGN ERROR ################
    ; ############# HACK COMMENTED OUT #######################################
	
	Yarr = alog10(outx.gainr);*((outx.beam1 ne 0) or (outx.scan1 ne 0)) - ((outx.beam1 eq 0) and (outx.scan1 eq 0))*0.01
    why = (where(finite(yarr) eq 0, ctyinf))
    if (ctyinf ne 0) then yarr[why] = 0.
    if (k eq 0) then begin
    decxall = decx
    raxall = rax1
endif else begin
    raxall = [raxall, rax1]
    decxall = [decxall, decx]
endelse

if (not (keyword_set(big))) then begin
    if (k eq 0) then begin
        yarrall = yarr
        xarrall = xarr   
        if (where(tag_names(outx) eq 'SIGAB') ne (-1)) then sigarrall = outx.sigab[1]
    endif else begin 
        yarrall = [yarrall, yarr]
        xarrall = [[xarrall], [xarr]]
        if (where(tag_names(outx) eq 'SIGAB') ne (-1)) then sigarrall = [sigarrall, outx.sigab[1]]
    endelse
endif else begin
    if (where(tag_names(outx) eq 'SIGAB') ne (-1)) then begin
        sigs = outx.sigab[1]
      	if total(sigs gt 1000.) eq n_elements(sigs) then continue
        wh = where(((sigs lt 1d-6) or (sigs gt 1)), ct)
        if ct gt 0. then begin
            sigs(wh) = 1000.
            print, 'bad sigs:' + string(ct)
        endif
        wh999 = where(where(sigs lt 999), ct999)
        if ct999 ne 0 then lmean = mean(sigs(wh999))
        sums = sigs
        if (ct gt 0) and (ct999 gt 0) and (ct lt (n_elements(outx))) then sums(where(sigs gt 999)) = lmean
        
        yarr = yarr/sigs
        xarr = xarr*rebin(reform(1/sigs, 1, n_elements(outx)), 7*kwsbg + kwsdg*scans + scans*7*(degree+1) +2*scans*7*(nf), n_elements(outx))
        totsig = totsig + total(sums, /nan)
      ;  print, totsig
    endif
    nsig =  nsig + n_elements(outx)
    xtx = xtx + xarr#transpose(xarr)

    if (n_elements(where(finite(yarr) eq 0))) ne 1 then stop
    ytx = ytx + reform(yarr#transpose(xarr))
    if (n_elements(where(finite(xtx) eq 0))) ne 1 then stop
    if (n_elements(where(finite(ytx) eq 0))) ne 1 then stop
endelse

endfor

;stop
; Now, if these sig values exist, let's weight X array and the Y array by them
; X = X_sigma#W
; Y = Y_sigma#W (see carl's 250 notes)
if keyword_set(big) then begin
    xtx = xtx*(totsig/nsig)^2.
    ytx = ytx*(totsig/nsig)^2.


endif else begin
    wsm=where(sigarrall eq 0.)
    swsm=size(wsm)
    if (swsm(0) ne 0.) then sigarrall(where(sigarrall eq 0.)) = mean(sigarrall)
    
    meanwgt = mean(sigarrall)
    wgtarr = meanwgt/sigarrall
    yarrall = yarrall*wgtarr
    xarrall = xarrall*rebin(reform(wgtarr, 1, n_elements(sigarrall)), 7*kwsbg + kwsdg*scans + scans*7*(degree+1) +2*scans*7*(nf), n_elements(sigarrall))
endelse
;stop
; the idea here is to pin down the overall gains of each scan at a number of pinpoints
if keyword_set(big) then ndata = nsig else ndata =(size(yarrall))[1]

;stop
c_xarr = fltarr(7*kwsbg + kwsdg*scans + scans*7*(degree+1) + 2*scans*7*(nf) , npp)
c_yarr = fltarr(npp)

ppoints = 1.

if ppoints eq 1 then begin

for i=0l, npp-1 do begin
    
    if (kwsbg) then c_xarr[0:6,i] = scans
    if (kwsdg) then c_xarr[7*kwsbg : 7*kwsbg +scans-1, i] = 7.
    for k=0, 6 do begin
        for l=0l, scans-1 do begin
            for j=0, degree do begin
                c_xarr[7*kwsbg + kwsdg*scans + (degree+1)*scans*k + (degree+1)*l + j, i] =  c_xarr[7*kwsbg + kwsdg*scans + (degree+1)*scans*k + (degree+1)*l+ j, i] + locdom(mdsts[l], pinpoints[i], /time) ^j
            endfor
            for j=0l, nf-1 do begin
                c_xarr[7*kwsbg + kwsdg*scans + scans*7*(degree+1) + nf*scans*k + nf*l + j, i] = c_xarr[7*kwsbg + kwsdg*scans + scans*7*(degree+1) + nf*scans*k + nf*l + j, i] + cos(fmodes[j]*!pi*locdom(mdsts[l], pinpoints[i], /time))
                c_xarr[7*kwsbg + kwsdg*scans + scans*7*(degree+1) + scans*7*(nf) + nf*scans*k + nf*l + j, i] = c_xarr[7*kwsbg + kwsdg*scans + scans*7*(degree+1) + nf*scans*k + nf*l + j, i] + sin(fmodes[j]*!pi*locdom(mdsts[l], pinpoints[i], /time))
            endfor
        endfor
    endfor
endfor


; Weighting of the pinpoint fits.
ampl_coef = 10.
;stop
if keyword_set(big) then begin
    xtx = xtx + (c_xarr*ampl_coef)#transpose(c_xarr*ampl_coef)
    ytx = ytx + reform(c_yarr#transpose(c_xarr*ampl_coef))
endif else begin
xarrall = [[xarrall], [c_xarr*ampl_coef]]
yarrall = [yarrall, c_yarr] 
endelse
endif
if (not keyword_set(daygain)) then daygain = 0.
if (not keyword_set(beamgain)) then beamgain = 0.

names = { beam:beamname,day:dayname, fit:fitname, order:ordername}
if (not (keyword_set(big))) then big = 0
if (not (keyword_set(big))) then time = 0
if n_elements(appl_xing) eq 0 then appl_xing='none'
if keyword_set(big) then save, big, time, ndata, mdsts, xtx, ytx, degree, beamgain, daygain, nf, fourier, names, raxall, decxall, pinpoints, ampl_coef, appl_xing, filename=root + proj + '/' + region + '/xing/'+ region + '_lsfxpt_' + xingname +'.sav' else save, big, time, ndata, mdsts, xarrall, yarrall, degree, beamgain, daygain, nf, fourier, names, raxall, decxall, pinpoints, ampl_coef, sigarrall, appl_xing, filename=root + proj + '/' + region + '/xing/'+ region + '_lsfxpt_' + xingname +'.sav'

end
