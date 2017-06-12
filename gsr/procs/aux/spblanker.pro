pro spblanker, data, mh, spblfile, spblank

blout=1
applyspbl, data, mh.utcstamp, spblfile, /noblank, blankout=blout
wh0bad = where(blout[*, 0, *, *] eq 1, ct0)
wh1bad = where(blout[*, 1, *, *] eq 1, ct1)
; overwrite bad data with opposite pol
; RIP 2 weeks of my life fixing this bug. -- JEGP
if ct0 ne 0 then begin
	polslice0 = reform(data[*, 0, *, *])
	polslice1 = reform(data[*, 1, *, *])
	polslice0[wh0bad] = polslice1[wh0bad]
	data[*, 0, *, *] = polslice0
endif
if ct1 ne 0 then begin
	polslice0 = reform(data[*, 0, *, *])
	polslice1 = reform(data[*, 1, *, *])
	polslice1[wh1bad] = polslice0[wh1bad]
	data[*, 1, *, *] = polslice1
endif
; bad in both pols, pass to gridder to get rid of
spblank = total(blout, 2) eq 2

end