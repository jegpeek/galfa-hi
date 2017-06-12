; The purpose of this script is to remove the stray radiation from the first sidelobes in the GALFA-HI final data cubes. In the interests of simplicity this is not a general code to remove ALFS sidelobes from HI maps, but rather designed specifically for GALFA-HI 512x512, 1-arcminute cubes. 

; KNOWN ISSUES:
;  - It doens't deal with things where the beam ellipticity isn't along dec (angle is off by ~7 deg)
;  - There can be some fluctuation around 180, depending upon whether you are in the N or S sky (This may just
;    be correct, as observations don't tend to rotate the feed 180 degrees depending on which region of sky
;    they are in...)


function find_alfa_angle, mht

bm_a = 0.
bm_b = 1.

ra_a = mht.ra_halfsec[bm_a]
ra_b = mht.ra_halfsec[bm_b]

; Fix any crossing RA=0/360
wh = where(abs(ra_a-ra_b) gt 1., ct)
;print, ct
if ct gt 0 then begin
    for i=0, ct-1 do begin
        if (ra_a[wh[i]] - ra_b[wh[i]]) gt 0 then begin
            ra_b[wh[i]] = ra_b[wh[i]] + 24.
        endif else begin
;        if (ra_a[wh[i]] - ra_b[wh[i]]) lt 0 then 
            ra_b[wh[i]] = ra_b[wh[i]] - 24.
        endelse
    endfor
endif

;plot, ra_a-ra_b
rslt = cv_coord(/degrees, from_rect=transpose([[(-1)*(ra_a-ra_b)*15.*cos(mht.dec_halfsec[0]*!pi/180.)], [(mht.dec_halfsec[bm_a]- mht.dec_halfsec[bm_b])/1.167]]), /to_polar)

return, rslt[0, *]-60.

end

; ##### NOTES #####
; As M33 is the poster child for stray radiation correction, I've downloaded the todarr.sav file
; that corresponds to the togsplus (fall) region that contains M33. I have also downloaded one of the final cubes that contains
; a part of M33 with the worst ripples in the the edges. The hope is we'll be able to check for sign changes and such by 
; applying the correction to the cube and 

;  scube - the survey cube to correct. Designed for _W and _N cubes, not 
;          slices
;  todfile - the time-ordered data file used to create the cube. 


; THIS IS CARL'S VERSION OF THE CLEANING CODE, WHERE THE CLEANING IS DONE IN THE TOD DOMAIN...
pro sheepdog, org_cube,a, d, mht,spbox;, ampl=ampl

;first we need to determine the rotation angle of ALFA as a function of time. We could do this by looking at the original mh files, but it is realtively simple to determine it from the RAs and decs of the various beams

;extract_coords, dirtycube, a, d, v, org_cube
mmra = minmax(a)
mmdec = minmax(d)

; haven't dealt with RA=0 problems here yet...
if (mmra[1] - mmra[0]) gt 100 then print, 'We may have some problems with wrap-around at RA=0'

;restore, todfile

; 0.2 degrees is for the next beam over from the center (0.1 degrees) and its sidelobe (~0.1 degrees)
;wh = where((mht.ra_halfsec[0]*15. gt (mmra[0]-0.2)) and (mht.ra_halfsec[0]*15. lt (mmra[1]+0.2)) and (mht.dec_halfsec[0] gt (mmdec[0]-0.2)) and (mht.dec_halfsec[0] lt (mmdec[1]+0.2)))

mhc = mht;[wh]

angle = find_alfa_angle(mhc)

; how do we best go about getting kernals for each of the beams, given that they can rotate?
; we need to bin by angle and by some range in cos(dec) and build a set of beams for each of these regions.
; we can then use a finite number of beams shapes to reconstruct the sidelobe contribution.
; for now let's just bin in angle and use the mean dec as the overall beamshape
; eh, we don't need to do this - it's cheap to make new beams.

; main beam effciency:
eta =  [0.875729, 0.764944,0.743301,0.742042,0.764944,0.769971,0.770685]
;if keyword_set(ampl) then eta[1:6] = 1/((1+ampl)*((1-eta[1:6])/eta[1:6])+1)
scl = (1.-eta)/eta

; average dec
meandec = mean(mhc.dec_halfsec[0])
n_tot = n_elements(mhc)
n_sec = n_tot
; write a clean cube

; do a loop over some finite number of seconds.
;inc_size=1000.
;q = 0
;while (q lt n_tot) do begin
;qmax = (q + inc_size -1) < (n_tot - 1)



spbox = fltarr(2048, n_sec, 7)

