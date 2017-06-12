pro allx1basket, root, region, scans, proj, no_over=no_over, badrxfile=badrxfile, tdf=tdf, odf=odf, no_auto=no_auto, xingname=xingname, keepold=keepold, parallel=parallel, no_spcor=no_spcor, goodx=goodx, xday=xday, spname=spname
;+
; Name:
;   ALLX1BASKET 
; PURPOSE:
;   A wrapper code to generate crossing points, read all spectra into crossing point files, compute relative gains, and save the output
;
; CALLING SEQUENCE:
;      allx1basket, root, region, scans, proj,$
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
;   keepold -- if set, move the old versions _f files to keep. This can be 
;          disk space intensive.
;   tdf -- use the older two-digit formatting
;   odf -- set if using .sav as main data structure (pre- gsr 2.2)
;   badrxfile -- Any file of badrx's
;   no_auto -- Skip the xing file within each day
;   no_over -- If set, will skip and not overwrite *_f.sav files already
;   no_spcor -- if set, don't use any spcor
;   parallel -- set to run in parallel with other machines
;   SPNAME - Set this to the name of your spcor file to use. If you want
;      to use spcor_NAME.sav, set it to 'NAME'. If you wish to use
;      spcor.sav, just set this to 'null'. This will have been set as a
;      xingname in a previous code, but as the user might want to use
;      an spcor file from a xing file different from the xing file whose
;      xing information they want to use, this is a separate keyword from XINGNAME

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
;   Removed XDAY in favor of xing.xday.sav from xgen; january 28, 2011
;   converted from LXW to be less i/o intensive; April 3 2014
;   Joshua E. Goldston, goldston@astro.berkeley.edu ; JEG Peek jegpeek@gmail.com
;-

st = systime(/sec)
; standard formatting issues
if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)' 

; record the applied xing/spcor correction
if keyword_set(xingname) then appl_xing = xingname else appl_xing = 'none'
path = root + proj + '/' + region + '/'

; we no longer will have this...
;restore, path + 'xing/xday.sav'
doij=1.
if not keyword_set(xingname) then xnus = '' else begin
    xnus = '_' + xingname
    restore, path + 'todarr.sav'     
    restore, path + 'xingarr_' + xingname +'.sav'
endelse

if not keyword_set(no_spcor) then begin
	if (keyword_set(spname)) then begin
	    if spname eq 'null' then restore, root + proj + '/' + region + '/spcor.sav'
    	if spname ne 'null' then restore, root + proj + '/' + region + '/spcor_' + spname + '.sav'
    	; HACK HERE ########### GOT RID OF THE SPCOR-XING-SPCOR-XING functionality!!!!
		;restore, root + proj + '/' + region + '/spcor' + xnus + '.sav'
    	if n_elements(zogains) ne 1 then spdat= { zogains:zogains, fpn_sp:fpn_sp} else spdat = fpn
    endif
endif

; all the header info
hdr_fn = strarr(scans)
for i=0, scans-1 do begin 
    hdr_fn[i] = file_search(root + proj + '/' + region + '/' + region + '_' +  string(i, format=scnfmt) + '/',  '*.hdrs.*')
endfor


;save for later!
; HACK to use xday as before
xday = fltarr(scans, scans)+1

xxdd = xday
todo = xday ne 0

; ############# this is gonna be a problem...
if keyword_set(parallel) then begin
      xsname = root + proj + '/' + region + '/xing/xsize.sav' 
    if file_search(xsname) eq xsname then begin 
        restore, xsname
    endif else begin
        find_x_size, root, region, scans, proj
        restore, xsname
    endelse
endif

if not keyword_set(no_auto) then begin


if (keyword_set(no_over) and (file_search(root + proj + '/' + region + '/xing/', region + 'auto_l.sav') eq root + proj + '/' + region + '/xing/'+region + 'auto_l.sav') ) then print, 'file ' + root + proj + '/' + region + '/xing/', region + 'auto_l.sav' + ' exists; skipping' else begin

	if (not (keyword_set(goodx))) then begin
		goodx = fltarr(7,7)
		goodx[0,2]=1.
		goodx[0,5]=1.
		goodx[1,4:6]=1.
		goodx[2,4:6]=1.
		goodx[3,4:6]=1.
	endif
 
 	xarr=0
