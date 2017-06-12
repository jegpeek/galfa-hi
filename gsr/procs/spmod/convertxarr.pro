; a code to make a new SP inverter
; fn -- new file name
; ncut -- number of fourier modes to remove from fit
pro convertxarr, fn, ncut, nsp

restore, getenv('GSRPATH') + 'savfiles/spcor_xinv.sav', /ver

; first channel of cos + sin fit is at 1031, and goes to channel 1254

newx1 = fltarr(231, 8192)  
for i=1, 6 do newx1 = newx1-xarr[1024:*,i*8192.:(i+1)*8192.-1]/6. 

xarr[1024:*,0:8191] = newx1
; excepting the values that correspond to '1'
xarr = [xarr[0:1023, *], xarr[1025:1030,*], xarr[1047:1047+6*16-1, *], xarr[1047+6*16-1+17:*, *]]

newx = fltarr(1222-ncut*6*2, 57344)
newx[0:1029, *] = xarr[0:1029, *]
for i=0, 5 do begin
    ; "sin"
    newx[1030+i*(16-ncut):1030+(i+1)*(16-ncut)-1, *] = xarr[1030+i*16:1030+i*16+(16-ncut)-1, *]
    ; "cos"
    newx[1030+(6*(16-ncut))+i*(16-ncut):1030+(6*(16-ncut))+(i+1)*(16-ncut)-1, *] = xarr[1030+(6*16)+i*16:1030+(6*16)+i*16+(16-ncut)-1, *]
endfor
xarr=newx

xarr = [xarr[256-nsp/2.:255+nsp/2.,*],  xarr[512+256-nsp/2.:512+ 255+nsp/2.,*], xarr[1024:*, *]]

xinv = transpose(xarr)#invert(xarr#transpose(xarr))
hnum=nsp
fpn = fpn
versiondate = 20090419

save, xarr, xinv, fpn, hnum, versiondate, f=fn

end
