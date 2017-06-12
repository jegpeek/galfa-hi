pro deblip_clean, data, slist, sp, offx

sz = size(data)
for i=0, 1 do begin
    for j=0, 6 do begin
        for k = 0, sz[4]-1 do begin
            data[*, i, j, k] = data[*, i, j, k] - shift(slist[i,j,k]*sp, offx[k])
        endfor
    endfor
endfor



end
