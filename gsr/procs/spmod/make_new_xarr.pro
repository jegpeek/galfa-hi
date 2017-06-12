pro make_new_xarr, nsin, fn

x01 = fltarr(1+2*nsin, 8192)

x01[0, *] = 1.

for i=1, nsin do begin
	x01[i, *] = sin(i*2*!pi*findgen(8192)/8192.)
	x01[i+nsin, *] = cos(i*2*!pi*findgen(8192)/8192.)
endfor

save, x01, f=fn

end