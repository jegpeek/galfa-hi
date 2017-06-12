pro polycorr, ggwb, ggnb_7679, rffrq_wb, rffrq_nb, m1, $
	snb_c, swb_c, pnb_uc, pwb_uc, pnb_uc_bin, pwb_uc_bin, $
	degree=degree, spwb=spwb, spnb=spnb, fctr=fctr

;+
;NAME:
;polycorr -- corrrect raw spectra for if gains and subtract polynomials
;
;PURPOSE:
;	correct raw spectra for i.f. gains and subtract polynomials.
;
;CALLING SEQUENCE: (normally called by m1polycorr)
;polycorr, ggwb, ggnb_7679, rffrq_wb, rffrq_nb, m1, $
;	snb_c, swb_c, pnb_uc, pwb_uc, pnb_uc_bin, pwb_uc_bin, $
;	degree=degree, spwb=spwb, spnb=spnb, fctr=fctr
;
;INPUTS:
;   GGWB[512,14,2], the wb if bandpass. ggwb[chnls, nrprx, calonoff]
;   GGNB_7679[7679,14,2], the nb if bandpass. ggwb_7679[chnls, nrprx, calonoff]
;	RFFRW_WB, the 512 wbrffrqs (ultimately from bbifdftprops)
;	RFFRW_NB, the 7679 nbrffrqs (ultimately from bbifdftprops)
;
;KEYWORD:
;	DEGREE, degree of polyfit. default = 24 (as of dec05)
;
;OPTIONAL OUTPUTS:
;	SPWB, THE WIDEBAND SPECTRA before the polyfit correction
;	SPNB, THE NARROWBAND SPECTRA before the polyfit correction
;	FCTR[ 14, nspectra], [counts of nb spectra]/[counts of wb spectra]
;each wb spectrum is multiplied by its corresponding FCTR so that
;all wb spectra and powers are on the same scale as the nb ones. 
;
;OUTPUTS:
;	SWB_C[ 512, 14, nspectra]. the gain-corr, poly-removed wb spectra.
;because it's poly-removed, the total power info is gone and the spectrum
;is sitting near zero. UNITS ARE GAIN-CORRECTED ORIGINAL WB DIGITAL UNITS.
;	SNB_C[ 7679, 14, nspectra], the gain-corr, poly-removed nb spectra.
;because it's poly-removed, the total power info is gone and the spectrum
;is sitting near zero. units are gain-corrected nb digital units.
;	PWB_UC[ 14, nspectra], the set of nb powers [2, 7, 600]. this is
;the total power under the wb spectra--the mean continuum over the band.
;UNITS ARE GAIN-CORRECTED WB ORIGINAL DIGITAL UNITS.
;	PNB_UC[ 14, nspectra], the set of nb powers [2, 7, 600]. this is
;the total power under the wb spectra--the mean continuum over the band.
;units are gain-corrected original nb digital units
;	PWB_UC_BIN[ 14, nspectra], the set of wb powers [2, 7, 600] in
;the wb data that precisely matches the BINNED NB data. the 
;original wb digital units are converted to gain-corrected original 
;nb digital units; the scale faactor is FCTR
;	PNB_UC_BIN[ 14, nspectra], the set of nb powers [2, 7, 600] in
;the BINNED nb data that precisely matches the wb data. 
;units are gain-corrected original nb digital units
;
;COMMENT AND NOTE
;	the matching up of the nb and wb intensity scales in creating
;PWB_UC_BIN and PWB_UC_BIN is crucial because
;we fit polynomials to the wb spectra and subtract them from the nb spectra.
;we bin the nb channels very carefully so that their binsize matches 
;almost exactly the bin size of the wb channels. see notes below. the
;arrays rffrq_nb_bin0 rffrq_nb_bin, rffrq_wb_bin are relevant to this process.
;
;history:
;EVOLUTION IN JUNE05: INCREASE DEGREE TO 18:
;TESTING ON SNEZ SPECTRUM RX 6, DEGREE 12 IS NOT GOOD ENOUGH BUT DEGREE 18 IS.
;
;21sep05: added fctr as optional output. tested polyfit_svd and found it wanting...
;21oct05: added pwb_uc and pnb_uc to output. these names used to refer
;to the binned versions, which are now called PWB_UC_BIN and PNB_UC_BIN;
;these binned versions, being less useful (and maybe useless), are
;added at the end to the output. 

;22nov05: modifed nb baseline fit so that it only uses a small fraction
;of the wb spectrum instead of all of it; done in the proc LEG_NB
;also, for wb fit, changed to legendre fit and changed default degree to 24.
;also, used rf frqs for leg fits instad of if frqs
;
;04May09: Removed first legendre baseline fitter.
;
;24Aug10: switched to legendrefit_mars
;01Nov10: ACTUALLY switched to legendrefit_mars. Ahem.
;-

forward_function get_xleg

