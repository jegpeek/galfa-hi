pro deblip_pos, data, s1, ch, nc

nc = 40

sz = size(data)
; an nc x 2 x 7 x sz[4] array of amplitude
data_av = smooth(rebin([data, fltarr(8000-7679,2, 7, sz[4])], nc, 2, 7, sz[4]), [3, 1, 1, 1])

data_blip = data_av-shift(data_av, [0, 0, 0,1])
;data_blip[*, *, *, sz[4]-1] =0.
data_blip[*, *, *, 0] =0.

b_amp = fltarr(nc, 2, 7, 12)

; a blip matched mask
comb = fltarr(sz[4])
comb[findgen(sz[4]/12.)*12] = 1.

for i=0, 11 do begin
    cshift = shift(comb, i)
    ; to not shift points off the end
    if i ne 0 then cshift[0:i-1]= 0
    for j=0, nc-1 do begin
        for k=0, 1 do begin
            for l=0, 6 do begin
                b_amp[j, k, l, i] = total(cshift*data_blip[j,k, l,*])
            endfor
        endfor
    endfor
endfor

is_blip = max(b_amp, xx)/stddev(b_amp)

;5 sigma cutoff?
if is_blip gt 5 then begin
    ch = xx mod nc
    s1 = floor(xx/(nc*2.*7.))
endif else begin
    s1 = -1
    ch = 0
endelse

end
