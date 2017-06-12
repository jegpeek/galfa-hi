FUNCTION WRITE_FITS_CUBE, outname, image, geo, grid, imsizex, $
  imsizey,refra, refdec, chan, observer, vel, restfreq, beam, hdronly=hdronly, truecart=truecart, lb=lb, nan=nan

; Purpose: to write a FITS file with lots of info for the header. 
;--------- GETTING INFO FOR FITS HEADER: ---------
; Central RA and Dec position:
CRVAL1=refra ; degrees
CRVAL2=refdec ; degrees
if keyword_set(truecart) then begin
crval1 = 180.
crval2 = 0.
endif
nstart=chan[0]
nch=chan[1]
nend=nstart+nch-1

; Reference pixels:
; Remember: FITS uses idices from 1 to N, not from 0 to N-1!!!!
; I have arbitrarily changed hte CRPIX postion without changing the
; CRVAL, thus moving where we think the pixels are - I am not sure if this is correct.
; Need to check with Tim R. 
CRPIX1=imsizex/2+0.5
CRPIX2=imsizey/2+0.5
CDELT1=double((-grid/60.)) ;in degrees
CDELT2=double((grid/60.))
if keyword_set(truecart) then begin
crpix1 = imsizex/2+0.5-(refra-180.)/cdelt1
crpix2 = imsizey/2+0.5-refdec/cdelt2
endif
;CDELT1=double((-grid/60.)) ;in degrees
;CDELT2=double((grid/60.))
; 3 fixed by Josh in confusion!
CDELT3=vel(1)-vel(0)
CRPIX3=1
CRVAL3=vel[0]
if keyword_set(lb) then begin
if (geo eq 'ncp') then begin       
    CTYPE1='GLON-NCP'
    CTYPE2='GLAT-NCP'
endif else if (geo eq 'sin') then begin
    CTYPE1='GLON-SIN'
    CTYPE2='GLAT-SIN'
endif else if (geo eq 'tan') then begin
    CTYPE1='GLON-TAN'
    CTYPE2='GLAT-TAN'
endif else if (geo eq 'car') then begin
    CTYPE1='GLON-CAR'
    CTYPE2='GLAT-CAR'
endif else if (geo eq 'sfl') then begin
    CTYPE1='GLON-SFL'
    CTYPE2='GLAT-SFL'
endif else MESSAGE,'Wrong cooridinate system specified.'
endif else begin
if (geo eq 'ncp') then begin       
    CTYPE1='RA---NCP'
    CTYPE2='DEC--NCP'
endif else if (geo eq 'sin') then begin
    CTYPE1='RA---SIN'
    CTYPE2='DEC--SIN'
endif else if (geo eq 'tan') then begin
    CTYPE1='RA---TAN'
    CTYPE2='DEC--TAN'
endif else if (geo eq 'car') then begin
    CTYPE1='RA---CAR'
    CTYPE2='DEC--CAR'
endif else if (geo eq 'sfl') then begin
    CTYPE1='RA---SFL'
    CTYPE2='DEC--SFL'
endif else MESSAGE,'Wrong cooridinate system specified.'
endelse 
; Writing FITS file with a minimalistic header:
mkhdr, hdr, image

; Need parameters!
sxaddpar, hdr, 'BUNIT', 'K'
sxaddpar, hdr, 'BZERO', 0
sxaddpar, hdr, 'BITPIX',-32 
sxaddpar, hdr, 'BSCALE', 1
;sxaddpar, hdr, 'DATAMIN', max(data, min=mindata)
;sxaddpar, hdr, 'DATAMAX', mindata
;sxaddpar, hdr, 'OBJECT', srcname
sxaddpar, hdr, 'EQUINOX', 2000.0
sxaddpar, hdr, 'TELESCOP', 'Arecibo 305-m'
sxaddpar, hdr, 'INSTRUME', 'ALFA'
sxaddpar, hdr, 'OBSERVER', observer
sxaddpar, hdr, 'CTYPE1', CTYPE1
;sxaddpar, hdr, 'CUNIT1', 'deg' 
sxaddpar, hdr, 'CRVAL1', CRVAL1
sxaddpar, hdr, 'CRPIX1', CRPIX1
sxaddpar, hdr, 'CROTA1', 0
sxaddpar, hdr, 'CDELT1', CDELT1
sxaddpar, hdr, 'CTYPE2', CTYPE2
;sxaddpar, hdr, 'CUNIT2', 'deg' 
sxaddpar, hdr, 'CRVAL2', CRVAL2
sxaddpar, hdr, 'CRPIX2', CRPIX2
sxaddpar, hdr, 'CROTA2', 0
sxaddpar, hdr, 'CDELT2', CDELT2
sxaddpar, hdr, 'CTYPE3', 'VELO-LSR'
;sxaddpar, hdr, 'CUNIT3', 'km/s' 
sxaddpar, hdr, 'CRVAL3', CRVAL3*1000.
sxaddpar, hdr, 'CRPIX3', CRPIX3
sxaddpar, hdr, 'CROTA3', 0
sxaddpar, hdr, 'CDELT3', CDELT3*1000.
sxaddpar, hdr, 'BMIN', beam/60.
sxaddpar, hdr, 'BMAJ', beam/60.
sxaddpar, hdr, 'RESTFREQ', restfreq*1e6
if not keyword_set(hdronly) then begin
    if keyword_set(nan) then begin
        img = total(image, 3)
        wh = where(img eq 0, ct)
        mask = fltarr(imsizex, imsizey)
        if ct ne 0 then mask[wh] = 1.
        rb = rebin(reform(mask, imsizex, imsizey, 1), imsizex, imsizey, n_elements(vel))
        outimage = image
        if ct ne 0 then outimage(where(rb eq 1)) = -1000
        writefits, outname, outimage, hdr, nanvalue=-1000
    endif else begin
        writefits, outname, image, hdr
    endelse
endif

return, hdr
end
