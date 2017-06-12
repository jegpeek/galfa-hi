pro xplot, root, proj, region, scans

;+
;NAME:
;  xplot
;PURPOSE:
; Plot the positions of the crossing points.
;
;CALLING SEQUENCE:
;   xplot,root,region,scans
;
;INPUTS:
; ROOT - The directory in which the project subdirectories reside (e.g. '/share/galfa/fallmrg/'
; REGION - The name of the region in question (e.g. 'sct')
; SCANS - The number of days of scans used, e.g. 11
; PROJ - The name of the project, e.g. 'a2124'
;
;OUTPUTS:
; 
;
;MODIFICATION HISTORY:
;  Initial documentation Monday, October 5, 2009, Jana Grcevich

cd,root + proj + '/' + region + '/'

i=0
j=0
k=0

;fn = file_search(*.sav)
;for k=0,n_elements(fn)
;restore,fn[k]

set_plot,'x'
;set_plot,'ps'
;
;

for i=0, scans-1 do begin
for j=i+1, scans-1 do begin
print,i,j
fn = 'sct' + string(i,f='(I3.3)') + '_' + string(j,f='(I3.3)') + '.sav'
restore,fn
if (i eq 0) and (j eq 1) then begin
plot,xarr.XRA,xarr.XDEC,xrange=[0.0,24.0],yrange=[0.0,45.0]
endif else begin
oplot,xarr.XRA,xarr.XDEC
endelse

endfor
endfor

;device,/close
;set_plot,'x'

end

