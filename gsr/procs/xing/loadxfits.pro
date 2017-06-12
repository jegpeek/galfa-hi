pro loadxfits, xarr,spdat=spdat, badrxfile=badrxfile, mht=mht, corf=corf

;+
; NAME:
;  LOADXFITS
; PURPOSE:
;   A code designed to, when presented with the appropriate 
;   structure of crossing points, fill in the appropriate values of 
;   for each crossing point spectrum. Used with post-stg0
;   data stored in FITS format.
;
; CALLING SEQUENCE:
;   loadx, xarr, spdat=spdat, badrxfile=badrxfile, mht=mht, corf=corf
;
; INPUTS:
;   xarr -- The input structure (see getx.pro)
;   
; KEYWORD PARAMETERS:
;   badrxfile -- Any file of badrx's
;   spdat -- Any spectra to do corrections with
;    mht -- all the mh information for the entire run - only used 
;           if applying a xing 
;   corf -- xing correction factors, only used if 
;           applying a xing
; OUTPUTS:
;   NONE (xin loaded with spectra)
; MODIFICATION HISTORY:
;   mht and corf added Oct 23rd 2006, JEG Peek
;-

for i = 0l, n_elements(xarr) -1 do begin
    loop_bar, i, n_elements(xarr)
    ;extract 2 pol at correct second and beam from correct file
    bef1 = gsrfits(xarr[i].fn1bef, /sav, sec=xarr[i].pos1bef, beam=xarr[i].beam1)
    aft1 = gsrfits(xarr[i].fn1aft, /sav, sec=xarr[i].pos1aft, beam=xarr[i].beam1)
    bef2 = gsrfits(xarr[i].fn2bef, /sav, sec=xarr[i].pos2bef, beam=xarr[i].beam2)
    aft2 = gsrfits(xarr[i].fn2aft, /sav, sec=xarr[i].pos2aft, beam=xarr[i].beam2)
    ; find any bad rxs.
    whichrx, xarr[i].time1, rxgood1, badrxfile=badrxfile
    whichrx, xarr[i].time2, rxgood2, badrxfile=badrxfile
    if keyword_set(corf) then begin
        ;correct the amplitude with corf
        wb1 = where(mht.utcstamp eq xarr[i].time1, ctb1)
  ;      wa1 = where(mht.utcstamp eq xarr[i].time1+1l, cta1)
        wb2 = where(mht.utcstamp eq xarr[i].time2, ctb2)
   ;     wa2 = where(mht.utcstamp eq xarr[i].time2+1l, cta2)
        if (ctb1+ctb2) ne 2 then begin
            print, 'Error in loadxfits.pro fitting xing correction'
            stop
        endif
        wa1 = wb1 + 1
        wa2= wb2 +1
        cfb1 = corf[xarr[i].beam1, wb1]
        cfa1 = corf[xarr[i].beam1, wa1]
        cfb2 = corf[xarr[i].beam2, wb2]
        cfa2 = corf[xarr[i].beam2, wa2]
        bef1 = bef1/cfb1[0]
        aft1 = aft1/cfa1[0]
        bef2 = bef2/cfb2[0]
        aft2 = aft2/cfa2[0]
    endif
    
    if keyword_set(spdat) then begin
        ; original version
        if tag_exist(spdat, 'zogains') then begin
            spfix1, bef1, xarr[i].scan1, xarr[i].beam1, spdat.zogains, spdat.fpn_sp
            spfix1, aft1, xarr[i].scan1, xarr[i].beam1, spdat.zogains, spdat.fpn_sp
            spfix1, bef2, xarr[i].scan2, xarr[i].beam2, spdat.zogains, spdat.fpn_sp
            spfix1, aft2, xarr[i].scan2, xarr[i].beam2, spdat.zogains, spdat.fpn_sp
        endif else begin
            spfix1, bef1, xarr[i].scan1, xarr[i].beam1, -99, spdat, xarr[i].xdec, xarr[i].vlsr1
            spfix1, aft1, xarr[i].scan1, xarr[i].beam1, -99, spdat, xarr[i].xdec, xarr[i].vlsr1
            spfix1, bef2, xarr[i].scan2, xarr[i].beam2, -99, spdat, xarr[i].xdec, xarr[i].vlsr2
            spfix1, aft2, xarr[i].scan2, xarr[i].beam2, -99, spdat, xarr[i].xdec, xarr[i].vlsr2
        endelse
    endif
    b1 = total(bef1*rebin(reform(rxgood1[*, xarr[i].beam1], 1, 2), 8192, 2), 2)/total(rxgood1[*, xarr[i].beam1])
    a1 = total(aft1*rebin(reform(rxgood1[*, xarr[i].beam1], 1, 2), 8192, 2), 2)/total(rxgood1[*, xarr[i].beam1])
    b2 = total(bef2*rebin(reform(rxgood2[*, xarr[i].beam2], 1, 2), 8192, 2), 2)/total(rxgood2[*, xarr[i].beam2])
    a2 = total(aft2*rebin(reform(rxgood2[*, xarr[i].beam2], 1, 2), 8192, 2), 2)/total(rxgood2[*, xarr[i].beam2])
    xarr[i].spect1 = b1*xarr[i].w1 + a1*(1-xarr[i].w1)
    xarr[i].spect2 = b2*xarr[i].w1 + a2*(1-xarr[i].w1)
endfor


end
