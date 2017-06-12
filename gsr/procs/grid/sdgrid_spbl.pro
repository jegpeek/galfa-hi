; A wrapper for sdgrid that can deal with blanked voxels
; Note that weights are returned as a 3D array, rather than 2D, for obvious reasons.

pro sdgrid_spbl, blanksp, data, lon, lat, fwhm, cube, crval=crval, nonormalize=nonormalize, weight=weight, projection=projection, arcminperpixel=arcminperpixel, imsize=imsize, gridfunc=gridfunc, imcen=imcen, latpole=latpole, threedweight=threedweight, _REF_EXTRA=_extra
     

wt1 = 1     
; are there any blanked data at all?

sz = size(data)

if total(blanksp) ne 0 then begin

; keep looking until we have ranged over all channels
done = 0
matched = 1
mask = fltarr(sz[1])
whum= where(mask eq 0, ct)
; into the same format as data
;tbsp = reform(blanksp, sz[1], sz[2])

weightall = fltarr(imsize[0], imsize[1], sz[2])
cubeall = fltarr(imsize[0], imsize[1], sz[2])
while ct ne 0 do begin
	; find the first element not yet covered
	mask[whum[0]] = 1.
	; make a new group of seconds to include this one and all like it
	whgp = whum[0]
	; which data to include in this cube, spectrall
	whchan = where(blanksp[whum[0], *] eq 0, whchct)
	for i=1, ct-1 do begin
		; are you the same as the first element?
		mask[whum[i]] = (total(blanksp[whum[0], *] eq blanksp[whum[i], *])/float(sz[2])) eq 1
		; slow, but I am too lazy to implement a linked list...
		if mask[whum[i]] eq 1 then whgp = [whgp, whum[i]]
	endfor
	; cut on seconds that match
	subdata = data[whgp, *]
	; cut on channels:
	if whchct ne 0 then begin
		subdata = subdata[*, whchan]
		sdgrid, subdata, lon[whgp], lat[whgp], fwhm, cube, crval=crval, nonormalize=nonormalize,  projection=projection, arcminperpixel=arcminperpixel, imsize=imsize, gridfunc=gridfunc, imcen=imcen, latpole=latpole, weight=wt1, _REF_EXTRA=_extra, nodata=0., /quiet
		;stop
		weightall[*, *, whchan] = weightall[*, *, whchan] + rebin(reform(wt1, imsize[0], imsize[1], 1),imsize[0], imsize[1], n_elements(whchan))
		cubeall[*, *, whchan] = cubeall[*, *, whchan] + temporary(cube)
		wt1=1
	endif	
	whum= where(mask eq 0, ct)
endwhile

cube = temporary(cubeall)
weight = temporary(weightall)
;stop
endif else begin
	wt1 = 1
	sdgrid, data, lon, lat, fwhm, cube, crval=crval, nonormalize=nonormalize, weight=wt1, projection=projection, arcminperpixel=arcminperpixel, imsize=imsize, gridfunc=gridfunc, imcen=imcen, latpole=latpole,  _REF_EXTRA=_extra, nodata=0., /quiet
    weight = rebin(reform(wt1, imsize[0], imsize[1], 1),imsize[0], imsize[1], sz[2])

endelse
;
;if total( minmax(total(weight[*, *, 0:4095], 3)-total(weight[*, *, 4096:*], 3)) ) ne 0 then threedweight = 1 else threedweight = 0
end