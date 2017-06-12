pro savelxw, root, region, scans, proj, badrxfile, tdf=tdf, odf=odf, no_auto=no_auto,  parallel=parallel
;+
; Name:
;   SAVELXW 
; PURPOSE:
;   A hack fix to the  wrapper code to load all spectra into crossing
;   point files, if you haven't called a badrxfile
;
; CALLING SEQUENCE:
;      lxw, root, region, scans, proj,$
;      xingname=xingname, no_over=no_over, xday=xday, $
;      badrxfile=badrxfile, tdf=tdf, sav=sav, no_auto=no_auto
;
;
; INPUTS:
;   root -- The main directory in which the project directory
;             resides (e.g. '/dzd4/heiles/gsrdata/' )
;   region -- The name of the source as entered into BW_fm (e.g. 'lwa')
;   scans -- Number of days the project consists of
;   proj -- The Arecibo project code (e.g. 'a2050')
;
; KEYWORDS PARAMETERS
;   xingname -- if set, use a version of spcor as built with a previous xing run
;               and applicable xing factors
;   keepold -- if set, move the old versions _l files to keep. This can be 
;          disk space intensive.
;   tdf -- use the older two-digit formatting
;   odf -- set if using .sav as main data structure (pre- gsr 2.2)
;   XDAY  -- A scans x scans matrix equivalent to the above, but for days. 
;   badrxfile -- Any file of badrx's
;   no_auto -- Skip the xing file within each day
;   no_over -- If set, will skip and not overwrite *_l.sav files already
;   no_spcor -- if set, don't use any spcor
;   keepold -- if set, keep the old copies of _l.sav files
;   xingname -- if set, use specific spcor file from previous version of xing
;   parallel -- set to run in parallel with other machines
; OUTPUTS:
;   NONE (files loaded with spectra)
;
; MODIFICATION HISTORY:
;   Initial Documentation Friday, July 22, 2005
;   Added Xday, May 26 2 thousand 6
;   Modified for S1H compatability, July 12, 2006, Goldston Peek
;   Added xingname & keepold. October 23rd, 2006 JEG Peek
;   Added parallel , April 15th, 2007 JEG Peek
;   Added code for SPCORv2, February 17th, 2009, JEGP
;   Redesigned parallel keyword for more flexible implementation, Feb 24 2009, JEGP
;   Joshua E. Goldston, goldston@astro.berkeley.edu
;-

if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)' 
; record the applied xing/spcor correction
if keyword_set(xingname) then appl_xing = xingname else appl_xing = 'none'
path = root + proj + '/' + region + '/'
doij=1.
if not keyword_set(xingname) then xnus = '' else begin
    xnus = '_' + xingname
    restore, path + 'todarr.sav'     
    restore, path + 'xingarr_' + xingname +'.sav'
endelse

if not keyword_set(no_spcor) then begin
    restore, root + proj + '/' + region + '/spcor' + xnus + '.sav'
    if n_elements(zogains) ne 1 then spdat= { zogains:zogains, fpn_sp:fpn_sp} else spdat = fpn
endif

; xday for only days that have at least one badrx
if (keyword_set(parallel) and (1 - file_exists(root + proj + '/' + region + '/xing/xsize.sav'))) or (1-keyword_set(parallel)) then begin
   xday = fltarr(scans, scans)
   for i=0, scans-2 do begin
      for j=i, scans-1 do begin
         if ((min(rxmultiplier[0, *, *, i]) eq 0) or (min(rxmultiplier[0, *, *, j]) eq 0)) then xday[i, j] = file_exists(root + proj + '/' + region + '/xing/'+ region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '_l'+xnus+'.sav')
      endfor
   endfor
endif

;if not (keyword_set(xday)) then xday = fltarr(scans, scans) + 1.
;save for later!
;if keyword_set(xday) then xxdd = xday
todo = xday
if keyword_set(parallel) then begin
      xsname = root + proj + '/' + region + '/xing/xsize.sav' 
    if file_search(xsname) eq xsname then begin 
        restore, xsname
    endif else begin
        find_x_size, root, region, scans, proj, xday=xday
        restore, xsname
    endelse
; new version of parallel
;    ttl = total(fs)
;   avgsz = ttl/parallel[0]
;    cum = total(fs, /cumulative)
;    wh = where((cum gt avgsz*parallel[1]) and (cum le avgsz*(parallel[1]+1)))
;    dox = xday*0.
;    dox[wh] = 1.
;    xday = xday*dox
endif

if not keyword_set(no_auto) then begin

if (keyword_set(no_over) and (file_search(root + proj + '/' + region + '/xing/', region + 'auto_l.sav') eq root + proj + '/' + region + '/xing/'+region + 'auto_l.sav') ) then print, 'file ' + root + proj + '/' + region + '/xing/', region + 'auto_l.sav' + ' exists; skipping' else begin
 
    restore, root + proj + '/' + region + '/xing/'+ region + 'auto_l.sav'
 ;   addspec, xarr
    badrx_bd = reform(rxmultiplier[0, 0, *, *]) ne 1

    whbad = where((badrx_bd[xarr.beam1, xarr.scan1] eq 1) or (badrx_bd[xarr.beam2, xarr.scan2] eq 1))
    xarrfix = xarr[whbad]
    if keyword_set(odf) then loadx, xarrfix,spdat=spdat, mht=mht, corf=corf, badrxfile=badrxfile else loadxfits, xarrfix,spdat=spdat, badrxfile=badrxfile, mht=mht, corf=corf
    xarr[whbad] = xarrfix
    if keyword_set(keepold) then spawn, 'cp ' + root + proj + '/' + region + '/xing/'+region + 'auto_l.sav ' + root + proj + '/' + region + '/xing/'+region + 'auto_l'+xnus+'_old.sav'
    save, xarr, appl_xing, filename=root + proj + '/' + region + '/xing/'+region + 'auto_l' + xnus  +'.sav'
