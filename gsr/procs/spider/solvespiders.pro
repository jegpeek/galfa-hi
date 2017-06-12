pro solvespiders, nbins, mx, indxstrt, indxstop, nspdrs, $
	beamin_arr, beamout_arr

FOR NSPDR= 0, NSPDRS-1 DO BEGIN
;FOR NSPDR= 0, 0 DO BEGIN
mwt= mx[ indxstrt[ nspdr]: indxstop[ nspdr]]

nmwt= n_elements( mwt)

;CHK CONTINUITY OF SOURCE NAME...
sourcenamestrt= mwt[ 0].mh.object
sourcenamestop= mwt[ nmwt-1].mh.object
if (sourcenamestrt ne sourcenamestop) then STOP, 'SOURCE CHANGE!! STOPPING!!!'
sourcename= strtrim(sourcenamestrt,2)

;GET CFR!!!!!
cfr= mwt[ 0].mh.restfreq/1.d6

;GET THE FREQS OF THE CHNLS...
sb1= -1.d
sb2= 1.d
sb_bb= -1.d
lo2= mwt[0].mh.g_lo2/1.d6
lo1= mwt[0].mh.g_lo1/1.d6
digitalmix= mwt[0].mh.g_mix/1.d6
bbifdftprops, sb1, sb2, sb_bb, lo1, lo2, digitalmix, $
        rffrq_wb, if1frq_wb, bbfrq_wb, $
        rffrq_nb, if1frq_nb, bbfrq_nb, $
        bbgain_dft_nb, $
        path= getenv( 'GSRPATH')+ 'init/rcvr/'

cfr= mean( rffrq_wb)
;bw= max( rffrq_wb)- min( rffrq_wb)
bw= 100.

;SOURCE PROPERTIES...
srcprops, sourcename, cfr, rasrc, decsrc, sourceflux
beamin_arr[ nspdr].sourceflux= sourceflux
beamin_arr[ nspdr].sourcename= sourcename
beamin_arr[ nspdr].rasrc= rasrc
beamin_arr[ nspdr].decsrc= decsrc
beamin_arr[ nspdr].cfr= cfr
for nr=0,1 do beamout_arr[ nspdr].(nr).b2dfit[ 17,0]= cfr
for nr=0,1 do beamout_arr[ nspdr].(nr).b2dfit[ 17,1]= bw

;stop

;GET FREQS FOR BINS...
rffrq_wb_bin= rebin( rffrq_wb, nbins)
bw= bw/nbins
for nr=2,3 do beamout_arr[ nspdr].(nr).b2dfit[ 17,0]= float(rffrq_wb_bin)
for nr=2,3 do beamout_arr[ nspdr].(nr).b2dfit[ 12,0]= $
	fluxsrc( sourcename, rffrq_wb_bin)
for nr=2,3 do beamout_arr[ nspdr].(nr).b2dfit[ 17,1]= bw

;stop

;RCVR DEFINITION...
rx= fix(strmid( mwt[nmwt-1].mh.obsmode,7))
beamin_arr[ nspdr].rx= rx
for nr=0,3 do beamout_arr[ nspdr].(nr).rx= rx

;stop

;EXTRACT DATA FOR THE PATTERN...
makepatt, nspdr, cfr, mwt, beamin_arr, beamout_arr, nbins, $
	rffrq_wb_bin, tsys_bins

;stop

;TREAT TOTAL POWER FOR BOTH POLS...
FOR NPOL= 0,1 DO BEGIN
;FOR NPOL= 0,0 DO BEGIN
gsr1dfit, nspdr, npol, beamin_arr, beamout_arr
gsr2dfit, nspdr, npol, beamin_arr, beamout_arr
gsrcalc_beam2d, nspdr, npol, beamin_arr, beamout_arr
;gsrprint_beam2d, beamout_arr[ nspdr].(npol).b2dfit
;gsrplot_beam2d, beamout_arr[ nspdr].(npol), 200, /show

;TREAT BINNED FREQUENCY-RESOLVED POWER FOR BOTH POLS...
;WE USE A KLUGE: INPUT IS IN BEAMIN_ARR, SO WE SAVE ITS CONTENTS AND
;WRITE THEM BACK LATER.
beamin_arr_tsys= beamin_arr[nspdr].tsys

;stop

FOR NBIN= 0, NBINS-1 DO BEGIN
beamin_arr[nspdr].tsys= tsys_bins[ nbin,*,*,*]
gsr1dfit, nspdr, npol, beamin_arr, beamout_arr, nbin=nbin
gsr2dfit, nspdr, npol, beamin_arr, beamout_arr, nbin=nbin
gsrcalc_beam2d, nspdr, npol, beamin_arr, beamout_arr, nbin=nbin
;gsrprint_beam2d, beamout_arr[ nspdr].(npol+2)[nbin].b2dfit
;gsrplot_beam2d, beamout_arr[ nspdr].(npol+2)[nbin], 200, /show
ENDFOR

beamin_arr[nspdr].tsys= beamin_arr_tsys
ENDFOR ;npol

ENDFOR ;nspdr

return
end

