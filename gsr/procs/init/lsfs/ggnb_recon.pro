pro ggnb_recon, rffrq_wb, rffrq_nb, bbgain_dft_nb, ggwb, ggnb, $
	ggnb_7679, ggnb_coeffs, ggnb_sigcoeffs, ggnb_problem, $
	quiet=quiet

;+
;PURPOSE
;	given the rebinned nb gains, calculate their 7680-channel counterpart.
;INPUTS:
;	RFFRQ_WB, the array of 512 wb rf freqs
;	RFFRW_NB, the array of 7679 nb rf freqs
;	BBGAIN_DFT_NB[ 7679], the theoretical nb filter shape.	
;	GGWB[ 512, 14, 2], the wb gains for pol, rx, calonoff
;	GGNB[ 480, 14, 2], the nb gains for pol, rx, calonoff
;
;OUTPUTS:
;	GGNB_7679, the 7679-chnl nb gains.
;	GGNB_COEFFS, the array of ggnb_star polyfit coeffs (see below)
;	GGNB_SIGCOEFFS, uncertainties in ggnb_star polyfit coeffs (see below)
;	GGNB_PROBLEM, nonzero if problems in ggnb_star fits. 
;METHOD:
;	input data consist of:
;	the wideband gains gwb512, 512 chnls chnls
;	the obs nb gains ggnb_480, 480 chnls, bad fourier coeffs; 
;		needs interpolation.
;	the theoretical nb gains thybb_480 and 7679 version bbgain_dft_nb
;
;	goal is to to make ggnb_star, a version of ggnb without the bad
;fourier coeffs, that has same shape as widebsand spectrum. thus:
;
;	1. generate gwb_480, a 480 channel version of gwb512 using
;polyfit interpolation, degree 6.
;
;	2. take the ratio gnb_480/( bbgain_dft_nb480 * gwb_480) . 
;		combo= gnb_480/( thybb_480* gwb_480)
;this combo should, in principle, be flat. fit it to a polynomial.
;
;	3. generate the ggnb_star using coeffs of above polynomial.
;
;in all polyfits the frequencies are centered at zero to avoid fitting problems.
;
;-


;-----PRELIMINARIES: GENERATE FREQ ARRAYS AND 480 CHNL THEOR GGNB -----

;DEFINE OUTPUT ARRAY FOR GAINS...
ggnb_7679= fltarr( 7679, 14, 2)
;DEFINE OUTPUT ARRAYS FOR POLY COEFFS...
ggnb_coeffs= fltarr( 8, 14, 2)
ggnb_sigcoeffs= fltarr( 8, 14, 2)
ggnb_problem= intarr( 14, 2)

;--------- GENERATE 480 CHNL VERSION OF NB FRQ ARRAY AND GAIN ARRAY------
	;CALCULATE THE 480 NB FRQS THAT WE PREVIOUSLY USED IN LSFS.PRO
delfrq= ( rffrq_nb[ 7678]- rffrq_nb[ 0])/7678.d
rffrq_nb_7680= [ rffrq_nb[0]- delfrq, rffrq_nb]
rffrq_nb_480= rebin( rffrq_nb_7680, 480)

	;INCREASE NR OF CHNLS IN theoretical NB SPECTRUM FROM 7679 TO 7680...
thybb_7680= [bbgain_dft_nb[ 0], bbgain_dft_nb]

	;DEFINE A 480 CHANNEL VERSION OF THE THEORETICAL GAIN...
thybb_480= rebin( thybb_7680, 480)

	;FIND fwb_nb, THE WB FRQ RANGE THAT LIES WITHIN NB FRQ RANGE...
indxwb= where( rffrq_wb gt min(rffrq_nb) and rffrq_wb lt max( rffrq_nb), countwb)
fwb_nb= rffrq_wb[indxwb]
indxnb= where( rffrq_nb gt min(fwb_nb) and rffrq_nb le max(fwb_nb))

