pro xgen, root, region, scans, proj, goodx=goodx, xday=xday, blankfile=blankfile, tdf=tdf, noauto=noauto, parallel=parallel

;+
; NAME:
;   xgen
; PURPOSE:
;  Generate all the locations of all crossing points within a given 
;  BW/Galspect run. Save these positions to files in a orderly fashion
;  for future crossing-point calibration steps.
;
; CALLING SEQUENCE:
;    xgen, root, region, scans, dates, proj
;
; INPUTS:
;   ROOT - The diectory in which the project subdirectory is located,
;          e.g. '/dzd4/heiles/gsrata/'
;   REGION - The name of the region in question, e.g. 'blw'
;   SCANS - The number of days of scans used, e.g. 11
;   PROJ - The name of the project, e.g. 'a2050'
;
; KEYWORD PARAMETERS:
;   GOODX - A 7x7 matrix - if an element is set to 1, the corrosponding beams
;           in a single day are allowed to cross. Note that only the upper
;           triangle, goodx[i,j], i < J, is used. The lower triangle is 
;           irrelevant. Goodx is otherwise set to values appropriate to
;           normal, gear6 basketweaves scans.   
;   XDAY  - A scans x scans matrix equivalent to the above, but for days. A 1 indicates
;           a crossing, a 2 indicates a linking, two drift scans that want to be linked together
;   tdf -- use the older two-digit formatting
;   blankfile - any seconds to blank out. See edblanks.
;   noauto - don't do the auto crossing scans
; OUTPUTS:
;    NONE (files in xing direcotry)
; MODIFICATION HISTORY:
;   Initial Documentation Wednesday, July 5, 2005.
;   Modified for S1H compatability, July 12, 2006, Goldston Peek
;   Modified to deal with days that have not XING points, added noauto October 5th, 2009
;-

if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)' 
hdr_fn = strarr(scans)

for i=0, scans-1 do begin 
    hdr_fn[i] = file_search(root + proj + '/' + region + '/' + region + '_' +  string(i, format=scnfmt) + '/',  '*.hdrs.*')
 endfor

; When cals are fired, only some xing points are legit. Others go through cals.
if (not (keyword_set(goodx))) then begin
    goodx = fltarr(7,7)
    goodx[0,2]=1.
    goodx[0,5]=1.
    goodx[1,4:6]=1.
    goodx[2,4:6]=1.
    goodx[3,4:6]=1.
endif

if(not (keyword_set(xday))) then xday = fltarr(scans, scans) + 1.
xarr=0
; Cross every scan with itself, being careful not cross beams that cross
; at cals or with scans that do not intersect.

if not keyword_set(noauto) then begin
for i=0, scans-1 do begin
    if xday[i,i] eq 1 then begin
        restore, hdr_fn[i]
        for j=0, 6 do begin
            for k=j+1, 6 do begin
                if (goodx[j,k]) then begin
                    print, format='(%" scan 1 = %d  beam 1 = %d  scan 2 = %d beam 2 = %d \r", $)', i, j ,i, k
                    print, ''
                    good = 0
;                    q=0.
                                ;p=0.
                    while (good eq 0) do begin
                     ;   good = getx(mh, fn, j, i, mh, fn, k, i, 0, q, x)
                        good = newx(mh, fn, j, i, filepos, mh, fn, k, i, filepos, x)
                        ;q=q+1
                                ;p=p+1
                    endwhile
                                ;if (n_elements(xarr) ne 1.) then xarr = [xarr, x] else xarr = x            
                    if good ne (-1.) then if (n_elements(xarr) ne 1.) then xarr = [xarr, x] else xarr = x
                    if good eq (-1.) then print, 'skipped', i,k,j
                endif
            endfor
        endfor
    endif
endfor


;; speed the plow!!
if keyword_set(blankfile) then removeblanks, blankfile, xarr
save, xarr, filename=root + proj + '/' + region + '/xing/'+ region + 'auto.sav'
endif
xarr=0

;cycle through scan1
for i=0, scans-1 do begin
    ; cycle through scans to cross with (scan2)
    for j=i+1, scans-1 do begin
        if xday[i,j] ne 0 then begin
                                ; load said scans
         ;An attempt to make xgen work in parallel.
   ;       if keyword_set(parallel) then begin
   ;          fncheck = root + proj + '/' + region + '/xing/'+ region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '.sav'
   ;          if file_search(fncheck) eq fncheck then begin
   ;             print, 'Exists already',i,j
   ;             continue
   ;          endif
   ;       endif
          ;*************

            restore, hdr_fn[i]
            mh1 = mh
            fn1 = fn
            fp1 = filepos
            restore, hdr_fn[j]
            mh2 = mh
            fn2 = fn
            fp2 = filepos
                                ; cycle though beam1
            for k=0, 6 do begin
                                ; cycle beam2 (note : 1x2 <> 2x1)
                for l =0, 6 do begin
                                ; find xing pts
                                ; only put together links for same beam number; assumes same alfaangle!
                    if (xday[i,j] ne 2) or (l eq k) then begin
                    print, format='(%" scan 1 = %d  beam 1 = %d  scan 2 = %d beam 2 = %d \r", $)', i, k ,j, l
                    print, ''
                    good = 0
 ;                   q=0
 ;                   p=0
                    while (good eq 0) do begin
;                        good = getx(mh1, fn1, k, i, mh2, fn2, l, j, p, q, x)
                        if xday[i, j] eq 1 then good = newx(mh1, fn1, k, i, fp1, mh2, fn2, l, j, fp2, x) else good = newx(mh1, fn1, k, i, fp1, mh2, fn2, l, j, fp2, x, /link)
;                       q=q+1
 ;                       p=p+1
                                ; if (good ne 1) then stop
                    endwhile
; add xing pts
                    if good ne (-1.) then if (n_elements(xarr) ne 1.) then xarr = [xarr, x] else xarr = x
                    if good eq (-1.) then print, 'skipped', i,k,j,l
                    endif
                endfor
            endfor
                 ;    xarr2 = temporary(xarr)
;    restore, 'temp.sav'
;    xarr = [xarr, xarr2]
;            if good ne (-1) then begin
            if(n_elements(xarr) gt 1.) then begin
            if keyword_set(blankfile) then removeblanks, blankfile, xarr
            save, xarr, filename= root + proj + '/' + region + '/xing/'+ region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '.sav'
         endif

            xarr=0.
         endif
    endfor
endfor

;;Kevin's little program to make an xday array that will work properly in lxw and xfit
kday=fltarr(scans,scans)
for k=0,scans-1 do kday(k,k)=1.0
for i = 0,scans - 2 do begin
    for j = i+1, scans-1 do begin
        xgf = root+proj+'/'+region+'/xing/'+region+string(i,format='(I3.3)')+'-'+string(j,format='(I3.3)')+'.sav'
        if file_search(xgf) then kday(i,j) = 1.0
    endfor
endfor
xall=fltarr(scans,scans)+1.0
if keyword_set(xday) then xall=xday
;xday will now be 1 only if a file exists... but don't want to
;get rid of 2's! This is sloppy but I don't want to mess with
;Kevin's loop so I'll just index the 2's and put em back in.
indx2=where(xall eq 2, count2)
xday=kday < xall
if count2 ne 0 then xday(indx2)=2
save,xday,filename=root+proj+'/'+region+'/xing/xday.sav'

end
