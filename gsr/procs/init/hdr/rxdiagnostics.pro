
pro rxdiagnostics, mh, ccf, acf, rmsratio, sju, nindxr, $
	smoothtime=smoothtime, nb=nb

;+
;NAME:
;rxdiagnostics -- calculate statistical properties of datapoints in
;an mh file using total power data.
;
;PURPOSE: CALCULATE CCF, WHICH PROVIDES INFO ON CABLE INTERCHANGE;
;	ACF, WHICH PROVIDES INFO ON RECURRANT INTERVERING PULSES
;	RMSRATIO, WHICH PROVIDES INFO ON WHETHER AN RX IS WORKING
;	SJU, CONVOLVES THE TIME SERIES WIHT 12 S PULSE TRAIN
;
;CALLING SEQUENCE:
;rxdiagnostics, mh, ccf, acf, rmsratio, sju, nindxr, $
;	smoothtime=smoothtime, nb=nb
;
;INPUTS:
;	MH, the mh structure
;
;OPTIONAL INPUTS:
;	NB. if set, it does nb. wb is the default
;	SMOOTHTIME, nr secs over which to median filter. should be
;odd. default is 19 seconds.
;OUTPUTS:
;	CCF, the ccf (not really ccf: more likee structure function,
;in that the self-product is zero and low values mean high correlation)
;	ACF, the acf
;	RMSRATIO, the ratio of rms power variation to mean
;	SJU, convolve powers with 12 s pulse train divide by mean power
;
;HISTORY:
;	paininss development finally works on 19oct2005.
;-

;INTERNALLY:
;nrmh is the nr of mh datapoints
;
;nindxr is the nr of non-cal datapoints
;indxr are the indices of the non-cal datapoints
;
;nindxz is the nr of yes-cal datapoints
;indxz are the indicese of the yes-cal datapoints
;
;pp is all of the mh.pwrs
;ppmod is used to calc ACF and SJU. it is like pp but:
;	a. the yes-cal ones are zeroed
;	b. a 39-point median filter is applied
;	c. in the rx-avg median-filtered stream, points > 3sigma are 
;	identified and zerod in individual rx's.
;
;ppp is the set of non-cal mh.pwrs--the yes-cal ones are excluded,
;	so ppp is a shorter array than pp. the same points zeroed
;	in pppmod are set eqwual to median of ppp, to get rid of outliers
;	in the rms calculation. ppp is used to calculate RMSRATIO
;pppmod is used to calc find bad datapoints. it is like ppp but:
;	a. the yes-cal ones are zeroed
;	b. a 39-point median filter is applied
;	c. in that median-filtered stream, points > 3sigma are 
;		declared to be bad
;pppa is like ppp except that all rx total pwrs are scaled to be identical
;	we take diffs of pppa from rx to rx to calculate the CCF

if keyword_set( smoothtime) eq 0 then smoothtime=19;

ccf= fltarr( 14, 14)
acf= fltarr( 128, 14)
rmsratio= fltarr( 14)
sju= fltarr( 14)

;DEFINE INDSR, THE SET OF MH INDICES NOT IN CALS...
indxr= where( strtrim(mh.obsmode,2) ne 'SMARTF' and $
             strtrim(mh.obsmode,2) ne 'CAL', nindxr)
IF nindxr LE 25 THEN RETURN

nrmh= n_elements( mh)

;DEFINE PP, PWR ARRAYS INCLUDING ALL DATA...
if keyword_set( nb) then pp= mh.pwr_nb else pp= mh.pwr_wb
pp= reform( pp, 14, nrmh)

;DEFINE PPP, THE NON-CAL PWR ARRAYS (SHORTER THAN PP IF THERE ARE CALS)...
ppp= pp[*, indxr]

;DEFINE pppmod BY DOING A MEDIAN FILTER TO SUBTRACT OFF LARGE SCALE DRIFTS...
pppmod= pp
for nr=0,13 do $
	pppmod[ nr,*]= pp[ nr,*]-median( reform(pp[ nr,*]),smoothtime)
