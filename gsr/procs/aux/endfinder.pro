;+
; NAME:
;   ENDFINDER
;
;
; PURPOSE:
;  To determine reasonable start and end points to feed to stg0
;
;
; CALLING SEQUENCE:
;  endfinder, year, month, day, proj, root, lsts, mhdir=mhdir
;
; INPUTS:
;  year -- the integer year of the scan
;  month -- the integer month of the scan
;  day -- the integer day of the scan
;  proj -- the project name (e.g. 'a2187')
;  root -- just for finding the mh files ('/share/galfa/')
;  
;
; OPTIONAL INPUTS:
;
;
; KEYWORD PARAMETERS:
;  mhdir -- a specified mh directory, typically '/share/galfa/galfamh/'
;           mht -- an output structure in the form of the concatenated mh files. optional.
;                  th -- the thickness of the points - try 2 to 4 for better readibility
;      wt -- the wait time between clicks - default is 0.5 (secs)
;      ct -- the color table to use. default is 13
;   xsize -- specify the width of the window, in pixels
;   ysize -- specify the height of the window, in pixels
; OUTPUTS:
;  lsts -- the start and end lsts in a two-element array
;
; MODIFICATION HISTORY:
;   Written and documented by JEG Peek Feb 19 2007
;   Color table keyword added by JEG Peek June 17, 2008
;-


pro endfinder, year, month, day, proj, root, lsts, mhdir=mhdir, mht=mht, th=th, wt=wt, ct=ct, xsize=xsize, ysize=ysize

if not keyword_set(wt) then wt = 0.5
if not keyword_set(ct) then ct = 13

device, decomposed=0.
window, 0, xsize=xsize, ysize=ysize
cuts = fltarr(2)
if (not keyword_set(mhdir)) then mhdir = root + '/' + proj + '/mh/'
circle
print, 'searching for files (this will take a few seconds)'

fns = file_search(mhdir, '*' + string(year, f='(I4.4)') + string(month, f='(I2.2)') + string(day, f='(I2.2)') +  '*' + proj + '*.mh.sav')

nf = n_elements(fns)
restore, fns[0]
mht = mh
print, 'reading positions'
for i=0, nf -2 do begin
    loop_bar, i, nf-1
    restore, fns[i+1]
    mht = [mht, mh]
endfor

modes = mht.obsmode
mode_names = modes(uniq(modes, sort(modes)))
nmn = n_elements(mode_names)
clrs = findgen(nmn)/(nmn-1)*200 + 55
objcol = fltarr(n_elements(mht))

for i=0, nmn-1 do objcol(where(modes eq mode_names[i])) = clrs[i]


for j=0, 1 do begin

if j eq 0 then sf = 'start'
if j eq 1 then sf = 'finish'

opixwin, ow
loadct, 0, /silent
plot, mht.ra_halfsec[0], mht.dec_halfsec[0], psym=3, /ynozero, background=128, xtitle='RA', ytitle='Dec', thick=th
loadct, ct, /silent
plots,  mht.ra_halfsec[0], mht.dec_halfsec[0], psym=3, color=objcol, thick=th
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
loadct, 0, /silent
plot, mht.ra_halfsec[0], mht.dec_halfsec[0], psym=3, /ynozero, xra=[ix, ax], yra=[iy, ay], background=128, xtitle='RA', ytitle='Dec', thick=th
loadct, ct, /silent
plots,  mht.ra_halfsec[0], mht.dec_halfsec[0], psym=3, color=objcol, thick=th
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
    d = min( (xs-mht.ra_halfsec[0])^2*225. + (ys - mht.dec_halfsec[0])^2, pos)
    plots, mht[pos].ra_halfsec[0], mht[pos].dec_halfsec[0], psym=8, symsize=3, thick=th
endwhile

cuts[j] = pos 
endfor

lsts = mht[cuts].lst_meanstamp

end