endelse

endif


;cycle through scan1
for i=0, scans-1 do begin
    ; cycle through scans to cross with (scan2)
    for j=i+1, scans-1 do begin
        if xday[i,j] eq 1 then begin
            if keyword_set(parallel) then begin
                xt= systime(/sec)
; ERIC'S LOCKING RESTORE CODE:                
                repeat begin
                    got_lock=get_lock_file(xsname + '.lock')
                endrep until got_lock eq 1
                restore, xsname
                dummy_var=free_lock_file(xsname+'.lock')
; END ERIC'S LOCKING RESTORE CODE
                if todo[i,j] ne 1 then begin
                    wh = where(transpose(todo) eq 1, ct)
                    if ct eq 0 then return
                    i = fix(min(wh)/scans)
                    j = fix(min(wh) mod scans)
                endif
                                ; 2. is in progress
                todo[i,j] = 2.
; ERIC'S LOCKING SAVE CODE:  
                repeat begin
                    got_lock=get_lock_file(xsname + '.lock')
                endrep until got_lock eq 1
                save, todo,fs, f=xsname
                dummy_var=free_lock_file(xsname+'.lock')
; END ERIC'S LOCKING SAVE CODE
                doij = 1.
            endif

                                ; if no_over is set, skip any files that exist
            ;;; BIG HACK to avoid file_search - reinstitute after system check is over.
            if (1 eq 0) then print, '???' else begin
;(keyword_set(no_over) and (file_search(root + proj + '/' + region + '/xing/', region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '_l.sav') eq root + proj + '/' + region + '/xing/'+region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '_l.sav') ) then print, 'file ' + root + proj + '/' + region + '/xing/', region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '_l.sav' + ' exists; skipping'
                print, 'reading file: ' +  region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '.sav'
                print, ' '
               ; restore, root + proj + '/' + region + '/xing/'+ region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '.sav'
                restore, root + proj + '/' + region + '/xing/'+ region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '_l.sav'
                   ; to distinguish from a 0.
                ; the rxes that are good
                rxmsij1 = reform(rxmultiplier[0, 0, *, i]) eq 1
                rxmsij2 = reform(rxmultiplier[0, 0, *, j]) eq 1
                whbbs1 = where(rxmsij1 eq 0)
                whbbs2 = where(rxmsij2 eq 0)
                fixmask = fltarr(n_elements(xarr))
                if total(whbbs1) ne (-1) then begin
                   for k=0, n_elements(whbbs1)-1 do begin
                      whx = where(xarr.beam1 eq whbbs1[k], ct)
                      if ct ne 0 then fixmask[whx] = 1.
                   endfor
                endif
                if total(whbbs2) ne (-1) then begin
                   for k=0, n_elements(whbbs2)-1 do begin
                      whx = where(xarr.beam2 eq whbbs2[k], ct)
                      if ct ne 0 then fixmask[whx] = 1.
                   endfor
                endif
                wherefix = where(fixmask eq 1, ct)
                if ct ne 0 then begin
                                ; if the files were corrupted by the
                                ; crap version of savelxe
                   ; then we need to re-load the xgen data
                   xarr_l = xarr
                   restore, root + proj + '/' + region + '/xing/'+ region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '.sav'
                   xarrfix = xarr[wherefix]
                   addspec, xarrfix
                   loadxfits, xarrfix,spdat=spdat, badrxfile=badrxfile,  mht=mht, corf=corf
                   xarr_l[wherefix] = xarrfix;[wherefix]
                   xarr = xarr_l
                   save, xarr, appl_xing, filename=root + proj + '/' + region + '/xing/'+ region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '_l'+xnus+'.sav'
                   endif
             endelse
            if ((keyword_set(parallel)) and (doij eq 1)) then begin
; ERIC'S LOCKING RESTORE CODE:                
               repeat begin
                  got_lock=get_lock_file(xsname + '.lock')
               endrep until got_lock eq 1
               restore, xsname
               dummy_var=free_lock_file(xsname+'.lock')
; END ERIC'S LOCKING RESTORE CODE
                                ; 3 is completed
               todo[i,j] = 3.
; ERIC'S LOCKING SAVE CODE:  
               repeat begin
                  got_lock=get_lock_file(xsname + '.lock')
               endrep until got_lock eq 1
               save, todo,fs, f=xsname
               dummy_var=free_lock_file(xsname+'.lock')
; END ERIC'S LOCKING SAVE CODE
               print, 'scan [' + string(i, f='(I3.3)') + ',' + string(j, f='(I3.3)') + ']: ' + string((systime(/sec) - xt)/fs[i,j]) + ' seconds per crossing point.'
            endif
         endif
     endfor
 endfor

if keyword_set(xday) then xday = xxdd

end