for i=0, n_sec-1 do begin
;    loop_bar, i, n_sec-1
    for j=0, 6 do begin
        
       ; find a region of the sky around the point
        a0 = interpol(findgen(512), a[*, 0], mhc[i].ra_halfsec[j]*15.+0.15) > 0.
        a1 = interpol(findgen(512), a[*, 0], mhc[i].ra_halfsec[j]*15.-0.15) < 511.
        d0 = interpol(findgen(512), d[0, *], mhc[i].dec_halfsec[j]-0.15) > 0.
        d1 = interpol(findgen(512), d[0, *], mhc[i].dec_halfsec[j]+0.15) < 511.
   
        if ((a0 gt 510) or (a1 lt 1) or (d0 gt 510) or (d1 lt 1) or (total(finite([a0, a1, d0, d1])) ne 4)) then continue
   
        a_prox = a[a0:a1,d0:d1]
        d_prox = d[a0:a1,d0:d1]
   
        sz = size(a_prox)
   
        galfabeam_reconstruct, j, bp, (a_prox-mhc[i].ra_halfsec[j]*15.)*cos(meandec*!pi/180.)*60., (d_prox-mhc[i].dec_halfsec[j])*60., tb, mb, sl, /noreform, rotang=angle[i]+180        
   
        data_slice = org_cube[a0:a1,d0:d1, 1024]
        
        whno = where(data_slice lt -20000, ct)
        if ct ne 0 then sl[whno] = 0.
        if ct ne 0 then tb[whno] = 0.
   
    ;    sl_prsm = rebin(reform(sl, sz[1], sz[2], 1), sz[1], sz[2], 2048)
   
   ;     pt_prsm = data[a0:a1,d0:d1, *]
; I think this is the correct way to scale the spectra, given eqn 12. of hartmann et al.
; This is the step that takes the vast bulk of the time, but I think 
; it is unavoidable. If we need to speed up this code, this step is the way to do it.
; NOTE OF HACK
; If you divide by eta, you need to _also_ do it in the 
; original cube step, so you have the correct thing to subtract from. It's not 
; clear whether you should make both a normal (no eta) cube to sample these data from (T_a) and 
; some kind of eta-balanced cube as well to subtract the eta-balanced data from. But 
; that's too sophisticated for this zeroeth order model. Here we assume that all of the 
; beams have the same eta, which is of course most wrong for beam zero. this
; will have the effect of over-subtracting the ring around beam zero, but that should be a pretty
; subtle effect.
        
; Turns out, that's not a subtle effect at all! It's totally noticable, 
; to the extent that you can't get a good deconvolution without it!
; So, we need to divide by eta and by the total effiency to get the 
; right scaling.
        
; Note that this won't work too well near the edges, (as mb will 
; not really be the whole beam) but not much will  anyway, so to hell with it.
        if keyword_set(etaset) then scale_factor = total(mb) else scale_factor = total(sl)
; THIS A SPEED BOOOST, about 2x faster than the commented out line.
        sp=dblarr(2048)
        sclnorm=scl[j]/total(sl)
        for loopvar=0,2047 do begin
            sp[loopvar]=total(sl*org_cube[a0:a1,d0:d1,loopvar])*sclnorm
        endfor
   ;     sp = total(total(rebin(reform(sl, sz[1], sz[2], 1), sz[1], sz[2], 2048)*org_cube[a0:a1,d0:d1, *], 1), 1)/total(sl)*scl[j]
        spbox[*, i, j] = sp
        endfor
endfor

;make the grid
;lat0=34.35
;lon0=20.
;projection = 'CAR'
;gridfunc = 'GAUSS'
;crvals = [180, 0] 
;latpole=90.
;imsizex = 512
;imsizey = 512
;imsize=[512,512]
;fwhm=3.35
;parm2=fwhm/3.
;dmin=2.355*parm2/(2.*sqrt(2.))
;arcminperpixel=1.
;tp_sp = reform(transpose(spbox, [2, 1, 0]), 7*n_sec, 2048)

;sdgrid, tp_sp, reform(mhc[q:q+n_sec-1].ra_halfsec, n_sec*7l)*15., reform(mhc[q:q+n_sec-1].dec_halfsec, n_sec*7l), fwhm, cube, crval=crvals,  /nonormalize, weight=weight, projection=projection, arcminperpixel=arcminperpixel, imsize=imsize, gridfunc=gridfunc, imcen=[lon0, lat0], latpole=latpole, nodata=0.

;nf = n_elements(where(finite(cube) eq 0, ct)) 
;if ct ne 0 then cube[where(finite(cube) eq 0.)] = 0. 

;if q eq 0. then begin
;    cubesav = cube
;    weightsav = weight
;    cube=0.
;endif
;if q ne 0. then begin
;    cubesav = temporary(cube)+temporary(cubesav)
;    weightsav = weight + weightsav
;    cube=0.
;endif

;q = qmax +1

;endwhile

;spp = weightsav
;invw = 1./weightsav
;szw = size(weightsav)
;feqz = where(finite(invw) eq 0., ct)
;if ct ne 0 then invw(feqz) = 0.
;cubesav = cubesav*reform(rebin(invw, szw[1], szw[2], 2048.))

;if keyword_set(outfile) then save, cubesav, f=outfile else save, cubesav, f='/share/galfa/togsplus/test1.sav'
;stop

end
