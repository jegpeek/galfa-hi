pro simpred_ch, fitspath, lsfspath, fitsfile, lsfsfile, qckpath, $
	csnb, cswb, csnbcont, cswbcont, rffrq_nb, rffrq_wb, countyes, $
	rffrq_wblsfs, rffrq_nblsfs, rffrq_wbm1, rffrq_nbm1, $
	saveall=saveall, alsodocals=alsodocals
;+
; NAME:
;SIMPRED_CH -- generate an avg calibrated spectrum for all non-cal records in a fits file
;
;CALLING SEQUENCE:
;simpred_ch, fitspath, lsfspath, fitsfile, lsfsfile, qckpath, $
;	csnb, cswb, csnbcont, cswbcont, rffrq_nb, rffrq_wb, $
;	saveall=saveall
;
; PURPOSE:
;   To produce intensity-calibrated spectra using fits and associaated 
;lsfs files. does not use mh files. averages all non-cal calibrated
;spectra within the fits file to produce a single average; this is writtten
;out in a file called *qck.sav , where * is the fits file name guts;
;'qck' means 'quick'.
;if SAVEALL is set it writes ALL intensity-calibrated spectra in a
;file called *nqck.sav (obviously, 'nqck' means 'not quick'; it should
;be called dnqck, for DEFINITELY not quick, because these files are
;about the samae size as the original fits files!
;
;INPUTS:
;FITSPATH, fits file path
;LSFSPATH, lsfs file path
;FITSFILE, name of fits file
;LSFSFILE, name of lsfs file to use for calibration
;QCKPATH, output path for the qck and nqck files
;
;OPTIONAL INPUT:
;SAVEALL, if set writes ALL spectra into the nqck file, not just ONE
;	spectrum into the qck file.
;ALSODOCALS, if set, don't exclude SMARTF and CAL spectra
;
;OUTPUTS
;CSNB, CSWB -- the avg nb and wb non-cal spectra in this fits file
;CSNBCONT, CSWBCONT -- the avg nb and wb non-cal continuum levels 
;	in this fits file
;RFFRQ_NB, RFFRQ_WB, rf frqs for nb and wb spectra from the fitsfile
;COUNTYES, the nr of spectra in the avg
;rffrq_wblsfs, 0 chnl wb rffrq from lsfs file
;rffrq_nblsfs, 0 chnl nb rffrq from lsfs file
;rffrq_wbm1, 0 chnl wb rffrq from fits file
;rffrq_nbm1, 0 chnl nb rffrq from fits file
;-


; READ IN M1 FILE
m1 = mrdfits(fitspath+fitsfile, 1, hdr1) 

; LENGTH OF THE M1 ARRAY (600, TYPICALLY)    
len = n_elements(m1)/14l
m1= m1[0:len*14-1]
m1= reform( m1, 14, len)

;stop

;DEFINE OUTPUT FILE NAME...
cuickfile= strmid( fitsfile, 0, strpos( fitsfile, 'fits', /reverse_search))
ncuickfile= cuickfile+ 'nqck.sav'
cuickfile= cuickfile+ 'qck.sav'
cuicfileout = qckpath + cuickfile
ncuicfileout = qckpath + ncuickfile

m1polycorr, lsfspath, lsfsfile, m1, snb_c, swb_c, $
        pnb_uc, pwb_uc, pnb_uc_bin, pwb_uc_bin, $
        degree=degree, fctr=fctr, $
        caldeflnnb=caldeflnnb, caldeflnwb=caldeflnwb, $
        rffrq_wb=rffrq_wb, rffrq_nb=rffrq_nb, error=error, $
	alsodocals=alsodocals

IF (ERROR NE 0) THEN BEGIN
	print, '########## NO NON-CAL DATA, NO QCK.SAV FILE WRITTEN'
	return
ENDIF

;GET 0-CHNL LSFS RFFRQS...
rffrq_wblsfs= rffrq_wb[ 0]
rffrq_nblsfs= rffrq_nb[ 0]

; CONVERT TO K
restore, lsfspath + lsfsfile
restore, getenv('GSRPATH') + 'savfiles/newtemp01032005.sav'
conv_factornb = reform( tcal/caldeflnnb, 14)
conv_factorwb = reform( tcal/caldeflnwb, 14)

;CONVERT NB AND WB SPECTRA TO TEMP UNITS...
;snb_c = reform( snb_c, 7679, 14, len)
nbsz= 7679 & wbsz= 512

snb_c = snb_c*rebin(reform(conv_factornb, 1, 2, 7, 1), nbsz, 2, 7, len)
swb_c = swb_c*rebin(reform(conv_factorwb, 1, 2, 7, 1), wbsz, 2, 7, len)

;CONVERT NB AND WB CONTINUA TO TEMP UNITS...
nb_cont= pnb_uc*rebin(reform(conv_factornb, 2, 7, 1), 2, 7, len)
wb_cont= pwb_uc*rebin(reform(conv_factorwb, 2, 7, 1), 2, 7, len)

;EXCLUDE NON-CAL SPECTRA UNLESS ALSODOCALS IS SET...
indxyes= where( (strpos( m1[0,*].obsmode, 'SMARTF') eq -1) and $
	        (strpos( m1[0,*].obsmode, 'CAL') eq -1), countyes)
if keyword_set( alsodocals) then begin
	countyes= len
	indxyes= indgen( countyes)
endif

if countyes ne 0 then begin
;CHK FRQ DIFF IN NON-CAL DATA...
lo1diff= m1[ indxyes[ 0]].g_lo1- m1[ indxyes[ countyes-1]].g_lo1
;GET FRQS FROM M1 STRUCTURE...
sb1= -1.d
sb2= 1.d
sb_bb= -1.d
lo2= m1[ 0, indxyes[0]].g_lo2/1.d6
digitalmix= m1[ 0, indxyes[0]].g_mix/1.d6
lo1= m1[ 0, indxyes[0]].g_lo1/1.d6
bbifdftprops, sb1, sb2, sb_bb, lo1, lo2, digitalmix, $
        rffrq_wb, if1frq_wb, bbfrq_wb, $
        rffrq_nb, if1frq_nb, bbfrq_nb, $
        bbgain_dft_nb
;GET 0-CHNL M1 RFFRQS...
rffrq_wbm1= rffrq_wb[ 0]
rffrq_nbm1= rffrq_nb[ 0]
endif

if countyes ne 0 then csnb= total( snb_c[ *,*,*,indxyes],4)/countyes else $
	csnb= 0*reform(snb_c[*,*,*,0])
if countyes ne 0 then cswb= total( swb_c[ *,*,*,indxyes],4)/countyes else $
	cswb= 0*reform(swb_c[*,*,*,0])
if countyes ne 0 then begin
	csnbcont= total( nb_cont[ *,*,indxyes],3)/countyes 
	cswbcont= total( wb_cont[ *,*,indxyes],3)/countyes
	meanra = mean(m1[0, indxyes].crval2a)
	meandec = mean(m1[0, indxyes].crval3a)
	meanaz = mean(m1[0, indxyes].crval2b)
	meanza = mean(m1[0, indxyes].crval3b)
endif else begin
	csnbcont= 0*reform( nb_cont[ *,*,0])
	cswbcont= 0*reform( wb_cont[ *,*,0])
	meanra=0
	meandec=0
	meanaz=0
	meanza=0
endelse

IF (COUNTYES NE 0) THEN BEGIN
save, csnb, cswb, csnbcont, cswbcont, rffrq_nb, rffrq_wb, $
	conv_factornb, conv_factorwb, countyes, $
	meanra, meandec, meanaz, meanza, tcal, $
	rffrq_wblsfs, rffrq_nblsfs, rffrq_wbm1, rffrq_nbm1, $
	filename=cuicfileout
    print, '******** wrote ', cuicfileout ;;;cuickfile

if keyword_set( saveall) then begin
lo1= m1[0,indxyes].g_lo1
az=  m1[0,indxyes].crval2b
za=  m1[0,indxyes].crval3b
ra=  m1[0,indxyes].crval2a
dec=  m1[0,indxyes].crval3a
obsmode= m1[0,indxyes].obsmode
obs_name= m1[0,indxyes].obs_name
alfa_ang= m1[0,indxyes].alfa_ang
object=  m1[0,indxyes].object
ut_approx= reform( ((m1[0,indxyes].g_time[0]+2ll^31ll) mod 86400)/3600.)
	save, snb_c, swb_c, nb_cont, wb_cont, rffrq_nb, rffrq_wb, $
	conv_factornb, conv_factorwb, countyes, $
	meanra, meandec, meanaz, meanza, tcal, $
	rffrq_wblsfs, rffrq_nblsfs, rffrq_wbm1, rffrq_nbm1, $
	lo1, az, za, ra, dec, obsmode, obs_name, object, alfa_ang, ut_approx, $
	filename=ncuicfileout
    print, '$$$$$$$$$$ wrote ', ncuicfileout  ;;ncuickfile
endif
ENDIF else print, '########## NO NON-CAL DATA, NO QCK.SAV FILE WRITTEN'

return
end
