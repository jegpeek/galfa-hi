pro add_blanks, root, region, scans, proj, blankfile, badrxfile=badrxfile, _REF_EXTRA=_EXTRA, badcl=badcl, range=range, xsize=xsize, ysize=ysize

window, 0, xsize=xsize, ysize=ysize
window, 1, xsize=xsize, ysize=ysize
window, 2, xsize=xsize, ysize=ysize

if not keyword_set(badcl) then badcl = 100
bkgrnd=64.
circle
 wt = 1.
fct=1e6
badbeam=0.
if not (keyword_set(coltab)) then coltab =13
device, decomposed=0

if not(keyword_set(range)) then begin
range[0] =0
range[1] = scans-1
endif

for i=range[0], range[1] do begin
    restore, blankfile
    loadct, 0, /silent
    restore, root + '/' + proj + '/' + region + '/'+ region + '_' + string(i, f='(I3.3)') + '/*hdrs*'
    nel = n_elements(mh)
    whichrx, mh[nel/2].UTCSTAMP, goodrx, badrxfile=badrxfile
    szp = size(mh.pwr_nb)
    pwrs = total(rebin(reform(goodrx, 2, 7, 1), 2, 7, szp[3])*mh.pwr_nb, 1)/total(rebin(reform(goodrx, 2, 7, 1), 2, 7, szp[3]), 1)
    sz = size(blanks)
    bk = fltarr(7, szp[3])
    for q=0, sz[2]-1 do begin
        whb = where((mh.utcstamp lt blanks[1, q]) and (mh.utcstamp gt blanks[0, q]), ct)
        if (ct ne 0) then bk(blanks[2, q], whb)= 1.
    endfor
    zct = min(mh.utcstamp)
    wset, 0
    !p.multi=0.
    plot, mh.ra_halfsec[0]*15., mh.dec_halfsec[0], psym=3, /ynoz, /nodata
    plot, mh.ra_halfsec[0]*15., mh.dec_halfsec[0], xra=reverse(!x.crange), psym=3, /ynoz
    
    loadct, /silent, coltab
    plots,  mh.ra_halfsec[0]*15., mh.dec_halfsec[0], psym=3, color=255-total(bk,1)*(255-badcl)/7.
    loadct, /silent, 0
    xyouts, 0.7, 0.5, 'scan=' + string(i, f='(I3.3)'), /normal
    wset, 1
    !p.multi=[0,1,7]
    for k=0,6 do begin
        loadct, /silent, 0
        plot, mh.utcstamp-zct, pwrs[k, *]/fct, _EXTRA=_EXTRA, title='BEAM=' + string(k, f='(I1.1)') +', time=' + string(zct, f='(I10.10)'), /xs, /ynoz
        loadct, /silent, coltab
        plots, mh.utcstamp-zct, pwrs[k, *]/fct, color=255-bk[k,*]*(255-badcl)
    endfor
    loadct, /silent, 0
    xyouts, 0.7, 0.5, 'scan=' + string(i, f='(I3.3)'), /normal
    !p.multi=0
    bad = buttons(['No', 'Yes'], asp=2, title='Any unmarked bad periods?', win=2)
    wait, 0.2
    if bad ne 0 then begin
        edmode = buttons(['RA/Dec', 'UTC/power'], asp=2, title='Which edit mode?', win=2)
        if edmode eq 0 then begin
; PORTED FROM ENDFINDER
cuts = fltarr(2)
modes = mh.obsmode
mode_names = modes(uniq(modes, sort(modes)))
nmn = n_elements(mode_names)
clrs = findgen(nmn)/(nmn-1)*200 + 55
objcol = fltarr(n_elements(mh))
for q=0, nmn-1 do objcol(where(modes eq mode_names[q])) = clrs[q]
wset, 0
device, decomposed=0.

for j=0, 1 do begin

if j eq 0 then sf = 'bad data start'
if j eq 1 then sf = 'bad data finish'

opixwin, ow
loadct, /silent, 0
plot, mh.ra_halfsec[0]*15., mh.dec_halfsec[0], psym=3, /ynozero, background=bkgrd, xtitle='RA', ytitle='Dec', thick=th, /nodata
plot, mh.ra_halfsec[0]*15., mh.dec_halfsec[0], psym=3, /ynozero, background=bkgrd, xtitle='RA', ytitle='Dec', thick=th, xra=reverse(!x.crange)
loadct, /silent, coltab
plots,  mh.ra_halfsec[0]*15, mh.dec_halfsec[0], psym=3, color=objcol, thick=th
legend, mode_names, psym=-3, color=clrs
cpixwin, ow, pw, x1, y1, p1
spixwin, pw

