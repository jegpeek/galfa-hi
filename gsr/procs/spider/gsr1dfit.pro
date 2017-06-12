pro gsr1dfit, nspdr, npol, beamin_arr, beamout_arr, nbin= nbin 

;+
;FIT THE TOTAL INTENSITY (THE ONE-DIMENSIONAL FIT) SEPARATELY FOR EACH
;STRIP USING IFIT_ALLCAL.PRO, WHICH FITS THREE GAUSSIANS--ONE FOR EACH
;SIDELOBE AND ONE FOR THE MAIN BEAM. THE MAIN BEAM GAUSSIAN HAS A
;SKEWNESS PARAMETER.
;
;Note that no input angles other than the total offset from center 
;are required to do these fits, so the only angular variable is
;totoffst[ ptsperstip,4]
;
;INPUTS: 
;
;	NRC, the pattern number.
;
;	BEAMIN, the input data structure, from which we extract...
;
;	HPBW_GUESS, the value of the HPBW to use as the initial guess
;in the nonlinear 1d Gaussian fits to each strip cut across the beam.
;
;	TOTOFFSET[ ptsperstrip, nrstrips], the total angular offset from
;center along each strip. UNITS ARE ARCMIN, in contrast to the original
;version of this program in which units were the assumed hpbw. nrstrips
;is 4 in original usage.
;
;	iOFFSET[ ptsperstrip, nrstrips], the system temp
;for each point in each of the nrstrips strips.
;
;OUTPUTS
;
;BEAMOUT_ARR, INTO WHICH WE INSERT EITHER STRIPFIT (FOR THE CONTINUUM)
;OR STRIPFIT_CHNLS( VALUES FOR EACH AND EVERY SINGLE CHANNEL)...
;
;----------->>> IMPORTANT NOTE ON UNITS <<<--------------------
;|                                                            |
;|	Units of the INPUT angle are arcmin.                  |
;|	They are converted to units of HPBW_GUESS internally  |
;|	Units of STRIPFIT angles are HPBW_GUESS.              |
;|                                                            |
;----------->>> IMPORTANT NOTE ON UNITS <<<--------------------
;
;	STRIPFIT[ 12, nrstrips], the ls fit parameters, defined as follows:
;		[ 12, nrstrips] are [parameter, strip]
;		stripfit[ 0, *] = skew of main beam
;		stripfit[ 1, *] = hgt of main beam
;		stripfit[ 2, *] = hgt of left sidelobe
;		stripfit[ 3, *] = hgt of right sidelobe
;		stripfit[ 4, *] = [cen, squint,squint,squint] of main beam
;		stripfit[ 5, *] = cen of left sidelobe
;		stripfit[ 6, *] = cen of right sidelobe
;		stripfit[ 7, *] = [wid, squash, squash, squash] of main beam
;		stripfit[ 8, *] = HPBW of left sidelobe
;		stripfit[ 9, *] = HPBW  of right sidelobe
;		stripfit[ 10, *] = zero offset
;		stripfit[ 11, *] = slope
;	  where 'left sidelobe' refers to the first one in time along the scan
;	  and 'right sidelobe' refers to the latter one.
;
;	SIGSTRIPFIT[ 12, nrstrips], the errors in the above fit parameters
;
;	TEMPFITS[ 60, nrstrips], the fits to the data from all those ls fits
;		[ datanr, stripnr] (i.e., the fits to the datapoints,
;		not the datapoints; useful for plotting)
;-

;--------------------NOW LS FIT EACH STRIP ------------------

;DEFINE QUANTITIES THAT CHARACTERIZE THE STRIP...
hpbw_guess= beamin_arr[ nspdr].hpbw_guess
totoffset= beamin_arr[ nspdr].totoffsets

nrstrips= (size( totoffset))[ 2]
tempfits = fltarr( 60, nrstrips)

stripfit = fltarr( 12, nrstrips)
sigstripfit = fltarr( 12, nrstrips)

;LS FIT EACH STRIP...
FOR NRST= 0, NRSTRIPS-1 DO BEGIN 

;GET THE ANGLE OFFSETS--*****IN UNITS OF THE HPBW_GUESS*****...
offset = totoffset[ *, nrst]/ hpbw_guess
tsys= beamin_arr[ nspdr].tsys[ npol, *, nrst]

;stop
;DO THE FITS...
tsysfit_newcal, nrst, offset, tsys, $
        tfit, sigma, stripfit, sigstripfit, problem, cov
tempfits[ *, nrst]= tfit

;stop

ENDFOR


IF N_ELEMENTS( NBIN) NE 0 THEN BEGIN
beamout_arr[ nspdr].(npol+2)[nbin].stripfit= stripfit
beamout_arr[ nspdr].(npol+2)[nbin].sigstripfit= sigstripfit
ENDIF ELSE BEGIN
beamout_arr[ nspdr].(npol).stripfit= stripfit
beamout_arr[ nspdr].(npol).sigstripfit= sigstripfit
beamin_arr[ nspdr].tempfits[ npol, *, *]= tempfits
ENDELSE

end
