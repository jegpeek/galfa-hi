;+
; NAME:
;   VETX
;
;
; PURPOSE:
;  To tag a file for whether making crossing points there is OK. should cut out LSFS and CAL.
;  Can be modified to cut out other things.
;
; CALLING SEQUENCE:
;  vetx, mh, beam, xok
;
;
; INPUTS:
;  mh - an mh structure
;  beam - the beam number in question
;
; KEYWORD PARAMETERS:
;
;
; OUTPUTS:
;  xok - an int array the length of mh: 0 for bad, 1 for good;
;
; EXAMPLE:
;
;
;
; MODIFICATION HISTORY:
; Built by JEG Peek, March 15th, 2007
; goldston@astro.berkeley.edu
;-
pro vetx, mh, beam, xok, blankfile=blankfile

len = (size(mh))[1]
xok = intarr(len)+1
wh = where(mh.obsmode eq 'SMARTF  ', ct)
if ct ne 0 then xok[wh] = 0
if keyword_set(blankfile) then begin
    



end
