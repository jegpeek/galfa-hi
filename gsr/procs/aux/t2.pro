;+
; NAME:
; T2
;
;
; PURPOSE:
;  To inspect final cubes alongside their generating data to determine the
;  origin of glitches and exceprt them from the data.
;
; CALLING SEQUENCE:
;  t2, fn, todarr, blfile, spblfile, slrange=slrange, bt=bt, badrxfile=badrxfile
;
; INPUTS:
;  fn -- The name of a fits data cube to inspect
;  todarr -- The name of the time-ordered data array file from todarr.pro
;          or the array itself
;  blfile -- a blanks file to write to
;  spblfile -- a spbl file to write to (note: do not include .sav or .fits)
; KEYWORDS:
;  slrange -- a predetermined slice range to read, if you do not want to read the whole cube
;  bt -- a brightness scale to include
;  badrxfile -- a badrxfile to use for setting the spblfile.
;  fits -- if set, contain the output of the fits file
;  hdr -- must be set to the header information if using the FITS keyword
; OUTPUTS:
;
; MODIFICATION HISTORY:
;  Documented Nov 17th, 2008, JEGP
;  Added NAN catch for scaling, March 3, 2011, JEGP
;  Added SPBL blanking, Wed, March 30th, 2011, JEGP
;-

pro t2, fn, todarr, blfile, spblfile, slrange=slrange, bt=bt, badrxfile=badrxfile, fits=fits, hdr=hdr, showspec=showspec, utcstamps=utcstamps, pols=pols, beams=beams, imskip=imskip

