;+
; NAME:
; T1
;
;
; PURPOSE:
;  To inspect final cubes alongside their generating data to determine the
;  origin of glitches
;
; CALLING SEQUENCE:
;  t1, fn, todarr, day, beam, second, file
;
; INPUTS:
;  fn -- The name of a survey cube to inspect, (e.g., 
;  'GALFA_HI_RA+DEC_148.00+10.35_W.fits')
;  todarr -- The name of the time-ordered data array file from todarr.pro
;          or the array itself
; OUTPUTS:
;  day -- The day of the selected second
;  beam -- The beam of the selected second
;  second -- The UTC second of the selected second
;  file -- The name of the file in which the selected second in located
;
; MODIFICATION HISTORY:
;  Documented Nov 17th, 2008, JEGP
;-

pro t1, fn, todarr, slrange=slrange, day, beam, second, file, blfile=blfile

circle
window, 0, xsi=800, ysi=800
if keyword_set(slrange) then begin
fits = fltarr(512, 512, slrange[1]-slrange[0]+1)
    for i=slrange[0], slrange[1] do begin
        slice = readfits(fn, hdr, nslice=i)
        fits[*, *, i-slrange[0]] = slice
    endfor 
endif else begin
    fits = readfits(fn, hdr)
endelse
wh = where(fits lt -100, ct)
if ct ne 0 then fits[wh] = 0.
xs = sxpar(hdr, 'naxis1')
ys = sxpar(hdr, 'naxis2')
window, 0, xsi=(xs+300) < 1500, ysi=(ys+300) < 1000
xx = rebin(reform(findgen(xs), xs, 1), xs, ys)
yy = rebin(reform(findgen(ys), 1, ys), xs, ys)
extast, hdr, astr
xy2ad, xx, yy, astr, a, d

;vrng = (findgen(2048)-1023.5)*astr.cdelt[2]*1d-3

; find where the todarr is in the cube
if n_elements(todarr) eq 1 then restore, todarr else mht = todarr
whc = where( (mht.ra_halfsec[0] lt max(a/15.)) and (mht.ra_halfsec[0] gt min(a/15.)) and(mht.dec_halfsec[0] gt min(d)) and (mht.dec_halfsec[0] lt max(d)))

mhtwhc = mht[whc]

if keyword_set(blfile) then whblanks, blfile, mhtwhc, flag else flag = fltarr((size(mhtwhc))[1], 7)

cruise, fits, v1, ra0=reform(a[*, 0]), dec0=reform(d[0, *])
cruise, fits, v2, ra0=reform(a[*, 0]), dec0=reform(d[0, *])

if floor(v1) eq floor(v2) then img = reform(fits[*, *, v1]) else img = total(fits[*, *, v1 < v2:v2 > v1 ], 3)

opixwin, ow

display, img, reform(a[*, 0]), reform(d[0, *]) ,  aspect=xs/ys

cpixwin, ow, pw, x1, y1, p1

spixwin, pw
!mouse.button = 1
th=4
deci = 10
while (!mouse.button ne 2) do begin
    cursor, x, y, /change
    print, x, y
    spixwin, pw
    d = min( (x-mhtwhc.ra_halfsec*15.)^2. + (y - mhtwhc.dec_halfsec)^2, pos)
    day = mhtwhc[pos/7.].day
    beam = pos mod 7
    whday = where(mhtwhc.day eq day)
    nwd = n_elements(whday)
    wpl = findgen(nwd/deci)*deci
    for j=0, 6 do begin
        plots, mhtwhc[whday[wpl]].ra_halfsec[j]*15., mhtwhc[whday[wpl]].dec_halfsec[j], psym=3, color=200.-flag[whday[wpl], j]*100.
    endfor
    plots, mhtwhc[whday].ra_halfsec[beam]*15., mhtwhc[whday].dec_halfsec[beam], psym=3
    plots, mhtwhc[pos/7.].ra_halfsec[beam]*15., mhtwhc[pos/7.].dec_halfsec[beam], psym=8, symsize=3


    xyouts, 0.1, 0.2, 'day: ' + string(day, f='(I3.3)'), /normal
    xyouts, 0.1, 0.1, 'second: ' + string(mhtwhc[pos/7.].utcstamp, f='(I10.10)'), /normal
    xyouts, 0.1, 0.15, 'beam: ' + string(beam, f='(I1.1)'), /normal
endwhile

second = mhtwhc[pos/7.].utcstamp
file = mhtwhc[pos/7.].fn

end
