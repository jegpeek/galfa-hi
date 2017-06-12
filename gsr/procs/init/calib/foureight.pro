; a code to look for and correct the strange 400 second baseline burst that happens
; every 1200 seconds in some data sets

pro foureight, root, region, scans, proj, tdf=tdf, badrxfile=badrxfile, scannum=scannum, intermittent=intermittent

; the usual
if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)' 

; initializing indices
ind0 = 0
ind1 = scans-1

; if scannum set, just do scannum
if keyword_set(scannum) then begin
	ind0 = scannum
	ind1 = scannum
endif 


; we don't need all the channels, so we bin down for fitting
n=6
deci = 8192/(2^n)

; looping over the scans of interest
for l=ind0, ind1 do begin
	; read in the meta data for the scan
	restore, root + '/' +  proj + '/' + region + '/' + region + '_'  + string(l, format=scnfmt) + '/' + '*hdrs*'
	; uniq file names
	ufns = fn[uniq(fn, sort(fn))]
	nufns = n_elements(ufns)
	; the spectrum, folded by 1200 seconds
	folded = fltarr(deci, 2, 7, 1200)
	n1200 = ceil(n_elements(mh)/1200.)
	unfolded = fltarr(deci, 2, 7, 1200, n1200)
	folded_ntimes = fltarr(deci, 2, 7, 1200)
	q = 0
        print, 'scan = ' + string(l, f=scnfmt) 
	for k=0, nufns-1 do begin
		loop_bar, k, nufns
		data = gsrfits(ufns[k], /savname)
		restore, ufns[k]
		whichrx, mh[0].UTCSTAMP, goodrx, badrxfile=badrxfile
		szd = size(data)
		; make any bad data just zeroes.
		data = data*rebin(reform(goodrx, 1, 2, 7, 1), 8192, 2, 7, szd[4])
		wh = (q + findgen(szd[4])) mod 1200
		folded[*, *, *, wh] = folded[*, *, *, wh] + rebin(data, deci, 2, 7, szd[4])
		firstsec1200 = floor(q/1200.)
		lastsec1200 = floor((q+szd[4])/1200.)
		if firstsec1200 eq lastsec1200 then unfolded[*, *, *, wh, q/1200.] = rebin(data, deci, 2, 7, szd[4])
		if firstsec1200 ne lastsec1200 then begin
			wh1 = where(floor((q+findgen(szd[4]))/1200.) eq floor(q/1200.))
			wh2 = where(floor((q+findgen(szd[4]))/1200.) ne floor(q/1200.))
			unfolded[*, *, *, wh[wh1], q/1200.] = (rebin(data, deci, 2, 7, szd[4]))[*, *, *, wh1]
			unfolded[*, *, *, wh[wh2], q/1200.+1] = (rebin(data, deci, 2, 7, szd[4]))[*, *, *, wh2]	
		endif
		folded_ntimes[*, *, *, wh] = folded_ntimes[*, *, *, wh] + 1.0
		q = q+szd[4]
	endfor
	folded = folded/folded_ntimes
	fes = findgen(n1200)
	if keyword_set(intermittent) then begin
		!p.multi=[0, 1, 5]
		loadct, 0, /sil
		print, 'now, take careful notes: which of these has the 4/8 glitch?'
		for q=0, ceil(n1200/5) do begin
			for i=0, 4 do begin
				j = i+5*q
				if j lt (n1200) then begin
					img = reform(rebin(reform(unfolded[*, *, *, *, j]), deci/4., 2, 7, 100), deci/4*2*7, 100)
					display, img - rebin(total(img, 2)/100., deci/4*2*7,100) < 0.1 > (-0.1), title=j
				endif
			endfor
			stop
		endfor
		print, "please make a list of all the 4/8 scans in the form fes = [0, 4, 5, 13], or I'll just assume you want all of them"
		stop
		folded = total(unfolded[*, *, *, *, fes], 5)/total(unfolded[*, *, *, *, fes] ne 0, 5)	
	endif
	
	tstart = findgen(1200)
	diff = fltarr(1200)
	for k=0, 1199 do begin
		shfold = shift(folded, 0, 0, 0, k)
		on = total(shfold[*, *, *, 0:399], 4)/400.
		off = total(shfold[*, *, *, 400:*], 4)/800.
		diff[k] = median(abs(on-off))
	endfor

	mx = max(diff, ind)
	print, mx
	shfold = shift(folded, 0, 0, 0, ind)
	on = total(shfold[*, *, *, 0:399], 4)/400.
	off = total(shfold[*, *, *, 400:*], 4)/800.
	scan=l
	save, on, off, n, ind, mx, scan, diff, fes, f=root + '/' +  proj + '/' + region + '/' + region + '_'  + string(l, format=scnfmt) + '/foureight_'+ string(l, format=scnfmt) + '.sav'
endfor




end
