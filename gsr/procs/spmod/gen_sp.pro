;+
; NAME:
;   GEN_SP
;
;
; PURPOSE:
;  Generate a non-standard SPCOR xarr and xinv file.
;
;
; CALLING SEQUENCE:
;  GEN_SP, mask, xarr, xinv
;
;
; INPUTS:
;   mask - an integer array of 8192 numbers, either 1 or 0. Places
;          where there is a 1 the code will fit for HI, otherwise not.
;   nt - the order of fourier terms to include
; KEYWORD PARAMETERS:
;
;
;
; OUTPUTS:
;   xarr - the x array to multiply the results by to get the FPN
;   xinv - the matrix by which to multiply to get the linear fits
;
; OPTIONAL OUTPUTS:
;
;
; MODIFICATION HISTORY:
;  JEG Peek March 4 2008
;-

pro gen_sp, mask, nt, xarr, xarrorg, xinv, fn

nm = float(total(mask))
wh = where(mask eq 1)
xarr = fltarr(nm*2. + 7 + nt*2*7., 8192.*7.)
ddec = [0, (-1.)*sqrt(3)/2., 0, sqrt(3)/2., sqrt(3)/2., 0, (-1.)*sqrt(3)/2.]
dra = [0, 0.5, 1, 0.5, -0.5, -1, -0.5]

for i=0., 6. do begin
    for j=0., nm-1. do begin
        xarr[j, wh[j]+8192.*i] = dra[i]
        xarr[j+nm, wh[j]+8192.*i] = ddec[i]
    endfor
    xarr[2*nm+i, 8192.*i: 8192.*i + 8191.] = 1.
    for k=0, nt-1 do begin
        xarr[2*nm+7+i*nt+k, 8192.*i: 8192.*i + 8191.] = sin(findgen(8192)/8192.*2*!pi*(k+1))
        xarr[2.*nm+7.+nt*7.+i*nt+k, 8192.*i: 8192.*i + 8191.] = cos(findgen(8192)/8192.*2*!pi*(k+1))
    endfor
endfor

xinv = transpose(xarr)#invert(xarr#transpose(xarr))
xarrorg = xarr
xarr[0:nm*2-1, *] = 0.
hnum = nm
save, nt, hnum, mask, xinv, xarr, f=fn

end

