function dfteval, nterms, fhgt, theta

;+ 
;
;PURPOSE: evaluate the fourier expansion of the sidelobes
;at an arbitrary point. The series was evaluated by IDL's FFT routine. 
;use dft to do this.
;
;	NTERM SHOULD BE ODD unless nterms is equal to 8 
;(which means you are using the full Fourier reconstruction).
;
;
;CALLING SEQUENCE:
;
;	RESULT= DFTEVAL( nterms, fhgt, theta)
;
;INPUTS: 
;
;	NTERMS is nr of fourier coefficients to actually employ. If the
;original data were noisy, using fewer terms respresents a least squares
;fit to the function using a smaller number of Fourier coefficients than
;the number of datapoint. NTERMS must be odd or equal to 8. to recover the 
;lowest order cyclic variation (one cycle around the circle), NTERMS ge 3
;
;	FHGT, the complex array of Fourier coefficients.
;
;	THETA, the angle at which to evaluate the Fourier series.
;
;OUTPUT: 
;
;	VALUE of the Fourier series at angle THETA. It's COMPLEX|
;
;HISTORY: explored nonreal situation on 26nov2004 and 09dec2004. found
;we must take the real part, not the magnitude. replaces ffteval.
;
;-

nf= n_elements( fhgt)

delang= 2.*!pi/nf
ang_rng_total= 2* !pi
angfreq_rng_total= 1./delang

dangfreq= angfreq_rng_total/nf
angfreq= angfreq_rng_total* (findgen( nf)- nf/2)/nf
angfreq= shift( angfreq, nf/2)

nkeep= [0]
if (nterms gt 1) then nkeep= [ indgen( (1+ nterms)/2), nf-1-indgen(nterms/2)]

;;-------------------------------------print, stuff...
;print, 'nterms = ', nterms
;for nr=0, n_elements( nkeep)-1 do $
;print, nr, nkeep[ nr], angfreq[ nkeep[nr]], fhgt[ nkeep[nr]]
;;-------------------------------------

;stop

dft, angfreq[ nkeep], fhgt[ nkeep], theta, value, /inverse

value= float( value)

return, value

end

