; interactive code for finding baseline ripple fits
; spec -- the spectrum to fit
; wgt0 -- initital weights -- either zero or one
; eoc -- the equations of conditions matrix
; LRval -- the edges of the core we weight to zero
; fit -- the final fit to the ripple

pro blinter, spec, wgt0, eoc, scan, LRval, fit

; the width of the spectrum
ny = n_elements(spec)
; and its center
cen = ny/2.
; the initial guess of the bounding region of HI we wish not to fit
LRval = [cen, cen]
; starting on the left side
side = 0
; initializing the weight matrix
wgt = wgt0
; finding any nans
whinf = where(finite(spec) eq 0, ctinf)
if ctinf ne 0 then begin
	spec[whinf] = 0
	wgt[whinf] =0
endif

yw = spec*wgt0
eocw = eoc*rebin(reform(wgt, 1, ny), (size(eoc))[1], ny)
eocwinv = transpose(eocw)#invert(eocw#transpose(eocw))
a = Yw#eocwinv
fit = eoc##a
loadct, 0, /sil
; some code for dealing with interactive windows
opixwin, ow
; plot the data
loadct, 0, /sil
plot, spec, /xs, yra=[-1, 1], title="scan = " + scan
loadct, 13, /sil
; overplot the weighted fit
oplot, fit
; plot the bounding areas
oplot, fltarr(2)+LRval[0], !y.crange
oplot, fltarr(2)+LRval[1], !y.crange
; and the weights on the same scale
oplot, wgt*0.1 -0.9
loadct, 13, /sil
cpixwin, ow, pw, x1, y1, p1 & spixwin, pw
cursor, junk, junk1, /up

while (!mouse.button ne 2) do begin
	; code for having an interactive moving line
	a = move_line(ow, pw, side, cen)
	if (!mouse.button ne 2) then LRVal[side] = a
	wgt = wgt0
	; set weights to exclude the HI line
	wgt[LRval[0]:LRval[1]] = 0
	; run the weighted fit
	yw = spec*wgt
	eocw = eoc*rebin(reform(wgt, 1, ny), (size(eoc))[1], ny)
	eocwinv = transpose(eocw)#invert(eocw#transpose(eocw))
	a = Yw#eocwinv
	fit = eoc##a
	opixwin, ow
	loadct, 0, /sil
	plot, spec, /xs, yra=[-1, 1], title="scan = " + scan
	loadct, 13, /sil
	; overplot the weighted fit
	oplot, fit
	oplot, fltarr(2)+LRval[0], !y.crange
	oplot, fltarr(2)+LRval[1], !y.crange
	oplot, wgt*0.1 -0.9
	loadct, 0, /sil
	cpixwin, ow, pw, x1, y1, p1 & spixwin, pw
	side = 1-side
	cursor, x, y, /up
endwhile

wgt0 = wgt

end



