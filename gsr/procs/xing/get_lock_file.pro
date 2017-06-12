function get_lock_file,filename,nowait=nowait,quiet=quiet
common lockfile,id,lun
if not(keyword_set(nowait)) then nowait=0
if not(keyword_set(id)) then id=long(randomu(seed)*2L^30)
FILE_NOT_FOUND=-247
; seems to be the real FNF error?
FILE_NOT_FOUND2=-250
; seems to be the real FNF error?
FILE_NOT_FOUND3=-249
repeat begin
  openr,lun,filename,err=err,/get_lun
  if (err ne FILE_NOT_FOUND) and  ((err ne FILE_NOT_FOUND2) and (err ne FILE_NOT_FOUND3)) then begin 
    close,lun
    free_lun,lun
    if nowait ne 0 then begin
      if not(keyword_set(quiet)) then print,"Unable to get lock file"
      return,0
    endif
  endif else begin
    openw,lun,filename,err=err,/get_lun
    if err eq 0 then begin
      printf,lun,id
      close,lun
      openr,lun,filename,err=err
      if err eq 0 then begin
         readf,lun,readid
         close,lun
         free_lun,lun
	 if readid eq id then begin
           return,1
	 endif
      endif
    endif
  endelse
  if not(keyword_set(quiet)) then print,"Waiting for lock file"
  wait,10
endrep until 0    
return,0
end
