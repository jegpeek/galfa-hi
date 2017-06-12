pro exam_add_rx, root, region, scans, proj, badrxfile, _REF_EXTRA=_EXTRA, badcl=badcl, pwr=pwr, start=start

if not keyword_set(pwr) then restore, root + '/' + proj + '/' + region + '/aggr.sav'
if not keyword_set(badcl) then badcl = 200
sz = size(aggr)

bad = 0.
badbeam = 0.
badpol = 0.
ft = file_test(badrxfile)
if ft eq 0 then begin
    ;initialize the badrxfile (I think it needs two inidces
    edbadrx, badrxfile, 0, 0, 0, 0
    edbadrx, badrxfile, 0, 0, 0, 0
 
endif

if keyword_set(start) then st = start else st=0

for i=st, scans-1 do begin
    !p.multi=[0,2,7]
    restore, root + '/' + proj + '/' + region + '/'+ region + '_' + string(i, f='(I3.3)') + '/*hdrs*'
    nel = n_elements(mh)
    whichrx, mh[nel/2].UTCSTAMP, goodrx, badrxfile=badrxfile
    for k=0,6 do begin
        for j=0,1 do begin
            if keyword_set(pwr) then plot, mh.pwr_nb[j, k], _EXTRA=_EXTRA, title='BEAM=' + string(k, f='(I1.1)') +', POL='+string(j, f='(I1.1)'), /xs, /ynoz else plot, aggr[*, j, k, i], _EXTRA=_EXTRA, title='BEAM=' + string(k, f='(I1.1)') +', POL='+string(j, f='(I1.1)'), /xs
            if goodrx[j,k] eq 0 then begin
                if keyword_set(pwr) then oplot, mh.pwr_nb[j, k], color=badcl, _EXTRA=_EXTRA else oplot, aggr[*, j, k, i], color=badcl, _EXTRA=_EXTRA
            endif
        endfor
    endfor
    xyouts, 0.7, 0.5, 'scan=' + string(i, f='(I3.3)'), /normal
    print, 'Any unmarked bad receivers? [0:No, 1:Yes]'
    read, bad
    if bad ne 0 then begin
        print, 'Enter bad beam [0-6]'
        read, badbeam
        print, 'Enter bad pol [0-1]'
        read, badpol
        edbadrx, badrxfile, mh[0].utcstamp-10l, mh[nel-1].utcstamp+10l, badpol, badbeam
        !p.multi=[ 14 - badbeam*2 - badpol,2,7]
        if keyword_set(pwr) then plot, mh.pwr_nb[j, k], _EXTRA=_EXTRA, color=badcl,/xs, /ynoz else plot, aggr[*, badpol, badbeam, i], color=badcl, _EXTRA=_EXTRA, /xs
        i=i-1
    end
    wait, 1
endfor

end
