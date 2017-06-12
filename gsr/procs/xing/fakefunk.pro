pro fakefunk, root, region, scans, proj, scanlist, tieday, rax, timex

nel = n_elements(scanlist)*7.

outx = replicate({scan1:0., beam1:0., time1:0l, fn1bef:'null', fn1aft:'null', W1:0., scan2:0., beam2:0., time2:0l, fn2bef:'null', fn2aft:'null', W2:0., XRA:0., Xdec:0., ZPTR:0., GAINR:0., sigab:fltarr(2)}, nel)

for i=0, n_elements(scanlist)-1 do begin
   for j=0, 6 do begin
      nn = i*7+j
      outx[nn].scan1=tieday
      outx[nn].beam1=j
      outx[nn].time1=timex
      outx[nn].scan2=scanlist[i]
      outx[nn].beam2=j
      outx[nn].time2=timex
      outx[nn].xra=rax
      outx[nn].gainr=1.
      outx[nn].sigab=0.001
   endfor
endfor

appl_xing  = 'none'
save, outx, appl_xing, filename= root + proj + '/' + region + '/xing/'+ region + 'fakefunk_f.sav'

end      
      
