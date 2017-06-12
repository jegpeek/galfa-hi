; gdate is a string such as '20080305' for the fifth of march 2008.
; if you don't enter it, the progarm will automatically make qck
; files for yesterday's (UT) scans.

pro data_check, gdate

if n_elements(gdate) eq 0 then begin
; get yesterday's date
caldat, systime(/julian)-1, month, day, year

; in GALFA terms
gdate = string(year, f='(I4.4)') + string(month, f='(I2.2)')+ string(day, f='(I2.2)')

endif
; find all the fits files for this day
; Min changed root directory from /share/galfa/ to
; /share/galfa/raw/all/ April 30 2008
files = file_search('/share/galfa/raw/all/', '*'+gdate +'*.fits', count=ct)
if ct eq 0 then retall
nf = n_elements(files)
; extract the file name without paths
for i=0, nf -1 do files[i] = (strsplit(files[i], '/', /extract))[4]


; extract the project name
projs = strarr(nf)
for i=0, nf -1 do projs[i] = (strsplit(files[i], '.', /extract))[2]

; find the unique project names
uproj = projs(uniq(projs, sort(projs)))
nup = n_elements(uproj)
cd,  '/share/galfa/qck/'
exist_proj = file_search('*')
qckpdfs = strarr(nup)

; loop over all the projects for the day
for i=0, nup-1 do begin
    if total(uproj[i] eq exist_proj) eq 0 then spawn, 'mkdir ' + uproj[i]
    ; move to project directory
    cd, uproj[i]
    ; make project day directory
    ndir =  uproj[i] + '_' +gdate
    spawn, 'mkdir '+ ndir
    ; move to new directory
    cd, ndir
    ; find the relevant project fits files
    pfiles = files(where(projs eq uproj[i]))
    ;TEMPORARY edit by Jana, July 23, 2008
    ;pfiles = pfiles[0:16]
    ; find the mh files
    mhfiles = file_search('/share/galfa/galfamh/', '*' + gdate + '*' + uproj[i] + '*')
    if (n_elements(mhfiles) eq (n_elements(pfiles) - 1)) then pfiles = pfiles[0:n_elements(mhfiles)-1]
    if n_elements(mhfiles) ne n_elements(pfiles) then begin
        print, 'number of mh files not equal to number of fits files'
        print, 'please fix mhfiles string array or pfiles string array'
        stop
    endif
    ; make a file list
    openw, 1, gdate + uproj[i]+'files.txt'
    for j=0, n_elements(pfiles)-1 do begin
        printf, 1, pfiles[j]
    endfor
    close, 1
    ; run the lsfs code
    lsfsfile='null'
    ; Min changed root directory from
    ; /share/galfa/' to
    ; '/share/galfa/raw/all/' April 30 2008
    lsfs_wrap, '/share/galfa/raw/all/', '/share/galfa/galfamh/', gdate + uproj[i]+'files.txt', '/share/galfa/qck/'+ uproj[i] + '/' + ndir +'/', savefilename=lsfsfile

    longlsfsfile = file_search( '/share/galfa/qck/'+ uproj[i] + '/' + ndir +'/', 'lsfs*')
    nl = n_elements(longlsfsfile)
    lsfsfile = strarr(nl)
    for m=0, nl-1 do lsfsfile[m] = (reverse(strsplit(longlsfsfile[m], '/', /extract)))[0]

if n_elements(lsfsfile) gt 1 then begin
       print, 'there are more than one lsfs files - choose one.'
       for m=0, n_elements(lsfsfile)-1 do print, '['+string(m, f='(I1.1)')+']: ' + lsfsfile[m]
       read, q
       lsfsfile = lsfsfile[q]
   endif
if lsfsfile eq '' then begin
    print, 'did not produce an LSFS file from this run: will search through old lsfs files of this project'
    alllsfs = file_search('/share/galfa/qck/'+ uproj[i] + '/*/', 'lsfs*')
    if n_elements(alllsfs) gt 1 then begin
        nel = n_elements(alllsfs)
        spawn, 'cp -p ' +alllsfs[nel-1] +' .'
        print, 'using: ' + alllsfs[nel-1]
    endif else begin
        if (alllsfs ne '') then begin
            spawn, 'cp -p ' +alllsfs +' .'
            print, 'using: ' + alllsfs
        endif
        if (alllsfs eq '') then begin
            print, 'There are no LSFS files in this entire project at all.'
            stop
        endif
    endelse
    longlsfsfile = file_search( '/share/galfa/qck/'+ uproj[i] + '/' + ndir +'/', 'lsfs*')
    lsfsfile = (reverse(strsplit(longlsfsfile, '/', /extract)))[0]
