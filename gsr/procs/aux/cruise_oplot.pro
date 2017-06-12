pro cruise, cube, v, mask=mask, vrng=vrng, cont=cont, level=level, ra0=ra0, dec0=dec0
sz = size(cube)
if not keyword_set(mask) then mask = fltarr(sz[1], sz[2]) + 1
if not keyword_set(vrng) then vrng = findgen(sz[3])
if not keyword_set(ra0) then ra0 = findgen(sz[1])
if not keyword_set(dec0) then dec0 = findgen(sz[2])

display, cube[*, *, 0]*mask, ra0, dec0, aspect=1.
!mouse.button=0.
while !mouse.button ne 1 do begin
    cursor, x, y, /change, /norm
    v = (x*sz[3] < sz[3]) > 0.
    display, cube[*, *, v]*mask, ra0, dec0, aspect=1.
    if keyword_set(cont) then contour, cont, level=level, /overplot 
    xyouts, 0.1, 0.1, vrng(v), /norm, charsize=1.5, charthick=1.5
endwhile

end