print, 'Choosing a ' + sf + ' point'

wait, wt
print, 'would you like to zoom in?  (L=no, R = yes)'
cursor, x, y, /up
if !mouse.button eq 1 then zoom = 0. else zoom = 1.

while zoom eq 1 do begin

print, 'middle buton to select'
!mouse.button=1.
while (!mouse.button ne 2) do begin
    cursor, x, y, /change
    spixwin, pw
    plots, x, y, psym=1, color=200, thick=1., symsize=2
endwhile

ropixwin, ow, pw, x1, y1, p1
plots, x, y, psym=1, color=200, thick=1., symsize=2
cpixwin, ow, pw, x1, y1, p1
wait, wt
!mouse.button=1.

while (!mouse.button ne 2) do begin
    cursor, xx, yy, /change
    spixwin, pw
    oplot, [x,xx, xx, x, x] , [y,y, yy, yy, y], color=200, thick=1
endwhile

ix = min([x, xx])
ax = max([x, xx])
iy = min([y, yy])
ay = max([y, yy])


opixwin, ow;, pw, x1, y1, p1
loadct, /silent, 0
plot, mh.ra_halfsec[0]*15, mh.dec_halfsec[0], psym=3, /ynozero, xra=[ax, ix], yra=[iy, ay], background=bkgrd, xtitle='RA', ytitle='Dec', thick=th
loadct, /silent, coltab
plots,  mh.ra_halfsec[0]*15., mh.dec_halfsec[0], psym=3, color=objcol, thick=th
legend, mode_names, psym=-3, color=clrs
cpixwin, ow, pw, x1, y1, p1
spixwin, pw
wait, wt
print, 'would you like to zoom in?  (L=no, R = yes)'
cursor, x, y, /up
if !mouse.button eq 1 then zoom = 0. else zoom = 1.

endwhile

print, 'Now select a ' + sf + 'ing point (middle button)'

while (!mouse.button ne 2) do begin
    cursor, xs , ys,/change
    spixwin, pw
    d = min( (xs-mh.ra_halfsec[0]*15.)^2*225. + (ys - mh.dec_halfsec[0])^2, pos)
    plots, mh[pos].ra_halfsec[0]*15., mh[pos].dec_halfsec[0], psym=8, symsize=3, thick=th
endwhile

cuts[j] = pos 
endfor
utcs = mh[cuts].utcstamp
; END PORT
badbeams = fltarr(7)+1.
for l=0, 6 do blanks = [[blanks], [utcs[0], utcs[1], l]]
        endif
        if edmode eq 1 then begin
         badbeam = buttons(['0', '1', '2', '3', '4', '5', '6', 'All'], asp=2, title='Which beam is bad?', win=2)
         if badbeam eq 7 then pwr = total(pwrs, 1)/7. else pwr = reform(pwrs[badbeam, *])
            ; PORTED FROM END FINDER
cuts = fltarr(2)
modes = mh.obsmode
mode_names = modes(uniq(modes, sort(modes)))
nmn = n_elements(mode_names)
clrs = findgen(nmn)/(nmn-1)*200 + 55
objcol = fltarr(n_elements(mh))
for q=0, nmn-1 do objcol(where(modes eq mode_names[q])) = clrs[q]

wset, 1
device, decomposed=0.

for j=0, 1 do begin

if j eq 0 then sf = 'bad data start'
if j eq 1 then sf = 'bad data finish'

opixwin, ow
loadct, /silent, 0
plot,mh.utcstamp, pwr, psym=3, /ynozero, background=bkgrd, xtitle='UTC', ytitle='power', thick=th, xtickf='(I10.10)'
loadct, /silent, coltab
plots, mh.utcstamp, pwr, psym=3, color=objcol, thick=th
legend, mode_names, psym=-3, color=clrs
cpixwin, ow, pw, x1, y1, p1
spixwin, pw

print, 'Choosing a ' + sf + ' point'

wait, wt
print, 'would you like to zoom in?  (L=no, R = yes)'
cursor, x, y, /up
if !mouse.button eq 1 then zoom = 0. else zoom = 1.

