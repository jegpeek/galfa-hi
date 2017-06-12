pro edblanks, file, utcstart, utcend, badbeam
;+
; NAME:
;  EDBLANKS
; PURPOSE:
;  A code to edit the file that tells us when stretches of data are bad
;
; CALLING SEQUENCE:
;    edblanks, file, utcstart, utcend, badbeam
;
; INPUTS:
;  FILE -- The full path and name of the file to be edited. This will work
;          on a new file (that does not yet exist) or add to an existing file.
;  UTCSTART -- The UTC time (in seconds) that the receiver went bad.
;  UTCEND -- The UTC time (in seconds) that the receiver was fixed.
;  BADBEAM -- The beam that we wish to remove: 0,1, 2,3 ,4, 5, or 6.
;
; KEYWORD PARAMETERS:
;  NONE
; OUTPUTS:
;  NONE (updated blanks files)
;-

; is file exisiting or otherwise
if (file_test(file)) then begin
    restore, file
    if n_elements(blanks) ne 3 then sz1 = (size(blanks))[2] else sz1 = 1
    
; if existing, make an N+1 array of structures and feed the old array of structures
; into it.
    blanks2 = lonarr(3, sz1 +1)
    blanks2[*, 0:sz1-1] = blanks
    i=sz1
endif else begin
; Otherwise, generate a 1 element array of structures.
     blanks2 =lonarr(3, 1)
     i=0
endelse

; update the last (or only) element of the structure
    blanks2[0, i] = utcstart
    blanks2[1, i] = utcend
    blanks2[2, i] = badbeam
    blanks = blanks2

; Save the structure.
save, blanks, filename=file

end

