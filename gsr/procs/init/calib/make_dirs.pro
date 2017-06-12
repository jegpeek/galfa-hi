;+
; NAME:
;   MAKE_DIRS
; PURPOSE:
;   Make all the direcrtories for a given Arecibo BW project in a consistant way
;
; CALLING SEQUENCE:
;   make_dirs, maindir, proj, regions, scans, tdf=tdf
;
; INPUTS:
;   root -- the direcotry in which you directory will sit (e.g. '/dzd4/heiles/gsrdata'
;   proj -- your project name (e.g. 'a2050')
;   regions -- names of all the objects you observe, in terms of their 
;            BW names (e.g. 'trb' or ['lwa', 'lwb'])
;   scans -- how many days was each observation (e.g. 12  or [12, 16])
;
; KEYWORD PARAMETERS:
;   tdf -- use the older two-digit formatting
; OUTPUTS:
;   NONE (file structure)
; HISTORY:
;   Modified to include cuffitsfile tag, October 21, 2005, Goldston
;   Modified for S1H compatability, July 12, 2006, Goldston Peek
;   Modified to remove nox and curfitsdir, May 30 2009, Peek
;-

pro make_dirs, root, proj, regions, scans,  tdf=tdf

if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)' 
cd, root

spawn, 'mkdir ' + proj
cd, proj
spawn, 'mkdir mh'
for i=0, n_elements(regions)-1 do begin
    spawn, 'mkdir ' + regions[i]
    cd, regions[i]
    spawn, 'mkdir lsfs'
    spawn, 'mkdir xing'
    for j = 0, scans[i] -1 do begin
        spawn, 'mkdir ' + regions[i] + '_'  + string(j, format=scnfmt)
    endfor
    cd , '..'
endfor
cd, '..'

end
