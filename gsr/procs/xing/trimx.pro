; get rid of any XING points with no data in their spectra, or that fall in bad UTC times with blankfile
;

pro trimx, xarr, blankfile=blankfile

CATCH, error_status
IF Error_status NE 0 THEN BEGIN 
    PRINT, 'Error index: ', Error_status 
    PRINT, 'Error message: ', !ERROR_STATE.MSG 
    error_status = 0.
    return
ENDIF 

max1 = fltarr(n_elements(xarr))
max2 = max1
for i=0, n_elements(xarr)-1 do begin
    max1[i] = max(xarr[i].spect1)   
    max2[i] = max(xarr[i].spect2)
endfor
ne1 = n_elements(where(max1 eq  0., ct1))
ne2 =n_elements(where(max2 eq  0., ct2))
wh = fltarr(n_elements(xarr))+1
if (ct1 ne 0.) then wh(where(max1 eq  0.)) =  0.
if (ct2 ne 0.) then wh(where(max2 eq  0.)) =  0.

if keyword_set(blankfile) then begin
    restore, blankfile
    whblank = fltarr(n_elements(xarr))+1
    sz = size(blank)
    for i=0, sz[2]-1 do begin
        whb = where((xarr.time1 lt blank[1, i]) and (xarr.time1 gt blank[0, i]) and (xarr.beam1 eq blank[2,i]), ct)
        if (ct ne 0) then whblank(whb) = 0.
        whb = where((xarr.time2 lt blank[1, i]) and (xarr.time2 gt blank[0, i] and (xarr.beam2 eq blank[2,i])), ct)
        if (ct ne 0) then whblank(whb) = 0.
    endfor
wh = wh*whblank
endif
whok = where(wh eq 1. , ctok)        

if (ctok ne 0) then xarr = xarr(where(wh eq 1.)) else xarr = 0.

end