;	DEFINE fwb_nbx, XTENDED WB FRQ RANGE, BY
;ADDING A CHNL ON EACH SIDE TO ENCOMPASS ENTIRE NB FREQ RANGE...
fwb_nbx= rffrq_wb[ indxwb[ 0]-1: indxwb[0]+ countwb]

;	FOR POLYFIT PURPOSES, GENERATE FRQS CNTRED ABOUT THE MEAN OF fwb_nbx...
fzro= mean( fwb_nbx)
fwb_nbxd= fwb_nbx- fzro
fnb_xd= rffrq_nb_480- fzro

;------------------------CYCLE THRU RCVRS---------------------------
;	CHOOSE A SPECTRUM TO WORK WITH...
nrprx= 5
nsp= 300

FOR NRPRX= 0,13 DO BEGIN
FOR NRCAL= 0,1 DO BEGIN

;	DEFINE A SHORT NON-INDIXED FORM FOR THE WIDEBAND AND NARROWBAND GAIN...
gwb_512= ggwb[ *, nrprx, nrcal]
gnb_480= ggnb[ *, nrprx, nrcal]

;	OBTAIN PORTION OF WB GAIN THAT LIES WITHIN NB FRQ RANGE...
gwb_nb= gwb_512[ indxwb]
gwb_nbx= gwb_512[ indxwb[ 0]-1: indxwb[0]+ countwb]

;	FIT A POLYNOMIAL TO THE WB GAIN...
degwb= 6
polyfit, fwb_nbxd, gwb_nbx, degwb, coeffswb, sigcoeffswb, gwb_nbxfit, $
	residbad= 3., goodindx=goodindx, problem=problem

;	NOW USE THIS POLYNOMIAL AS INTERP FCN TO GET WB GAIN SPECTRUM AT 
;THE 480 NB FREQS, THEN AT THE 7679 FREQS...
gwb_480= fltarr( 480)
for nd=0, degwb do gwb_480= gwb_480+ coeffswb[ nd]* fnb_xd^nd
gwb_7679= fltarr( 7679)
for nd=0, degwb do gwb_7679= gwb_7679+ coeffswb[ nd]* (rffrq_nb- fzro)^nd

;	WE WILL FIT THE FOLLOWING COMBO TO A POLYNOMIAL:
deg=2
combo= gnb_480/( thybb_480* gwb_480)
polyfit, fnb_xd, combo, deg, coeffs_c, sigcoeffs_c, combofit, $
	residbad=3., goodindx=goodindx, problem=problem

;	CALCULATE THE SMOOTHED APPROX TO THE OBSERVED 480 CHNL GAINS...
gg480_star= fltarr( 480)
for nd=0, deg do gg480_star= gg480_star+ coeffs_c[ nd]* fnb_xd^nd
gg480_star= gg480_star* thybb_480* gwb_480

;	CALCULATE THE SMOOTHED APPROX TO THE OBSERVED 480 CHNL GAINS...
gg7679_star= fltarr( 7679)
for nd=0, deg do gg7679_star= $
	gg7679_star+ coeffs_c[ nd]* (rffrq_nb- fzro)^nd
gg7679_star= gg7679_star* bbgain_dft_nb* gwb_7679

IF KEYWORD_SET( QUIET) NE 1 THEN BEGIN
plot, fnb_xd, gnb_480
oplot, fnb_xd, gg480_star, color=!red
oplot, rffrq_nb- fzro, gg7679_star, color=!green, lines=2
ENDIF

polyndx= indgen( deg+ 1)
ggnb_7679[ *, nrprx, nrcal]= gg7679_star
ggnb_coeffs[ polyndx, nrprx, nrcal]= coeffs_c
ggnb_sigcoeffs[ polyndx, nrprx, nrcal]= sigcoeffs_c
ggnb_problem[ nrprx, nrcal]= problem

ENDFOR
ENDFOR

;stop

end
