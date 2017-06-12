pro test_xfit, root, region, scans, proj, no_auto=no_auto, conrem=conrem, xday=xday, tdf=tdf, keepold=keepold, xingname=xingname

;+
; NAME:
;   XFIT
; PURPOSE:
;   Given spectrum-loaded xing structure files, generate the
;   relative gain at each xing point. 
;
; CALLING SEQUENCE:
;   xfit, root, region, scans, proj, no_auto=no_auto, conrem=conrem, $
;           xday=xday, tdf=tdf, keepold=keepold, xingname=xingname
;
; INPUTS:
;   root -- The main directory in which the project directory
;             resides (e.g. '/dzd4/heiles/gsrdata/' )
;   region -- The name of the source as entered into BW_fm (e.g. 'lwa')
;   scans -- Number of days the project consists of
;   proj -- The Arecibo project code (e.g. 'a2050')
;
; KEYWORDS PARAMETERS
;   conrem -- If set, assume the input spectra have not had their continua
;             removed, and remove them before comparing gains.
;   no_auto -- If set, do not go through and generate the 'auto' files.
;   tdf -- use the older two-digit formatting
;   xingname -- if set, use a version of spcor as built with a previous xing run
;   keepold -- if set, move the old versions _l files to keep. This can be 
;          disk space intensive.
;
; OUTPUTS:
;   NONE (structured xing files with gains)
;
; MODIFICATION HISTORY:
;   Initial Documentation Monday, July 25, 2005
;   Modded to deal with RFI, October 26, 2005
;   Added Xday, May 26 2 thousand 6
;   Modified for S1H compatability, July 12, 2006, Goldston Peek
;   Added xingname and keepold, noauto -> no_auto. Oct 23, 2006
;   Joshua E. Goldston, goldston@astro.berkeley.edu
;-
if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)' 
if keyword_set(xingname) then appl_xing = xingname else appl_xing = 'none'
if not keyword_set(xingname) then xnus = '' else xnus = '_' + xingname


; 3 sigma has been tested, and seems optimal.
if(not (keyword_set(xday))) then xday = fltarr(scans, scans) + 1.

f=3.
xaxis = findgen(8192)- 4096 + 0.5
if (not keyword_set(no_auto)) then begin
restore, root + proj + '/' + region + '/xing/'+ region + 'auto_l'+xnus+'.sav'
l = (size(xarr))[1]
outx = replicate({scan1:0., beam1:0., time1:0l, fn1bef:'null', fn1aft:'null', W1:0., scan2:0., beam2:0., time2:0l, fn2bef:'null', fn2aft:'null', W2:0., XRA:0., Xdec:0., ZPTR:0., GAINR:0., sigab:fltarr(2)}, l) 
for k=0, l-1 do begin
    loop_bar, k, l
    ; noise in each beam:
    std1 = stddev(xarr[k].spect1[where(xarr[k].spect1 ne 0.)])
    std2 = stddev(xarr[k].spect2[where(xarr[k].spect2 ne 0.)])
    ; where the fit isn't too off of 1. Exclude zero-point ellispe
    wh = where( (xarr[k].spect1 ne 0.) and (xarr[k].spect2 ne 0.) and ((xarr[k].spect1 lt f*std1) and (xarr[k].spect2 lt f*std2) or ((xarr[k].spect2/xarr[k].spect1 gt 0.5) and (xarr[k].spect2/xarr[k].spect1 lt 2.0))))
    A1=0.
    A2=0.
    B1=0.
    B2=0.
    ; to get rid of continuum in each line
    if (keyword_set(conrem)) then begin
    wh1 = where( (xarr[k].spect1 ne 0.) and (abs(xaxis) gt 512))
    wh2 = where( (xarr[k].spect2 ne 0.) and (abs(xaxis) gt 512))
    fitexy, xaxis[wh1], xarr[k].spect1[wh1], A1, B1, X_SIG=1. , Y_SIG=1.
    fitexy, xaxis[wh2], xarr[k].spect2[wh2], A2, B2, X_SIG=1. , Y_SIG=1.
    endif
    s1 = xarr[k].spect1[wh] - (A1 + B1*xaxis)[wh]
    s2 = xarr[k].spect2[wh] - (A2 + B2*xaxis)[wh]

    s1(where(sqrt((s1/std1)^2+(s2/std2)^2) lt 3.5)) = 0.
    s2(where(sqrt((s1/std1)^2+(s2/std2)^2) lt 3.5)) = 0.
    

   ; Establish error handler. When errors occur, the index of the 
   ; error is returned in the variable Error_status: 
    CATCH, Error_status 
   
   ;This statement begins the error handler: 
    IF Error_status NE 0 THEN BEGIN 
       PRINT, 'Error index: ', Error_status 
       PRINT, 'Error message: ', !ERROR_STATE.MSG 
       error_status = 0.
       stop     
   ENDIF 
    FITEXY, s2, s1, A, B, X_SIG=1., Y_SIG=1., sig_a_b
    outx[k].gainr=B
;   this is a little cheap-ass, perhaps it could be tighter.
    outx[k].zptr= A
    outx[k].sigab = sig_a_b


