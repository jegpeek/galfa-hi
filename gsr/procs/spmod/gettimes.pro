
;+
; NAME:
;   GETTIMES
; PURPOSE:
;   Find the time in UTC that starts a day. 
;
; CALLING SEQUENCE:
;   time = gettimes(root, region, scans, proj)
; INPUTS:
;   root -- The main direcotry in which the project directory
;             resides (e.g. '/dzd4/heiles/gsrdata/' )
;   region -- The name of the source as entererd into BW_fm (e.g. 'lwa')
;   scans -- Number of days the project consists of
;   proj -- The Arecibo project code (e.g. 'a2050')
; KEYWORD PARAMETERS:
;   tdf -- use the older two-digit formatting
;
; RETURNS:
;   The times (in UTC) that each day began upon.
;
; MODIFICATION HISTORY
;
;  Initial documentation, January 16, 2006
;  Modified for S1H compatability, July 12, 2006, Goldston Peek
;  Joshua E. Goldston, goldston@astro.berkeley.edu
;-


function gettimes, root, region, scans, proj, tdf=tdf
if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)' 

times = lindgen(scans)

for i=0, scans -1 do begin
    restore,  root + proj + '/' + region + '/' + region + '_' + string(i, format=scnfmt) + '/*hdrs*'
    times[i] = mh[0].utcstamp
endfor

return, times

end
