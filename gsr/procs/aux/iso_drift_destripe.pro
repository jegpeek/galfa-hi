; a code for destriping drift data of isolated objects, such as HVCs and galaxies
; this only works on cubes where pixels increasing in x have a fixed dec.

pro iso_drift_destripe, cc, ct
; load a color table
loadct, ct
; get the integrated column
col = total(cc, 3)
; size of the data cube
sz = size(cc)
; open a window the size of the image
window, 0, xsi=sz[1], ysi=sz[2]
; show the total data
tvscl, col
; choose edges
print, 'select the far left of a region with no objects in it'
cursor, x0, y, /device
plot, [x, x], [0, sz[2]]

print, 'select the far right of a region with no objects in it'
cursor, x1, y, /device
plot, [x1, x1], [0, sz[2]]


print, 'select the far left of another region with no objects in it'
cursor, x2, y, /device
plot, [x2, x2], [0, sz[2]]


print, 'select the far right of another region with no objects in it'
cursor, x3, y, /device
plot, [x3, x3], [0, sz[2]]

regA = total(cc[x0:x1, *, *], 1)
regB = total(cc[x2:x3, *, *], 1)
reg = (regA + regB)/(x1-x0+1 + x3-x2+1)

cc = cc - reform(rebin(reg, 1, sz[2], sz[3]), sz[1], sz[2], sz[3])

end





