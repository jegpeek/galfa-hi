; the interior code to xfit, called by allx1basket

pro xf1, xarr, outx

f=3.
xaxis = findgen(8192)- 4096 + 0.5

if (size(size(xarr)))[1] ne 4 then xarr = reform(xarr, 1)

l = (size(xarr))[1]
outx = replicate({scan1:0., beam1:0., time1:0l, fn1bef:'null', fn1aft:'null', W1:0., scan2:0., beam2:0., time2:0l, fn2bef:'null', fn2aft:'null', W2:0., XRA:0., Xdec:0., ZPTR:0., GAINR:0., sigab:fltarr(2)}, l) 
for k=0l, l-1 do begin
	; noise in each beam:
	std1 = stddev(xarr[k].spect1[where(xarr[k].spect1 ne 0.)])
	std2 = stddev(xarr[k].spect2[where(xarr[k].spect2 ne 0.)])
	; where the fit isn't too off of 1.
	wh = where( (xarr[k].spect1 ne 0.) and (xarr[k].spect2 ne 0.) and ((xarr[k].spect1 lt f*std1) and (xarr[k].spect2 lt f*std2) or ((xarr[k].spect2/xarr[k].spect1 gt 0.5) and (xarr[k].spect2/xarr[k].spect1 lt 2.0))))
  ;  sqrt((xarr[k].spect1/std1)^2+(xarr[k].spect2/std2)^2) gt 3.5
	A1=0.
	A2=0.
	B1=0.
	B2=0.
 ; to get rid of continuum in each line
	if (keyword_set(conrem)) then begin
		wh1 = where( (xarr[k].spect1 ne 0.) and (abs(xaxis) gt 512))
		wh2 = where( (xarr[k].spect2 ne 0.) and (abs(xaxis) gt 512))
		fitexy, xaxis[wh1], xarr[k].spect1[wh1], A1, B1, X_SIG=1. , Y_SIG=1.
		fitexy, xaxis[wh2], xarr[k].spect2[wh2], A2, B2, X_SIG=1. , Y_SIG=1.
	endif
	s1 = xarr[k].spect1[wh] - (A1 + B1*xaxis)[wh]
	s2 = xarr[k].spect2[wh] - (A2 + B2*xaxis)[wh]

	s1(where(sqrt((s1/std1)^2+(s2/std2)^2) lt 3.5)) = 0.
	s2(where(sqrt((s1/std1)^2+(s2/std2)^2) lt 3.5)) = 0.

	fitab = mpFITEXY(s2, s1, std2, std1,error=sig_a_b, /silent)
	outx[k].gainr=fitab[0]
	outx[k].zptr= fitab[1]
	outx[k].sigab = reverse(sig_a_b)


endfor

outx.scan1 = xarr.scan1
outx.beam1 = xarr.beam1
outx.time1 = xarr.time1
outx.fn1bef = xarr.fn1bef
outx.fn1aft = xarr.fn1aft
outx.W1 = xarr.W1
outx.scan2 = xarr.scan2
outx.beam2 = xarr.beam2
outx.time2 = xarr.time2
outx.fn2bef = xarr.fn2bef
outx.fn2aft = xarr.fn2aft
outx.W2 = xarr.W2
outx.XRA = xarr.XRA
outx.Xdec = xarr.Xdec


end