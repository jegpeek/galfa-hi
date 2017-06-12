; a code to make a new SP inverter
; fn -- new file name
; ncut -- number of fourier modes to remove from fit
; versiondate -- the date, like 20120607
pro make_new_sp, fn, ncut, versiondate

restore, getenv('GSRPATH') + 'savfiles/spcor_xinv.sav', /ver

; first channel of cos + sin fit is at 1031, and goes to channel 1254

newx = fltarr(1255-ncut*7*2, 57344)
newx[0:1030, *] = xarr[0:1030, *]
for i=0, 6 do begin
    ; "sin"
    newx[1031+i*(16-ncut):1031+(i+1)*(16-ncut)-1, *] = xarr[1031+i*16:1031+i*16+(16-ncut)-1, *]
    ; "cos"
    newx[1031+(7*(16-ncut))+i*(16-ncut):1031+(7*(16-ncut))+(i+1)*(16-ncut)-1, *] = xarr[1031+(7*16)+i*16:1031+(7*16)+i*16+(16-ncut)-1, *]
endfor

newinv = transpose(newx)#invert(newx#transpose(newx))

fpn = fpn-ncut
;versiondate = 20090414
xarr= newx
xinv = newinv

save, xarr, xinv, fpn, hnum, versiondate, f=fn


end
