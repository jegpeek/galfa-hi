function gsrfits, fn, savname=savname, sec=sec, beam=beam, pol=pol 
;+
; NAME:
;  GSRFITS
;
; PURPOSE:
;  To read in a .fits file from the stg0 gsr processing efficiently 
;  and with many options
;
; CATEGORY:
;  I/O
;
; CALLING SEQUENCE:
;    function gsrfits, fn, savname=savname, sec=sec, beam=beam, pol=pol 
;
; INPUTS:
;  FN - The name of the file to read in
;
; OPTIONAL INPUTS:
;  NONE
;
; KEYWORD PARAMETERS:
;  sec - spcify this keyword if you wish to only read in a spefic
;        second of the observation. The returned array will be
;        in the [8192, 2, 7] format.
;  beam - Set this if you wish to get only a single beam. This
;         keyword does not function if you do not pass in the sec
;         keyword. Returns arry in the [8192, 2] format
;  pol -  Set this if you with to get only a single pol. This
;         keyword does not function if you do not pass in the sec 
;         and beam keywords. Returns a [8192] array.
; 
; MODIFICATION HISTORY:
;  JEG Peek, August 2006
;-

; get from .sav name to .fits name
if keyword_set(savname) then fn = STRMID(fn,0, strlen(fn)-4)+'.fits'

if n_elements(sec) eq 0 then begin
return, readfits(fn, hdr, /silent) 
endif 
; if you want a whole second slice use fitsread
if n_elements(beam) eq 0 then begin
return, readfits(fn, hdr, nslice=sec, /silent) 
endif
; if you want just a single beam and sec 
if n_elements(pol) eq 0 then begin
fits_read, fn, out, first=7d*2.*8192*sec + 2.*8192.*beam , last=  7d*2.*8192*sec + 2d*8192.*beam + 8192d*2.-1
out= reform(out, 8192, 2)
return, out 
endif
; if you want just a single beam, sec and pol
fits_read, fn, out, first=7d*2.*8192*sec + 2d*8192.*beam + 8192.*pol , last=  7d*2.*8192*sec + 2.*8192d*beam + 8192d*pol + 8192.-1
return, out 

end
