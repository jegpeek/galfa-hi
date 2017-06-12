;+
; NAME:
;   lookforgzip
;
; PURPOSE:
;   Look for a gzip-ed file, 
;
; CALLING SEQUENCE:
;   thisfile = lookforgzip( filename, count= )
;
; INPUTS:
;   filename   - Input file name w/out any ".gzip" extension
;
; OPTIONAL KEYWORDS:
;
; OUTPUTS:
;   thisfile   - Returns input file name with a ".gzip" extension if it
;                exists, or w/out that extension if it exists, or '' if
;                neither exists.
;
; OPTIONAL OUTPUTS:
;   count      - Number of files that matched
;
; COMMENTS:
;   This routine uses FINDFILE().
;
; EXAMPLES:
;
; BUGS:
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;   20-Oct-2000  Written by S. Burles, FNAL
;-
;------------------------------------------------------------------------------
function lookforgzip, filename, count=ct

   thisfile = findfile(filename, count=ct)
   if (ct GT 0) then return, thisfile

   thisfile = findfile(filename+'.gz', count=ct)
   if (ct GT 0) then return, thisfile

   return, ''
end
;------------------------------------------------------------------------------
