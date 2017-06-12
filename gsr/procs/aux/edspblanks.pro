pro edspblanks, file, utcs, beams, pols, fitps
;+
; NAME:
;  EDBLANKS
; PURPOSE:
;  A code to edit the file that tells us when stretches of data are bad, including spectral info
;
; CALLING SEQUENCE:
;    edspblanks, file, utcs, beam, pol, fitps
;
; INPUTS:
;  FILE -- The full path and name of the file to be edited. This will work
;          on a new file (that does not yet exist) or add to an existing file. Do not include
;          .sav or .fits in the name, as the code will create both file.fits and file.sav
;  UTC -- The UTC times (in seconds) of the spectrum are being edited. N-element long array
;  BEAM -- The beams that we wish to edit: 0,1, 2,3 ,4, 5, or 6. N-element array
;  POL -- The polarizations we wish to edit; 0,1. N-element array
;  FITPS -- The parameters for the fits to remove, an [20, N] array
;
; KEYWORD PARAMETERS:
;  NONE
; OUTPUTS:
;  NONE (updated blanks files)
;-

; is files exisiting or otherwise

nsp = n_elements(utcs)
if (file_test(file + '.fits')) then begin
    spbl = mrdfits(file + '.fits',1, hdr)
    restore, file+ '.sav'

    sz1 = (size(spbl))[3]
; if existing, make an #+nsp array of structures and feed the old array of structures
; into it.
    spbl2 = replicate({utc:0l, beam:0, pol:0, fitp:fltarr(20)}, sz1+nsp)
    spbl2[0:sz1-1] = spbl
    allutc = [allutc, utcs]
    allmethod = [allmethod, fltarr(nsp)]
    i=sz1
endif else begin
; Otherwise, generate an N element array of structures.
     spbl2 =replicate({utc:0l, beam:0, pol:0, fitp:fltarr(20)}, nsp)
	 allutc = utcs
	 allmethod = fltarr(nsp)
     i=0

endelse

; update the last (or only) element of the structure
    spbl2[i:*].utc = utcs
    spbl2[i:*].beam = beams
    spbl2[i:*].pol = pols
    spbl2[i:*].fitp = fitps
    spbl = spbl2
	allmethod[i:*] = reform(fitps[0, *])
; Save the UTCS and methods
	save, allutc, allmethod, filename=file + '.sav'
; write the data structure

	mwrfits, spbl, file + '.fits', /create
end

