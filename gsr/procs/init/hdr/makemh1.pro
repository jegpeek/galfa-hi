pro makemh1, pathin, filein, pathout, fileout, mh, mx, $
	m1=m1, nochdoppler=nochdoppler, skiperror=skiperror

;+
;NAME:
;MAKEMH1: generate a single mh file from a single original fits file.
;the file contains two structures called MH and MX.
;
;PURPOSE:
;	MH contains exact coorddinates, times, and doppler shifts.
;the times in the original fits files are muddied by the sampling
;uncertainties and possible loss of samples.
;	MX contains statistical linformation on data quality 
;obtained from analyuses of the frequency-integrated powers from 
;each receiver, using only the non-calibration data. the analyses 
;include:
;
;	fractional rms of each receiver. if this is low, then the receiver
;is not working (becauswe when you move around in the sky you see signals
;that add to the rms).
;
;	ACF and its FT to find period signals (i.e., radar).
;
;	CCF of recdeivers with one another, to see if cablese were
;interchanged (CCF of two receivers on a giveen feed should be largest(
;
;	SJU: crosscorrelaltion of power data with 12 sec period pulse
;to check seriousness of SJU radar.
;
;CALLING SEQUENCE:
; makemh1, pathin, filein, pathout, fileout, mh, mx, $
;		m1=m1, nochdoppler=nochdoppler, skiperror=skiperror
;
;INPUTS:
;	PATHIN, the path for the input FITS files. 
;	FILEIN, name the original FITS file
;	PATHOUT, the path for the output mh.sav files
;
;OPTIONAL INPUT KEYWORD:
;	NOCHDOPPLER. if set, does not do chdoppler correction, 
;this use to be time consuming so was used during software development.
;there's little sense in setting this now. do not set it for normal reduction
;	SKIPERROR. if set, an error will leave you inside. normal
;operation: an error stops processing and goes onto the next input file.
;
;OUTPUTS:
;	FILEOUT, the array of output filenames (including pathout)
;	MH, the mh structure written into FILEOUT.
;	MX, the mx structure written into FILEOUT.
;
;OPTIONAL OUTPUT:
;	M1, the data structure from the fits file.
;
;EXAMPLE: the complete file spec is 
;	 /dzd4/heiles/gsrdata/galfa.20050504.X107.0000.fits
;	pathin = '/dzd4/heiles/gsrdata/'
;	filein = 'galfa.20050504.X107.0000.fits'
;
;SIDE EFFECTS: generates the output mh.sav files.
;
;HISTORY: written by josh. may 05, nochdoppler added 
; 17 oct 05, documentation added by carl.	
;-

if keyword_set( skiperror) then GOTO, SKIPERRORCATCH

catch, error_status
if error_status ne 0 then begin
print, 'ERROR IN READING OR PROCESSING', FILEIN, ' --- SKIP THIS PROCESSING'
return
endif

SKIPERRORCATCH:

;stop
time0= systime(1)
fn = pathin + filein

;DEFINE OUTPUT FILE NAME...
fileout= strmid( filein, 0, strpos( filein, 'fits', /reverse_search))
fileout= fileout+ 'mh.sav'
fileout = pathout + fileout
;stop
m1 = mrdfits(fn, 1, hdr)
print, '################### SUCCESSFULLY READ ', fn
nspectra = n_elements(m1)/14l
if (nspectra le 3) then begin
    print, 'less than 4 spectra in file: error'
    return
endif

print, 'time to read fits file = ', systime(1)-time0

;;CHECK FOR MULTIPLE OF 14 RECORDS...
;IF 14L*NSPECTRA NE N_ELEMENTS( M1) THEN BEGIN
;	print, 'FILE DOESNT HAVE MULTIPLE OF 14 RECORDS: ', filein
;	return
;ENDIF

m1 = reform(temporary(m1[0l: 14l*nspectra- 1]), 2, 7, nspectra)	
m1_hdr, m1, mh, mx, nochdoppler=nochdoppler

mh.fitsfilename= filein
mx.fitsfilename= filein

save, mh, mx, filename=fileout

print, '***************************writing ', fileout

end









