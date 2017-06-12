pro find_x_size, root, region, scans, proj
if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)' 
fs = fltarr(scans, scans)
todo = fltarr(scans,scans)
path = root + proj + '/' + region + '/'
restore, path + 'xing/xday.sav'
for i=0, scans-1 do begin
    loop_bar, i, scans
    for j=i+1, scans-1 do begin
        if xday[i,j] eq 1 then begin
    ;        fn = file_search(root + proj + '/' + region + '/xing/' + region + string(i, format=scnfmt) + '-' +  string(j, format=scnfmt)  + '.sav')
           fe = file_exists(root + proj + '/' + region + '/xing/' + region + string(i, format=scnfmt) + '-' +  string(j, format=scnfmt)  + '.sav')
    if fe then begin restore, root + proj + '/' + region + '/xing/' + region + string(i, format=scnfmt) + '-' +  string(j, format=scnfmt)  + '.sav'
                if (size(xarr))[0] ne 0. then begin
                    fs[i,j] = n_elements(xarr)
                    todo[i,j] = 1.
                endif
            endif
    endif
    endfor
endfor

save, fs, todo, f= root + proj + '/' + region + '/xing/xsize.sav'

end