if ~keyword_set(imskip) then begin

	; wait time
	wt = 1.
	device, dec=0
	loadct, 0, /sil
	!p.multi=0
	circle
	window, 0, xsi=800, ysi=800
	if keyword_set(slrange) then begin
	fits = fltarr(512, 512, slrange[1]-slrange[0]+1)
		for i=slrange[0], slrange[1] do begin
			slice = readfits(fn, hdr, nslice=i)
			fits[*, *, i-slrange[0]] = slice
		endfor 
	endif else begin
		if 	not keyword_set(fits) then fits = readfits(fn, hdr)
	endelse
	wh = where(fits lt -100, ct)
	if ct ne 0 then fits[wh] = 0.
	xs = sxpar(hdr, 'naxis1')
	ys = sxpar(hdr, 'naxis2')
	window, 0, xsi=(xs+300) < 1500, ysi=(ys+300) < 1000
	xx = rebin(reform(findgen(xs), xs, 1), xs, ys)
	yy = rebin(reform(findgen(ys), 1, ys), xs, ys)
	; if someone used the wrong sdgw fits code...
	if ((sxpar(hdr, 'CRVAL1') ne 180) or (sxpar(hdr, 'CRVAL2') ne 0)) then begin
		crv1 = sxpar(hdr, 'CRVAL1')
		crv2 = sxpar(hdr, 'CRVAL2')
		crp1 = sxpar(hdr, 'CRPIX1')
		crp2 = sxpar(hdr, 'CRPIX2')
		sxaddpar, hdr, 'CRVAL1', 180
		sxaddpar, hdr, 'CRVAL2', 0
		sxaddpar, hdr, 'CRPIX1', crp1-(crv1-180.)/sxpar(hdr, 'CDELT1')
		sxaddpar, hdr, 'CRPIX2', crp2-crv2/sxpar(hdr, 'CDELT2')
	endif
	extast, hdr, astr
	xy2ad, xx, yy, astr, a, d
	; test for crossing ra=0
	if min(a) lt 1 and max(a) gt 359 then ra0 = 1 else ra0 = 0
	if ra0 then a = ((a + 180.) mod 360 ) -180

	ras = a
	decs = d


	;Vrng = (findgen(2048)-1023.5)*astr.cdelt[2]*1d-3

	; find where the todarr is in the cube
	if n_elements(todarr) eq 1 then restore, todarr else mht = todarr
	if ra0 then mht.ra_halfsec = ((mht.ra_halfsec + 12.) mod 24 ) -12
	if ra0 then whc = where( ((mht.ra_halfsec[0] lt max(ras(where(ras lt 180))/15.)) or (mht.ra_halfsec[0] gt min((ras+360)/15.))) and (mht.dec_halfsec[0] gt min(decs)) and (mht.dec_halfsec[0] lt max(decs))) else whc = where( (mht.ra_halfsec[0] lt max(ras/15.)) and (mht.ra_halfsec[0] gt min(ras/15.)) and (mht.dec_halfsec[0] gt min(decs)) and (mht.dec_halfsec[0] lt max(decs)))

	mhtwhc = mht[whc]
	if ra0 then mhtwhc.ra_halfsec = ((mhtwhc.ra_halfsec + 12.) mod 24 ) -12

	whblanks, blfile, mhtwhc, flag


	print, 'Once you see an image, move the cursor left and right'
	print, 'to cruise through the data cube in velocity-space.'
	print, 'When you are satisfied with the velocity, left-click.'
	print, 'Then repeat this process to select a second velocity.'
	print, 'For the rest of the blanking process you will be using'
	print, 'an image that is the data cube integrated over this range'
	print, 'in velocities.'

	cruise, fits, v1, ra0=reform(ras[*, 0]), dec0=reform(decs[0, *])
	cruise, fits, v2, ra0=reform(ras[*, 0]), dec0=reform(decs[0, *])
	!mouse.button = 1

	if floor(v1) eq floor(v2) then img = reform(fits[*, *, v1]) else img = total(fits[*, *, v1 < v2:v2 > v1 ], 3)

	; get the channel #s in 8192-space:
	; 8192 space
	del_vel=-2.99792458e+5*((100./14.)/8192.)/1420.405751786
	all_vel = del_vel*(findgen(8192)-4095.5)	

	; cube space
	vv = (findgen(sxpar(hdr, 'NAXIS3')) - (sxpar(hdr, 'CRPIX3') -1))*sxpar(hdr, 'CDELT3')*1d-3 + sxpar(hdr, 'CRVAL3')*1d-3

	chsp1 = interpol(findgen(8192), all_vel, vv[v1])
	chsp2 = interpol(findgen(8192), all_vel, vv[v2])

	whspblanks, spblfile, mhtwhc, (chsp1 < chsp2), (chsp1 > chsp2), flag2

	flag = (1 + flag*11 + flag2*6)*16

	if not (keyword_set(bt)) then begin
	mn = min(img,/nan)
	mx = max(img, /nan)
	print, 'select an amplitude range over which to display the slice by moving'
	print, 'the cursor. Middle-click to select'
	while (!mouse.button ne 2) do begin
		cursor, x, y, /normal, /change
		top = (x*(mx-mn)+mn) > (y*(mx-mn)+mn)
		bottom = (y*(mx-mn)+mn) < (x*(mx-mn)+mn)
		display, (img < top) > bottom, reform(ras[*, 0]), reform(decs[0, *]), /silent
		xyouts, 0.1, 0.1, string(bottom)+', '+ string(top), /normal
	endwhile
	endif else begin
		top = bt[1]
		bottom = bt[0]
	endelse
	cursor, aa, bb, /up
	opixwin, ow

	display, (img < top) > bottom, reform(ras[*, 0]), reform(decs[0, *]) ,  aspect=xs/ys, /silent

	cpixwin, ow, pw, x1, y1, p1

	spixwin, pw
	;wait, 5
	!mouse.button = 1
	th=4
	deci = 10


	print, 'would you like to zoom in?  (L=no, R = yes)'

	cursor, a, d, /up
	if !mouse.button eq 1 then zoom = 0. else zoom = 1.
	zoom=1
		while zoom eq 1 do begin

		print, 'middle buton to select'
		!mouse.button=1.
		while (!mouse.button ne 2) do begin
			cursor, a, d, /change
			spixwin, pw
			plots, a, d, psym=1, color=200, thick=1., symsize=2
		endwhile

		ropixwin, ow, pw, x1, y1, p1
		plots, a, d, psym=1, color=200, thick=1., symsize=2
		cpixwin, ow, pw, x1, y1, p1
		wait, wt
		!mouse.button=1.

		while (!mouse.button ne 2) do begin
			cursor, aa, dd, /change
			spixwin, pw
			oplot, [a,aa, aa, a, a] , [d,d, dd, dd, d], color=200, thick=1
		endwhile

		ia = min([a, aa])
		fa = max([a, aa])
		id = min([d, dd])
		fd = max([d, dd])
	
		ad2xy, ia, id, astr, ix, iy
		ad2xy, fa, fd, astr, fx, fy

		fx = fx > 0
		ix = ix < (size(img))[1]

		iy = iy > 0
		fy = fy < (size(img))[2]


		opixwin, ow;, pw, x1, y1, p1

		display, (img[fx:ix, iy:fy] < top) > bottom, reform(ras[fx:ix, 0]), reform(decs[0, iy:fy]) ,  aspect=xs/ys, /silent
		cpixwin, ow, pw, x2, y2, p2
		spixwin, pw
		wait, wt
	
		print, 'would you like to zoom in?  (L=no, R = yes)'
		cursor, x, y, /up
		if !mouse.button eq 1 then zoom = 0. else zoom = 1.
	endwhile




	print, 'select a scan by middle-clicking'

	while (!mouse.button ne 2) do begin
		cursor, x, y, /change
	;    print, x, y
		spixwin, pw
		d = min( (x-mhtwhc.ra_halfsec*15.)^2. + (y - mhtwhc.dec_halfsec)^2, pos)
		day = mhtwhc[pos/7.].day
		beam = pos mod 7
		whday = where(mhtwhc.day eq day)
		nwd = n_elements(whday)
		wpl = findgen(nwd/deci)*deci
		loadct, 12, /sil
		for j=0, 6 do begin
			plots, mhtwhc[whday[wpl]].ra_halfsec[j]*15., mhtwhc[whday[wpl]].dec_halfsec[j], psym=3, color=flag[whday[wpl], j]
		endfor
		loadct, 0, /sil
		plots, mhtwhc[whday].ra_halfsec[beam]*15., mhtwhc[whday].dec_halfsec[beam], psym=3
		plots, mhtwhc[pos/7.].ra_halfsec[beam]*15., mhtwhc[pos/7.].dec_halfsec[beam], psym=8, symsize=3
		if keyword_set(showspec) then begin
			restore, mhtwhc[pos/7.].fn
			whutc = where(mhtwhc[pos/7.].utcstamp eq mh.utcstamp)
			sp_sec = gsrfits(mhtwhc[pos/7.].fn, /savname, sec =whutc, beam=beam, pol=pol)
			bangp = !p
			bangx = !x
			bangy = !y
			loadct, 0, /sil
			clrch = fltarr(8192)+128
			clrch[(chsp1 < chsp2):(chsp1 > chsp2)] = 255
			for kk=0, 1 do begin
				!p.multi=[kk, 2, 1]
				plot, findgen(8192), sp_sec[*, kk], /noerase, ys=-1, xs=-1
				plots,findgen(8192), sp_sec[*, kk], color=clrch
			endfor
			!y = bangy
			!p = bangp
			!x = bangx
		endif

		xyouts, 0.1, 0.2, 'day: ' + string(day, f='(I3.3)'), /normal
		xyouts, 0.1, 0.1, 'second: ' + string(mhtwhc[pos/7.].utcstamp, f='(I10.10)'), /normal
		xyouts, 0.1, 0.15, 'beam: ' + string(beam, f='(I1.1)'), /normal
		xyouts, 0.1, 0.30, 'ra: ' + string(x), /normal
		xyouts, 0.1, 0.25, 'dec: ' + string(y), /normal
	
	endwhile
	cursor, aa, bb, /up
	!mouse.button = 1

	print, 'you may select a particular beam by middle-clicking or all beams by right-clicking'
	print, 'NOTE: you can always exit this code with ctrl-C in this window, putting the cursor in the plot window and typing retall at the prompt'

	while ((!mouse.button ne 2) and (!mouse.button ne 4)) do begin
		cursor, x, y, /change
	;    print, x, y
		spixwin, pw
		d = min( (x-mhtwhc[whday].ra_halfsec*15.)^2. + (y - mhtwhc[whday].dec_halfsec)^2, pos)
		beam = pos mod 7
		loadct, 12, /sil
		plots, mhtwhc[whday].ra_halfsec[beam]*15., mhtwhc[whday].dec_halfsec[beam], psym=3, color=flag[whday, beam]
		loadct, 0, /sil
		xyouts, 0.1, 0.2, 'day: ' + string(day, f='(I3.3)'), /normal
		xyouts, 0.1, 0.1, 'second: ' + string(mhtwhc[pos/7.].utcstamp, f='(I10.10)'), /normal
		xyouts, 0.1, 0.15, 'beam: ' + string(beam, f='(I1.1)'), /normal
	endwhile

	if !mouse.button eq 2 then bm = beam else bm = 7
	wait, 1
	!mouse.button =1

	print, 'select a starting (ending) second to blank by middle-clicking'

	while (!mouse.button ne 2) do begin
		cursor, x, y, /change
	;    print, x, y
		spixwin, pw
		d = min( (x-mhtwhc[whday].ra_halfsec[bm mod 7]*15.)^2. + (y - mhtwhc[whday].dec_halfsec[bm mod 7])^2, pos)

		if bm ne 7 then begin
			plots, mhtwhc[whday[pos]].ra_halfsec[bm]*15., mhtwhc[whday[pos]].dec_halfsec[bm], psym=3
		endif else begin
			for qq=0, 6 do plots, mhtwhc[whday[pos]].ra_halfsec[qq]*15., mhtwhc[whday[pos]].dec_halfsec[qq], psym=3
		endelse 
		xyouts, 0.1, 0.2, 'day: ' + string(day, f='(I3.3)'), /normal
		xyouts, 0.1, 0.1, 'second: ' + string(mhtwhc[pos/7.].utcstamp, f='(I10.10)'), /normal
		xyouts, 0.1, 0.15, 'beam: ' + string(beam, f='(I1.1)'), /normal
	endwhile

	pos1 = pos
	cursor, aa, bb, /up
	!mouse.button =1
	print, 'select an ending (starting) second to blank by middle-clicking'

	while (!mouse.button ne 2) do begin
		cursor, x, y, /change
	;    print, x, y
		spixwin, pw
		d = min( (x-mhtwhc[whday].ra_halfsec[bm mod 7]*15.)^2. + (y - mhtwhc[whday].dec_halfsec[bm mod 7])^2, pos)
		poss = min([pos, pos1]) + findgen((abs(pos-pos1) > 1))
		if bm ne 7 then begin
			plots, mhtwhc[whday[poss]].ra_halfsec[bm]*15., mhtwhc[whday[poss]].dec_halfsec[bm], psym=3
		endif else begin
			for qq=0, 6 do plots, mhtwhc[whday[poss]].ra_halfsec[qq]*15., mhtwhc[whday[poss]].dec_halfsec[qq], psym=3
		endelse 
		xyouts, 0.1, 0.2, 'day: ' + string(day, f='(I3.3)'), /normal
		xyouts, 0.1, 0.1, 'second: ' + string(mhtwhc[pos/7.].utcstamp, f='(I10.10)'), /normal
		xyouts, 0.1, 0.15, 'beam: ' + string(beam, f='(I1.1)'), /normal
	endwhile

	pos2 = max([pos, pos1])
	pos1 = min([pos, pos1])
	cursor, aa, bb, /up

