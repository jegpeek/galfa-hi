;+
; NAME:
;  MERGE_AGGR
;
;
; PURPOSE:
;  While aggr_spect (or spcor calling aggr_spect) can be run on merged data, if you wish to directly
;  merge aggr.sav files, use this code.
;
; CALLING SEQUENCE:
;   merge_aggr, roots, projs, regions, dayss, newroot, newproj, newreg, odf=odf
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
;   firstscans - as in merge.pro
;
; OUTPUTS:
;  NONE.
;
; MODIFICATION HISTORY:
;  Written on January 12th, 2009
;  Tweaked to add firstscans (and function), identical to merge June 10 2009
;  J.E.G. Peek  goldston@astro
;-

pro merge_aggr, roots, projs, regions, dayss, newroot, newproj, newreg, firstscans=firstscans

if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)' 
od = 0.
aggr_all = fltarr(8192, 2, 7, total(dayss))
for k=0, n_elements(regions) -1 do begin
    restore, roots[k] +'/'+ projs[k] + '/' + regions[k] + '/aggr.sav'
    if keyword_set(firstscans) then aggr = aggr[*, *, *, firstscans[k]:*]
    ; to accomodate firstscans
    aggr = aggr[*, *, *, 0:dayss[k]-1]
    aggr_all[*, *, *,(total( [0,dayss], /cum))[k]:(total(dayss, /cum))[k]-1]=aggr
endfor
aggr = temporary(aggr_all)

save, aggr, f=newroot +'/'+ newproj + '/' + newreg + '/aggr.sav'

end
