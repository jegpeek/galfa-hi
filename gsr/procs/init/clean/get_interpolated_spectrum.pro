pro get_interpolated_spectrum, fin, tin, fout, tout, d, ampl, delay, avg, $
	gain=gain, iter=iter, avgratio=avgratio

; Given a spectrum(fin, tin, frequencies and corresponding signals)
; estimate a interpolated spectrum(tout) at given frequencies(fout)
;
; CALLING SEQUENCE: call get_interpolated_spectrum, fin, tin, fout, tout
;
; INPUTS:
;  fin => frequencies at which input spectrum is sampled
;  tin => amplitude of input spectrum at given frequencies
;  fout => frequencies at which output spectrum is sampled
;  gain - loop gain, try 0.4
;  iter - nr interations

; OUTPUTS: 
;	d: the structure from dirty_spectrum
;	ampl: ampl of clean components
;	delay: channel delay of clean components
;	avg: avg of first/second half of resids versus iteration number
;  ys2 => estimated spectrum at fout.
;  

if keyword_set( gain) eq 0 then gain=0.4
if keyword_set( iter) eq 0 then iter=10000
if keyword_set( avgratio) eq 0 then avgratio=0.025

d= dirty_spectrum(fin, tin)

clean, d, gain, iter, cc, rsd, ampl, delay, avg, fout, avgratio=avgratio

;stop

;;INTERPOLATION EXPERIMENT...
;gcurv, findgen(13)-6., 0., 1., 0., 1., kernal
;kernal= kernal/total( kernal)
;cc_c= convol( cc, kernal, /edge_wrap)
;dft, d.spec_freq, cc_c, fout, tout, /inverse

;stop

;NO INTERPOLATION HERE...
dft, d.spec_freq, cc, fout, tout, /inverse

tout= float( tout)

end



