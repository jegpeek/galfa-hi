pro gsrcalc_beam2d, nspdr, npol, beamin_arr, beamout_arr,  $
	nterms=nterms, nbin=nbin

;+
;PURPOSE: evaluate properties of the 2d beam and load b2dfit.
;INPUTS:
;
;	from structure BEAMIN
;
;	STRIPFIT, the 1-d stripfit ls fit coefficients from BEAM_DESCRIBE
;
;	BEAMOUT, a structure which contains...
;		B2DFIT, the 2-d ls fit coefficients from BEAM2D_DESCRIBE.
;		fhgt, fcen, fhpbw, generated in this proc.
;
;	SOURCEFLUX, used for getting kperjy
;
;OUTPUTS: ALL CALCULATED QUANTITIES OF SIGNIFICANCE ARE PUT INTO B2DFIT.
;
;	SIDELOBE_INTEGRAL, the integral of the sidelobe pattern in units
;of Kelvins arcmin^2.
;
;	MAINBEAM_INTEGRAL, the integral of the mainbeam pattern in units
;of Kelvins arcmin^2.
;
;	SIDELOBE, the sidelobe pattern on the original 60 X 60 observing
;grid.
;
;	MAINBEAM, the mainbeam pattern on the original 60 X 60 observing
;grid. 
;
;	KPERJY, the kperjy of the source. here Kelvins is Stokes I/2.
;
;	FHGT, the ratio of the heights of first sidelobe to main beam.
;
;	ETA_MAINBEAM, the main beam efficiency
;
;	ETA_SIDELOBE, the sidelobe efficiency
;	
;KEYWORDS:
;
;	NTERMS, the number of terms to use in reconstructing the
;sidelobe structure from the Fourier fit to the sidelobe structure. Use
;of NTERMS=8 forces the reconstruction to duplicate the measured points
;because there were 8 measured data points (2 on each end of the strip,
;so they are located every 45 deg around the circle). Use of NTERMS<8 is
;equivalent to least squares fitting those 8 points with a Fourier series
;having the chosen value of NTERMS, which means that the fitted curve
;will not go through the points. Seeing as the 'measured points' are really
;the result of model fits to the sidelobes with Gaussians, and that these
;fitted parameters are not perfect, I don't believe using NTERMS=8 is
;necessarily justified. 
;
;	If NTERMS<8, THEN NTERMS SHOULD BE ODD. Otherwise, the last 
;Fourier coefficient is reproduced at only half amplitude.
;
;09dec2004: the default for nterms changed from 6 to 3.
;21dec2004: the default for nterms changed from 3 to 8.
;
;-

;BEAM MAP HAS NxN PIXELS; DEFINE N AS NR OF PTS PER STRIP...
ptsperstrip=  (size( beamin_arr[nspdr].totoffsets))[ 1]
;sourceflux=  beamin_arr[ nspdr].sourceflux

;EXTRACT FROM STRUCTURES...

IF N_ELEMENTS( NBIN) NE 0 THEN BEGIN
stripfit= beamout_arr[ nspdr].(npol+2)[nbin].stripfit
b2dfit= beamout_arr[ nspdr].(npol+2)[nbin].b2dfit
ENDIF ELSE BEGIN
stripfit= beamout_arr[ nspdr].(npol).stripfit
b2dfit= beamout_arr[ nspdr].(npol).b2dfit
ENDELSE

lambda= 30000./b2dfit[ 17, 0]

if (keyword_set( nterms) eq 0) then nterms=8

;DEFINE THE AZ, ZA ARRAYS FOR THE BEAM MAPS (UNITS ARE ARCMIN)...
make_azza_newcal, ptsperstrip, b2dfit, pixelsize, azarray, zaarray

;GENERATE THE SIDELOBE FOURIER COEFFICIENTS...
gsrft_sidelobes_newcal, stripfit, b2dfit, fhgt, fcen, fhpbw

;stop

;print, 'nterms ', nterms
;GENERATE THE SIDELOBE AND MAINBEAM MAPS...
gsrsidelobe_eval, nterms, fhgt, fcen, fhpbw, azarray, zaarray, sidelobe
sidelobe= sidelobe/b2dfit[2,0]
sidelobe_integral= pixelsize^2 * total( sidelobe)

;stop

mainbeam_eval_newcal, azarray, zaarray, b2dfit, mainbeam
mainbeam= mainbeam/b2dfit[2,0]
mainbeam_integral=  pixelsize^2 * total( mainbeam)

totalbeam_integral= sidelobe_integral+ mainbeam_integral
mainbeam_integral= mainbeam_integral/lambda^2
sidelobe_integral= sidelobe_integral/lambda^2

;*************** NOTE THAT WE DEFINE SOME PORTIONS OF B2DFIT HERE!!! *******

sourceflux= b2dfit[ 12,0]
if (n_elements( sourceflux) eq 0) then sourceflux= -1.0
;b2dfit[ 12,*] = [ sourceflux, 0.]
b2dfit[ 13,*] = [ float( fhgt[ 0]), nterms]

;NOTE THE DIFF BETWEEN ALL STOKES AND THIS: IN ALL STOKES, WE HAVE
;0.5 IN KPERJY DEFINITION...BUT NOT HERE!
;kperjy= 0.5* b2dfit[2,0]/sourceflux
kperjy= b2dfit[2,0]/sourceflux
eta_mainbeam= 2.34 * kperjy * mainbeam_integral
eta_sidelobe= 2.34 * kperjy * sidelobe_integral

b2dfit[ 14,*] = [eta_mainbeam, 0.]
b2dfit[ 15,*] = [eta_sidelobe, 0.]
b2dfit[ 16,*] = kperjy
b2dfit[ 18, 1]= ptsperstrip


IF N_ELEMENTS( NBIN) NE 0 THEN BEGIN
beamout_arr[ nspdr].(npol+2)[ nbin].b2dfit= b2dfit
beamout_arr[ nspdr].(npol+2)[ nbin].fhgt= fhgt
beamout_arr[ nspdr].(npol+2)[ nbin].fcen= fcen
beamout_arr[ nspdr].(npol+2)[ nbin].fhpbw= fhpbw
ENDIF ELSE BEGIN
beamout_arr[ nspdr].(npol).b2dfit= b2dfit
beamout_arr[ nspdr].(npol).fhgt= fhgt
beamout_arr[ nspdr].(npol).fcen= fcen
beamout_arr[ nspdr].(npol).fhpbw= fhpbw
ENDELSE

return
end

