pro m1polycorr, lsfspath, lsfsfile, m1, snb_c, swb_c, $
	pnb_uc, pwb_uc, pnb_uc_bin, pwb_uc_bin, $
	degree=degree, fctr=fctr, $
	caldeflnnb=caldeflnnb, caldeflnwb=caldeflnwb, $
        rffrq_wb=rffrq_wb, rffrq_nb=rffrq_nb, error=error, $
	alsodocals=alsodocals

;+
;NAME:
;m1polycorr -- wrapper for polycorr, which corrects spectra 
;using derived if bandpasses and polyfitting
;
;PURPOSE: take spectra in m1 and generate corrected spectra using 
;if bandpass in lsfspath+lsfsfile. 
;
;CALLING SEQUENCE:
;m1polycorr, lsfspath, lsfsfile, m1, snb_c, swb_c, pnb_uc, pwb_uc, $
;	degree=degree, fctr=fctr
;
;ASSUMPTION:
;	ASSUME THT THE LO FREQUENCY IS EVERYWHERE EQUAL TO THAT OF
;THE FIRST NON-SMARTF SPECTRUM.
;
;INPUTS: 
;	LSFSPATH, the pthto the calib save file
;	LSFSFILE, the name of the lsfsfile.
;	M1[8400], the input structure from a single fits record.
;dimension might be less, should be multiple of 14 (nr of rcvrs)
;
;KEYWORD:
;	DEGREE, the degree of polynomial to fit to wb spectrum. 
;used in polycorr, where its default is 18.
;	ALSODOCALS if set, do all records, whether or not they are cals
;
;OPTIONAL OUTPUTS:
;	ERROR, nonzero if problems
;  FCTR[ 2,7, 600], obtained from calling polycorr. 
;	digital units of nb spectrum/digital units of output spectrum
;	CALDEFLNNB, nb cal defln. this is read from lsfs, not calculated here
;	CALDEFLNWB, wb cal defln. this is read from lsfs, not calculated here
;	RFFRQ_WB, the rffrqs of the wb spectrum, read from lsfs
;	RFFRQ_NB, the rffrqs of the nb spectrum, read from lsfs
;OUTPUTS:
;       SWB_C[ 512, 14, nspectra]. the gain-corr, poly-removed wb spectra.
;because it's poly-removed, the total power info is gone and the spectrum
;is sitting near zero. UNITS ARE GAIN-CORRECTED ORIGINAL WB DIGITAL UNITS.
;       SNB_C[ 7679, 14, nspectra], the gain-corr, poly-removed nb spectra.
;because it's poly-removed, the total power info is gone and the spectrum
;is sitting near zero. units are gain-corrected nb digital units.
;       PWB_UC[ 14, nspectra], the set of nb powers [2, 7, 600]. this is
;the total power under the wb spectra--the mean continuum over the band.
;UNITS ARE GAIN-CORRECTED WB ORIGINAL DIGITAL UNITS.
;       PNB_UC[ 14, nspectra], the set of nb powers [2, 7, 600]. this is
;the total power under the wb spectra--the mean continuum over the band.
;units are gain-corrected original nb digital units
;       PWB_UC_BIN[ 14, nspectra], the set of wb powers [2, 7, 600] in
;the wb data that precisely matches the BINNED NB data. the
;original wb digital units are converted to gain-corrected original
;nb digital units; the scale faactor is FCTR
;       PNB_UC_BIN[ 14, nspectra], the set of nb powers [2, 7, 600] in
;the BINNED nb data that precisely matches the wb data.
;units are gain-corrected original nb digital units
;
;ACTION:
;	does i.f. gain corr for both wb and nb spectra
;	fits polynomial to wb spectra excluding region of nb spectra
;	applies polynomial to nb spectra and returns the result.
;
;HISTORY:
;21SEP05, added degree as a keyword and fctr as optional output
;20 oct 05, added caldeflns (from lsfs file) as optional outputs
;-

error=0
;REFORM THE INPUT STRUCTURE FOR CONVENIENCE...
orig_size= size( m1)

nspectra= n_elements(m1)/14l
m1 = reform(temporary( m1), 14 ,nspectra)

;CALCULATE RFFRQS FROM FIRST NON=smartf RECORD OF INPUT STRUCTURE,
;ASSUME THEY ARE CONSTANT FOR THE WHOLE RECORD

;FIND FIRST NON-SMARTF SPECTRUM FROM WHICH LO FRQS ARE OBTAINED...
indx= where( (strpos( m1[0,*].obsmode, 'SMARTF') eq -1) and $
                (strpos( m1[0,*].obsmode, 'CAL') eq -1), count)
;indx= where( m1[ 0,*].obsmode ne 'SMARTF  ', count)
IF (COUNT EQ 0) THEN BEGIN
	print, 'ALL RECORDS ARE SMARTF'
	IF ( KEYWORD_SET( ALSODOCALS) NE 1) THEN BEGIN
		print, 'RETURNING, NO FILE WRITTEN'
		ERROR=1
		RETURN
	ENDIF
ENDIF

if keyword_set( alsodocals) then indx= indgen( nspectra)

nsplo= min( indx)
if (nsplo ne nspectra-1) then nsplo= nsplo+1

;GET FRQS...
sb1= -1.d
sb2= 1.d
sb_bb= -1.d
lo2= m1[ 0, nspLO].g_lo2/1.d6
digitalmix= m1[ 0, nspLO].g_mix/1.d6
lo1= m1[ 0,nspLO].g_lo1/1.d6
bbifdftprops, sb1, sb2, sb_bb, lo1, lo2, digitalmix, $
        rffrq_wb, if1frq_wb, bbfrq_wb, $
        rffrq_nb, if1frq_nb, bbfrq_nb, $
        bbgain_dft_nb

restore, lsfspath+ lsfsfile

polycorr, ggwb, ggnb_7679, rffrq_wb, rffrq_nb, m1, $
        snb_c, swb_c, pnb_uc, pwb_uc, pnb_uc_bin, pwb_uc_bin, $
	degree=degree, fctr=fctr

snb_c= reform( snb_c, 7679, 2, 7, nspectra)
swb_c= reform( swb_c, 512, 2, 7, nspectra)

pnb_uc= reform( pnb_uc, 2, 7, nspectra)
pwb_uc= reform( pwb_uc, 2, 7, nspectra)

pnb_uc_bin= reform( pnb_uc_bin, 2, 7, nspectra)
pwb_uc_bin= reform( pwb_uc_bin, 2, 7, nspectra)

fctr= reform( fctr, 2, 7, nspectra)

if orig_size[0] eq 1 then m1= reform( m1, n_elements( m1))
if orig_size[0] eq 2 then m1= reform( m1, 14, nspectra)
if orig_size[0] eq 3 then m1= reform( m1, 2, 7, nspectra)

return
end
