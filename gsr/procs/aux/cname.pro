; output the base name of a data cube, given its TOGS coordiantes
; compatible with scube.pro naming scheme

function cname, cnx, cny

cx0 = 4.0 ;degrees
cy0 = 2.35 ;degrees
dcx = 8. ;degrees
dcy = 8. ;degrees

; centers of the final cube of interest
cx = cx0+cnx*dcx
cy = cy0+cny*dcy
name = 'GALFA_HI_RA+DEC_' + string(cx, f='(I3.3)') + '.00+' +  string(cy, f='(I2.2)') + '.35'
return, name

end
