pro edbadrx, badrxfile, utcstart, utcend, badpol, badbeam
;+
; NAME:
;  EDBADRX
; PURPOSE:
;  A code to edit the badrxfile that tells us when receivers are bad
;
; CALLING SEQUENCE:
;   edbadrx, badrxfile, utcstart, utcend, badpol, badbeam
;
; INPUTS:
;  BADRXFILE -- The full path and name of the file to be edited. This will work
;          on a new file (that does not yet exist) or add to an existing file,
;          and will work on a user's own list of bad receivers or on the main list.
;  UTCSTART -- The UTC time (in seconds) that the receiver went bad.
;  UTCEND -- The UTC time (in seconds) that the receiver was fixed.
;  BADPOL -- The polarization that went bad: 0 or 1
;  BADBEAM -- The beam that went bad: 0,1, 2,3 ,4, 5, or 6.
;
; KEYWORD PARAMETERS:
;  NONE
; OUTPUTS:
;  NONE (updated badrx files)
;-

; is file exisiting or otherwise
if (file_test(badrxfile)) then begin
    restore, badrxfile
    sz1 = (size(badrx))[1]
    
; if existing, make an N+1 array of structures and feed the old array of structures
; into it.
    badrx2 = replicate({utcstart:0l, utcend:0l, dateadded:' ', badpol:0., badbeam:0. }, sz1 +1)
    badrx2[0:sz1-1] = badrx
    i=sz1
endif else begin
; Otherwise, generate a 1 element array of structures.
     badrx2 = replicate({utcstart:0l, utcend:0l, dateadded:' ', badpol:0., badbeam:0. }, 1)
     i=0
endelse

; update the last (or only) element of the structure
    badrx2[i].utcstart=utcstart
    badrx2[i].utcend=utcend
    badrx2[i].dateadded=systime()
    badrx2[i].badpol=badpol
    badrx2[i].badbeam=badbeam
    badrx = badrx2

; Save the structure.
save, badrx, filename=badrxfile

end

