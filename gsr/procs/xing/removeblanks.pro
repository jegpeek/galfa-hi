;+
; NAME:
;
;  REMOVEBLANKS
;
; PURPOSE:
;
;  This is a slightly strange command for a very specfic purpose. The
;  idea is that times that specific beams have bad data are in a file
;  called BLANKFILE, in the [3, N] format, with the 3 being
;  startutc, endutc and beam, for each bad stretch. This code reads in
;  such a file and then removes all elements of the xarr crossing point
;  structure that fall within this range.
;
; CALLING SEQUENCE:
;  
;  removeblanks, blankfile, xarr
;
; INPUTS:
;  
;   blankfile - the full path to the file that contains the times and beams
;               to eliminate.
;   xarr - The loaded crossing point structure as generated by lxw.pro
;
; OUTPUTS:
;   mht - with bad data removed
;
; MODIFICATION HISTORY:
; Initally writted by J.E.G. Peek on August 28, 2006
; rewritten to not be totally non-functional by JEG Peek March 23,2009. Sigh
; rerewritten to handle beams correctly by JEG Peek December 22,
; 2009. Double sigh.
; I think this finally actually works, but if history is any guide... JEGP Jan 27 2011
;- 
pro removeblanks, blankfile, xarr

restore, blankfile

sz = size(blanks)
;stop
for i=0, sz[2]-1 do begin
    whb = where( ((xarr.time1 gt blanks[1, i]) or (xarr.time1 lt blanks[0, i]) or (xarr.beam1 ne blanks[2, i])) and ((xarr.time2 gt blanks[1, i]) or (xarr.time2 lt blanks[0, i]) or (xarr.beam2 ne blanks[2, i])), ct)
    if (ct ne 0) then xarr = xarr[whb] else begin
        xarr = 0.
        return
    endelse
endfor
end
