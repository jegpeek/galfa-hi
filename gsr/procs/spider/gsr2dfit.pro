pro gsr2dfit, nspdr, npol, beamin_arr, beamout_arr, nbin=nbin

;+
;PURPOSE: do the grand 2d least squares fit for the beam plus sidelobes.
;
;INPUTS:
;
;	HPBW_GUESS, the hpbw guessed value for ls fit.  all internal offset
;angles, and some outputs, are specified in units of hpbw_guess. 
;
;	
;	BEAMIN, the structure containing input data.  Inputs from
;structure BEAMIN that are used include... 
;
;	BEAMIN.AZENCODERS, the set of [60,4] az encoder readings for the pattern.
;	BEAMIN.ZAENCODERS, the set of [60,4] za encoder readings for the pattern.
;
;
;	BEAMIN.AZOFFSETS, BEAMIN.ZAOFFSETS, the set of [60, 4] az, za
;offsets in the pattern.  UNITS ARE ARCMIN, NOT HPBW; THIS IS A CHANGE
;FROM ORIGINAL VERSION.  (the array size [60, 4] is illustrative; sizes
;are determined from the input data.) these are immediately copied to the
;(azoffset, zaoffset) arrays, which are in units of hpbw_guess, and which
;are used in the calculations. 
;
;
;	TOTOFFSETS, the set of [60, 40] total offsets (same for each
;strip...runs negative to positive).  UNITS ARE ARCMIN, NOT HPBW; THIS IS
;A CHANGE FROM ORIGINAL VERSION.  (the array size [60, 4] is
;illustrative; sizes are determined from the input data.)
;
;	STOKESOFFSET_CONT, the total system temp (antenna plus rcvr) for
;each pattern point.  stokesoffset_cont[ 4, 60, 4]; again, sizes are
;determined from the input data. 
;	
;	STRIPFIT, the array of outputs from least square fitting each
;strip previously in BEAM1DFIT.
;
;KEYWORD: 
;	SQUOOSH. set it to include squoosh in the fit.
;
;OUTPUTS
;
;	B2DFIT is the output array containing the solved-for ls
;coefficients, size [50,2]. Not all the elements are used to reserve room
;for future expansion if required (God forbid!). In the second element,
;The first element is the value, the second its formal error from the
;fit.
;
;	b2dfit = fltarr[ 50,2]		;NORMALLY 0 IS VALUE, 1 IS ITS ERROR
;	b2dfit[ 0,*] = [ tsys,		;OFFSRC TSYS, KELVINS
;	b2dfit[ 1,*] = [dtsys_dza,	;DTSYS/DZA, KELVINS/DEG
;	b2dfit[ 2,*] = [ tsrc,		;SRC DEFLN, KELVINS
;	b2dfit[ 3,*] = [ az_bmcntr,	;AZ OFFSET OF SCAN CENTER
;						FROM TRUE BEAM CENTER, ARCMIN
;	b2dfit[ 4,*] = [ za_bmcntr, 	;ZA OFFSET, AS FOR AZ
;	b2dfit[ 5,*] = [ bmwid_0,	;AVG HPBW, ARCMIN  ***SEE NOTE BELOW***
;	b2dfit[ 6,*] = [ bmwid_1, 	;(MAXHPBW-MINHPBW)/2, ARCMIN *SEE NOTE*
;	b2dfit[ 7,*] = [ phi_bm, ]	;PA OF HPBW MAJOR AXIS, DEGREES
;	b2dfit[ 8,*] = [ alpha_coma, 	;COMA AMPLITUDE, UNITS OF HPBW
;	b2dfit[ 9,*] = [ phi_coma,	;PA OF COMA LOBE, DEGREES 
;	b2dfit[ 10,0] = [ sigma, 	;SIGMA OF DATAPOINTS, KELVINS
;	b2dfit[ 10,1] = hpbw_guess] 	;nominal HPBW ARCMIN USED IN
;		OBSERVING, and the guess for the nonlinear Gauss fit

;	b2dfit[ 11,*] = [ beam_integral,;MAIN BEAM INTEGRAL, K ARCMIN^2

;THE FOLLOWING ARE DEFINED IN PLOT2D_BEAMFITS.PRO
;	b2dfit[ 12,*] = adopted source flux. THIS IS SET EQUAL TO 1 JY
;		UNLESS IT IS SPECIFIED IN ADVANCE.
;	b2dfit[ 13,0] = hgt[0]: the zeroth fourier coeff of teh first sidelobe
;		(same as the average sidelobe level) UNITS ARE TSRC, i.e. 
;		this is ratio of sidelobe hgt to mainbeam peak 
;	b2dfit[ 13,1] = nterms, the nr of terms used in the sidelobe
;			fourier reconstruction
;	b2dfit[ 14,*] = eta_mainbeam for the adopted source flux
;	b2dfit[ 15,*] = eta_sidelobe for the adopted source flux
;	b2dfit[ 16,*] = kperjy for the adopted source flux
;	b2dfit[ 17,0] = the center freq in MHz (set OUTSIDE this program)
;	b2dfit[ 17,1] = the bandwidth in MHz (set OUTSIDE this program)
;
;THE PREVIOUS ARE DEFINED IN BEAM2D_PLOT.PRO
;
;	.   .   .   .
;
;	b2dfit[ 18,0] = the mean PA for the pattern
;	b2dfit[ 18,1] = ptsperstrip, nr points per strip
;	b2dfit[ 19,*] = [meanaz, meanza], meam az and za for the pattern
;obtained by averaging all az's and za's for the 240 observations in the
;pattern. 


;***********IMPORTANT NOTE ABOUT DEFINITION OF POSITION ANGLE PA******

;	POSITION ANGLES (PA'S) ARE IN THE AZ, ZA COORDINATE SYSTEM AND
;ARE MEASURED FROM AZ=0 TOWARDS POSITIVE ZA.
;THIS IS DEFINITELY NOT THE CONVENTIONAL ASTRONOMY DEFINITION OF PA!!
;RATHER, IT CORRESPONDS TO PHI IN THE AOTM WRITEUP.

;************** IMPORTANT NOTE ABOUT DEFINITION OF WIDTH **************
;	THE INPUTS AND OUTPUTS TO THIS PROC FOR THE WIDTH ARE HPBW,
;NOT 1/E. THUS B2DFIT IS HPBW IN ARCMIN.
;	HOWEVER, WITHIN THIS ROUTING, THE WIDTHS ARE CONVERTED TO
;1/E.

;MODIFICATION HISTORY:
;	Definition of alpha_coma changed 17 oct 2000. see
;	Bug in hpbw conversion fixed 29 oct 2000. affects defn of alpha_coma.
;	calculate meanaz using vector avg, 30 oct 2000.
;	squash_avg term added (vectors from s2wdfit have 8 els instead
;	of 7; include results in b2dfit). 31jul03

;g2dcurv_allcal.pro, mainbeam_eval.pro

;-

;EXTRACT VARIABLE NAMES FROM INPUT STRUCTURE BEAMIN...
hpbw_guess= beamin_arr[ nspdr].hpbw_guess
az_encoder= beamin_arr[ nspdr].azencoders
za_encoder= beamin_arr[ nspdr].zaencoders
azoffset= beamin_arr[ nspdr].azoffsets/ hpbw_guess
zaoffset= beamin_arr[ nspdr].zaoffsets/ hpbw_guess
totoffset= beamin_arr[ nspdr].totoffsets/ hpbw_guess

;stokesoffset_cont= beamin_arr[ nspdr].stkoffset_cont
stokesoffset_cont= fltarr( 4, 60, 4)
stokesoffset_cont[ 0,*,*]= beamin_arr[ nspdr].tsys[npol,*,*]

;stop

IF N_ELEMENTS( NBIN) NE 0 THEN BEGIN
stripfit= beamout_arr[ nspdr].(npol+2)[nbin].stripfit
b2dfit = beamout_arr[ nspdr].(npol+2)[nbin].b2dfit
ENDIF ELSE BEGIN
stripfit= beamout_arr[ nspdr].(npol).stripfit
b2dfit = beamout_arr[ nspdr].(npol).b2dfit
ENDELSE

meanza = mean( za_encoder)
avg_srcphase, !dtor*az_encoder, meanaz
meanaz = !radeg* meanaz
meanpa= pangle( meanaz,meanza)

delt_zaencoder = za_encoder - meanza
sigmalimit=3.

;SIDELOBE PARAMETERS:
hgt_lobe= reform( stripfit[ 2:3, *])
cen_lobe= reform( stripfit[ 5:6, *])
wid_lobe= reform( stripfit[ 8:9, *])

;GENERATE THE GUESSES...
tsrc0 = mean(  stripfit[1,*])
az_bmcntr0 = 0.01
za_bmcntr0 = 0.01
phi_bm0 = !dtor * 80.
alpha_coma0 = 0.01
phi_coma0 = !dtor* 45.
tsys0= mean( stripfit[ 10, *])
dtsys_dza0 = 1.
;28 OCT: CHANGE THESE TO 1/E!
bmwid_00 = 0.6005612* mean( stripfit[7,*])
bmwid_10 = 0.6005612* (abs( stripfit[ 7, 1] - stripfit[ 7, 0]))


;DO THE STOKES I FIT...
gsrg2dfit_allcal, sigmalimit, delt_zaencoder, azoffset, zaoffset, totoffset, $
        stokesoffset_cont, hgt_lobe, cen_lobe, wid_lobe, $
        tsys0, dtsys_dza0, tsrc0, az_bmcntr0, za_bmcntr0, $
        bmwid_00, bmwid_10, phi_bm0, alpha_coma0, phi_coma0, $
        tfit, sigma, tsys, dtsys_dza, tsrc, az_bmcntr, za_bmcntr, $
        bmwid_0, bmwid_1, phi_bm, alpha_coma, phi_coma, $
        sigtsys, sigdtsys_dza, sigtsrc, sigaz_bmcntr, sigza_bmcntr, $
        sigbmwid_0, sigbmwid_1, sigphi_bm, sigalpha_coma, sigphi_coma, $
        problem, cov

;stop

nr=-1
nr=nr+1 & b2dfit[ nr,*] = [ tsys, sigtsys]
nr=nr+1 & b2dfit[ nr,*] = [dtsys_dza, sigdtsys_dza]
nr=nr+1 & b2dfit[ nr,*] = [ tsrc, sigtsrc]

;POINTING OFFSETS IN ARCMIN...
nr=nr+1 & b2dfit[ nr,*] = hpbw_guess* [ az_bmcntr, sigaz_bmcntr]
nr=nr+1 & b2dfit[ nr,*] = hpbw_guess* [ za_bmcntr, sigza_bmcntr]

;THE **HPBW** BEAMWIDTHS IN ARCMIN...
nr=nr+1 & b2dfit[ nr,*] = hpbw_guess* [ bmwid_0, sigbmwid_0]/0.6005612 
nr=nr+1 & b2dfit[ nr,*] = hpbw_guess* [ bmwid_1, sigbmwid_1]/0.6005612

;THE PA OF THE HPBW ELLIPSE. CONVERT TO DEGREES.
nr=nr+1 & b2dfit[ nr,*] = !radeg*[ phi_bm, sigphi_bm]

;TAKE CARE OF NEGATIVE ALPHA_COMA CASE...
IF (alpha_coma lt 0.) THEN BEGIN
	alpha_coma= -alpha_coma
	phi_coma= phi_coma+ !pi
ENDIF

;UNITS OF ALPHA_COMA: CONVERT TO UNITS OF BMWID_0 BY MULTIIPLYING BY BMWID_0.
;THEN CONVERT TO UNITS OF HPBW BY MULTIPLYING BY 1/0.6
;nr=nr+1 & b2dfit[ nr,*] = [ alpha_coma, sigalpha_coma]*bmwid_0/0.6005612 

;CHANGE OF 17 OCT: LEAVE THE UNITS OF ALPHA_COMA ALONE. COMPLETELY!
nr=nr+1 & b2dfit[ nr,*] = [ alpha_coma, sigalpha_coma]
nr=nr+1 & b2dfit[ nr,*] = !radeg* [ phi_coma, sigphi_coma]

nr=nr+1 & b2dfit[ nr,*] = [ sigma, hpbw_guess]

;BEAM INTEGRAL: USE ANALYTIC RESULT AND MULTIPLY BY TSRC; MAKE THE
;UNITS K ARCMIN^2
beam_integral= !pi* bmwid_0^2
sigbeam_integral= 2.* !pi* bmwid_0* sigbmwid_0
nr=nr+1 & b2dfit[ nr,*] = tsrc* hpbw_guess^2* [ beam_integral, sigbeam_integral]

b2dfit[ 18,0]= meanpa
b2dfit[ 19,*] = [meanaz, meanza]

IF N_ELEMENTS( NBIN) NE 0 THEN BEGIN
beamout_arr[ nspdr].(npol+2)[nbin].b2dfit= b2dfit
ENDIF ELSE BEGIN
beamout_arr[ nspdr].(npol).b2dfit= b2dfit
ENDELSE

;STOP, 'stop at end of beaem2dfit'

return
end

