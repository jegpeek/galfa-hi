;+
; NAME:
;  EXTRACT_COORDS
;
; PURPOSE:
;  To extract position and velocity information, as well as data, from a GALFA fits cube.
;
;
; CATEGORY:
;
;
;
; CALLING SEQUENCE:
;    extract_coords, fn, a, d, v, data
;
;
; INPUTS:
;   fn - string of the filename with full path
;
; OPTIONAL INPUTS:
;
; KEYWORD PARAMETERS:
;
; OUTPUTS:
;  a - the value of ra in an [n, m] array.  
;  d - the value of dec in an [n, m] array.  
;  v - the velocty in an array [l]
;  data - the full datacube in [n,m,l]
; OPTIONAL OUTPUTS:
;
;
;
; COMMON BLOCKS:
;
;
;
; SIDE EFFECTS:
;
;
;
; RESTRICTIONS:
;
;
;
; PROCEDURE:
;
;
;
; EXAMPLE:
;
;
;
; MODIFICATION HISTORY:
;  built and documented by JEG Peek, Sept 2006
;  added keyword fill by JEG Peek Sept 2014
;-

pro extract_coords, fn, a, d, v, data, fill=fill

data= readfits(fn, hdr,/noscale)
sz = size(data)
bscale=sxpar(hdr, 'BSCALE')
bzero=sxpar(hdr, 'BZERO')

; if we have missing data, assume it is the median of all the other data by slice, if fill is set
if keyword_set(fill) then begin
	for i=0, sz[3]-1 do begin
		slice = data[*, *, i]
		wh = where(slice eq sxpar(hdr, 'BLANK'),  ctwh,complement=compl)
		if ctwh ne 0 then begin
			slice[wh] = median(slice[compl])
			data[*, *, i] = slice
		endif		
	endfor
endif

data=float(bscale)*temporary(data)+float(bzero)
extast,hdr,astr

xmax = sz[1]
ymax = sz[2]
zmax = sz[3]
x= findgen( xmax)
y= findgen( ymax)
xx= intarr( xmax, ymax)
yy= intarr( xmax, ymax)
for ny= 0, ymax-1 do xx[ *,ny]= x
for nx= 0, xmax-1 do yy[ nx,*]= y
xy2ad, xx, yy, astr, a, d
crval3 = sxpar(hdr, 'CRVAL3')
cdelt3 = sxpar(hdr, 'CDELT3')
crpix3 = sxpar(hdr, 'CRPIX3')

v = ((findgen(zmax)- crpix3+1)*cdelt3+crval3)/1000.  

end
