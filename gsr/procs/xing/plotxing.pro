; A procedure for plotting XING fits to spectra

pro plotxing, root, region, scans, proj, xingname=xingname, ratio_resid=ratio_resid, noplot=noplot

!p.multi=[0, 7, 7]

xm = !x.margin
ym = !y.margin

!y.margin=[0, 0]
!x.margin=[0,0]
path = root + proj + '/' + region + '/xing/'
fns = file_search(path, '*_f.sav')

nf = n_elements(fns)

ratio_resid = fltarr(7, 7, scans, scans)

for q=0, nf-1 do begin
	restore, fns[q]
	rac = xfit[n_elements(xfit)/2.].xra
	mmxfit = minmax(xfit.scan1)
	; if this is not AUTO and we have a xingname, go get the right hdrs and gain files
	if mmxfit[1]-mmxfit[0] eq 0 and keyword_set(xingname) then begin
		restore, root + proj + '/' + region + '/' + region + '_' + string(xfit[0].scan1, f='(I3.3)') + '/' + '*hdrs*'
		times1 = mh.utcstamp
		restore, root + proj + '/' + region + '/' + region + '_' + string(xfit[0].scan1, f='(I3.3)') + '/' + '*'+xingname+'*'
		gain1 = gain
		restore, root + proj + '/' + region + '/' + region + '_' + string(xfit[0].scan2, f='(I3.3)') + '/' + '*hdrs*'
		times2 = mh.utcstamp
		restore, root + proj + '/' + region + '/' + region + '_' + string(xfit[0].scan2, f='(I3.3)') + '/' + '*'+xingname+'*'
		gain2 = gain
		
		wh1_init = (where(times1 eq xfit[0].time1))[0]
		wh2_init = (where(times1 eq xfit[0].time2))[0]
		
		whtime1 = xfit.time1-xfit[0].time1 + wh1_init
		whtime2 = xfit.time2-xfit[0].time2 + wh2_init

		fitgains1 = gain1[xfit.beam1, whtime1]
		fitgains2 = gain2[xfit.beam2, whtime2]
                
		gainr_fit = fitgains1/fitgains2
	endif

	for j=0, 6 do begin
		for i=0, 6 do begin
			wh = where(xfit.beam1 eq i and xfit.beam2 eq j, ct)
			if ct gt 1 then begin
				loadct, 0, /sil
				racenter = ((xfit[wh].xra-rac + 24+12) mod 24) -12
				if not keyword_set(noplot) then begin
					plot, racenter, xfit[wh].gainr, yra=[0.7, 1.3], psym=3, xminor=-1, yminor=-1, /ys
					loadct, 13, /sil
					if keyword_set(xingname) then oplot, racenter, gainr_fit[wh]
					loadct, 0, /sil
					xyouts, i/7.+0.12, (6-j)/7.+0.012, string(i, f='(I1.1)') + '/' +string(j, f='(I1.1)'), /normal
					;
				endif
				ratio_resid[i, j, xfit[0].scan1, xfit[0].scan2] = median(alog10(gainr_fit[wh])-alog10(xfit[wh].gainr))
				ratio_resid[i, j, xfit[0].scan2, xfit[0].scan1] = median(alog10(xfit[wh].gainr)-alog10(gainr_fit[wh]))
			endif else begin
				
			endelse 
		endfor
	endfor	
        short_fn = (reverse(strsplit(fns[q], '/', /extract)))[0]
       if not keyword_set(noplot) then xyouts, 0.5, 0.97, short_fn, align=0.5, /normal, charsize=2
       if not keyword_set(noplot) then wait, 0.1
        if q lt (nf-1) then begin        
           print, 'type ".cont" to look at more XING files'
           stop
        endif
endfor

!x.margin = xm
!y.margin = ym


end
