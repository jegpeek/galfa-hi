; code for looking at spcor files

pro view_fpn_fit, fpn, scan, beam

ndec = n_elements(fpn.(scan).decs)
device,dec=0
!p.multi=[0, 1, ndec]
bm1=beam
bm2=beam
; if beam=7 then display all 7 beams in plot window
if beam eq 7 then begin
 !p.multi=[0, 7, ndec,1,1]
 bm1=0
 bm2=6
endif

for bm=bm1,bm2 do begin
 for i=0, ndec-1 do begin
   loadct, 0, /sil
;   rxg = fpn.(scan).rxg[*, bm]
;   aggr = fpn.(scan).aggr
;   stop
   plot, total(rebin(reform(fpn.(scan).rxg[*, bm], 1, 1, 2), 8192, 1, 2)*fpn.(scan).aggr[*, bm,*,  i], 3)/2. - total(total(rebin(reform(transpose(reform(fpn.(scan).rxg)), 1, 7, 2), 8192, 7, 2)*fpn.(scan).aggr[*, *, *,  i], 3),2 )/total(fpn.(scan).rxg), yra=[-1, 1], title = 'dec = ' + string(fpn.(scan).decs[i]) + ',scan=' + string(scan) + ',  bm = ' + string(bm),xra=[0,8192],/xs
   loadct, 13, /sil
   oplot, fpn.(scan).fpn[*, bm, i]
 endfor
endfor

end
