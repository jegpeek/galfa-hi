pro examaggr, root, region, proj, wt, _REF_EXTRA=_EXTRA, start=start

restore, root + '/' + proj + '/' + region + '/aggr.sav'

sz = size(aggr)
!p.multi=[0,2,7]

if keyword_set(start) then st = start else st=0

for i=st, sz[4]-1 do begin
    for k=0,6 do begin
        for j=0,1 do begin
            plot, aggr[*, j, k, i], _EXTRA=_EXTRA
        endfor
    endfor
    xyouts, 0.9, 0.9, string(i, f='(I3.3)'), /normal, charsize=2
    wait, wt
endfor

end
