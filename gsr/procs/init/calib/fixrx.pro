pro fixrx, outdata, rxgood
;+
; NAME:
;  FIXRX
; PURPOSE:
;  If fed an outdata strucutre, from standard reducton process,
;  and an rxgood table, copies good data over bad data in a single beam
;
; CALLING SEQUENCE:
;    fixrx, outdata, rxgood
;
; INPUTS:
;   outdata -- The data to be fixed, in [8192, 2, 7, N] format.
;   rxgood -- The good receivers table, in [2,7] format.
; KEYWORD PARAMETERS:
;   NONE
; OUTPUTS:
;   NONE (xin loaded with spectra)
;-

if (n_elements(rxgood) ne 0) then begin
    if total(rxgood) ne 14 then begin
        whbad = where(rxgood eq 0.)
        for j=0, n_elements(whbad)-1 do begin
            outdata[*,whbad[j] mod 2, floor(whbad[j]/2.), *] =  outdata[*,1 - (whbad[j] mod 2), floor(whbad[j]/2.), *]
        endfor
    endif
endif

end
