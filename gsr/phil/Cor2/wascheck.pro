;+
;NAME:
;wascheck - check if this call is for was data
;
; SYNTAX: istat=wascheck(lun,file=file)
;
; ARGS:
;      lun/desc: int or {wasdesc} .. 
;KEYWORDS: 
;	 file: char	if provided, then ignore lun and see if this file
;			    ends in .fits.
;
; RETURNS: 1 this is a was call (lun is a structure or file ends in .fits)
;          0 lun is an int, must be cor data
;
;DESCRIPTION:
;   Return 1 if the lun is a was descriptor rather than a int. Or if
;	file ends in .fits
;-
;history:
;
function wascheck ,desc,file=file
;   
	if n_elements(file) gt 0 then return,(strmid(file,4,5,/rev) eq '.fits')
    a=size(desc)
    return,a[n_elements(a)-2] eq 8          ; was used a strcuture
end
