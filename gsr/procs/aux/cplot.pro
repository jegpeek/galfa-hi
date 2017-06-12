; output the base name of a data cube, given its TOGS coordiantes
; compatible with scube.pro naming scheme

pro cplot, cnx, cny, _EXTRA=_EXTRA, hrs=hrs

cx0 = 4.0 ;degrees
cy0 = 2.35 ;degrees
dcx = 8. ;degrees
dcy = 8. ;degrees

; centers of the final cube of interest
cx = cx0+cnx*dcx
cy = cy0+cny*dcy
; distance from center to edge
off = 512./60./2.
if keyword_set(hrs) then conv = 15. else conv=1.

oplot, [cx+off, cx+off, cx-off, cx-off, cx+off]/conv, [cy+off, cy-off, cy-off,cy+off, cy+off], _EXTRA=_EXTRA


end
