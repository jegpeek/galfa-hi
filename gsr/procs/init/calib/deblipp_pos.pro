pro deblip_pos, data, s1, ch

sz = size(data)
; an 80 x sz[4] array of amplitude
data_av = smooth(total(total(rebin([data, fltar(8000-7679,2, 7, sz[4])], 80, 2, 7, sz[4]),2), 2) [3, 1])

data_blip = data_av-shift(data_av, [0, 1])
b_amp = fltarr(80, 12)

; a blip matched mask
comb = fltarr(sz[4])
comb[findgen(sz[4]/12.)*12] = 1.

for i=0, 11 do begin
    cshift = shift(comb, i]
    ; to not shift points off the end
    if i ne 0 then cshift[0:i]= 0
    for j=0, 79 do begin
        b_amp[j, i] = total(cshift*data_blip[j,i])
    endfor
endfor

is_blip = max(b_amp, xx)/stddev(b_amp)

;5 sigma cutoff?
if is_blip gt 5 then begin
    s1 = xx / 80
    ch = xx mod 80
endif else begin
    s1 = -1
    ch = 0
endelse

end
