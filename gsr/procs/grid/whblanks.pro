;+
; NAME:
;
;  WHBLANKS
;
; PURPOSE:
;
;  This is a slightly strange command for a very specfic purpose. The
;  idea is that times that specific beams have bad data are in a file
;  called BLANKFILE, in the [3, N] format, with the 3 being
;  startutc, endutc and beam, for each bad stretch. This code reads in
;  that file and then makes a flag file.
;
; CALLING SEQUENCE:
;  
;  whblanks, blankfile, mht
;
; INPUTS:
;  
;   blankfile - the full path to the file that contains the times and beams
;               to eliminate.
;   mht - an abbreviated, concatenated mh file of all of the region's data, 
;         cf todarr.pro
;
; OUTPUTS:
;   flag - 1s are bad, 0s are good.
;   
; MODIFICATION HISTORY:
; Initally writted by J.E.G. Peek on July 11, 2006
;-

pro whblanks, blankfile, mht, flag

len = (size(mht))[1]
flag = fltarr(len, 7)
if (file_test(blankfile)) then begin 
	restore, blankfile

	;whblank = fltarr(n_elements(xarr))+1
	sz = size(blanks)
	for i=0, sz[2]-1 do begin
	    whb = where((mht.utcstamp lt blanks[1, i]) and (mht.utcstamp gt blanks[0, i]), ct)
    	if (ct ne 0) then flag[whb,blanks[2,i]] = 1.
	endfor
endif

end
