pro acfchksym, nindx, acf, rxradar, nfrq

;+
;NAME:
;ACFCHKSYM, calc pwr spectrum of symmetrized input acf to find peak period
; and power
;
;CALLING SEQUENCE:
;acfchksym, nindx, acf, rxradar, nfrq
;
;INPUT PARAMETERS:
;NINDX, the nr of records processed by rxdiagnostic.pro. >25: forget it
;ACF, the acf calc by rxdiagnostic.pro
;
;OUTPUTS:
;RXRADAR[2,14], [period in s,  power/mean power] for each of 14 rx
;NFRQ, the nr of elements in acf
;
;-

rxradar= fltarr( 2, 14)
nfrq= n_elements( acf)/14.

IF (NINDX LT 25) THEN RETURN

if keyword_set( nfrq) eq 0 then nfrq= 128

;GET TIMES, FREQS FOR FFT, DFT...
tsmpl= 1.
times= tsmpl* (findgen( nfrq) - nfrq/2)
fsmpl= 1./tsmpl
fnyq= 0.5*fsmpl
delf= fsmpl/ nfrq
frqs= shift( fsmpl*(findgen( nfrq)- nfrq/2)/ nfrq, nfrq/2)

times_sym= shift( tsmpl*( findgen( 2*nfrq)- nfrq), nfrq)
delf_sym= fsmpl/(2*nfrq)
frqs_sym= shift( fsmpl*(findgen( 2*nfrq)- nfrq)/(2* nfrq), nfrq)

;nr=3
FOR NR=0, 13 DO BEGIN
;FOR NR=1,1 DO BEGIN
;FOR NR=2,3 DO BEGIN
symp= acf[*,nr]
sym= [symp, symp[127], reverse( symp[1:*])]

;GET APPROX FRQ FROM fFT...
pwrsymfft= abs(fft( sym))
pwrmax= max( pwrsymfft[ 1:nfrq], indxpwrmax)

;stop

;;COMPARE WITH DFT RESULT...
;dft, times_sym, sym, frqs_sym, pwrsymdft

;CHECK FOR SUBHARMONICS ASSUMING FUNDAMENTAL IS IN 4TH FREQ BIN OR HIGHER...
nrsubmax= indxpwrmax/4
IF (NRSUBMAX GT 1) THEN BEGIN
pwrtry= fltarr( nrsubmax+1)
FOR NRSUB= 1, NRSUBMAX DO BEGIN
chnltry= indxpwrmax/nrsub
pwrtry[nrsub]= total( pwrsymfft[ chnltry-1:chnltry+1])
ENDFOR
;FIND THE MAX PWR OF ALL THE SUBHARMONICS...
pwmax= max( pwrtry, nrsubpwmax)
indxpwrmax= indxpwrmax/nrsubpwmax
ENDIF

;stop

if (indxpwrmax) eq 0 then goto, skip

;EXPAND FRQ SCALE USING DFT...
frqsnew= frqs_sym[ indxpwrmax-1]+ findgen(19)*delf_sym/8.
dft, times_sym, sym, frqsnew, symdft

;FIND MAX AMP OF DFT AND FIT A PARABOLA TO GET THE EXACT CNTR FRQ...
pwrmax= max( abs(symdft), chnl)
pwrmax= float( symdft[ chnl])
frqmax= frqsnew[ chnl]

;RECORD THE PERIOD OF MAX AND ITS POWER RELATIVE TO MEDIAN POWER...
;rxradar[ *,nr]= [1./frqmax, pwrmax/median( pwrsymfft)]
rxradar[ *,nr]= [1./frqmax, pwrmax/mean( pwrsymfft)]

SKIP:

ENDFOR

;stop

return
end
