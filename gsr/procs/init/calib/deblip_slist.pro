pro deblip_slist, data, s1, ch, nc, slist, bl_data

sz = size(data)
; this is the number of blips (tested)
nbl = floor(sz[4]/12.) + (s1 lt (sz[4] - floor(sz[4]/12.)*12.))

bl_data = fltarr(7679, 2, 7, nbl)
for i=0, nbl-1 do begin
    pon = s1+12*i
    poff = s1+12*i + 1
    ; so as not to run off the end of the time axis, or loop
    if poff gt (sz[4]-1) then poff = poff-2
    bl_data[*, *, *, i] = smooth(data[*, *, *, pon] - data[*, *, *, poff], [8000./nc, 1, 1])
endfor

slist = fltarr(2, 7, sz[4])
for i=0, 1 do begin
    for j=0, 6 do begin
        for k=0, nbl-1 do begin
            slist[i, j, s1+k*12] = max(bl_data[ch*(8000./nc):ch*(8000./nc)+(8000./nc-1) < 7678, i, j, k])
            if slist[i, j, s1+k*12] lt 3*stddev(bl_data[*, i, j, k]) then slist[i, j, s1+k*12] = 0.
        endfor
    endfor
endfor




end
 
