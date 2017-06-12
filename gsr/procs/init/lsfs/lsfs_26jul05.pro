pro lsfs, path, inputfiles, $
	ggwb, rf4wb, rfwb, fnewwb, multwb, problemwb, $
	ggnb, rf4nb, rfnb, fnewnb, multnb, problemnb, $
	bbfrq_nb, bbgain_dft_nb, $
	rffrq_wb, rffrq_nb, $
	yesnowb=yesnowb, yesnonb=yesnonb, skipwb=skipwb, seq=seq, $
	error=error, quiet=quiet, skiprec=skiprec

;+
;PURPOSE: GIVE IT INPUT FILES, IT EXTRACTS THE SMARTF SPECTRA STRUCTURES
;M1S AND THE ASSOCIATED RECEIVER PARAMETERS.
;
;INPUTS:
;	PATH, path to the input files
;	INPUTFILES, a list of input files within which the SMARTF data 
;reside.
;
;KEYWORDS:
;	YESNOWB, YESNONB. set equal to 3 unless you want to re-evaluate the svd 
;matrices.
;	SKIPWB: skip wb calc for testing nb.
;	ERROR: nonzero means error, don't write a file
;	QUIET: no plots or printed output from carl9
;
;OUTPUTS:
;	GGWB, the 14 wideband gains with cal on, cal off GGWB[ 512, 14, 2]
;	RF4WB, the 14 rf powers at the 7 diff frqs. rf4wb[ 512, 14, 7, 2]
;		rf4wb[ chnls, polrx, lofrq, calonoff]
;	RFWB, the rf powers at all possible rf frqs. rfwb[ 543, 14, 2]
;		rfwb[ chnls, polrx, calonoff]
;	FNEWWB[ 543], the frqs for rrfwb.
;	MULTWB[ 14,2], the multiplier for each polrx/cal combo.
;
;	GGNB, the 14 wideband gains with cal on, cal off GGNB[ 480, 14, 2]
;NOTE that NB quantities are rebinned from 7679 to 480...
;NOTE that we have NB quans at only 6 frqs because the 7th is out of band.
;	RF4NB, the 14 rf powers at the 7 diff frqs. rf4NB[ 480, 14, 6, 2]
;		rf4NB[ chnls, polrx, lofrq, calonoff]
;	RFNB, the rf powers at all possible rf frqs. rfNB[ 718, 14, 2]
;		rfNB[ chnls, polrx, calonoff]
;	FNEWNB[ 718], the frqs for rrfNB. fnewnb[ 718]
;	MULTNB [ 14, 2], the multiplier for each polrx/cal combo.
;	BBFRQ_NB, baseband frqs of the nb spectra
;	bbgain_dft_nb, theoretical baseband filter shape of the nb spsectra
;
;NOTE ABOUT UNITS:
;
;	for gg, the mean is roughly unity.
;	the rf powers are in the original digital units.
;
;-

;FIRST CUT SELECTION OF SMARTF DATA...
print, 'in lsfs.pro. skiprec = ', skiprec
m1_to_m1s_s0, path, inputfiles, m1s, seq=seq, skiprec=skiprec

;STOP, 'JUST BEFORE LSFS1 IN LSFS.PRO'
;restore, '/share/heiles/m1s.sav'

;stop, 'in lsfs before lsfs1'

;ULTIMATE CUT SELECTION OF SMARTF DATA...
lsfs1, m1s, lofrqs_lsfs, indxbreak, pwrwb, $
	pwrwb_avg, g_wide_avg, $
	pwrnb_avg, g_nb_avg, error=error

if error ne 0 then return

;stop, 'in lsfs'

;GENERATE SOME ESSENTIAL INFO...
sb1= -1.d
sb2= 1.d
sb_bb= -1.d
lo2= m1s[0,0,0].g_lo2/1.d6
digitalmix= m1s[0,0,0].g_mix/1.d6
frqinwb= dblarr( n_elements( m1s[0,0,0].g_wide), 7)
frqinnb= dblarr( n_elements(  m1s[0,0,0].data), 7)
FOR NFRQ=0,6 DO BEGIN
bbifdftprops, sb1, sb2, sb_bb, lofrqs_lsfs[ nfrq], lo2, digitalmix, $
        rffrq_wb, if1frq_wb, bbfrq_wb, $
        rffrq_nb, if1frq_nb, bbfrq_nb, $
        bbgain_dft_nb
frqinwb[ *, nfrq]= rffrq_wb
frqinnb[ *, nfrq]= rffrq_nb
ENDFOR

;STOP, 'JUST BEFORE WB IN LSFS.PRO'

if keyword_set( skipwb) then goto, nb
;--------------------------- WB -----------------------------------

;EVALUATE THE XMATRIX IF DESIRED. NORMALLY NO (yesnowb=3).
if (n_elements( yesnowb) eq 0) then yesnowb= 3
xmatrixeval, yesnowb, xmatrixyes, savesvdyes, manual, wgt_inv, xxinv_svd
if (savesvdyes) then $
	restore, getenv( 'GALFAPATH') + 'savfiles/' + 'svd512.sav'

