pro makemhh, mhpath, fitsfiles, smartf

;+
;MAKEMHH: given a set of fits files (inputfiles) that have 
;a corresponding set of mh files located in mhpath, use the mh files
;to generate arraysfind all files containing data having mh.obsmode eq SMARTF. we
;use the mh files instead of the fits files because it's lots faster.
;
;CALLING SEQUENCE: FIND_SMARTF, mhpath, fitsfiles, smartf
;
;INPUTS;
;	MHPATH, path to the mh files
;	FITSFILES, the names of the fits files; the pgm converts these
;to the corresponding mh file names.
;
;OUTPUTS:
;	SMARTF, a byte array of same length as fitsfiles. 0 means
;the file contains no SMARTF, 1 means it does contain SMARTF.
;
;-

nfiles= n_elements( fitsfiles)
smartf= bytarr( nfiles)

FOR NR= 0, NFILES-1l DO BEGIN

mhfile= $
  strmid( fitsfiles[ nr], 0, strpos( fitsfiles[ nr], 'fits', /reverse_search)) $
	+ 'mh.sav'
if (file_search(mhpath+ mhfile) eq '') then goto, skip
restore, mhpath+ mhfile
indx= where( strpos( mh.obsmode, 'SMARTF') ne -1, count)
if count ne 0 then smartf[ nr]= 1
;for mr=0,599,6 do print, mr, '  ', mh[mr].obsmode, mh[mr].obs_name, mh[mr].object
;stop
skip:
ENDFOR

;stop

return
end
