pro define_bins, nspdr, rx, rffrq_wb_bin, indxcalon, indxcaloff, nbins, mwt, $
	adu_chnls, tsys_bins, beamout_arr

;+
;TURNS ADU INTO KELVINS FOR A SINGLE POWER CHANNEL
;INPUTS ARE:
;	RX, the rx nr
;       CALVAL: THE CAL VALUE array.
;	NBINS, the nr of bins into which the original NCHNLS are packed
;       MWT, the input structure (MWT = {MH, G_WIDE}
;
;OUTPUTS:
;	TSYS_NBINS, the calib tsys in the new bins for this pol
;-


;GET THE CAL TEMP...
rcvnum=17               ; rcvr num i use for alfa
caltype=1               ; hcorcal .. but alfa just has the 1 high cal.

;REBIN THE INPUT G_WIDE...
nmwt= n_elements( mwt)
mwtbin= mwt.g_wide[ *, *, rx, *]
mwt_bins= rebin( mwtbin, nbins, 2, nmwt)

;define adu strip binned...
adu_bins= rebin( adu_chnls, nbins, 2, 60, 4)
tsys_bins= fltarr( nbins, 2, 60, 4)

;DEFINE CALON AND CALOFF...

FOR NBIN= 0, NBINS-1 DO BEGIN
calon0= mean( mwt_bins[ nbin, 0, indxcalon])
calon1= mean( mwt_bins[ nbin, 1, indxcalon])
caloff0= mean( mwt_bins[ nbin, 0, indxcaloff])
caloff1= mean( mwt_bins[ nbin, 1, indxcaloff])

adu_bins0= reform( adu_bins[ *,0,*,*])
adu_bins1= reform( adu_bins[ *,1,*,*])

istat=calget1(rcvnum,caltype, rffrq_wb_bin[ nbin], calval)
for nr=0,1 do beamout_arr[ nspdr].(nr+2)[ nbin].cal= calval[ nr, rx]

IF (NBINS NE 1) THEN BEGIN
adu_to_tsys, calval[ 0,rx], calon0, caloff0, adu_bins0[ nbin,*,*], tsys0, fctr0
adu_to_tsys, calval[ 1,rx], calon1, caloff1, adu_bins1[ nbin,*,*], tsys1, fctr1
tsys_bins[ nbin, 0, *, *]= tsys0
tsys_bins[ nbin, 1, *, *]= tsys1
beamout_arr[ nspdr].(2)[nbin].fctr= fctr0
beamout_arr[ nspdr].(3)[nbin].fctr= fctr1
;stop
ENDIF ELSE BEGIN
adu_to_tsys, calval[ 0,rx], calon0, caloff0, adu_bins0[ *,*], tsys0, fctr0
adu_to_tsys, calval[ 1,rx], calon1, caloff1, adu_bins1[ *,*], tsys1, fctr1
tsys_bins[ nbin, 0, *, *]= tsys0
tsys_bins[ nbin, 1, *, *]= tsys1
beamout_arr[ nspdr].(2)[nbin].fctr= fctr0
beamout_arr[ nspdr].(3)[nbin].fctr= fctr1
ENDELSE

;stop

ENDFOR  ;nbin

return
end
