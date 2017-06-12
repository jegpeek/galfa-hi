;+
; NAME:
;  ARB_SPECT_RAT
;
;
; PURPOSE:
;  To find the ratio of two spectra of arbitary resolution and domain
;
;
; CALLING SEQUENCE:
;    result = arb_spect_rat(s1x, s1y, s2x, s2y)
;
;
; INPUTS:
;   s1x - domain of spectrum 1
;   s1y - values of spectrum 1
;   s2x - domain of spectrum 2
;   s2y - values of spectrum 2
;
; OUTPUTS:
;   The result is the measured ratio between s1y and s2y i.e.
;   result = s1y/s2y 
;
; MODIFICATION HISTORY:
;   Initial documentation, JEG Peek August 15th 2006
;-

function arb_spect_rat, s1x, s1y, s2x, s2y

; set up the range over which to compare the spectra
vmax = min([max(s1x), max(s2x)])
vmin = max([min(s1x), min(s2x)])

if vmax le vmin then begin
    print, 'no overlapping domain: ARB_SPECT_RAT'
    return, 1.
endif

;set if 1 is higher res than 2
one_hires_two = abs(s1x[0] - s1x[1]) le abs(s2x[0] - s2x[1])

;r1x is the higher res of the two
if one_hires_two then begin
    r1x = s1x
    r1y = s1y
    r2x = s2x
    r2y = s2y
endif else begin
    r1x = s2x
    r1y = s2y
    r2x = s1x
    r2y = s1y
endelse

; hires spectrum over a restricted range
r1y_rr = r1y(where( (r1x ge vmin) and (r1x le vmax)))
; hires velocites over restricted range
r1x_rr = r1x(where( (r1x ge vmin) and (r1x le vmax)))
; lowres spectrum over hires restricted range
r2y_predict = interpol(r2y, r2x, r1x_rr)

spect_rat, r1y_rr, r2y_predict, 3, a, b, sig_a_b, r1x_rr

if not one_hires_two then b = 1./b

return, b

end
