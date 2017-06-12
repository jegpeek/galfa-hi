;+
; NAME:
;
;  MOVEBLANKS
;
; PURPOSE:
;
;  This is a slightly strange command for a very specfic purpose. The
;  idea is that times that specific beams have bad data are in a file
;  called BLANKFILE, in the [3, N] format, with the 3 being
;  startutc, endutc and beam, for each bad stretch. This code reads in
;  such a file and then assigns the postions in the mht file to be at an
;  RA and dec, so that they are not gridded. It is a little kludgy, but
;  it gets around any problems that might arise from trying to do more
;  invasive reprogramming.
;
; CALLING SEQUENCE:
;  
;  moveblanks, blankfile, mht
;
; INPUTS:
;  
;   blankfile - the full path to the file that contains the times and beams
;               to eliminate.
;   mht - an abbreviated, concatenated mh file of all of the region's data, 
;         cf todarr.pro
;
; OUTPUTS:
;   mht - with bad data moved
;
; MODIFICATION HISTORY:
; Initally writted by J.E.G. Peek on July 11, 2006
;-

pro moveblanks, blankfile, mht

restore, blankfile

;whblank = fltarr(n_elements(xarr))+1
sz = size(blanks)
for i=0, sz[2]-1 do begin
    whb = where((mht.utcstamp lt blanks[1, i]) and (mht.utcstamp gt blanks[0, i]), ct)
    if (ct ne 0) then mht(whb).dec_halfsec[blanks[2,i]] = 60
endfor
end