;SET UP OUTPUT ARRAYS FOR POLRX COMBO AND CALONOFF...
ggwb= fltarr( 512, 14, 2)
rfwb= fltarr( 543, 14, 2)
multwb= fltarr( 14, 2)
rf4wb= fltarr( 512, 14, 7, 2)           ;chnls, prx, lofrq, calonoff
problemwb= intarr( 14, 2)
ncycs= n_elements( g_wide_avg)/( 512l* 14l* 7l* 2l)
g_wide_avg= reform( g_wide_avg, 512, 14, 7, 2, ncycs)


;NOW DO THE SOLUTIONS...
FOR NRPRX= 0, 13 DO BEGIN                ;PRX means 'pol/rx'
FOR NRCAL= 0, 1 DO BEGIN

if ncycs ne 1 then begin
spctinwb= reform( total( g_wide_avg[ *, nrprx ,*, nrcal, *],5)/ncycs)
endif else spctinwb= reform( g_wide_avg[ *, nrprx ,*, nrcal, 0])
 
carl_preliminary, spctinwb, frqinwb, $
        indx0a, fnewwb, spctinwbmod, frqinwbmod, indxtot

;STOP, 'IN LSFS JUST AFTER CARL_PRELIMINARY'

if (xmatrixyes) then xmatrixgen, indx0a, indxtot, xmatrix

;stop, 'in wb lsfs.pro, nrprx= ', nrprx

carl9, xmatrix, spctinwbmod, frqinwbmod, indx0a, fnewwb, $
        fctr, gg, rf, rf4, $
        wgts=wgts, wgt_inv=wgt_inv, xxinv_svd=xxinv_svd, $
	problem=problem, manual=manual, quiet=quiet  ;;, /verbose

ggwb[ *, nrprx, nrcal]= gg
rf4wb[ *, nrprx, *, nrcal]= fctr* (1.+ rf4)
rfwb[ *, nrprx, nrcal]= fctr* (1.+ rf)
multwb[ nrprx, nrcal]= fctr
problemwb[ nrprx, nrcal]= problem
 
ENDFOR
ENDFOR

;--------------------------- NB -----------------------------------
nb:

;EVALUATE THE XMATRIX IF DESIRED. NORMALLY NO (yesnonb=3).
if (n_elements( yesnonb) eq 0) then yesnonb= 3
xmatrixeval, yesnonb, xmatrixyes, savesvdyes, manual, wgt_inv, xxinv_svd
if (savesvdyes) then $
	restore, getenv( 'GALFAPATH') + 'savfiles/' + 'svd7680.sav'
;stop

g_nb_avg= reform( g_nb_avg, 7679, 14, 7, 2, ncycs)
 
;SET UP OUTPUT ARRAYS FOR POLRX COMBO AND CALONOFF...
ggnb= fltarr( 480, 14, 2)
rfnb= fltarr( 718, 14, 2)
multnb= fltarr( 14, 2)
rf4nb= fltarr( 480, 14, 6, 2)           ;chnls, prx, lofrq, calonoff
problemnb= intarr( 14, 2)

;NOW DO THE SOLUTIONS...
FOR NRPRX= 0, 13 DO BEGIN                ;PRX means 'pol/rx'
FOR NRCAL= 0, 1 DO BEGIN

if ncycs ne 1 then begin
spctinnb= reform( total( g_nb_avg[ *, nrprx , *, nrcal, *],5)/ncycs)
endif else spctinnb= reform(   g_nb_avg[ *, nrprx , *, nrcal, 0])
 
;NOTE THAT WE REBIN BOTH THE NB FREQUENCY AND PWR SPECTRUM 
;	FROM 7679 TO 7680, THEN COLLAPSE TO 480...
frqin= dblarr( 7680,6)
spctin= fltarr( 7680,6)

delfrq= (frqinnb[ 7678, 0]- frqinnb[ 0, 0])/7678.d
FOR NRF= 1,6 DO BEGIN
;WE ADD an extra ONE AT THE END. NOW WE ADD ONE AT THE BEGINNING...
;frqin[ *, nrf- 1]= [ frqinnb[ *, nrf], frqinnb[ 7678, nrf]]
;spctin[ *, nrf-1]= [ spctinnb[ *, nrf], spctinnb[ 7678, nrf]]
frqin[ *, nrf- 1]= [ frqinnb[ 0, nrf]-delfrq, frqinnb[ *, nrf]]
spctin[ *, nrf-1]= [ spctinnb[ 0, nrf], spctinnb[ *, nrf]]
ENDFOR

frqin= rebin( frqin, 480, 6)
spctin= rebin( spctin, 480, 6)
 
;stop, 'stop lsfs, 1'

carl_preliminary, spctin, frqin, $
        indx0a, fnewnb, spctinnbmod, frqinnbmod, indxtot
if (xmatrixyes) then xmatrixgen, indx0a, indxtot, xmatrix

;stop, 'stop lsfs, 2'

carl9, xmatrix, spctinnbmod, frqinnbmod, indx0a, fnewnb, $
        fctr, gg, rf, rf4, $
        wgts=wgts, wgt_inv=wgt_inv, xxinv_svd=xxinv_svd, $
	problem=problem, manual=manual, quiet=quiet  ;;, /verbose

;stop, 'stop lsfs, 3'

ggnb[ *, nrprx, nrcal]= gg
rf4nb[ *, nrprx, *, nrcal]= fctr* (1.+ rf4)
rfnb[ *, nrprx, nrcal]= fctr* (1.+ rf)
multnb[ nrprx, nrcal]= fctr
problemnb[ nrprx, nrcal]= problem
 
ENDFOR
ENDFOR

return

end