endif else begin
	
	if n_elements(todarr) eq 1 then restore, todarr else mht = todarr
	mwtwhc = mwt
	; some code here that sets all the relevant parameters?
	window, 0, xsi=800, ysi=600
	nsecs = n_elements(utcstamps)
	if n_elements(utcstamps) ne 0 then diffs = utcstamps[1:*]-utcstamps[0:nsecs-2]
	if max(diffs) gt 1 then begin
		print, 'theses utcstamps are non-continguous, I cant hack that'
		stop
	endif
	whday = where(mhtwhc.utcstamp eq utcstamps[0])+findgen(nsecs)
	pos1 = 0
	pos2 = nsecs-1
	bm = beam
	;%%%%%%%%%%%%%%%%%%%
	;%%%%%%%%%%%%%%%%%%%
	;%%%%%%%%%%%%%%%%%%%
	;%%%%%%%%%%%%%%%%%%%
	;%%%%%%%%%%%%%%%%%%%
	;%%%%%%%%%%%%%%%%%%%
	;%%%%%%%%%%%%%%%%%%%
	;%%%%%%%%%%%%%%%%%%%
	;%%%%%%%%%%%%%%%%%%%
endelse


print, 'if you wish to blank the entire spectrum, right click. If you wish to blank only a part of the spectrum, left click'
!mouse.button =-1
cursor, x, y, /up
choice = !mouse.button

