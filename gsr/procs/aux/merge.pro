;+
; NAME:
;  MERGE
;
;
; PURPOSE:
;  To join many different (typically overlapping) regions into a single
;  region, for the puposes of XING and GRID
;
; CALLING SEQUENCE:
;   merge, roots, projs, regions, dayss, newroot, newproj, newreg, odf=odf
;
;
; INPUTS:
;    roots - array of paths to original regions
;    projs - array of projects for original regions
;    regions - array of original regions
;    dayss - array of days for orginal regions
;    newroot - path to new region
;    newproject - name for new project
;    newreg - name of new region
;
; KEYWORD PARAMETERS:
;   ODF - set if using .sav as main data structure (pre- gsr 2.2)
;   TDF - set if using two digit format (pre- gsr 2.2)
;   FIRSTSCANS - if set, must be an numerical array with same length as dayss
;                and dictates where to start each region: i.e. if you had
;                a region called cold, and you wanted to use days 0-10 and 12-20
;                dayss = [11, 9], regions =['cold', 'cold'] and 
;                firstscans=[0, 12]
; OUTPUTS:
;  NONE.
;
; MODIFICATION HISTORY:
;  Written on April 11th, 2006
;  Documented and tuned for GSR2.2 Aug 10 2006
;  Modified to fix fits bug and for > 2 regions by Peek and Douglas, Oct 10 2006
;  Added FIRSTSCANS, Feb 3 2009, JEGP
;  J.E.G. Peek  goldston@astro
;-

pro merge, roots, projs, regions, dayss, newroot, newproj, newreg, odf=odf, tdf=tdf, firstscans=firstscans

make_dirs, newroot, newproj, newreg, total(dayss)  ;  , /nox
if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)' 
od = 0.
if keyword_set(firstscans) then begin
    startis = firstscans
    endis = firstscans+dayss-1
endif else begin
    startis = fltarr(n_elements(regions))
    endis = dayss-1
endelse 
for k=0, n_elements(regions) -1 do begin
    for i=startis[k], endis[k] do begin
        savfiles = file_search(roots[k] + '/' + projs[k] + '/' +  regions[k] + '/' + regions[k] + '_' + string(i, format=scnfmt) + '/', 'galfa*'+ regions[k]+  '.sav')
        if not keyword_set(odf) then fitsfiles = file_search(roots[k] + '/' + projs[k] + '/' +  regions[k] + '/' + regions[k] + '_' + string(i, format=scnfmt) + '/', 'galfa*'+ regions[k]+  '.fits')
        shtnm = strmid(savfiles, 24 + strlen(regions[k]) + strlen(projs[k]),25 + strlen(regions[k]) + strlen(projs[k]), /reverse_offset)
        if not keyword_set(odf) then  shtnmfits = strmid(fitsfiles, 25 + strlen(regions[k]) + strlen(projs[k]),25 + strlen(regions[k]) + strlen(projs[k]), /reverse_offset)
        for j=0, n_elements(savfiles)-1 do begin
            ; these fail when proj[k] is a subset of regions[k]. Douglas!!!
  ;       newname = (strsplit(shtnm[j], projs[k], /extract, /regex))[0] + newproj + (strsplit(shtnm[j], projs[k], /extract, /regex))[1]
  ;       newname = (strsplit(newname, regions[k], /extract, /regex))[0] + newreg + (strsplit(newname, regions[k], /extract, /regex))[1]
            newname = strmid(shtnm[j], 0, 15) + newproj + strmid(shtnm[j], 15 + strlen(projs[k]),  1 + 4 +1 + strlen(regions[k]) +1 + 3)
            newname = strmid(newname, 0, 15 + strlen(newproj) + 1+ 4 + 1) + newreg + '.sav'
            spawn, 'ln -s ' + savfiles[j] + ' ' + newroot + '/'  + newproj + '/' + newreg + '/' + newreg + '_' + string(od, format=scnfmt) + '/' + newname
            if  ((not keyword_set(odf)) and (j ne n_elements(savfiles)-1)) then begin
                                ;newnamefits = (strsplit(shtnmfits[j], projs[k], /extract, /regex))[0] + newproj + (strsplit(shtnmfits[j], projs[k], /extract, /regex))[1]
                                ;newnamefits = (strsplit(newnamefits, regions[k], /extract, /regex))[0] + newreg + (strsplit(newnamefits, regions[k], /extract, /regex))[1]
                newnamefits = strmid(shtnmfits[j], 0, 15) + newproj + strmid(shtnmfits[j], 15 + strlen(projs[k]),  1 + 4 +1 + strlen(regions[k]) +1 + 4)
                newnamefits = strmid(newnamefits, 0, 15 + strlen(newproj) + 1+ 4 + 1) + newreg + '.fits'
                spawn, 'ln -s ' + fitsfiles[j] + ' ' + newroot + '/'  + newproj + '/' + newreg + '/' + newreg + '_' + string(od, format=scnfmt) + '/' + newnamefits
            endif
        endfor
        od = od+1.
    endfor
endfor    


end
