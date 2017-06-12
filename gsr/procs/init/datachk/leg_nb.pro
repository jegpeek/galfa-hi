pro leg_nb, rffrq_wb, rffrq_nb, spwb_c, rfleg_nb, coeffs, $
	degree=degree, fctr=fctr

;+
;LEG_NB -- USE WB SPECTRUM TO FIT NB SPECTRUM AND SUBTRACT THE BASELINE
;
;fit a low-order polynomial to wb spectrum using only the immediate vicinity 
;of the nb spectrum.
;
;CALLING SEQUENCE:
;	LEG_NB, rffrq_wb, rffrq_nb, spwb_c, rfleg_nb, $
;	degree=degree, fctr=fctr
;
;INPUTS:
;	RFFRQ_WB, the 512 wb rffrq
;	RFFR1_NB, the 7679 nb rffrq
;	SPWB_C, the wb spectrum not baseline corrected
;
;OPTIONAL INPUTS:
;	DEGREE, the deg of the poly to fit. defaule=6
;	FCTR, the amount of 'baseline' on each side of the nb spectrum.
;	    X0 00000000000 X1 ---------------- X2 000000000000000 X3;
;	for fctr=1, the 0000 is equal in nr chnls to the ----.
;	default=1
;
;OUTPUTS:
;	RFLEG_NB, the legendre-fitted wb spectrum for the nb rffrq_nb.
;	COEFFS, the fitted legendre coeffs
;
;-

;DEFINE DEFAULT DEGREE AND FCTR...
if keyword_set( degree) eq 0 then degree= 6
if keyword_set( fctr) eq 0 then fctr= 1.

fspan= max(rffrq_wb)- min(rffrq_wb)
dfspan= fspan/( n_elements( rffrq_wb)- 1.d)

;GT INDICES OF WB FREQS THAT LIE WITHIN EXTREMES OF NB FREQS...
indxwb= where( rffrq_wb gt min(rffrq_nb) and rffrq_wb lt max( rffrq_nb), $
        countwb, complement=indxwb_incl)
indxwb_range= max(indxwb)- min(indxwb)
maxindxwb= max(indxwb)
minindxwb= min(indxwb)

;WE USE 000 RANGE BELOW TO FIT LEGPOLY FOR WB SPECTRUM.
;X0 00000000000 X1 ---------------- X2 000000000000000 X3;
x0= minindxwb- fctr*indxwb_range
x1= minindxwb
x2= maxindxwb
x3= maxindxwb+ fctr*indxwb_range
ndg= indgen( 512)
indxwb_incl= [ndg[ x0:x1], ndg[ x2:x3]]
mmrffrq_wb= minmax( rffrq_wb[ indxwb_incl])

;SET UP LEGENDRE FIT TO WB SPECTRUM USING ABOVE INTERVAL AND DO IT...
xlegfit= get_xleg( rffrq_wb, mmrffrq_wb[0], mmrffrq_wb[1], dfspan)
legendrefit, xlegfit[ indxwb_incl], spwb_c[ indxwb_incl], degree, $
        coeffs, sigcoeffs, rfleg_wb, residbad= 4., problem=problem

;APPLY RESULTS OF FIT TO NB SPECTRUM...
;delrf_nb= rffrq_nb- rffrq_wb[ 255]
;xlegfit_nb= get_xleg( delrf_nb, mmdelrf[0], mmdelrf[1], dfspan)
xlegfit_nb= get_xleg( rffrq_nb, mmrffrq_wb[0], mmrffrq_wb[1], dfspan)
rfleg_nb= polyleg( xlegfit_nb, coeffs)

;stop

return
end