endif
;  if ((lsfsfile eq 'null') or (file_search('.', 'lsfs*') ne './' +lsfsfile)) then begin
;       print, 'The code did not produce an LSFS file. Please choose an alternative lsfs file inlcuding full path'
;       altfile=''
;       read, altfile
;       spawn, 'cp '+ altfile+ ' .'
;       lsfsfile = file_search('.', 'lsfs*')
;    endif
    ; make a structure for qck data
    qcks = replicate({ csnb:fltarr(7679,2,7), cswb:fltarr(512, 2, 7), csnbcont:fltarr(2,7), cswbcont:fltarr(2,7), rffrq_nb:fltarr(7679), rffrq_wb:fltarr(512), countyes:0., rffrq_wblsfs:0., rffrq_nblsfs:0., rffrq_wbm1:0., rffrq_nbm1:0.},n_elements(pfiles)) 
    ; make an array for rest frequency data
    freqs =dblarr(n_elements(pfiles), 600)
    nmh = n_elements(mhfiles)
    for j=0, n_elements(pfiles)-1 do begin
; Min changed root directory from '/share/galfa/' to
; '/share/galfa/raw/all/' April 30 2008
        simpred_ch,  '/share/galfa/raw/all/',  '/share/galfa/qck/'+ uproj[i] + '/' + ndir +'/',pfiles[j], lsfsfile, '/share/galfa/qck/'+ uproj[i] + '/' + ndir +'/', csnb, cswb, csnbcont, cswbcont, rffrq_nb, rffrq_wb, countyes, rffrq_wblsfs, rffrq_nblsfs, rffrq_wbm1, rffrq_nbm1,/alsodocals
        qcks[j].csnb=csnb
        qcks[j].cswb=cswb
        qcks[j].csnbcont=csnbcont
        qcks[j].cswbcont=cswbcont
        qcks[j].rffrq_nb=rffrq_nb
        qcks[j].rffrq_wb=rffrq_wb
        qcks[j].countyes=countyes
        qcks[j].rffrq_wblsfs=rffrq_wblsfs
        qcks[j].rffrq_nblsfs=rffrq_nblsfs
        qcks[j].rffrq_wbm1=rffrq_wbm1
        qcks[j].rffrq_nbm1=rffrq_nbm1
        spawn, 'rm *qck.sav' 
        if j lt nmh then begin
            restore, mhfiles[j]
            sz = size(mh)
            freqs[j, 0:sz[1]-1] = mh.crval1
        endif
    endfor
; plot the qck files

    plot_qck, qcks, gdate, uproj[i], freqs
; make them PDFs
;    spawn, 'gv ' + 'qckplots' + gdate + '.' +uproj[i] +'.ps &'
    spawn, 'ps2pdf ' + 'qckplots' + gdate + '.' +uproj[i] +'.ps'
    spawn, 'mv -f ' + 'qckplots' + gdate + '.' +uproj[i] +'.pdf /share/galfa/qck/qckpdf/'
    notes=''
    print, 'PDFs can be found at: http://www.naic.edu/alfa/galfa/data/josh/qckpdf/qckplots' + gdate + '.' +uproj[i] +'.pdf'
    read, 'Enter any notes:', notes
    if notes ne '' then notes = ' NOTE: '+ notes
;    spawn, 'ps2pdf ' + 'qckplots' + gdate + '.' +uproj[i] +'.ps'
  ;  spawn, 'mv -f ' + 'qckplots' + gdate + '.' +uproj[i] +'.pdf /share/galfa/qck/qckpdf/'
    qckpdfs[i] = 'qckplots' + gdate + '.' +uproj[i] +'.pdf'
    save, qcks, f='qck_'+ uproj[i] + '_' +gdate+'.sav'
    cd, '/share/galfa/qck/'
; add them to the webpage - editied JEGP
    add_page_item, '/share/galfa/request/qck/index.html',uproj[i] + ': ' + gdate, string(n_elements(pfiles), f='(I4.1)') + ' fits files.' + notes, 'http://www.naic.edu/alfa/galfa/data/josh/qckpdf/qckplots' + gdate + '.' +uproj[i] +'.pdf', 'qck file plots here'
endfor

close, /all
end
