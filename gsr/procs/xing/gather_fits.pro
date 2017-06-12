pro gather_fits, root, region, scans, proj, xingname=xingname

if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)' 
if keyword_set(xingname) then appl_xing = xingname else appl_xing = 'none'
if not keyword_set(xingname) then xnus = '' else xnus = '_' + xingname

guess = 1d6

gf = replicate({scan1:0., beam1:0., scan2:0., beam2:0., XRA:0., Xdec:0., GAINR:0., fn:''}, guess)
q = 0

for i=0l, scans-1 do begin   
   loop_bar, i, scans
    ; cycle through scans to cross with (scan2)
   for j=i+1, scans-1 do begin   
      fe = file_exists(root + proj + '/' + region + '/xing/'+ region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '_f'+xnus+'.sav')
      if fe then restore, root + proj + '/' + region + '/xing/'+ region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '_f'+xnus+'.sav'
      nel = n_elements(outx)
      if (q+nel-1) gt guess then begin
         gf2 =  replicate({scan1:0., beam1:0., scan2:0., beam2:0., XRA:0., Xdec:0., GAINR:0., fn:''}, guess*2)
         gf2[0:guess-1] = gf
         gf = gf2
         guess = guess*2.
      endif
      gf[q:q+nel-1].scan1 = outx.scan1
      gf[q:q+nel-1].beam1 = outx.beam1
      gf[q:q+nel-1].scan2 = outx.scan2
      gf[q:q+nel-1].beam2 = outx.beam2
      gf[q:q+nel-1].xra = outx.xra
      gf[q:q+nel-1].xdec = outx.xdec
      gf[q:q+nel-1].gainr = outx.gainr
      gf[q:q+nel-1].fn = region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '_f'+xnus+'.sav'
      q = q + nel
   endfor
endfor
gf = gf[0:q-1]

save, gf, f=root + proj + '/' + region + '/xing/gf.sav'

end

