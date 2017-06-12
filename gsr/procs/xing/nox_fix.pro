pro nox_fix, root, region, scans, proj, f, beamgain, daygain, degree, nf, fourier
;+
; NAME:
;  NOX_FIX
;
; PURPOSE:
; Substitue ZOGAINS in for places with no XING data, that will typically go off the deep end in XG_ASSN
;
;
; CALLING SEQUENCE:
;   nox_fix, root, regiom, scans, proj, f, beamgain, daygain, degree, nf, fourier
;
; INPUTS:
;  root
;  region
;  scans
;  proj
;  f
;  beamgain
;  daygain
;  degree
;  nf
;  fourier
;
; OPTIONAL INPUTS:
;
;
;
; KEYWORD PARAMETERS:
;
;
;
; OUTPUTS:
;
;
;
; OPTIONAL OUTPUTS:
;
;
;
; COMMON BLOCKS:
;
;
;
; SIDE EFFECTS:
;
;
;
; RESTRICTIONS:
;
;
;
; PROCEDURE:
;
;
;
; EXAMPLE:
;
;
;
; MODIFICATION HISTORY:
;
;-

if file_search(root + proj + '/' + region + '/xing/xsize.sav') eq root + proj + '/' + region + '/xing/xsize.sav' then begin 
    restore, root + proj + '/' + region + '/xing/xsize.sav' 
endif else begin
    find_x_size, root, region, scans, proj
    restore, root + proj + '/' + region + '/xing/xsize.sav'
endelse

nx = total(fs, 1) + total(fs, 2)

wh = where(nx eq 0., ct)

if ct ne 0 then begin

restore, root + proj + '/' + region + '/spcor.sav' ; only for first pass! Not set up for iterative spcor/xing

if (daygain eq 1) then f[wh +7*beamgain] = 0.
; THESE NEED TESTING, BIG TIME...
if (degree ge 0) then begin
    for i=0, n_elements(wh)-1 do begin
        f[7*beamgain+scans*daygain + (degree+1)*wh[i] + rebin(reform(findgen(degree+1), degree+1, 1), degree+1,7) + (degree+1)*scans*rebin(reform(findgen(7), 1, 7), degree+1, 7)] = 0.
        f[7*beamgain+scans*daygain + (degree+1)*wh[i] + (degree+1)*scans*findgen(7)] = 1- zogains[*, wh[i]]
    endfor    
endif

if (nf gt 0) then begin
    for i=0, n_elements(wh)-1 do begin
        f[7*beamgain+scans*daygain+7*scans*(degree+1) + nf*wh[i] + rebin(reform(findgen(nf), 1, nf), 7, nf) + nf*scans*rebin(reform(findgen(7), 1, 7), 7, nf)] = 0.
        f[7*beamgain+scans*daygain+7*scans*(degree+1) + 7*scans*nf + nf*wh[i] + rebin(reform(findgen(nf), 1, nf), 7, nf) + nf*scans*rebin(reform(findgen(7), 7, nf), 7, nf)] = 0.
    endfor    
endif


endif

end