if (keyword_set( degree) ne 1) then degree= 24

;ADD 2^31 OR NOT?
offset= 0ll
if ( m1[ 0,0].g_time[ 0] lt 0ll) then offset= 2ll^31ll

;DEFINE OUTPUT ARRAYS...
nspectra= (size( m1))[2]
swb_c= fltarr( 512, 14, nspectra)
snb_c= fltarr( 7679, 14, nspectra)
pwb_uc= fltarr( 14, nspectra)
pnb_uc= fltarr( 14, nspectra)
pwb_uc_bin= fltarr( 14, nspectra)
pnb_uc_bin= fltarr( 14, nspectra)
fctr= fltarr( 14, nspectra)

;CHANNEL SEPARATION FOR NB SPECTRA...
min_rffrq_nb= min( rffrq_nb)
max_rffrq_nb= max( rffrq_nb)
delfnb= (max_rffrq_nb- min_rffrq_nb)/7678.d
min_rffrq_wb= min( rffrq_wb)
max_rffrq_wb= max( rffrq_wb)
delfwb= 100.d/512.d

;FIND fwb_nb, THE WB FRQ RANGE THAT LIES WITHIN NB FRQ RANGE...
indxwb= where( rffrq_wb gt min_rffrq_nb and rffrq_wb lt max_rffrq_nb, $
	countwb, complement=indxwb_incl)
fwb_nb= rffrq_wb[indxwb]
indxnb= where( rffrq_nb gt min(fwb_nb) and rffrq_nb le max(fwb_nb))
fnb= rffrq_nb[indxnb]

;INDXNB0 AND INDXNB1 ARE THE NB INDICES THAT MATCH THE EDGES OF THE WB
;SPECTRUM. EQUAL TO 31, 7647 RESPECTIVELY.
diff0= min( abs( rffrq_wb[ indxwb[0]]- rffrq_nb), indxnb0)
diff1= min( abs( rffrq_wb[ indxwb[countwb-1]]- rffrq_nb), indxnb1)

;THERE ARE 224 NB CHNLS PER WB CHNL. THUS TO GENERATE NB BINS THAT BEGIN
;	112 CHNLS LATER WE SAY...
rffrq_nb_bin0= rffrq_nb[ indxnb0+ 112: indxnb1- 112- 1]
rffrq_nb_bin= rebin( rffrq_nb_bin0, n_elements( rffrq_nb_bin0)/224)

;CREATE WB ARRAY THAT MATCHES THE NB BINNED ONE...
rffrq_wb_bin= rffrq_wb[indxwb[0]+1:indxwb[ countwb-2]]

;THE 33 FREQS OF RFFRQ_NB_BIN ARE 0.5*DELFNB LOWER THAN
;	rffrq_sb[indxwb[0]+1:indxwb[ countwb-2]]
;	WE WILL WANT TO DISCARD THE 2 OR 3 CHANNELS AT THE EDGE.

;-------------------------------------------------------------------------- 
;CYCLE THRU ALL SPECTRA...


;FOR NRPRX= 6,6 DO BEGIN
FOR NRPRX=0, 13 DO BEGIN
;WANT MEANS OF IF GAINS TO EQUAL 1, SO FORCE THAT ***BUT ONLY FOR CALOFF***
;ggwb_normalized= ggwb[*, nrprx, 0]  ;;;;;;;;;;;;;;;;;/ mean( ggwb[*, nrprx, 0])
;ggnb_normalized= ggnb_7679[*, nrprx, 0]  ;;;;;;;;;;;;/ mean( ggnb_7679[*, nrprx, 0])
ggwb_normalized= ggwb[*, nrprx, 0] / mean( ggwb[*, nrprx, 0])
ggnb_normalized= ggnb_7679[*, nrprx, 0] / mean( ggnb_7679[*, nrprx, 0])

;FOR NSP= 300, 300 DO BEGIN
FOR NSP= 0, NSPECTRA-1 DO BEGIN
spwb= float( m1[ nrprx, nsp].g_wide+ offset)
spnb= float( m1[ nrprx, nsp].data+ offset)

;;QUICK PATCH TO LOOK AT 600 SPECTRA AVERAGED WITH CAL OFF...
;;YOU MUST ALSO USE FOR NSP= 300, 300 DO BEGIN
indxcal= where( strpos( m1[ nrprx,*].obsmode, 'BASKET') ne -1 or $
	strpos( m1[ nrprx,*].obsmode, 'FIXEDAZ') ne -1, countcal)
;print, 'countcal = ', countcal
;if countcal eq 0 then goto, skip
;spwb= total( float(m1[ nrprx, indxcal].g_wide+ offset), 3)/countcal
;spnb= total( float(m1[ nrprx, indxcal].data+ offset), 3)/countcal

;INTERPOLATE OVER DC SPIKE IN WB...
spwb[ 256]= 0.5*( spwb[ 255]+ spwb[ 257])

