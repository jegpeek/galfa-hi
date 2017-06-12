pro make_fpn_array, ndec, reg, fpn

;up = projs(uniq(projs))
;nr = n_elements(regions)
;nu = n_elements(up)
;bl is for blank - a place holder
nel = n_elements(ndec)
fpn = {bl:0}
for i=0, nel -1 do begin
    fpn = create_struct(reg+'_'+string(nel-i-1, f='(I3.3)'), {decs:fltarr(ndec[nel-i-1]), rxg:fltarr(2, 7), zgn:fltarr(7), fpn:reform(fltarr(8192, 7, ndec[nel-i-1]), 8192, 7, ndec[nel-i-1]), aggr:reform(fltarr(8192, 7, 2, ndec[nel-i-1]), 8192, 7, 2, ndec[nel-i-1]), av:fltarr(8192)}, fpn)
endfor
fpn = st_add_field(fpn, 'bl', /remove)

;for i=0, nr -1 do begin
;    dummy = st_add_field(fpn.(where(projs(i) eq up)), regions[i], {decs:fltarr(ndec[i]), rxm:fltarr(2,7,nscans[i]), zgns:fltarr(2, 7 nscans[i]), fpn:fltarr(8192, 7,nscans[i], ndec[i])})
;    fpn = st_add_field(fpn, projs[i], dummy, /swap)
;endfor

;for i=0, nu -1 do begin
;    dummy = st_add_field(fpn.(i), 'bl', /remove)
;    fpn = st_add_field(fpn, up[i], dummy, /swap)
;endfor

end


