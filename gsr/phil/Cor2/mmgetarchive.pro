;+
;NAME:
;mmgetarchive - restore all or part of calibration archive
;SYNTAX: count=mmgetarchive(yymmdd1,yymmdd2,mm,rcvnum=rcvnum)
;ARGS: 
;      yymmdd1  : long    year,month,day of first day to get (ast)
;      yymmdd2  : long    year,month,day of last  day to get (ast)
;KEYWORDS:
;       rcvnum  : long  .. receiver number to extract:
;                       1=327,2=430,3=610,5=lbw,6=lbn,7=sbw,8=sbw,9=cb,$
;                       10=xb,12=sbn,100=430ch
;RETURNS:
;   mm[count]: {mueller} data found
;   count       : long   number of patterns found
;DESCRIPTION:
;   This routine will restore the x102 calibration data stored in 
;/share/megs/phil/x101/x102/runs. It is updated monthly. You specify
;the start and end dates of the data to extract. You can optionally
;specify a receiver with keyword rcvnum. Once the data has been input
;you can created subsets of the data with the mmget() routine.
;
;See mmrestore for a description of the structure format.
;
;EXAMPLES
;
;;get all data for jan02->apr02
; nrecs=mmgetarchive(020101,020430,mm)
;
;;get the cband data for apr02
;
; nrecs=mmgetarchive(020101,020430,mm,rcvnum=9)
;
;;from the cband data extract the 5000 Mhz data
; mm5=mmget(mm,count,freq=5000.)
;
;
;-
function mmgetarchive,yymmdd1,yymmdd2,mmall,rcvnum=rcvnum
;
; list the files in the directory
;
    on_error,1
    maxrecs=50000           ; 11610 y2001
    dir='/share/megs/phil/x101/x102/runs/'
    cmd='ls ' + dir + 'c*sav'
    spawn,cmd,list
    nfiles=n_elements(list)
    juldates=dblarr(2,nfiles)       ; start,end juldates each file
;
;   yymmdd1 is ast
;
    julday1=yymmddtojulday(yymmdd1) + 4./24. ; go utc to ast
    julday2=yymmddtojulday(yymmdd2) + 4./24. ; go utc to ast
    usefile=intarr(nfiles)
    for i=0,nfiles-1 do begin 
        a=stregex(list[i],'c([0-9]*)_([0-9]*)\.sav',/extract,/subexpr ) 
;
;   convert begin,end to jul days
;
        yymmddf1=long(a[1]) 
        yymmddf2=long(a[2]) 
        juldates[0,i]=yymmddtojulday(yymmddf1)
        juldates[1,i]=yymmddtojulday(yymmddf2)
        if (yymmddf2 lt yymmdd1) or (yymmddf1 gt yymmdd2) then begin
        endif else begin
            usefile[i]= 1
        endelse
;        print,list[i]," use:",usefile[i]
    endfor
    mmall=replicate({mueller},maxrecs)
    ii=0
    for i=0,nfiles-1 do begin
        if usefile[i] then begin
            restore,list[i]
;
;           file overlaps 1 side of range, just use part in range
;
            nrecs=n_elements(mm)
            if n_elements(rcvnum) gt 0 then begin
                ind=where(mm.rcvnum eq rcvnum,nrecs)
                if nrecs gt 0 then mm=mm[ind]
            endif
            if nrecs gt 0 then begin
               ind=where(((mm.julday + 2400000.D) ge julday1) and $
                      ((mm.julday + 2400000.D) lt julday2+1),count)
               if count gt 0 then begin
                  mmall[ii:ii+count-1]=mm[ind]
                  ii=ii+count
               endif
            endif
        endif
    endfor
    nrecs=ii
    if nrecs lt maxrecs then begin
        if nrecs eq 0 then begin
            mmall='' 
        endif else begin
            mmall=mmall[0:nrecs-1]
        endelse
    endif 
    return,nrecs
end