endfor

outx.scan1 = xarr.scan1
outx.beam1 = xarr.beam1
outx.time1 = xarr.time1
outx.fn1bef = xarr.fn1bef
outx.fn1aft = xarr.fn1aft
outx.W1 = xarr.W1
outx.scan2 = xarr.scan2
outx.beam2 = xarr.beam2
outx.time2 = xarr.time2
outx.fn2bef = xarr.fn2bef
outx.fn2aft = xarr.fn2aft
outx.W2 = xarr.W2
outx.XRA = xarr.XRA
outx.Xdec = xarr.Xdec

if keyword_set(keepold) then spawn, 'cp ' + root + proj + '/' + region + '/xing/'+ region + 'auto_f.sav ' + root + proj + '/' + region + '/xing/'+ region + 'auto_f_'+xingname+'_old.sav'
save, outx, appl_xing, filename= root + proj + '/' + region + '/xing/'+ region + 'auto_f.sav'

endif

;cycle through scan1
tn = 0.
print, scans
help, /st, xday
for i=0, scans-1 do begin
    ; cycle through scans to cross with (scan2)
    for j=0, scans-1 do begin   
            if xday[i,j] eq 1 then begin
             print, i, j
             if(file_test(root + proj + '/' + region + '/xing/'+ region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '_l'+xnus+'.sav') eq 1) then begin 
        loop_bar, tn, total(xday)
        restore,  root + proj + '/' + region + '/xing/'+ region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '_l'+xnus+'.sav'
        if (size(size(xarr)))[1] eq 4 then begin
        l = (size(xarr))[1]
        outx = replicate({scan1:0., beam1:0., time1:0l, fn1bef:'null', fn1aft:'null', W1:0., scan2:0., beam2:0., time2:0l, fn2bef:'null', fn2aft:'null', W2:0., XRA:0., Xdec:0., ZPTR:0., GAINR:0., sigab:fltarr(2)}, l) 
        for k=0, l-1 do begin
            ; noise in each beam:
            std1 = stddev(xarr[k].spect1[where(xarr[k].spect1 ne 0.)])
            std2 = stddev(xarr[k].spect2[where(xarr[k].spect2 ne 0.)])
            ; where the fit isn't too off of 1.
            wh = where( (xarr[k].spect1 ne 0.) and (xarr[k].spect2 ne 0.) and ((xarr[k].spect1 lt f*std1) and (xarr[k].spect2 lt f*std2) or ((xarr[k].spect2/xarr[k].spect1 gt 0.5) and (xarr[k].spect2/xarr[k].spect1 lt 2.0))))
          ;  sqrt((xarr[k].spect1/std1)^2+(xarr[k].spect2/std2)^2) gt 3.5
            A1=0.
            A2=0.
            B1=0.
            B2=0.
         ; to get rid of continuum in each line
            if (keyword_set(conrem)) then begin
                wh1 = where( (xarr[k].spect1 ne 0.) and (abs(xaxis) gt 512))
                wh2 = where( (xarr[k].spect2 ne 0.) and (abs(xaxis) gt 512))
                fitexy, xaxis[wh1], xarr[k].spect1[wh1], A1, B1, X_SIG=1. , Y_SIG=1.
                fitexy, xaxis[wh2], xarr[k].spect2[wh2], A2, B2, X_SIG=1. , Y_SIG=1.
            endif
            s1 = xarr[k].spect1[wh] - (A1 + B1*xaxis)[wh]
            s2 = xarr[k].spect2[wh] - (A2 + B2*xaxis)[wh]

            s1(where(sqrt((s1/std1)^2+(s2/std2)^2) lt 3.5)) = 0.
            s2(where(sqrt((s1/std1)^2+(s2/std2)^2) lt 3.5)) = 0.
   
            FITEXY, s2, s1, A, B, X_SIG=1. , Y_SIG=1., sig_a_b
            outx[k].gainr=B
            outx[k].zptr= A
            outx[k].sigab = sig_a_b


        endfor
        
        outx.scan1 = xarr.scan1
        outx.beam1 = xarr.beam1
        outx.time1 = xarr.time1
        outx.fn1bef = xarr.fn1bef
        outx.fn1aft = xarr.fn1aft
        outx.W1 = xarr.W1
        outx.scan2 = xarr.scan2
        outx.beam2 = xarr.beam2
        outx.time2 = xarr.time2
        outx.fn2bef = xarr.fn2bef
        outx.fn2aft = xarr.fn2aft
        outx.W2 = xarr.W2
        outx.XRA = xarr.XRA
        outx.Xdec = xarr.Xdec
        if keyword_set(keepold) then spawn, 'cp ' + root + proj + '/' + region + '/xing/'+ region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '_f.sav ' + root + proj + '/' + region + '/xing/'+ region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '_f_'+xingname+'_old.sav'
        save, outx, appl_xing, filename= root + proj + '/' + region + '/xing/'+ region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '_f.sav'
        endif
        tn = tn + 1.
             endif 
endif
    endfor
endfor


end
