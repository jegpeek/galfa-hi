pro deblip_makesp, data, s1, slist, sp, bl_data, wblp, offx

; kelvin limit for fitting
kcut = 3.
mx = max(slist, xx)
szsl = size(slist)
isp = fltarr(7679)
wblp = s1 + findgen(600/12.)*12
wblp = wblp(where(wblp lt (size(data))[4]))

if mx gt kcut then begin
    db = data-shift(data, [0, 0, 0,1])
;data_blip[*, *, *, sz[4]-1] =0.
    db[*, *, *, 0] =0.
    for i=0, 1 do begin
        for j=0, 6 do begin
            wh = where(slist[i, j, *] gt kcut, ct)
            if ct ne 0 then begin
                for q = 0,n_elements(wh)-1 do isp = isp + db[*, i, j, wh[q]]
            endif
        endfor
    endfor
endif
if mx le kcut then isp = data[*, xx mod 2, xx/(2) mod 7, xx/(2*7)]

restore, + getenv('GSRPATH') + 'savfiles/blip.sav'

bsp = fltarr(7679)
bsp[2000:5999] = blip
offfit = fltarr(7679)
for i=0, 7678 do offfit[i] = total(isp*shift(bsp, i))

maxsh = max(offfit, xsh)
sp = shift(bsp, xsh)
sp = sp/max(sp)

; is there enough signal to fit for offset with time?
sz4 = (size(data))[4]   ; Kevin put this outside the if statement

if mx gt kcut then begin
    shval = slist*0.
    snr = slist*0.
    for i=0, 1 do begin
        for j=0, 6 do begin
            wh = where(slist[i, j, *] gt kcut, ct)
            if ct ne 0 then begin
                for q = 0,n_elements(wh)-1 do begin
                    shsp = fltarr(7679)
                    for k=0, 7678 do shsp[k] = total(shift(sp, k)*db[*, i, j, wh[q]])
                    peak = max(shsp, kk)
                    if kk gt 4000 then noise = stddev(shsp[kk-2500:(kk-2000)]) else noise = stddev(shsp[kk+2000:(kk+2500)])
                    shval[i, j, wh[q]] = kk
                    snr[i, j, wh[q]]  =peak/noise
                endfor
            endif
        endfor
    endfor

;    sz4 = (size(data))[4]  ;; sz4 needs to be defined whether mx gt kcut or not!
    if n_elements(where(snr gt 3)) gt 10 then begin
        shvalcent = (shval + 4000) mod 7679
        med = median(shvalcent)
        wh = where((snr gt 3) and (abs(shvalcent - med) lt 500))
        xxx = rebin(reform(findgen(sz4), 1, 1, sz4), 2, 7, sz4)
        yf = poly_fit(xxx[wh], shvalcent[wh], 1)
        xx = findgen(sz4)
        offx = yf[0] + xx*yf[1] - 4000
      ;  stop
    endif else begin
        offx = fltarr(sz4)
    endelse
endif else begin
    offx = fltarr(sz4)
endelse

end
