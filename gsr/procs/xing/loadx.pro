pro loadx, xin,spdat=spdat, badrxfile=badrxfile, mht=mht, corf=corf
;+
; NAME:
;  LOADX
; PURPOSE:
;   A code designed to, when presented with the appropriate 
;   structure of crossing points, fill in the appropriate values of 
;   for each crossing point spectrum
;
; CALLING SEQUENCE:
;   loadx, xin ,spdat=spdat, badrxfile=badrxfile, mht=mht, corf=corf
;
; INPUTS:
;   xin -- The input structure (see getx.pro)
; 
; KEYWORD PARAMETERS:
;   badrxfile -- Any file of badrx's
;   spdat -- Any spectra to do corrections with
;   xingarr -- any xing corrections to apply
;    mht -- all the mh information for the entire run - only used 
;           if applying a xing 
;   corf -- xing correction factors, only used if 
;           applying a xing
; OUTPUTS:
;   NONE (xin loaded with spectra)
; MODIFICATION HISTORY:
;   mht and corf added Oct 23rd 2006, JEG Peek
;-

;find all of the files to look through for data
xn = n_elements(xin)

b1 = xin(uniq(xin.fn1bef, sort(xin.fn1bef))).fn1bef
b2 = xin(uniq(xin.fn2bef, sort(xin.fn2bef))).fn2bef
a1 = xin(uniq(xin.fn1aft, sort(xin.fn1aft))).fn1aft
a2 = xin(uniq(xin.fn2aft, sort(xin.fn2aft))).fn2aft
nms = [a1,a2,b1,b2]
names = nms(uniq(nms, sort(nms)))
nn = n_elements(names)
;stop
for i=0, nn-1 do begin
    loop_bar, i, nn
    restore, names[i]
    sz = size(outdata)
    if keyword_set(corf) then begin
        whf = where(mht.fn eq names[i])
        outdata = temporary(outdata)/rebin(reform(corf[*, whf], 1, 1, 7, sz[4]), 8192, 2, 7, sz[4])
    endif
    whichrx, mh[0].utcstamp, rxgood, badrxfile=badrxfile
    fixrx, outdata, rxgood
    if keyword_set(spdat) then begin
       ;day = float((strsplit((strsplit(names[i], '_', /extract))[1], '/', /extract))[0])   
       day = max(float(strsplit(names[i], '_', /extract)))
       spfix, outdata, day, spdat.zogains, spdat.fpn_sp   
    endif
; find all the spots where the crossing point is 
; not split across a file 
    w_x1 = where((xin.fn1bef eq names[i]) and (xin.fn1aft eq names[i]))
    w_x2 = where((xin.fn2bef eq names[i]) and (xin.fn2aft eq names[i]))
; Does anything fit this criterion?
    cr1 = 1 - total((w_x1 eq -1) )
    cr2 = 1 - total((w_x2 eq -1) )
; Where are all the times requested?
    if (cr1) then fn_idx_1 = subset(xin[w_x1].time1,mh.utcstamp) 
    if (cr2) then fn_idx_2 = subset(xin[w_x2].time2,mh.utcstamp) 
