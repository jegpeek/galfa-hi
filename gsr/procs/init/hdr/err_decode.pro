function err_decode, errs_in
;+
; NAME:
;     err_decode
; PURPOSE:
;     Given an array of uncorrected errors, return an array of the same
;     size with a preceeding dimension of 6 ([AxBx...xZ] =>
;     [6xAxBx...xZ]) for each of the error types:
;
;       array[0,*,*...] :  narrowband mixer saturation
;       array[1,*,*...] :  narrowband lowpass filter saturation
;       array[2,*,*...] :  narrowband FFT overflow
;       array[3,*,*...] :  narrowband upshift saturation
;       array[4,*,*...] :  wideband FFT overflow
;       array[5,*,*...] :  wideband upshift saturation
;
;     (the errors are arranged this way such that the (corrected) error
;     number could read back by reading the error array as a base 4
;     number: Err = 4^5*array[0] + 4^4*array[1] + 4^3*array[2] ...)
;
;EXPLANATION:
;     Each of the codes is read with a -32768 offset, which we
;     correct, and then should be read as a binary number, where
;     various digits correspond to various errors, with amplitudes
;     ranging from 0 to 3:
;     0 -> 0-15 errors in 1sec
;     1 -> 16-255 errors in 1sec
;     2 -> 256-4095 errors in 1sec
;     3 -> 4096+ errors in 1sec
; CALLING SEQUENCE
;     result = err_decode(errs_in) 
; INPUTS:
;     an array of uncorrected errors, as created with mrdfits
; OUTPUT:
;     result - corrected errors in the same array structure as the
;              input, but with another dimension to contain the 6
;              error types and their values.
; METHOD:
;     Use mod and floor to extract the binary.
;
; REVISION HISTORY:
;     Written J. Goldston                 October, 2004
;	05nov04: chk if 2^15 needs to be added, carl h
;-

erroffset= 0
if (min( errs_in lt 0)) then erroffset= 2l^15

sz =size(errs_in)

IF (SZ[0] NE 0) THEN BEGIN
; reshape the errors into being  [6xAxBx...xZ] and add the magical 32768
errs_in = rebin(reform(errs_in+erroffset, [1,sz[1:sz[0]]]), [6, [sz[1:sz[0]]]])
    
rrfindgen = rebin(reform(findgen(6), [6,fltarr(sz[0])+1]) , [6,sz[1:sz[0]]])

errs_out = floor( ( errs_in mod 4.^(6-rrfindgen) )/(4.^(6-rrfindgen-1)) )
ENDIF

if (sz[0] eq 0) then $
errs_out = floor( ( (errs_in+erroffset) mod 4.^(6-findgen(6)) )/(4.^(6-findgen(6)-1)) )

return, errs_out

end


