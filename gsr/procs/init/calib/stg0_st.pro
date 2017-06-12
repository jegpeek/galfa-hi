;+
; Name:
;   stg0_st
; PURPOSE:
;   A wrapper script for stg0.pro reductions that uses BW_fm output to ease reduction process
;
; CALLING SEQUENCE:
;   stg0_st, year, month, day, proj, scan, root, redst, delay=delay, _EXTRA=EX, fitsdir=fitsdir
;
; Inputs:
;   YEAR - The year, as an integer (e.g. 2005, not '2005')
;   MONTH - The month, as an integer (e.g. 6, not 'June')
;   DAY - The day as an integer (e.g. 27 )
;   PROJ - The Arecibo project code (e.g. 'a2050')
;   SCAN - The scan number. If the object is lwa_03_01, the scan number is 3.
;   ROOT - The main direcotry in which the project directory
;             resides (e.g. '/dzd4/heiles/gsrdata/' )
; 
; KEYWORDS PARAMETERS
;  DELAY - If the scan was started on a 'Lambda' later than the first (e.g. lwa_06_01, 
;          not lwa_06_00) set this parameter to the delay (e.g. 1)
;  FITSDIR - The direcotry inwhich to look for the fits files if non-standard. 
;  _EXTRA - any keyword availible to stg0.pro is availible to this program.  
;           see stg0.pro for a list of keywords
; OUTPUTS:
;   NONE (reduced data, calibration files, mh files)
;
; MODIFICATION HISTORY:
;   Initial Documentation Wednesday, July 27, 2005
;   Fixed formatting bug, October 21st, 2005
;   Added _EXTRA, November, 2006
;   JEG Peek, goldston@astro.berkeley.edu
;-

pro stg0_st, year, month, day, proj, scan, root, redst, delay=delay, _EXTRA=EX, fitsdir=fitsdir

if (not keyword_set(delay)) then delay = 0.
slst = redst.start_lsts[scan, delay]
elst = redst.end_lsts[scan]
region = redst.sourcename


if (not (keyword_set(fitsdir))) then files = findfile(root + '/' + proj + '/fits/' + '*.' + string(year, format='(I4.4)')+ string(month, format='(I2.2)')+ string(day, format='(I2.2)')+'.' + proj + '.*') else files = findfile(fitsdir + '/*.' + string(year, format='(I4.4)')+ string(month, format='(I2.2)')+ string(day, format='(I2.2)')+'.' + proj + '.*')

fns = float(strmid(files, 8, 4, /reverse_offset))
if keyword_set(stops) then stop

stg0, year, month, day, proj, region, root, min(fns), max(fns), slst, elst, scan, fitsdir=fitsdir, _extra=ex

end
