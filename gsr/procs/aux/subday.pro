;+
; NAME:
;  SUBDAY
;
;
; PURPOSE:
;  To make a stg0 data set with a subset of another region's data set
; 
;
; CALLING SEQUENCE:
;   subday, sds, root1, proj1, region1, days1, newroot, newproj, newreg, odf=odf, tdf=tdf
;
;
; INPUTS:
;    SDS - a list of days you wish to extract
;    root1 - path to original region
;    proj1 - project of original region
;    region1 - name of original region
;    days1 - nubmer of days in original region
;    newroot - path to new region
;    newproject - name for new project
;    newreg - name of new region
;
; KEYWORD PARAMETERS:
;   ODF - set if using .sav as main data structure (pre- gsr 2.2)
;   TDF - set if using two digit format (pre- gsr 2.2)
;
; MODIFICATION HISTORY:
;  Adapted from merge.pro on July 11th
;  Documented and tuned for GSR2.2 Aug 10 2006
;  J.E. Goldston Peek goldston@astro
;-

pro subday, sds, root1, proj1, region1, days1, newroot, newproj, newreg, odf=odf, tdf=tdf

if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)' 
make_dirs, newroot, newproj, newreg, n_elements(sds), /nox

for i=0, n_elements(sds)-1 do begin
    savfiles = file_search(root1 + '/' + proj1 + '/' +  region1 + '/' + region1 + '_' + string(sds[i], format=scnfmt) + '/', 'galfa*'+ region1+  '.sav')
    if not keyword_set(odf) then fitsfiles = file_search(root1 + '/' + proj1 + '/' +  region1 + '/' + region1 + '_' + string(sds[i], format=scnfmt) + '/', 'galfa*'+ region1+  '.fits')
    shtnm = strmid(savfiles, 24 + strlen(region1) + strlen(proj1),25 + strlen(region1) + strlen(proj1), /reverse_offset)
    if not keyword_set(odf) then  shtnmfits = strmid(fitsfiles, 25 + strlen(region1) + strlen(proj1),25 + strlen(region1) + strlen(proj1), /reverse_offset)

    for j=0, n_elements(savfiles)-1 do begin
        newname = (strsplit(shtnm[j], proj1, /extract, /regex))[0] + newproj + (strsplit(shtnm[j], proj1, /extract, /regex))[1]
        newname = (strsplit(newname, region1, /extract, /regex))[0] + newreg + (strsplit(newname, region1, /extract, /regex))[1]
        if  not keyword_set(odf) then begin
              newnamefits = (strsplit(shtnmfits[j], proj1, /extract, /regex))[0] + newproj + (strsplit(shtnmfits[j], proj1, /extract, /regex))[1]
              newnamefits = (strsplit(newnamefits, region1, /extract, /regex))[0] + newreg + (strsplit(newnamefits, region1, /extract, /regex))[1]
              spawn, 'ln -s ' + fitsfiles[j] + ' ' + newroot + '/'  + newproj + '/' + newreg + '/' + newreg + '_' + string(i, format=scnfmt) + '/' + newnamefits
          endif
        spawn, 'ln -s ' + savfiles[j] + ' ' + newroot + '/'  + newproj + '/' + newreg + '/' + newreg + '_' + string(i, format=scnfmt) + '/' + newname
    endfor
endfor

end
