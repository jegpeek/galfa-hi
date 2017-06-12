; pts is in RA, Dec
; data in [nchan, 7,nsec]
; mh in [7, nsec] 
pro hilite_pts, mh, data, pts

sz = size(data)
npts = N_elements(pts)/2.
for i=0, npts-1 do begin
    ddegsqrd = min( ((mh.ra_halfsec - pts[i, 0])*15)^2 + ((mh.dec_halfsec - pts[i, 1]))^2, x)
    ddeg = sqrt(ddegsqrd)
    print, ddegsqrd
    if ddeg lt 2./60. then begin
        data[x*sz[1] + findgen(sz[1])] = 1e6
        print, 'point!'
endif
endfor

end