; Check doubles
    if (cr1) then if (n_elements(fn_idx_1) ne n_elements(w_x1)) then stop
    if (cr2) then if (n_elements(fn_idx_2) ne n_elements(w_x2)) then stop
    if (cr1) then begin
        sz = double(size(outdata))
 ; A way to extract the correct indices from outdata. Involves some Erik R. black magic
        index_p0b = lindgen(sz[1])#replicate(1.,n_elements(w_x1))+ replicate(1,sz[1])#(xin[w_x1].beam1*sz[1]*sz[2]+ fn_idx_1*sz[1]*sz[2]*sz[3]+sz[1]*0.)
        index_p1b = lindgen(sz[1])#replicate(1.,n_elements(w_x1))+ replicate(1,sz[1])#(xin[w_x1].beam1*sz[1]*sz[2]+ fn_idx_1*sz[1]*sz[2]*sz[3]+sz[1]*1.)
        index_p0a = lindgen(sz[1])#replicate(1.,n_elements(w_x1))+ replicate(1,sz[1])#(xin[w_x1].beam1*sz[1]*sz[2]+ (fn_idx_1+1)*sz[1]*sz[2]*sz[3]+sz[1]*0.)
        index_p1a = lindgen(sz[1])#replicate(1.,n_elements(w_x1))+ replicate(1,sz[1])#(xin[w_x1].beam1*sz[1]*sz[2]+ (fn_idx_1+1)*sz[1]*sz[2]*sz[3]+sz[1]*1.)
        xin[w_x1].spect1 = (outdata[index_p0b]+outdata[index_p1b])/2.*(replicate(1., 8192)#xin[w_x1].W1) + (outdata[index_p0a]+outdata[index_p1a])/2.*(replicate(1., 8192)#(1.-xin[w_x1].W1))
    endif
    if (cr2) then begin
        sz = double(size(outdata))
        index_p0b = lindgen(sz[1])#replicate(1.,n_elements(w_x2))+ replicate(1,sz[1])#(xin[w_x2].beam2*sz[1]*sz[2]+ fn_idx_2*sz[1]*sz[2]*sz[3]+sz[1]*0.)
        index_p1b = lindgen(sz[1])#replicate(1.,n_elements(w_x2))+ replicate(1,sz[1])#(xin[w_x2].beam2*sz[1]*sz[2]+ fn_idx_2*sz[1]*sz[2]*sz[3]+sz[1]*1.)
        index_p0a = lindgen(sz[1])#replicate(1.,n_elements(w_x2))+ replicate(1,sz[1])#(xin[w_x2].beam2*sz[1]*sz[2]+ (fn_idx_2+1)*sz[1]*sz[2]*sz[3]+sz[1]*0.)
        index_p1a = lindgen(sz[1])#replicate(1.,n_elements(w_x2))+ replicate(1,sz[1])#(xin[w_x2].beam2*sz[1]*sz[2]+ (fn_idx_2+1)*sz[1]*sz[2]*sz[3]+sz[1]*1.)
        xin[w_x2].spect2 = (outdata[index_p0b]+outdata[index_p1b])/2.*(replicate(1., 8192)#xin[w_x2].W2) + (outdata[index_p0a]+outdata[index_p1a])/2.*(replicate(1., 8192)#(1.-xin[w_x2].W2))
    endif

; find all the spots where the crossing point _IS_ split across a file 
    w_x1_b = where((xin.fn1bef eq names[i]) and (xin.fn1aft ne names[i]))
    w_x1_a = where((xin.fn1bef ne names[i]) and (xin.fn1aft eq names[i]))
    w_x2_b = where((xin.fn2bef eq names[i]) and (xin.fn2aft ne names[i])) 
    w_x2_a = where((xin.fn2bef ne names[i]) and (xin.fn2aft eq names[i])) 

; Does anything fit this criterion?
    b1 = 1 - total((w_x1_b eq -1) )
    a1 = 1 - total((w_x1_a eq -1) )
    b2 = 1 - total((w_x2_b eq -1) )
    a2 = 1 - total((w_x2_a eq -1) )
    
; Where are all the times requested?
    if (b1) then fn_idx_1_b = subset(xin[w_x1_b].time1,mh.utcstamp)
;    if (a1) then fn_idx_1_a = subset(xin[w_x1_a].time1,mh.utcstamp)
    if (b2) then fn_idx_2_b = subset(xin[w_x2_b].time2,mh.utcstamp)
;    if (a2) then fn_idx_2_a = subset(xin[w_x2_a].time2,mh.utcstamp)

; Check doubles
    if (b1) then if (n_elements(fn_idx_1_b) ne n_elements(w_x1_b)) then stop
;    if (a1) then if (n_elements(fn_idx_1_a) ne n_elements(w_x1_a)) then stop
    if (b2) then if (n_elements(fn_idx_2_b) ne n_elements(w_x2_b)) then stop
;    if (a2) then if (n_elements(fn_idx_2_a) ne n_elements(w_x2_a)) then stop
    
; If there isn't already a spectra loaded from a previous file then load
; the associated spectrum _with no weighting_. Else, (i.e. if there 
; is already a spectrum in .spectN) then take the current spectrum
; and add it to the laoded spectrum with appropriate weighting.
; We are averaging the polarizations together here, for now.
; G!d have mercy on this code. :)

if (b1) then begin
    for j=0, n_elements(w_x1_b) -1 do begin
        if (total(xin[w_x1_b[j]].spect1) eq 0.) then xin[w_x1_b[j]].spect1 = (outdata[*,0,xin[w_x1_b[j]].beam1, fn_idx_1_b[j]] +  outdata[*,1,xin[w_x1_b[j]].beam1, fn_idx_1_b[j]])/2. else xin[w_x1_b[j]].spect1 =  (outdata[*,0,xin[w_x1_b[j]].beam1, fn_idx_1_b[j]] +  outdata[*,1,xin[w_x1_b[j]].beam1, fn_idx_1_b[j]])/2.*xin[w_x1_b[j]].w1 + xin[w_x1_b[j]].spect1*(1-xin[w_x1_b[j]].w1)
    endfor
endif

if (a1) then begin
    for j=0, n_elements(w_x1_a) -1 do begin
        if (total(xin[w_x1_a[j]].spect1) eq 0.) then xin[w_x1_a[j]].spect1 = (outdata[*,0, xin[w_x1_a[j]].beam1, 0]+outdata[*,1, xin[w_x1_a[j]].beam1, 0])/2. else xin[w_x1_a[j]].spect1 = (outdata[*,0, xin[w_x1_a[j]].beam1,0]+ outdata[*,1, xin[w_x1_a[j]].beam1,0])/2.*(1-xin[w_x1_a[j]].w1) + xin[w_x1_a[j]].spect1*xin[w_x1_a[j]].w1
    endfor
endif


if (b2) then begin
    for j=0, n_elements(w_x2_b) -1 do begin
        if (total(xin[w_x2_b[j]].spect2) eq 0.) then xin[w_x2_b[j]].spect2 = (outdata[*,0,xin[w_x2_b[j]].beam2, fn_idx_2_b[j]] +  outdata[*,1,xin[w_x2_b[j]].beam2, fn_idx_2_b[j]])/2. else xin[w_x2_b[j]].spect2 =  (outdata[*,0,xin[w_x2_b[j]].beam2, fn_idx_2_b[j]] +  outdata[*,1,xin[w_x2_b[j]].beam2, fn_idx_2_b[j]])/2.*xin[w_x2_b[j]].w2 + xin[w_x2_b[j]].spect2*(1-xin[w_x2_b[j]].w2)
    endfor
endif

if (a2) then begin
    for j=0, n_elements(w_x2_a) -1 do begin
        if (total(xin[w_x2_a[j]].spect2) eq 0.) then xin[w_x2_a[j]].spect2 = (outdata[*,0, xin[w_x2_a[j]].beam2, 0]+outdata[*,1, xin[w_x2_a[j]].beam2, 0])/2. else xin[w_x2_a[j]].spect2 = (outdata[*,0, xin[w_x2_a[j]].beam2,0]+ outdata[*,1, xin[w_x2_a[j]].beam2,0])/2.*(1-xin[w_x2_a[j]].w2) + xin[w_x2_a[j]].spect2*xin[w_x2_a[j]].w2
    endfor
endif

endfor

end