while zoom eq 1 do begin

print, 'middle buton to select'
!mouse.button=1.
while (!mouse.button ne 2) do begin
    cursor, x, y, /change
    spixwin, pw
    plots, x, y, psym=1, color=200, thick=1., symsize=2
endwhile

ropixwin, ow, pw, x1, y1, p1
plots, x, y, psym=1, color=200, thick=1., symsize=2
cpixwin, ow, pw, x1, y1, p1
wait, wt
!mouse.button=1.

while (!mouse.button ne 2) do begin
    cursor, xx, yy, /change
    spixwin, pw
    oplot, [x,xx, xx, x, x] , [y,y, yy, yy, y], color=200, thick=1
endwhile

ix = min([x, xx])
ax = max([x, xx])
iy = min([y, yy])
ay = max([y, yy])


opixwin, ow;, pw, x1, y1, p1
loadct, /silent, 0
plot,mh.utcstamp, pwr, psym=3, /ynozero, xra=[ix, ax], yra=[iy, ay], background=bkgrd, xtitle='UTC', ytitle='power', thick=th, xtickf='(I10.10)'
loadct, /silent, coltab
plots, mh.utcstamp, pwr, psym=3, color=objcol, thick=th
legend, mode_names, psym=-3, color=clrs
cpixwin, ow, pw, x1, y1, p1
spixwin, pw
wait, wt
print, 'would you like to zoom in?  (L=no, R = yes)'
cursor, x, y, /up
if !mouse.button eq 1 then zoom = 0. else zoom = 1.

endwhile

print, 'Now select a ' + sf + 'ing point (middle button)'

while (!mouse.button ne 2) do begin
    cursor, xs , ys,/change
    spixwin, pw
    d = min( (xs-mh.utcstamp)^2*225. + (ys - pwr)^2, pos)
    plots, mh[pos].utcstamp, pwr[pos], psym=8, symsize=3, thick=th
endwhile

cuts[j] = pos 
endfor
utcs = mh[cuts].utcstamp
; END PORT
if badbeam eq 7 then for l=0l, 6l do blanks = [[blanks], [utcs[0], utcs[1], l]]
if badbeam ne 7 then blanks = [[blanks], [utcs[0], utcs[1], badbeam]] 
endif
        ;replot the day
        bk = fltarr(7, szp[3])
        sz = size(blanks)
        for q=0, sz[2]-1 do begin
            whb = where((mh.utcstamp le blanks[1, q]) and (mh.utcstamp ge blanks[0, q]), ct)
            if (ct ne 0) then bk(blanks[2, q], whb)= 1.
        endfor
        wset, 0
        !p.multi=0.
        loadct, /silent, 0
    
        plot, mh.ra_halfsec[0]*15., mh.dec_halfsec[0], psym=3, /ynoz, /nodata
        plot, mh.ra_halfsec[0]*15., mh.dec_halfsec[0], psym=3, /ynoz, xra=reverse(!x.crange)
       
        loadct, /silent, coltab
        plots,  mh.ra_halfsec[0]*15., mh.dec_halfsec[0], psym=3, color=255-total(bk,1)*(255-badcl)/7.
        loadct, /silent, 0
        xyouts, 0.7, 0.5, 'scan=' + string(i, f='(I3.3)'), /normal
        wset, 1
        !p.multi=[0,1,7]
        for k=0,6 do begin
            loadct, /silent, 0
            plot, mh.utcstamp, pwrs[k, *]/fct, _EXTRA=_EXTRA, title='BEAM=' + string(k, f='(I1.1)'), /xs, /ynoz , xtickf='(I10.10)'
            loadct, /silent, coltab
            plots, mh.utcstamp, pwrs[k, *]/fct, color=255-bk[k,*]*(255-badcl)
        endfor
        loadct, /silent, 0
        xyouts, 0.7, 0.5, 'scan=' + string(i, f='(I3.3)'), /normal
        !p.multi=0.
        useedit = buttons(['No', 'Yes'], asp=2, title='Do you like this edit?', win=2)
        if useedit eq 1 then begin
            if ((badbeam ne 7) and (edmode ne 0)) then edblanks, blankfile, utcs[0], utcs[1], badbeam else begin
                for l=0, 6 do edblanks, blankfile, utcs[0], utcs[1], l
            endelse
           
        endif
        i=i-1
        endif
        wait, 1
    endfor


end
