function intscl, cube, bzero, bscale, cut=cut, force=force
mm = minmax(cube)
if keyword_set(cut) then begin
    mm[0] = mm[0] > cut[0]
    mm[1] = mm[1] < cut[1]
endif
if keyword_set(force) then mm = cut
bscale = (mm[1]-mm[0])/65534.0
bzero = (mm[1]+mm[0])/2.0
; so that phys val  =  int x factor + min
return, fix(( ((cube > mm[0]) < mm[1]) - mm[0])/(mm[1]-mm[0])*65534. -32767)

end



