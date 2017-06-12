pro bbifdftprops, sb1, sb2, sb_bb, lo1, lo2, digitalmix, $
	rffrq_wb, if1frq_wb, bbfrq_wb, $
	rffrq_nb, if1frq_nb, bbfrq_nb, $
	bbgain_dft_nb, path=path

;+
;PURPOSE: calculate frqs vs chnls for rf, if1, and bb for wb and nb spectra.
;	also calculates the theoretical nb bandpass.
;
;CALLING SEQUENCE:
;bbifdftprops, sb1, sb2, sb_bb, lo1, lo2, digitalmix, $
;	rffrq_wb, if1frq_wb, bbfrq_wb, $
;	rffrq_nb, if1frq_nb, bbfrq_nb, $
;	bbgain_dft_nb, path=path
;
;INPUTS: 
;	SB1, +/- 1 for upper/lower sidebands of first mix. normally SB1=-1.
;	SB2, +/- 1 for upper/lower sidebands of second mix. normally SB=+1.
;	SB_BB, +/- 1 to reverse bb freq axis. normally SB_BB=-1 so that
;		rf freqs always increase with bb channel number.
;	LO1, first lo freq in MHz (e.g. 1695.4), lo1= m1s[0,0,0].g_lo1/1.d6
;	LO2, second lo freq in MHz (e.g. 256.25), lo2= m1s[0,0,0].g_lo2/1.d6
;	DIGITALMIX, digital mixing freq in MHz (e.g. -18.75), 
;		digitalmix= m1s[0,0,0].g_mix/1.d6
;
;USES INPUT FILE:
;	 'n_lpf_coeff_1', the list of Fourier coefficients provided by
;Jeff Mock. see gsr/savfiles/n_lpf_coeff_1
;
;KEYWORD:
;	PATH, the path to n_lpf_coeff_1. default is...
;	getenv('GALFAPATH') + 'savfiles/'
;
;OUTPUTS: 
;	RFFRQ_WB, rf frqs for each chnl of wb spectrum
;	IF1FRQ_WB, if1 frqs for each chnl of wb spectrum
;	BBFRQ_WB, baseband for each chnl of wb spectrum
;	RFFRQ_NB, rf frqs for each chnl of nb spectrum
;	IF1FRQ_NB, if1 frqs for each chnl of nb spectrum
;	BBFRQ_NB, baseband for each chnl of nb spectrum
;	BBGAIN_DFT_NB, bandpass for nb spectrum
;BASIC EQUATIONS for RF, IF1, BB frequencies in MHz:
;   (1)	IF1 = SB1*( RF - LO1)
;		SB1=-1, we use lower sideband
;		if RF=1420.4, LO1 might be 1695.4. LO1 is always 275 MHz
;		above the specified line frequency because the center 
;		WAPP frq is 275 MHz. This cannot be changed.
;
;   (2)	BB_wb= SB_BB* SB2*( IF1-LO2)
;		SB2= +1, normally; we use the upper sideband.
;		For the above, we set LO2= 256.25 MHz. 
;		SB_BB = -1, normally, to keep rf frq increase with chnl nr
;
;   (3)	BB_nb= SB_BB* SB2* [ (IF1 + DIGITALMIX) - LO2)]
;
; ********************* IMPORTANT NOTICE ******************************
;	NOTE THAT WE MULTIPLY ALL BB FRQS BY -1 because
;Jeff Mock outputs the channels in reverse order so that rf freq always 
;increases with channel number.
;
;HISTORY:
;	created 20 oct 04 by carl h
;	the 20 oct version assumes 256 chnls for wb, 7935 for nb
;	THIS version (~01nov04) assumes 512 chnls for wb, 7679 chnls for nb
;-

if  keyword_set( path) eq 0 then path= getenv('GALFAPATH') + $
	'savfiles/'

readcol, path+ 'n_lpf_coeff_1', f1_1, $
	/silent

;-------------------------WIDEBAND---------------------------

;;SAMPLE TIME IS 0.01/14. MICROSEC...
;t_smpl= 0.01/ 14.
;time= t_smpl* (findgen( 336)- (336./2.) + 0.5)

;WE WANT FREQS AT THE FOLLOWING LOCATIONS...
;NOTE THE MINUS SIGN...GIVES THE SIGN INVERSION FOR FREQ, INSERTED  ON 14 OCT 
bbfrq_wb= SB_BB* 100.d0* (dindgen( 512)- (512.d0/2.d0))/(512.d0)

if1frq_wb= (bbfrq_wb/sb2) + lo2
rffrq_wb= (if1frq_wb/sb1) + lo1

;---------------------NARROWBAND----------------------------

;SAMPLE TIME IS 0.01 MICROSEC...
t_smpl= 0.01d0
time= t_smpl* (dindgen( 336)- (336/2) + 0.5d0)

;WE WANT FREQS AT THE FOLLOWING LOCATIONS...
;NOTE THE MINUS SIGN...GIVES THE SIGN INVERSION FOR FREQ, INSERTED  ON 14 OCT
frq_nb= SB_BB* (100.d0/14.d0)* (dindgen( 8192) - (8192/2) )/8192.d0
dft, time, f1_1, frq_nb, f1_1_ft
gain_nb=  abs(f1_1_ft)^2/ abs( f1_1_ft[ 4095])^2

bbfrq_nb= SB_BB* (100.d0/14.d0)* (dindgen( 7679) - (7679/2) )/8192.d0
bbgain_dft_nb= gain_nb[ dindgen( 7679)+ (4096- (7679/2) )]

;bbfrq_nb= SB_BB* (100.d0/14.d0)* (findgen( 7935)- (7935/2) )/8192.d0
;bbgain_dft_nb= gain_nb[ indgen( 7935)+ (4096- (7935/2) )]
;bbfrq_nb= SB_BB* (100.d0/14.d0)* (findgen( 7935)- 3967.d0)/8192.d0
;bbgain_dft_nb= gain_nb[ indgen( 7935)+ (4096-3967)]

if1frq_nb= (bbfrq_nb/sb2) + lo2- digitalmix
rffrq_nb= (if1frq_nb/sb1) + lo1

return
end
