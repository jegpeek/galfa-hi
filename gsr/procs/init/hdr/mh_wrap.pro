pro mh_wrap, fitspath, fitsfilelist, mhpath, namearray=namearray

;+
;NAME:
;MH_WRAP -- input a list of fits files and generate their mh counterparts.
;
;CALLING SEQUENCE:
;mh_wrap, fitspath, fitsfilelist, mhpath, namearray=namearray
;
;INPUTS
;FITSPATH, the path to the fits files
;FITSFILELIST, a list of the fits files. this should be in a file located
;       in the directory inm which you are running IDL
;
;OPTIONAL INPUT
;NAMEARRAY. if you give this an array of filenames, it won't read fitsfilelist
;OUTPUT: 	
;none
;
;ACTION:
;	writes the associated mh files.
;-
;stop

if n_elements( namearray) eq 0 then $
	readcol, fitsfilelist, fitsfiles, format='a' $
else fitsfiles= namearray

;LOOP THROUGH EACH FILE SEPARATELY...
for nr=0, n_elements( fitsfiles)-1 do begin
;	print, nr, fitspath, fitsfiles[nr]
        makemh1, fitspath, fitsfiles[ nr], mhpath, fileout
	loop_bar, nr, n_elements( fitsfiles)-1
endfor

return
end
