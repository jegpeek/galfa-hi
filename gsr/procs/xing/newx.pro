function newx, mh1, fn1, beam1, scan1, fp1,  mh2, fn2, beam2, scan2, fp2, outx, link=link

; tested value, optimized
res=0.03

timestart = systime(/seconds)

;dec and ra of the first scan
med = median(mh1.dec_halfsec[beam1])
if keyword_set(link) then dec1 = med + (findgen(n_elements(mh1)) mod 2)*0.04 else dec1 = mh1.dec_halfsec[beam1]
RA1 = mh1.RA_halfsec[beam1]

; dec and ra of the second scan

if keyword_set(link) then dec2 = med + (findgen(n_elements(mh2)) mod 2)*0.04 else dec2 = mh2.dec_halfsec[beam2]
RA2 = mh2.RA_halfsec[beam2]
n = n_elements(dec2)


mid = 0
while (( max([ra1,ra2]) - min([ra1, ra2]) ) gt 23) do begin
    if mid gt 23 then break
    mid = mid +1.
;    print, mid

    ra1 = (ra1 + 1) mod 24
    ra2 = (ra2 + 1) mod 24
endwhile

;seed of the crossing pt structure.
outx = {scan1:scan1, beam1:beam1, time1:0l, pos1bef:0., pos1aft:0., fn1bef:'null', fn1aft:'null', vlsr1:0., W1:0., scan2:scan2, beam2:beam2, time2:0l, pos2bef:0., pos2aft:0.,fn2bef:'null', fn2aft:'null', vlsr2:0., W2:0., XRA:0., Xdec:0., ZPTR:0., GAINR:0.}

mask2 = fltarr( ceil( 15*(max([ra1, ra2]) - min([ra1, ra2]))/res),ceil( (max([dec1, dec2]) - min([dec1, dec2]))/(res)))

rafl2 = floor(15.*(ra2 -  min([ra1, ra2]))/res)
decfl2 = floor((dec2 -  min([dec1, dec2]))/res)
mask2[rafl2, decfl2] = 1.

mask2 = gromask(mask2)

rafl1 = floor(15.*(ra1 -  min([ra1, ra2]))/res)
decfl1 = floor((dec1 -  min([dec1, dec2]))/res)

whix = where(mask2[rafl1, decfl1] eq 1.)

for i=0l, n_elements(whix) -2 do begin
    if (abs(ra1[whix[i]] - ra1[whix[i]+1]) lt 23) then begin 
    loop_bar, i, n_elements(whix)

    ma = (dec1[whix[i]]- dec1[whix[i]+1])/(ra1[whix[i]]- ra1[whix[i]+1])
    mb = (dec2- dec2[1:*])/(ra2 - ra2[1:*])
    XRA = (mb*ra2[1:*] -ma*ra1[whix[i]+1] + replicate(dec1[whix[i]+1], n-1) -dec2[1:*])/(mb-ma)
    Xdec = ma*(XRA - ra1[whix[i]+1])+dec1[whix[i]+1]
    isect = (XRA lt max(ra1[whix[i]:whix[i]+1])) and (XRA gt min(ra1[whix[i]:whix[i]+1])) and (XRA lt (ra2 > ra2[1:*])) and (XRA gt (ra2 < ra2[1:*])) and (abs(ra2 - ra2[1:*]) lt 23)
    
    if total(isect) ne 0 then begin
        where_cross_1 = whix[i]
        wh = where(isect eq 1.)
        for j = 0l, total(isect)-1 do begin
            where_cross_2 = wh[j]
            W_bef_1 = (XRA[wh[j]] - ra1[whix[i]+1])/(ra1[whix[i]] - ra1[whix[i]+1])
            W_bef_2 = (XRA[wh[j]] - ra2[wh[j]+1])/(ra2[wh[j]] - ra2[wh[j]+1])
            outxj = {scan1:scan1, beam1:beam1, time1:0l, pos1bef:0.,pos1aft:0.,fn1bef:'null', fn1aft:'null', vlsr1:0., W1:0., scan2:scan2, beam2:beam2, time2:0l, pos2bef:0., pos2aft:0., fn2bef:'null', fn2aft:'null', vlsr2:0., W2:0., XRA:0., Xdec:0., ZPTR:0., GAINR:0.}
            outxj.time1 = mh1[where_cross_1].UTCSTAMP
            outxj.time2 = mh2[where_cross_2].UTCSTAMP
            outxj.pos1bef = fp1[where_cross_1]
            outxj.pos2bef = fp2[where_cross_2]
            outxj.pos1aft = fp1[where_cross_1+1]
            outxj.pos2aft = fp2[where_cross_2+1]
            outxj.fn1bef = fn1[where_cross_1]
            outxj.fn2bef = fn2[where_cross_2]
            outxj.fn1aft = fn1[where_cross_1+1]
            outxj.fn2aft = fn2[where_cross_2+1]
            outxj.W1 = W_bef_1
            outxj.W2 = W_bef_2
            outxj.vlsr1 = mh1[where_cross_1].vlsr[0]
            outxj.vlsr2 = mh2[where_cross_2].vlsr[0]
            outxj.XRA = (XRA[wh[j]] -mid + 24) mod 24
            outxj.Xdec = Xdec[wh[j]]
            outx = [outx, outxj]
        endfor
    endif
endif
endfor

if (n_elements(outx) ne 1) then outx = outx[1:*] else return, -1

;print, 'dt = ', systime(/seconds)-timestart
return, 1
;return, systime(/seconds)-timestart
end