if choice eq 4 then begin
	if bm eq 7 then begin
    	for l=0, 6 do edblanks, blfile, mhtwhc[whday[pos1]].utcstamp,mhtwhc[whday[pos2]].utcstamp, l 
		endif else begin
    	    edblanks, blfile, mhtwhc[whday[pos1]].utcstamp,mhtwhc[whday[pos2]].utcstamp, bm
		endelse
endif else begin
	print, 'Retrieving TOD...'
	pp1 = whday[pos1]
	pp2 = whday[pos2]
	spectrum = fltarr(8192, 2)
	spectra = fltarr(8192, 2, 7, pp2-pp1+1)
	fns = mhtwhc[pp1:pp2].fn
	ufns = fns(uniq(fns, sort(fns)))
	for i=0, n_elements(ufns)-1 do begin
		whfn = where(fns eq ufns[i])
		restore, ufns[i]
		for j=0, n_elements(whfn)-1 do begin
			whs = where(mh.utcstamp eq mhtwhc[pp1+whfn[j]].utcstamp, ct)
			if ct ne 1 then stop
			data = gsrfits(fns[whfn[j]], /savname, sec=whs)
			spectra[*, *, *, whfn[j]] = data
			if keyword_set(badrxfile) then begin
				whichrx, mh[0].UTCSTAMP, goodrx, badrxfile=badrxfile
				data =reform(data, 8192, 2, 7, 1)
				fixrx, data, goodrx
				data = reform(data)
			endif	
			if bm eq 7 then spectrum = spectrum + total(data, 3)/7. else spectrum = spectrum + data[*, *, bm]
		endfor
	endfor	
	spectrum = spectrum/(pp2-pp1+1)
	; in TOD space
	del_vel=-2.99792458e+5*((100./14.)/8192.)/1420.405751786
    all_vel = del_vel*(findgen(8192)-4095.5)	
	; in cube space
	if ~keyword_set(imskip) then begin
		vv = (findgen(sxpar(hdr, 'NAXIS3')) - (sxpar(hdr, 'CRPIX3') -1))*sxpar(hdr, 'CDELT3')*1d-3 + sxpar(hdr, 'CRVAL3')*1d-3
		vel1 = vv[v1]
		vel2 = vv[v2]
		opixwin, ow1
	endif else begin
		;print, 'NB: the width of the zoom you choose will determine the blank width'; HOW????
		vel1 = min(all_vel)
		vel2 = max(all_vel)
	endelse
	
	plot, all_vel, spectrum[*, 0]
	oplot, all_vel, spectrum[*, 1], color=128
	oplot, [vel1, vel1], !y.crange
	oplot, [vel2, vel2], !y.crange

	cpixwin, ow1, pw1, x2, y2, p2
	spixwin, pw1
	
	
	print, 'would you like to zoom in?  (left click=no, right click = yes)'

	cursor, x, y, /up
	if !mouse.button eq 1 then zoom = 0. else zoom = 1.

	while zoom eq 1 do begin

		print, 'middle buton to select'
		!mouse.button=1.
		while (!mouse.button ne 2) do begin
			cursor, x, y, /change
			spixwin, pw1
			plots, x, y, psym=1, color=200, thick=1., symsize=2
		endwhile

		ropixwin, ow1, pw1, x2, y2, p2
		plots, x, y, psym=1, color=200, thick=1., symsize=2
		cpixwin, ow1, pw1, x2, y2, p2
		wait, wt
		!mouse.button=1.

		while (!mouse.button ne 2) do begin
			cursor, xx, yy, /change
			spixwin, pw1
			oplot, [x,xx, xx, x, x] , [y,y, yy, yy, y], color=200, thick=1
		endwhile

		ix = min([x, xx])
		ax = max([x, xx])
		iy = min([y, yy])
		ay = max([y, yy])

		opixwin, ow1;, pw, x1, y1, p1
		;loadct, 0, /silent
		plot, all_vel, spectrum[*, 0], /ynozero, xra=[ix, ax], yra=[iy, ay], xtitle='velocity', ytitle='T_B[K]'
		oplot, all_vel, spectrum[*, 1], color=128
		oplot, [vel1, vel1], !y.crange
		oplot, [vel2, vel2], !y.crange
		cpixwin, ow1, pw1, x2, y2, p2
		spixwin, pw1
		wait, wt
	
		print, 'would you like to zoom in?  (L=no, R = yes)'
		cursor, x, y, /up
		if !mouse.button eq 1 then zoom = 0. else zoom = 1.
	endwhile

	if keyword_set(imskip) then begin
		vel1 = ix
		vel2 = ax
	endif	
	
	; deal with the case where only 1 polarization is "good"
	; by forcing both pols
	!mouse.button = 0
	if keyword_set(badrxfile) and (bm ne 7) then begin
		if total(goodrx[*, bm]) ne 2 then begin
			!mouse.button = 2
			print, 'forcing selection of both (identical) pols as one pol is badrxed'
		endif		
	endif
	
	if !mouse.button eq 0 then begin
		print, 'Fix pol A (white), pol B (gray), or both? (L=pol A, C= both, R= pol B)'
		cursor, x, y, /up
	endif
	
	if !mouse.button eq 1 then begin
		pol = 0
		print, 'pol A (white) selected'
	endif	
	if !mouse.button eq 4 then begin
		pol = 1
		print, 'pol B (gray) selected'
	endif
	if !mouse.button eq 2 then begin
		pol = 2
		print, 'both pols selected'
	endif
	print, 'select a region to excerpt'
	!mouse.button=0
	if pol ne 2 then begin
		while (!mouse.button ne 2) do begin
    		cursor, xx, yy, /change
    		mn = min( ((xx-all_vel)/(!x.crange[1]-!x.crange[0]))^2 + ((yy-spectrum[*, pol])/(!y.crange[1]-!y.crange[0]))^2, close)
    		spixwin, pw1
    		plots, all_vel[close], spectrum[close, pol], psym=8, syms=3
		endwhile
	endif else begin
		while (!mouse.button ne 2) do begin
	    	cursor, xx, yy, /change
    		mn = min( abs(xx-all_vel), close)
    		spixwin, pw1
    		plots, [xx, xx], !y.crange
		endwhile
	endelse 
	
	cursor, aa, bb, /up
	!mouse.button =1
	loadct, 13, /sil
	if pol ne 2 then begin
		while (!mouse.button ne 2) do begin
   		 	cursor, xx2, yy2, /change
    		mn = min( ((xx2-all_vel)/(!x.crange[1]-!x.crange[0]))^2 + ((yy2-spectrum[*, pol])/(!y.crange[1]-!y.crange[0]))^2, close2)
    		spixwin, pw1
    		plots, all_vel[min([close, close2]):max([close, close2])], spectrum[min([close, close2]):max([close, close2]), pol], thick=2
		endwhile
	endif else begin
		while (!mouse.button ne 2) do begin
   		 	cursor, xx2, yy2, /change
    		mn = min( abs(xx2-all_vel), close2)
    		spixwin, pw1
    		plots, all_vel[min([close, close2]):max([close, close2])], spectrum[min([close, close2]):max([close, close2]), 0], thick=2
    		plots, all_vel[min([close, close2]):max([close, close2])], spectrum[min([close, close2]):max([close, close2]), 1], thick=2
		endwhile
	endelse
	c0 = min([close, close2])
	c1 = max([close, close2])
	nchan = c1-c0+1
	;sptot = total(spectra, 4)/(pp2-pp1+1)
	;y0s = fltarr(2, 7)
	;y1s = y0s
	;for i=0, 1 do begin
	;	for j=0, 6 do begin
	;		y0s[i, j] = reform(sptot[c0, i, j])
	;		y1s[i, j] = reform(sptot[c1, i, j])
	;	endfor
	;endfor
	
	;spectra_rem = spectra*0.
	;for i=0, 1 do begin
	;	for j=0, 6 do begin
	;		for k=0, pp2-pp1 do begin
	;			spectra_rem[*, i, j, k] = spectra[*, i, j, k] - (((y1s[i,j]-y0s[i,j])/(float(c1)-float(c0))*(findgen(8192)-c0) + y0s[i,j]))
	;			spectra_rem[0:c0, i, j, k] =0
	;			spectra_rem[c1:*, i, j, k] =0
	;		endfor
	;	endfor
	;endfor
	
	loadct, 0, /sil
	cursor, aa, bb, /up
	;ix_ind = interpol(findgen(8192), all_vel, ix)
	;ax_ind = interpol(findgen(8192), all_vel, ax)
	
	print, 'What kind of spectral cleaning would you like to do  (L=Blanking, C= Bootstrap blank to Gauss, R = Gaussian fitting)'
	cursor, x, y, /up
	bootstrap=0
	if !mouse.button eq 2 then bootstrap=1
	if !mouse.button eq 1 then usegauss = 0 else usegauss = 1

	if usegauss then begin
	print, 'using Gaussian fitting'
	if bootstrap then print, 'Using bootstrap to blanks'
	if bm ne 7 then begin
		fits = fltarr(20, 1 + (pol eq 2), (pp2-pp1+1))
		fits[0, *, *] = 1
		fits[1, *, *] = c0
		fits[2, *, *] = c1
		fitspecs = fltarr(c1-c0+1, 1 + (pol eq 2), (pp2-pp1+1))
		clnspecs = fltarr(c1-c0+1, 1 + (pol eq 2), (pp2-pp1+1))
		window, 1, xsi=1400, ysi=400
		!p.multi=0
		;loop over only the spectra of interest
		for i=pol - 2*(pol eq 2), pol - (pol eq 2) do begin
		;	display, reform(spectra[c0:c1, i, bm, *])
			for j= 0, pp2-pp1 do begin
				ft = fits[*, i, j]
				; get fit parameters
				ds = dilshod(1, ft, spectra[*, i, bm, j], 1)
				; use them to get fit spectrum
				spout=0
				ds = dilshod(1, ft, spout, 2)
				fitspecs[*, i*(pol eq 2), j] = (c0+findgen(c1-c0+1))*ft[7] + ft[6] + spout[c0:c1] 
				clnspecs[*, i*(pol eq 2), j] = spectra[c0, i, bm, j] - spout[c0:c1] 
				fits[*, i*(pol eq 2), j] = ft
			endfor
			display, [reform(spectra[c0:c1, i, bm, *]), reform(fitspecs[*, i*(pol eq 2), *]), reform(clnspecs[*, i*(pol eq 2), *])], aspect=2
		endfor
	endif

	if bm eq 7 then begin
		fits = fltarr(20, 1 + (pol eq 2), 7, (pp2-pp1+1))
		fits[0, *, *, *] = 1
		fits[1, *, *, *] = c0
		fits[2, *, *, *] = c1
		fitspecs = fltarr(c1-c0+1, 1 + (pol eq 2), 7, (pp2-pp1+1))
		clnspecs = fltarr(c1-c0+1, 1 + (pol eq 2), 7, (pp2-pp1+1))
		window, 1, xsi=600*(1+(pol eq 2)), ysi=1200
		!p.multi=[0, 1+ (pol eq 2), 7]
		for j=0, 6 do begin
			for i=pol - 2*(pol eq 2), pol - (pol eq 2) do begin
				for k= 0, pp2-pp1 do begin
					ft = fits[*, i*(pol eq 2), j, k]
					; get fit parameters
					ds = dilshod(1, ft, spectra[*, i, j, k], 1)
					; use them to get fit spectrum
					spout=0
					ds = dilshod(1, ft, spout, 2)
					fitspecs[*, i*(pol eq 2), j, k] = (c0+findgen(c1-c0+1))*ft[7] + ft[6] - spout[c0:c1] 
					clnspecs[*, i*(pol eq 2), j, k] = spectra[c0:c1, i, j, k] + spout[c0:c1] 
					fits[*, i*(pol eq 2), j, k] = ft
				endfor
			display, [ reform(spectra[c0:c1, i, j, *]), reform(fitspecs[*, i*(pol eq 2), j, *]), reform(clnspecs[*, i*(pol eq 2), j, *])], aspect=2
			endfor
		endfor
	endif
	
	!mouse.button =2
	
	window, 2, xsi=1000, ysi=400
	!p.multi=[0, 3, 1]
	if bm eq 7 then wh = where(total(fits[3:5, *, *, *], 1) ne 0, ctwh) else wh = where(total(fits[3:5, *, *], 1) ne 0, ctwh) 
	if ctwh eq 0 then stop
	rfits = reform(fits, 20, (1 + (pol eq 2))*(1 + 6*(bm eq 7))*(pp2-pp1+1))
	plot, rfits[4, wh], rfits[3, wh], psym=3, charsize=2, /xs, /ys, /ynoz, xtitle='Centroid [channel]', ytitle='Amplitude [K]'
	plot, rfits[4, wh], rfits[5, wh], psym=3, charsize=2, /xs, /ys, /ynoz, xtitle='Centroid [channel]', ytitle='Width [channels]'
	plot, rfits[3, wh], rfits[5, wh], psym=3, charsize=2, /xs, /ys, /ynoz, xtitle='Amplitude [K]', ytitle='Width [channels]'
	print, 'Which metric would you prefer to use to select which fits to keep? (L= C vs. A, M = C vs. W , R = A vs. W)'
	cursor, x, y, /up
	if !mouse.button eq 1 then begin
		xax = 4
		yax = 3
	endif
	if !mouse.button eq 2 then begin
		xax = 4
		yax = 5
	endif
	if !mouse.button eq 4 then begin
		xax = 3
		yax = 5
	endif
	
		
	print, 'select a collection of points to use in the fit'

	select = 1
	while select eq 1 do begin

		titles = ['Amplitude [K]', 'Centroid [channel]', 'Width [channels]']
		opixwin, ow2
		!p.multi=0
		plot, rfits[xax, wh], rfits[yax, wh], psym=3, charsize=2, /xs, /ys, /ynoz, xtitle=titles[xax-3], ytitle=titles[yax-3]
		cpixwin, ow2, pw2, x3, y3, p3
		spixwin, pw2

		print, 'middle buton to select'
		!mouse.button=1.
		while (!mouse.button ne 2) do begin
    		cursor, x, y, /change
			spixwin, pw2
		    plots, x, y, psym=1, color=200, thick=1., symsize=2
		endwhile

		cursor, null1, null2, /up
		ropixwin, ow2, pw2, x3, y3, p3
		plots, x, y, psym=1, color=200, thick=1., symsize=2
		cpixwin, ow2, pw2, x3, y3, p3
		!mouse.button=1.

		while (!mouse.button ne 2) do begin
    		cursor, xx, yy, /change
    		spixwin, pw2
  	  		oplot, [x,xx, xx, x, x] , [y,y, yy, yy, y], color=200, thick=1
		endwhile

		bx = min([x, xx])
		tx = max([x, xx])
		by = min([y, yy])
		ty = max([y, yy])
		cursor, aa, bb, /up
		whsel = where( (rfits[xax, wh] gt bx) and (rfits[xax, wh] lt tx) and (rfits[yax, wh] gt by) and (rfits[yax, wh] lt ty), ctsel)

		if ctsel ne 0 then oplot, rfits[xax, wh[whsel]], rfits[yax, wh[whsel]], psym=1

		print, 'Do you like this selection? (L=no, R = yes)'
		cursor, x, y, /up
		if !mouse.button eq 4 then select = 0. else select = 1.
	endwhile
	
	mask = reform(spectra[0, *, *, *])*0
	mask[wh[whsel]] = 1.
	meq1 = where(mask eq 1)
	
	print, 'Do you like these fits? (L=no, R = yes)'
	cursor, x, y, /up

	if !mouse.button eq 4 then begin
		if bm eq 7 then begin
			beams = reform(rebin(reform(findgen(7), 1, 7, 1), 1 + (pol eq 2), 7, (pp2-pp1+1)), (1 + (pol eq 2))*7*(pp2-pp1+1))
			pols =  reform(rebin(reform(findgen(1 + (pol eq 2)) + pol*(pol ne 2), 1 + (pol eq 2), 1, 1), 1 + (pol eq 2), 7, (pp2-pp1+1)),(1 + (pol eq 2))*7*(pp2-pp1+1))
			utcs = reform(rebin(reform(mhtwhc[pp1:pp2].utcstamp, 1, 1, (pp2-pp1+1.)), 1 + (pol eq 2), 7, (pp2-pp1+1)),(1 + (pol eq 2))*7*(pp2-pp1+1))
			fitps = reform(fits, 20, (1 + (pol eq 2))*7*(pp2-pp1+1))
			if bootstrap eq 0 then begin 
				print, 'applying Gaussian fits'
				edspblanks, spblfile, utcs[meq1], beams[meq1], pols[meq1], fitps[*, meq1] 
			endif else begin
				print, 'applying blanks bootstrapped from Gaussian fit locations'
				fitps[0, *] = 0.
				fitps[3:*, *] = 0.
				edspblanks, spblfile, utcs[meq1], beams[meq1], pols[meq1], fitps[*, meq1]
			endelse
		
		endif else begin
			beams = reform(rebin(reform(bm, 1, 1), 1 + (pol eq 2), (pp2-pp1+1)), (1 + (pol eq 2))*(pp2-pp1+1))
			pols = reform(rebin(reform(findgen(1 + (pol eq 2))+ pol*(pol ne 2), 1 + (pol eq 2), 1), 1 + (pol eq 2), (pp2-pp1+1)),(1 + (pol eq 2))*(pp2-pp1+1))
			utcs = reform(rebin(reform(mhtwhc[pp1:pp2].utcstamp, 1, (pp2-pp1+1.)), 1 + (pol eq 2), (pp2-pp1+1)),(1 + (pol eq 2))*(pp2-pp1+1))
			fitps = reform(fits, 20, (1 + (pol eq 2))*(pp2-pp1+1))
			if bootstrap eq 0 then begin 
				print, 'applying Gaussian fits'
				edspblanks, spblfile, utcs[meq1], beams[meq1], pols[meq1], fitps[*, meq1] 
			endif else begin
				print, 'applying blanks bootstrapped from Gaussian fit locations'
				fitps[0, *] = 0.
				fitps[3:*, *] = 0.
				edspblanks, spblfile, utcs[meq1], beams[meq1], pols[meq1], fitps[*, meq1]
			endelse
		endelse
	endif else begin
		print, 'stopping code: type .cont to finish with no file editing'
		stop
	endelse
	
