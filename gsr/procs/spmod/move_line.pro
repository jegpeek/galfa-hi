function move_line, ow, pw, side, cen

!mouse.button = 4
box = [0, 1, 1, 0, 0]
spixwin, pw
a=0
while ((!mouse.button ne 1) and (!mouse.button ne 2)) do begin
	cursor, a, d, /change
	spixwin, pw
	plots, ([a, a] > cen)*side + ([a, a] < cen)*(1-side), !y.crange, color=200, thick=1.
	oplot, [cen, cen, 2*cen*side, 2*cen*side, cen], (!y.crange)[box], thick=3
	if ((a-cen) gt 0) and side eq 0 then !mouse.button = 4
	if ((a-cen) lt 0) and side eq 1 then !mouse.button = 4
endwhile

return, a
end