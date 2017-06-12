
;+
;NAME:
;wasprojfiles - find the files belonging to a project id
;
; SYNTAX: istat=wasprojfiles(proj,fileInfo)
;
; ARGS:
;      proj:  string  proj name to search for
; RETURNS: 
;     istat:  number of files found 
;fileinfo[istat]:   array of file info structures containing the name 
;                   and size of the file
;
;DESCRIPTION:
;   Search through the wapp fits directories looking for files that
;belong to a particular project. Return an array of stuctures containing
;the filename and file size.
;
;-
;
function wasprojfiles ,proj,fileI,dir=dir
;   
;
    defdir='/proj/'+proj
    if not keyword_set(dir) then dir=defdir
    dirl=dir
    if strmid(dirl,strlen(dirl)-1,0) ne '/' then dirl=dirl+'/'
;       
    ntot=0
    fpat=dirl+'wapp*'+proj+'*'+'.fits'
    flist=findfile(fpat,count=ntot)
    if ntot eq 0 then return,0
    a={ fname:''    ,$
        size:  0ul  }
    fileI=replicate(a,ntot)
    fileI.fname=flist
    lun=-1
    for i=0,ntot-1 do begin
        openr,lun,flist[i],/get_lun
        a=fstat(lun)
        free_lun,lun
        lun=-1
        fileI[i].size=a.size
    endfor
    return,ntot
end
