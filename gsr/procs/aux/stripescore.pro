; a bit of code to assess how stripey the cube is

function stripescore, cube, ch0, ch1

sz = size(cube)
if (sz[1] ne 512) or (sz[2] ne 512) then print, 'Hey, this is only for 512 x 512 cubes!'
ssch = fltarr(ch1-ch0+1)
for ch= ch0, ch1 do begin
	loop_bar, ch-ch0, ch1-ch0
	img = cube[*, *, ch]
	on = total((rot(shift(alog10(fft(img)*conj(fft(img))), 256, 256), 9.346))[*, 256])
	off1 = total((rot(shift(alog10(fft(img)*conj(fft(img))), 256, 256), 8.346))[*, 256])
	off2 = total((rot(shift(alog10(fft(img)*conj(fft(img))), 256, 256), 10.346))[*, 256])
	ssch[ch-ch0] = on-(off1 + off2)/2.
endfor

return, ssch
end