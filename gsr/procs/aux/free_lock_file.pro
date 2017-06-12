function free_lock_file,filename
common lockfile,id,lun
if not(keyword_set(id)) then id=long(randomu(seed)*2L^30)
FILE_NOT_FOUND=-247
repeat begin
  openr,lun,filename,err=err,/get_lun
  if err ne -247 then begin 
    readf,lun,readid
    close,lun
    free_lun,lun
    if readid ne id then begin
      print,'I do not own this lock file'
      return,0
    endif
    file_delete,filename
    return,1
  endif
  print,"Got error ",err," waiting..."
  wait,10
endrep until 0    
return,0
end
