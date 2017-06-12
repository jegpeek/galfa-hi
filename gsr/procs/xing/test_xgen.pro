pro test_xgen, root, region, scans, proj, goodx=goodx, xday=xday, blankfile=blankfile, tdf=tdf, noauto=noauto

if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)' 

hdr_fn = strarr(scans)
for i=0, scans-1 do begin 
    hdr_fn[i] = file_search(root + proj + '/' + region + '/' + region + '_' +  string(i, format=scnfmt) + '/',  '*.hdrs.*')
endfor

if (not (keyword_set(goodx))) then begin
    goodx = fltarr(7,7)
    goodx[0,2]=1.
    goodx[0,5]=1.
    goodx[1,4:6]=1.
    goodx[2,4:6]=1.
    goodx[3,4:6]=1.
endif

if(not (keyword_set(xday))) then xday = fltarr(scans, scans) + 1.

xarr = 0
if not keyword_set(noauto) then begin
for i = 0, scans-1 do begin
    if xday[i,i] eq 1 then begin
        restore, hdr_fn[i]
        for j = 0, 6 do begin
            for k = j+1, 6 do begin
                if (goodx[j,k]) then begin
                    print, format='(%" scan 1 = %d  beam 1 = %d  scan 2 = %d beam 2 = %d \r", $)', i, j ,i, k
                    good = 0
                    while (good eq 0) do begin
                        good = newx(mh, fn, j, i, filepos, mh, fn, k, i, filepos, x)
                    endwhile
                    if good ne (-1.) then if (n_elements(xarr) ne 1.) then xarr = [xarr, x] else xarr = x
                    if good eq (-1.) then print, 'skipped', i,k,j
                endif
            endfor
        endfor
    endif
endfor


if keyword_set(blankfile) then removeblanks, blankfile, xarr
save, xarr, filename=root + proj + '/' + region + '/xing/'+ region + 'auto.sav'
endif

xarr = 0
for j = 25, 26 do begin
     restore, hdr_fn[24]
     mh1 = mh
     fn1 = fn
     fp1 = filepos
     restore, hdr_fn[j]
     mh2 = mh
     fn2 = fn
     fp2 = filepos
     for k = 0, 6 do begin
       for l = 0, 6 do begin
         good = 0
         while (good eq 0) do begin
             good = newx(mh1, fn1, k, 24, fp1, mh2, fn2, l, j, fp2, x)
         endwhile
         if good ne (-1.) then if (n_elements(xarr) ne 1.) then xarr = [xarr, x] else xarr = x
         if good eq (-1.) then print, 'skipped', 24, k, j, l
       endfor
     endfor
;     ne1 = n_elements(xarr, ct)
;     if (ct ne 0) then begin
     if(n_elements(xarr) gt 1.) then begin   
       print, 'test1'
       save, xarr, filename = root + proj + '/' + region + '/xing/' + 'xgen_test_day24_xarr_tot.sav'
       if keyword_set(blankfile) then removeblanks, blankfile, xarr
       print, 'test2'
       save, xarr, filename = root + proj + '/' + region + '/xing/'+ region + string(24, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '.sav'
       print, root + proj + '/' + region + '/xing/'+ region + string(24, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '.sav'
     endif
     xarr = 0.
endfor

stop
end
