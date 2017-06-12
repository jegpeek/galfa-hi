; purpose - read in kevin's files and store the data as a structure.

; kfilenames - names of files as created by kevin douglas.
; lsfsdir - directory in which to locate LSFS files
; outstfn - filename for the structure to be stored.

pro stg0strctify, kfilenames, lsfsdir, outstfn

answer=0l
stg0str = replicate({scan:0., year:0., month:0., day:0., first:0., last:0., slst:0., elst:0., lsfs:''}, 1000)
stg0str.scan  = findgen(1000)

nf = n_elements(kfilenames)

for i=0, nf-1 do begin
    readcol, kfilenames[i], date, first, last, scan, slst, elst, f='L,F,F,F,F,F'
    ndays = n_elements(date)
    for j=0, ndays-1 do begin
        if stg0str[scan[j]].year eq 0 then begin
        stg0str[scan[j]].year = floor(float(date[j])/1000.)
        stg0str[scan[j]].month = floor((float(date[j])- stg0str[scan[j]].year*1000.)/100.)
        stg0str[scan[j]].day = float(date[j]) -  stg0str[scan[j]].year*1000 -  stg0str[scan[j]].month*100
        stg0str[scan[j]].slst = slst[j]
        stg0str[scan[j]].elst = elst[j]
        stg0str[scan[j]].last = first[j]
        stg0str[scan[j]].first = last[j]
        strdate = string(date[j], f='(I8.8)')
        lsfsfns = file_search(lsfsdir, '*' + strdate + '*')
        if (n_elements(lsfsfns) gt 1) or (lsfsfns[0] eq '') then begin
            print, ' '
            print, 'Notes on day ' +  strdate + ':'
            spawn, 'more ' + kfilenames[i] + ' | grep ' + strdate
            for k=0, n_elements(lsfsfns)-1 do begin
                print, '[' + string(k, f='(I1.1)') + ']: ' + lsfsfns[k]
            endfor
            read, 'which LSFS file would you like? (or type in new date to look for?)', answer
            while answer gt 10 do begin
                lsfsfns = file_search(lsfsdir, '*' + string(answer, f='(I8.8)') + '*')
               stop
                for k=0, n_elements(lsfsfns)-1 do begin
                    print, '[' + string(k, f='(I1.1)') + ']: ' + lsfsfns[k]
                endfor
                answer=0l
                read, 'which LSFS file would you like? (or type in new date to look for?)', answer
            endwhile
            stg0str[scan[j]].lsfs = (reverse(strsplit(lsfsfns[answer], '/')))[0]
            answer=0l
        endif
        endif
    endfor
endfor
save, stg0str, f=outstfn




end