endif else begin
	; blanking code
	if bm eq 7 then begin
			beams = reform(rebin(reform(findgen(7), 1, 7, 1), 1 + (pol eq 2), 7, (pp2-pp1+1)), (1 + (pol eq 2))*7*(pp2-pp1+1))
			pols =  reform(rebin(reform(findgen(1 + (pol eq 2)) + pol*(pol ne 2), 1 + (pol eq 2), 1, 1), 1 + (pol eq 2), 7, (pp2-pp1+1)),(1 + (pol eq 2))*7*(pp2-pp1+1))
			utcs = reform(rebin(reform(mhtwhc[pp1:pp2].utcstamp, 1, 1, (pp2-pp1+1.)), 1 + (pol eq 2), 7, (pp2-pp1+1)),(1 + (pol eq 2))*7*(pp2-pp1+1))
			fitps = fltarr(20, (1 + (pol eq 2))*7*(pp2-pp1+1))
			fitps[1, *] = c0
			fitps[2, *] = c1
			edspblanks, spblfile, utcs, beams, pols, fitps
	endif else begin
			beams = reform(rebin(reform(bm, 1, 1), 1 + (pol eq 2), (pp2-pp1+1)), (1 + (pol eq 2))*(pp2-pp1+1))
			pols = reform(rebin(reform(findgen(1 + (pol eq 2))+ pol*(pol ne 2), 1 + (pol eq 2), 1), 1 + (pol eq 2), (pp2-pp1+1)),(1 + (pol eq 2))*(pp2-pp1+1))
			utcs = reform(rebin(reform(mhtwhc[pp1:pp2].utcstamp, 1, (pp2-pp1+1.)), 1 + (pol eq 2), (pp2-pp1+1)),(1 + (pol eq 2))*(pp2-pp1+1))
			fitps = fltarr(20, (1 + (pol eq 2))*(pp2-pp1+1))
			fitps[1, *] = c0
			fitps[2, *] = c1
			edspblanks, spblfile, utcs, beams, pols, fitps
	endelse
endelse

endelse

end
