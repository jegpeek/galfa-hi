; fix36 fixes all of the names of a file type within a directory from xx.36 to
; xx.35, which is correct.
; 

pro fix36


dirs = file_search('', 'GALFA*', /test_dir)
files = file_search('', 'GALFA_HI_RA+DEC_??????????????.fits')

for i=0, n_elements(files)-1 do begin
    len = strlen(files[i])
    spawn, 'mv '+ files[i] + ' ' +  strmid(files[i], 0, 27) + '5' + strmid(files[i], 28, len-28)
endfor

nd = n_elements(dirs) 
for j=0, nd-1 do begin
    files = file_search(dirs[j], 'GALFA_HI*.fits')
    nf = n_elements(files)
    if nf eq 1 then begin
        if files eq '' then nf = 0
    endif

    for i=0, nf-1 do begin
        len = strlen(files[i])
        spawn, 'mv '+ files[i] + ' ' +  strmid(files[i], 0, 27+29) + '5' + strmid(files[i], 28+29, len-(28+29))
    endfor

    len = strlen(dirs[j])
    print,  dirs[j] + ' ' +  strmid(dirs[j], 0, 27) + '5' + strmid(dirs[j], 28, len-28)
    spawn, 'mv '+ dirs[j] + ' ' +  strmid(dirs[j], 0, 27) + '5' + strmid(dirs[j], 28, len-28)
endfor

end
