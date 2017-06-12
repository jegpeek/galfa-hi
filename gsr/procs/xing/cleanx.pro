; The purpose of the cleanx code is to get rid of weird outlier points that influence our fit. In a perfect world we'd be doing some kind of MARS fit, but for now, we just kick out the flukes. The way we do this is set the errors in the crossing points to be *negative*. This is just a way to remind the lsfxpt code not to use these data; it has no other meaning. 
; we also build a method to *not* fit those data with few crossing points, and then go back and force the rarely crossed data to a reasonable value

pro cleanx, root, region, scans, proj, degree, redchisq, redabs, redrd, daygain=daygain, beamgain=beamgain, fourier=fourier, tdf=tdf, big=big, time=time, blankfile=blankfile, cutoff=cutoff,  noxfix=noxfix, lapack=lapack, lambda= lambda, tval=tval, nit=nit, tru=tru, kill6=kill6, zfv=zfv

Print, "hold on a sec -- I'm going to need your advice in a minute or two"


if keyword_set(tval) then cutoff = tval else cutoff = 1.3
; number of iterations
if keyword_set(nit) then niter = nit else niter = 5
; how many to truncate each iteration
if keyword_set(tru) then trunc = tru else trunc = 10

rawcut = alog10(cutoff)

; some parameters for how bad the fit is
redchisq = fltarr(niter)
redabs = fltarr(niter)
redrd = fltarr(niter)

; do a count of how many we have at each pair

cmat = countx(root, region, scans, proj, tdf=tdf)

loadct, 0, /sil
!p.multi=[0, 1,2]
display, cmat
nxpt = total(cmat+transpose(cmat), 2)/2.
plot, findgen(scans), nxpt, psym=-1

print, "select a cutoff value; any scans with fewer than the value you click will be ignored in the fit"

cursor, x, minnum

oplot, findgen(scans), fltarr(scans)+minnum

whmn = where(nxpt lt minnum, nskipscans)
if nskipscans gt 0 then begin
	if keyword_set(beamgain) or keyword_set(daygain) or keyword_set(fourier) then begin
		print, 'ack, I am not set up for doing this with anything other than polynomial fits. Please use only polynomial fits or rewrite this code ^_^;;'
		return
	endif

	skipfit = fltarr(scans)
	skipfit[whmn] = 1.
	rsf = rebin(reform(skipfit, 1, scans, 1), degree+1, scans, 7)
	fvi = where(rsf eq 1, ctskip)
	fvv = fltarr(ctskip)
endif

; generate the initial xing results
lsfxpt, root, region, scans, proj, degree, xarrall, yarrall, 'x_clean', daygain=daygain, beamgain=beamgain, fourier=fourier, tdf=tdf, big=big, time=time, blankfile=blankfile
xg_assn, root, region, scans, proj, fitsvars, 'x_clean',  cutoff=cutoff, big=big, tdf=tdf, time=time, noxfix=noxfix, lapack=lapack, lambda= lambda, fvi=fvi, fvv=fvv, zfv=1e-6

;plotxing, root, region, scans, proj, xingname='x_clean'

; the names of the files
filenames = file_search(root + proj + '/' + region + '/xing/', '*_f.sav*')

nf = n_elements(filenames)

; initialize a number of parameters
allrcs = 0
allabs = 0
allrawdiff = 0
scannum = 0
elnum = 0
notneg = 0

; and read in the overall data files
restore, root + proj + '/' + region + '/todarr.sav'
timesboth = mht.utcstamp

wt1 = 0
xfb1 = 0
wt2 = 0
xfb2 = 0
xgains = 0
xerr = 0
scan1 = 0
scan2 = 0


for i=0, nf-1 do begin
	print,format='(%"%s/%s\r",$)',i,nf
	restore, filenames[i]
	mmxfit = minmax(xfit.scan1)
	if mmxfit[1]-mmxfit[0] ne 0 then begin
		; auto method is annoying and slow. Booooo.
		print, 'using auto method for ' + filenames[i]
		for p=0, n_elements(xfit)-1 do begin
			loop_bar, p, n_elements(xfit)
			wt1 = [wt1, (where(timesboth eq xfit[p].time1))[0]]
			wt2 = [wt2, (where(timesboth eq xfit[p].time2))[0]]
		endfor
		xfb1 = [xfb1, xfit.beam1]
		xfb2 = [xfb2, xfit.beam2]
		
		scannum = [scannum, fltarr(n_elements(xfit))+i ]
		elnum = [elnum, findgen(n_elements(xfit))]
		xgains = [xgains, xfit.gainr]
		xerr = [xerr, xfit.sigab[1]]
		
		; apply the raw cut
		whcut = where(alog10(xfit.gainr) gt rawcut or alog10(xfit.gainr) lt (-1)*rawcut, ncut)
		if ncut gt 0 then xfit[whcut].sigab[1] = abs(xfit[whcut].sigab[1])*(-1)
 		if ncut gt 0 then print, 'Raw cut ' + string(ncut) + ' xpoints in ' +filenames[i]
 		if keyword_set(kill6) then begin
 			wh6 = where(xfit.beam1 eq 6 or xfit.beam2 eq 6, ct6)
 			if ct6 ne 0 then xfit[wh6].sigab[1] = abs(xfit[wh6].sigab[1])*(-1)
 		endif
		isntnegative = xfit.sigab[1] gt 0
		notneg = [notneg, isntnegative]
		scan1 = [scan1, xfit.scan1]
		scan2 = [scan2, xfit.scan2]
		save, xfit, appl_xing, file=filenames[i]
		
	endif else begin

		wh1_init = (where(timesboth eq xfit[0].time1))[0]
		wh2_init = (where(timesboth eq xfit[0].time2))[0]

		whtime1 = xfit.time1-xfit[0].time1 + wh1_init
		whtime2 = xfit.time2-xfit[0].time2 + wh2_init

		xfb1 = [xfb1, xfit.beam1]
		xfb2 = [xfb2, xfit.beam2]
	
		wt1 = [wt1, whtime1]
		wt2 = [wt2, whtime2]
	
		xgains = [xgains, xfit.gainr]
		xerr = [xerr, xfit.sigab[1]]
	
		; apply the raw cut
		whcut = where(alog10(xfit.gainr) gt rawcut or alog10(xfit.gainr) lt (-1)*rawcut, ncut)
		if ncut gt 0 then xfit[whcut].sigab[1] = abs(xfit[whcut].sigab[1])*(-1)
 		if ncut gt 0 then print, 'Raw cut ' + string(ncut) + ' xpoints in ' +filenames[i]
 		if keyword_set(kill6) then begin
 			wh6 = where(xfit.beam1 eq 6 or xfit.beam2 eq 6, ct6)
 			if ct6 ne 0 then xfit[wh6].sigab[1] = abs(xfit[wh6].sigab[1])*(-1)
 		endif

		isntnegative = xfit.sigab[1] gt 0
		notneg = [notneg, isntnegative]
	
		scannum = [scannum, fltarr(n_elements(xfit))+i ]
		elnum = [elnum, findgen(n_elements(xfit))]
		scan1 = [scan1, xfit.scan1]
		scan2 = [scan2, xfit.scan2]
		save, xfit, appl_xing, file=filenames[i]
	endelse
		
