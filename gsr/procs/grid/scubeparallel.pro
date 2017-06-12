pro scubeparallel, root, region, proj, rs=rs, tdf=tdf, spname=spname, badrxfile=badrxfile, xingname=xingname, odf=odf, blankfile=blankfile, arcminperpixel=arcminperpixel, pts=pts, cpp=cpp, madecubes=madecubes, noslice=noslice, nocleanup=nocleanup, spblfile=spblfile, _REF_EXTRA=_extra, allfls=allfls

allfls = ' '

q = 0
while q ne 1 do begin
scname = root + proj + '/' + region + '/sclist.sav' 
if file_search(scname) eq scname then begin 
	restore, scname
endif else begin
	print, 'I need a scube file list, called ' + root + proj + '/' + region + '/sclist.sav' 
	return
endelse

i=0
j=0
xt= systime(/sec)
; ERIC'S LOCKING RESTORE CODE:                
repeat begin
got_lock=get_lock_file(scname + '.lock')
endrep until got_lock eq 1
restore, scname
dummy_var=free_lock_file(scname+'.lock')
; END ERIC'S LOCKING RESTORE CODE
if todo[i,j] ne 1 then begin
	wh = where(todo eq 1, ct)
	if ct eq 0 then return
	chrand = (wh[sort(randomu(seed, ct))])[0]
	j = fix(chrand/45)
	i = fix(chrand mod 45)
endif
; 2. is in progress
todo[i,j] = 2.

; ERIC'S LOCKING SAVE CODE:  
repeat begin
got_lock=get_lock_file(scname + '.lock')
endrep until got_lock eq 1
save, todo,fs, f=scname
dummy_var=free_lock_file(scname+'.lock')
; END ERIC'S LOCKING SAVE CODE

PRINT, 'Now doing cube ' + cname(i, j)

; DO SCUBE STUFF HERE

scube, root, region, proj, i, j, rs=rs, tdf=tdf, spname=spname, badrxfile=badrxfile, xingname=xingname, odf=odf, blankfile=blankfile, arcminperpixel=arcminperpixel, norm=1, pts=pts,  cpp=cpp, madecubes=madecubes, noslice=noslice, spblfile=spblfile, _REF_EXTRA=_extra

scube, root, region, proj, i, j, rs=rs, tdf=tdf, spname=spname, badrxfile=badrxfile, xingname=xingname, odf=odf, blankfile=blankfile, arcminperpixel=arcminperpixel, norm=1, pts=pts,  cpp=cpp, madecubes=madecubes, noslice=noslice, /nocleanup, spblfile=spblfile, strad=1, _REF_EXTRA=_extra, fls=fls

allfls = [allfls, fls]

; ERIC'S LOCKING RESTORE CODE:                
repeat begin
	got_lock=get_lock_file(scname + '.lock')
endrep until got_lock eq 1
restore, scname
dummy_var=free_lock_file(scname+'.lock')
; END ERIC'S LOCKING RESTORE CODE
				; 3 is completed
todo[i,j] = 3.

; ERIC'S LOCKING SAVE CODE:  
repeat begin
	got_lock=get_lock_file(scname + '.lock')
endrep until got_lock eq 1
save, todo,fs, f=scname
dummy_var=free_lock_file(scname+'.lock')
; END ERIC'S LOCKING SAVE CODE
endwhile


end