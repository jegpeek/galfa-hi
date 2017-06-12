;+
;NAME:
;allmkdoc - create all html documentation.
;SYNTAX: @allmkdoc
;
;DESCRIPTION:
;   Create all of the html documentation in the directory specified by
;aodefdir(/doc). The routine will create a temporary file /tmp/idlmkall.pro
;and then executes it. It deletes it when done.
; You need write access to the aodefdir(/doc) directory and to /tmp
;- 
;
tmpfile='/tmp/idlmkall.pro'
openw,lun,tmpfile,/get_lun
flist=['gen/pnt/pntmkdoc',$
 'gen/genmkdoc',$
 'Cor2/cormkdoc',$
 'Cor2/cormap/cormapmkdoc',$
 'was2/wasmkdoc',$
 'atm/atmmkdoc',$
 'wapp/wappmkdoc',$
 'ri/rimkdoc']

for i=0,n_elements(flist)-1 do printf,lun,'.run ' + aodefdir() + flist[i]
free_lun,lun
@/tmp/idlmkall
$rm /tmp/idlmkall.pro
