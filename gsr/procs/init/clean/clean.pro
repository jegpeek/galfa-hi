
pro clean, d, gain, iter, cc, rsd, ampl, delay, avg, fout, avgratio=avgratio
; Given a dirty spectrum and dirty beam, conduct a cleaning.
;
; CALLING SEQUENCE: call clean, d, gain, iter, cc, rsd, [noise]
;
; INPUTS:
;  d => ouput from dirty_spectrum function containg both 
;	dirty spectrum and dirty beam.
;  gain => gain value.
;  iter => maximum number of iteration.

;avgratio

;  noise[optional] => iteration stops when the amplitude of residual 
;	is smaller than this
;
; OUTPUTS: 
;     cc => clean component
;     rsd => residual
;	ampl: amplitude of clean component
;	delay: index of clean component  



J = (n_elements(d.spec) - 1)/2
;;J = n_elements(d.spec)/2

cc = complexarr(n_elements(d.spec))

rsd = d.spec

;AMPLITUDE AND INDEX OF COMPONENTS...
ampl= fltarr( iter)
delay= intarr( iter)

;CONVERGENCE CRITERION DEALIE...
avg= fltarr( 2, iter)

FOR I=0l, ITER-1 DO BEGIN
    abs_spec = abs(rsd[J+1:*]) 

avg[0,i]= mean( abs_spec[0:j/2-1])
avg[1,i]= mean( abs_spec[j/2:j-1])
ampl[ i]= max( abs_spec, indx)
delay[ i]= indx

    j_max = J+1+maxind(abs_spec) ;; find index where abs(rsd) is the maximum

;CONVERGENCE CRITERION...
    if keyword_set(avgratio) then $
	if 2*(avg[0,i]-avg[1,i])/(avg[0,i]+avg[1,i]) lt avgratio then break

    cc[j_max] = cc[j_max] + gain*rsd[j_max] 
    cc[2*J-j_max] = cc[2*J-j_max] + gain*conj(rsd[j_max])
    ;; add up to clean component by muplying a gain.

    ; (j_max, ds[j_max], ds[2*J-j_max]) peak
    ccp = rsd[j_max] * shift(d.beam, -(2*J-j_max))

    ; ccn = conj(rsd[j_max]) * shift(d.beam, -(j_max))
    ccn = rsd[2*J-j_max] * shift(d.beam, -(j_max))

;TEST SECTION...
;;plot, abs_spec, xtit= string( avg[0,i]) + '  '  + string( avg[1,i])
;;plots, maxind(abs_spec), abs_spec[ maxind(abs_spec)], psym=2, color=211
;IF (I MOD 100) EQ 0 THEN BEGIN
;dft, d.spec_freq, cc, fout, sigout, /inverse
;oplot, fout, sigout, color=211

;res= get_kbrd( 1)
;if ( res eq 'q') then break
;oplot, fout, sigout, color=0
;ENDIF


    rsd = rsd - gain*(ccp + ccn) ;; subtract it form residual.

ENDFOR

ampl= ampl[0: i-1]
delay= delay[0: i-1]
avg= avg[ *, 0:i-1]

;stop

;print, " ** number of iteration", i

end