endfor

wt1 = wt1[1:*]
xfb1 = xfb1[1:*]
wt2 = wt2[1:*]
xfb2 = xfb2[1:*]
xgains = xgains[1:*]
notneg = notneg[1:*]
xerr = xerr[1:*]
scannum = scannum[1:*]
elnum = elnum[1:*]
scan1 = scan1[1:*]
scan2 = scan2[1:*]

npts = n_elements(wt1)


for q=0, niter-1 do begin

	restore, root + proj + '/' + region + '/xingarr_x_clean.sav'
	fitgains1 = corf[xfb1, wt1]
	fitgains2 = corf[xfb2, wt2]
	gainr_fit = fitgains1/fitgains2

	rcs = ((gainr_fit-xgains)/xerr)^2
	aabs =  abs(gainr_fit-xgains)/xerr
	rawdiff = abs(gainr_fit-xgains)

	redchisq[q] = total(rcs*notneg, /nan)/total(notneg)
	redabs[q] = total(aabs*notneg, /nan)/total(notneg)
	redrd[q] = total(rawdiff*notneg, /nan)/total(notneg)

	wnn = where(notneg eq 1, ctnn)
	srt = sort(rawdiff[wnn])
	wh = srt[ctnn-trunc-1:ctnn-1]

	for j=0, trunc-1 do begin
		restore, filenames[(scannum[wnn])[wh[j]]]
		xfit[(elnum[wnn])[wh[j]]].sigab[1] = xfit[(elnum[wnn])[wh[j]]].sigab[1]*(-1)
		print, "gain of " + string(xfit[(elnum[wnn])[wh[j]]].gainr) + " eliminated in " + filenames[(scannum[wnn])[wh[j]]]
		notneg[wnn[wh[j]]] = 0
		save, xfit, appl_xing, file=filenames[scannum[wh[j]]]
	endfor
	
	lsfxpt, root, region, scans, proj, degree, xarrall, yarrall, 'x_clean', daygain=daygain, beamgain=beamgain, fourier=fourier, tdf=tdf, big=big, time=time, blankfile=blankfile
	xg_assn, root, region, scans, proj, fitsvars, 'x_clean',  cutoff=cutoff, big=big, tdf=tdf, time=time, noxfix=noxfix, lapack=lapack, lambda= lambda, fvi=fvi, fvv=fvv, zfv=1e-6
	
endfor

if nskipscans gt 0 then begin
	if keyword_set(zfv) then begin
		q = 0
		p = 0
		while q ne (-1) do begin
			zfvi = q
			if fvi[p] ne q then begin
				q= (-1) 
			endif else begin
				q = q + (degree+1)
				p++
			endelse
		endwhile
	endif
	plotxing, root, region, scans, proj, xingname='x_clean', ratio_resid=rr, /noplot
	wnoskip = where(skipfit eq 0)
	wskip = where(skipfit eq 1, nskip)
	fvv_new = fltarr(degree+1, scans, 7) 
	for i=0, nskip-1 do begin
		for j=0, 6 do begin
			fvv_new[0, wskip[i], j] = median(rr[*, j, wnoskip, wskip[i]])
		endfor
	endfor
	fvv = (reform(fvv_new, (degree+1)*scans*7))[fvi]
	if keyword_set(zfv) then begin
		; slope can't be trusted
		fvi = [zfvi+1, fvi]
		fvv = [0, fvv] 
		zfv1 = median(rr[*, zfvi/(scans*(degree+1)), wnoskip, zfvi/(degree+i) mod scans])
	endif
	
	print, 'zfv = ' + string(zfv1)
	print, 'zfvi = ' + string(zfvi)
endif	
	
	
	
	lsfxpt, root, region, scans, proj, degree, xarrall, yarrall, 'x_clean', daygain=daygain, beamgain=beamgain, fourier=fourier, tdf=tdf, big=big, time=time, blankfile=blankfile
	xg_assn, root, region, scans, proj, fitsvars, 'x_clean',  cutoff=cutoff, big=big, tdf=tdf, time=time, noxfix=noxfix, lapack=lapack, lambda= lambda, fvi=fvi, fvv=fvv, zfv=zfv1
	
end