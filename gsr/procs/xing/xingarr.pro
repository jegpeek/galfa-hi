pro xingarr, root, region, scans, proj, xingname=xingname, tdf=tdf

;+
; Name:
;   XINGARR
; PURPOSE:
;   Generate a file that contains all Time Ordered Data (TOD) 
;   correction factors
;
; CALLING SEQUENCE:
;   xingarr, root, region, scans, proj, xingname=xingname, tdf=tdf
;
; INPUTS:
;   root -- The main directory in which the project directory
;             resides (e.g. '/dzd4/heiles/gsrdata/' )
;   region -- The name of the source as entered into BW_fm (e.g. 'lwa')
;   scans -- Number of days the project consists of
;   proj -- The Arecibo project code (e.g. 'a2050')
; 
; KEYWORDS PARAMETERS
;   tdf - use older two digit formatting
;   xingname - name to tag xing file with
; OUTPUTS:
;   NONE (files loaded with spectra)
;
; MODIFICATION HISTORY:
;   Initial Documentation Friday, August 9, 2005
;   name -> xingname, added appl_xing, October 15, 2006
;   Joshua E. Goldston, goldston@astro.berkeley.edu
;-

if (not keyword_set(xingname)) then xingname = ''
if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)' 

for i=0, scans-1 do begin
    loop_bar, i, scans
    restore, root + proj + '/' + region + '/' + region + '_' + string(i, format=scnfmt) +'/' + '*_xing_' + xingname + '.sav'
    if (i eq 0) then corf = gain else corf = [[corf],[gain]]
    
endfor

save, corf, mdsts, degree, daygain, beamgain, xingname, appl_xing, filename= root + proj + '/' + region + '/xingarr_' + xingname + '.sav'

end
