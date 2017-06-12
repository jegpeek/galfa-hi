;+
;NAME:
;fwhmtosigf - convert factor fwhm to sigma 
; this uses y=a0*exp(x^2/sig^2)  .. no factor of 2 in exponent
; If factor of 1/2 in exponent then 
; 1.d/(sqrt(8*alog(2.))
;-
function fwhmtosigf,div2=div2
	if keyword_set(div2) then begin
    	return,1.D/(sqrt(8D*alog(2.)))
	endif else begin
    	return,1.D/(2.D*sqrt(alog(2.)))
	endelse

end