; Cross every scan with itself, being careful not cross beams that cross
; at cals or with scans that do not intersect.

	for i=0, scans-1 do begin
		restore, hdr_fn[i]
		for j=0, 6 do begin
			for k=j+1, 6 do begin
				if (goodx[j,k]) then begin
					print, format='(%" scan 1 = %d  beam 1 = %d  scan 2 = %d beam 2 = %d \r", $)', i, j ,i, k
					print, ''
					good = 0
					while (good eq 0) do begin
						good = newx(mh, fn, j, i, filepos, mh, fn, k, i, filepos, x)
					endwhile
					if good ne (-1.) then if (n_elements(xarr) ne 1.) then xarr = [xarr, x] else xarr = x
					if good eq (-1.) then print, 'skipped', i,k,j
				endif
			endfor
		endfor
	endfor
	addspec, xarr

		if keyword_set(odf) then loadx, xarr,spdat=spdat, mht=mht, corf=corf, badrxfile=badrxfile else loadxfits, xarr,spdat=spdat, badrxfile=badrxfile, mht=mht, corf=corf

	trimx, xarr
	xf1, xarr, xfit
		if keyword_set(keepold) then spawn, 'cp ' + root + proj + '/' + region + '/xing/'+region + 'auto_f.sav ' + root + proj + '/' + region + '/xing/'+region + 'auto_l'+xnus+'_old.sav'
	save, xfit, appl_xing, filename=root + proj + '/' + region + '/xing/'+region + 'auto_f' + xnus  +'.sav'
endelse

endif
;cycle through scan1
for i=0, scans-1 do begin
    ; cycle through scans to cross with (scan2)
    for j=i+1, scans-1 do begin
        ;ne 0 because we have 2's in xday
		xfit = 0
        if xday[i,j] ne 0 then begin
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
			restore, hdr_fn[i]
            mh1 = mh
            fn1 = fn
            fp1 = filepos
            restore, hdr_fn[j]
            mh2 = mh
            fn2 = fn
            fp2 = filepos
                                ; if no_over is set, skip any files that exist
            ;;; BIG HACK to avoid file_search - reinstitute after system check is over.
            ;if (1 eq 0) then print, '???' else begin
            if (keyword_set(no_over) and (file_search(root + proj + '/' + region + '/xing/', region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '_f.sav') eq root + proj + '/' + region + '/xing/'+region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '_f.sav') ) then print, 'file ' + root + proj + '/' + region + '/xing/', region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '_f.sav' + ' exists; skipping' else begin
                xarr=0
				for k=0, 6 do begin
                	for l =0, 6 do begin
                	print, format='(%" scan 1 = %d  beam 1 = %d  scan 2 = %d beam 2 = %d \r", $)', i, k ,j, l
                	print, ' ' 
						 if xday[i, j] eq 1 then good = newx(mh1, fn1, k, i, fp1, mh2, fn2, l, j, fp2, x) else good = newx(mh1, fn1, k, i, fp1, mh2, fn2, l, j, fp2, x, /link)
						
						if good ne (-1.) then if (n_elements(xarr) ne 1.) then xarr = [xarr, x] else xarr = x
						if good eq (-1.) then print, 'skipped', i,k,j
                	endfor
                endfor
                if (size(size(xarr)))[1] eq 4 then begin
                addspec, xarr
                if keyword_set(odf) then loadx, xarr,spdat=spdat, badrxfile=badrxfile, mht=mht, corf=corf else loadxfits, xarr,spdat=spdat, badrxfile=badrxfile,  mht=mht, corf=corf          
                endif
                trimx, xarr
                szxarr = size(xarr)
                nsz = n_elements(szxarr)
                isastruct = szxarr[nsz-2] eq 8
                if isastruct then begin
	                xf1, xarr, xfit
	                if keyword_set(keepold) then spawn, 'cp ' + root + proj + '/' + region + '/xing/'+ region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '_f.sav ' + root + proj + '/' + region + '/xing/'+ region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '_f_old.sav'
    	            save, xfit, appl_xing, filename=root + proj + '/' + region + '/xing/'+ region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '_f'+xnus+'.sav'
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

xday = xxdd

print, 'allx1basket took ' + string((systime(/sec)-st)/3600.) + ' hours'

end