;FOR THE AVERAGE PPPMOD, FIND THOSE PARTICULAR DATAPOINTS WHICH 
;	DIFFER BY MORE THAN 3 SIGMA AND ZERO THEM IN EACH
;	INDIVIDUAL PPP AND PPPMOD.
pppmodavg= total( pppmod,1)/14.
rms= sqrt( variance( pppmodavg))
indxrms= where( abs( pppmodavg) gt 3.*rms, countrms)
IF COUNTRMS GT 0 THEN BEGIN
pppmod[ *, indxrms]= 0.
for nr=0,13 do ppp[ nr, indxrms]= median( ppp[ nr,*])
ENDIF

;USE PPP TO GET RMSRATIO'S AND COMPARE TO AVG...
FOR NR=0, 13 DO BEGIN
mom= moment( ppp[ nr,*])
rmsratio[ nr]= sqrt( mom[ 1])/mom[ 0]
ENDFOR

;GET PPPA, WHICH IS PPP WITH ALL RX HAVING EQUAL RESPONSE...
fctr= total(ppp,2)
fctr=fctr/mean(fctr)
pppa=ppp
for nr=0,13 do pppa[nr,*]=pppa[nr,*]/fctr[nr]
;DONT INCLUDE POINTS WHERE THE MEAN DIFFERS MUCH FROM ZERO...
pppamean= total(pppa,1)/14.
;SUBTRACT THE MEAN FROM EVERYTHING TO HELP GET RID OF INTERFERENCE...
for nr=0,13 do pppa[nr,*]=pppa[nr,*]-pppamean

;stop, 'STOP AFTER PPPA GENERATED'

;NEW WAY TO CCF:
FOR NR0=0,13 DO BEGIN
FOR NR1=NR0,13 DO BEGIN
diff= reform( pppa[ nr0,*]- pppa[ nr1,*])
diff= diff - median( diff, smoothtime)
avg=  reform( pppa[ nr0,*]+ pppa[ nr1,*])
avg= avg - median( avg, smoothtime)
ccf[ nr1,nr0]= sqrt( variance( diff))/ sqrt( variance( avg))
ccf[ nr0,nr1]= ccf[ nr1,nr0]
ENDFOR
ENDFOR

;stop, 'STOP AFTER NEW WAY CCF GENERATED'

;--------------------------NOW DO THE ACF'S-----------------------
; NEED TO RESTORE TIME COHERENCE, SO INSTEAD OF
;USING SHORTER ARRAYS WE ZERO THE CAL RECORDS...
;RESTRICT TO NONCAL SPECTRA...

;FIND THE CAL RECORDS AND SET THE PWR PP EQW TO ZERO FOR TIME ANALYSIS...
indxz= where( strtrim(mh.obsmode,2) eq 'SMARTF' or $
              strtrim(mh.obsmode,2) eq 'CAL', nindxz)
if (nindxz eq 0) then return
pp[ *,indxz]= 0.

;SUBTRACT MEDIAN FROM PP TO ZERO OUT LONG TERM STUFF...
ppmod= pp
for nr=0,13 do $
  ppmod[ nr,*]= pp[ nr,*]-median( reform(pp[ nr,*]),smoothtime)
;FIND THOSE PARTICULAR DATAPOINTS WHICH DIFFER BY MORE THAN 3 SIGMA
;	AND EXCLUDE THEM.
FOR NR=0,13 DO BEGIN

;ZERO OUTLIERS
rms= sqrt( variance( ppmod[ nr,*]))
indxrms= where( abs(ppmod[ nr,*]) gt 3.*rms, countrms)
if countrms gt 0 then ppmod[ nr, indxrms]= 0.
ENDFOR

length=128 < nrmh-2
lag= indgen( length)
for nr=0,13 do acf[ 0:length-1,nr]= a_correlate( ppmod[ nr,*], lag)

;DO CROSSCORRELATION OF PPMOD WITH PULSE TRANS OF 12 SEC PERIOD...
IF NRMH GT 13 THEN BEGIN
sig= fltarr( 600) & sig= reform(sig,12,50) & sig[ 0,*]= 1. & sig=reform(sig,600)
sig= sig[ 0:nrmh-1]
lagcc= indgen( 12)
ccsig= fltarr( 12, 14)
for nr=0,13 do ccsig[*, nr]= c_correlate( ppmod[ nr,*], sig, lagcc)

for nr=0,13 do begin
pwr= sqrt( variance( ccsig[*,nr]))
maxi= max( abs( ccsig[ *,nr]), indxmaxi)
sju[ nr]= ccsig[ indxmaxi, nr]/ pwr
ENDFOR
ENDIF

;stop

return
end