;CORRECT SPECTRA FOR BANDPASSES...
spwb_c= spwb/ ggwb_normalized
spnb_c= spnb/ ggnb_normalized

;GENERATE THE BINNED NB SPECTRUM...
spnb_c_bin0= spnb_c[ indxnb0+ 112: indxnb1- 112- 1]
spnb_c_bin= rebin( spnb_c_bin0, n_elements( rffrq_nb_bin0)/224)

;EXTRACT ITS WIDE COUNTERPART...
spwb_c_bin= spwb_c[ indxwb[0]+1:indxwb[ countwb-2]]

;NORMALIZE WB POWER TO NB BY SUMMING OVER IDENTICALLY BINNED SPECTRA, EXCLUDING THE
;	2 ENDPOINTS...
ndx_incl= 1 + indgen( n_elements( rffrq_nb_bin)-2)
fctr0= total( spnb_c_bin[ ndx_incl])/ total( spwb_c_bin[ ndx_incl])
spwb_c= fctr0* spwb_c
spwb_c_bin= fctr0* spwb_c_bin

;DO A LS LEG FIT TO THE DIFF BETWEEN NB AND WB POWERS. EXCLUDE THE END POINTS.
;***QUESTION*** SHOULD WE FITTING THE RATIO OR THE DIFF? ASSUME DIFF FOR NOW*****
degree_diff=2
rffrq_nb_bin_incl= rffrq_nb_bin[ ndx_incl]
xlegfit_nb_bin= get_xleg( rffrq_nb_bin, min_rffrq_nb, max_rffrq_nb, delfwb)
legendrefit_mars, xlegfit_nb_bin[ ndx_incl], (spnb_c_bin-spwb_c_bin)[ ndx_incl], degree_diff, coeffs, sigcoeffs, yfit, problem=problem

;CORRECT THE NB BINNED SPECTRUM FOR THE ABOVE FIT...
diff_fit_bin= polyleg( xlegfit_nb_bin, coeffs)
spnb_c_bin= spnb_c_bin- diff_fit_bin

;CORRECT THE FULL 7679 CHNL NB SPECTRUM FOR THE ABOVE FIT...
delrf_nb= rffrq_nb- rffrq_wb[ 255]
xlegfit_nb= get_xleg( rffrq_nb, min_rffrq_nb, max_rffrq_nb, delfwb)
diff_fit= polyleg( xlegfit_nb, coeffs)
; decommented this line? correct? JEGP Nov 1 2010
spnb_c= spnb_c- diff_fit

;GET THE POLYUNCORRECTED SPECTRAL INTEGRALS in NB freq region
;	BY TAKING MEAN OF BINNED SPECTRA (EXCLUDING THE TWO ENDPOINTS)...
pnb_uc_bin[ nrprx, nsp]= mean( spnb_c_bin[ ndx_incl])
pwb_uc_bin[ nrprx, nsp]= mean( spwb_c_bin[ ndx_incl])/ fctr0

;GET THE POLYUNCORRECTED SPECTRAL INTEGRALS over whole nb and wb freq range
;	BY TAKING MEAN OF unbinned SPECTRA...
pnb_uc[ nrprx, nsp]= mean( spnb_c)
pwb_uc[ nrprx, nsp]= mean( spwb_c)/ fctr0

;STOP, 'STOP ===================== POLYCORR.PRO 1'

;DO THE LEGENDRE FIT TO WB SPECTRUM...
nrt=512
fspan= max_rffrq_wb- min_rffrq_wb
dfspan= fspan/( nrt-1.d)
sfspan=  max_rffrq_wb+ min_rffrq_wb
xlegfit= get_xleg(quick=512)
legendrefit_mars, xlegfit[indxwb_incl], spwb_c[ indxwb_incl], degree, $
        coeffs, sigcoeffs, yfit, problem=problem

;APPLY COEFFICIENTS TO WB SPECTRUM...
rfleg_wb= polyleg( xlegfit, coeffs)

;WE USED TO APPLY THESE COEFFS TO THE NB SPECTRUM. BUT THAT'S NOT GREAT. 
;NOW WE HAVE A SEPARATE NB BASELINE FITTER PROC.
leg_nb, rffrq_wb, rffrq_nb, spwb_c, rfleg_nb, coeffs_nb

;stop, 'STOP ================== IN POLYCORR BEFORE APPLYING CORRECTIONS; ', nrprx, nsp

;SUBTRACT OFF BOTH POLYNOMIALS FROM THE FULL WB AND NB SPECTRA...
swb_c[ *, nrprx, nsp]= (spwb_c- rfleg_wb)/fctr0
snb_c[ *, nrprx, nsp]= spnb_c- rfleg_nb
fctr[ nrprx, nsp]= fctr0

;stop, 'STOP ================== IN POLYCORR AT END; ', nrprx, nsp

skip:
ENDFOR
ENDFOR

end                                                                         


