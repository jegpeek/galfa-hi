;added NorW code, JEGP May 1, 2011

pro corral, todfile, cnx, cny, dirtycube, fls, NorW;, ampl=ampl

restore, todfile

data = fltarr(n_elements(mht)*7,1)+1.
;print, 'ampp2', arcminperpixel
;st1 = systime(/sec)

cx0 = 4.0 ;degrees
cy0 = 2.35 ;degrees
dcx = 8. ;degrees
dcy = 8. ;degrees

; centers of the final cube of interest
lon0 = cx0+cnx*dcx
lat0 = cy0+cny*dcy

;make the grid
projection = 'CAR'
gridfunc = 'GAUSS'
crvals = [180, 0] 
latpole=90.
imsizex = 512
imsizey = 512
imsize=[512,512]
fwhm=3.35
parm2=fwhm/3.
dmin=2.355*parm2/(2.*sqrt(2.))
arcminperpixel=1.
if (lon0 - arcminperpixel*imsize[0]/2./60.) lt 0 then mht.ra_halfsec = ((mht.ra_halfsec+12-lon0/15.) mod 24) +lon0/15.-12.
;if (lon0 - arcminperpixel*imsize[0]/2./60.) lt 0 then mht.ra_halfsec = ((mht.ra_halfsec+lon0/15.) mod 24) -lon0/15.
if (lon0 + arcminperpixel*imsize[0]/2./60.) gt 360 then mht.ra_halfsec = ((mht.ra_halfsec-lon0/15.-12) mod 24) +lon0/15.+12.

sdgrid, data, unwrap(reform(mht.ra_halfsec, n_elements(mht)*7l)*15., lon0), reform(mht.dec_halfsec, n_elements(mht)*7l),  fwhm, cube, cpp=0., CRVAL=crvals, sparseout=spout, _EXTRA=_extra, crange=[0,0], projection=projection, arcminperpixel=arcminperpixel, imsize=imsize, gridfunc=gridfunc, imcen=[lon0, lat0], latpole=latpole

allsecs = floor(spout.col/7l)
usecs = allsecs(uniq(allsecs, sort(allsecs)))
allfiles = (mht.fn)[usecs]
wuf = uniq(allfiles, sort(allfiles))
ufiles = allfiles[wuf]

extract_coords, dirtycube, a, d, v, org_cube, /fill


if (lon0 - arcminperpixel*imsize[0]/2./60.) lt 0 then a = ((a+lon0+180) mod 360) -lon0-180.
if (lon0 + arcminperpixel*imsize[0]/2./60.) gt 360 then a = ((a-lon0-180.) mod 360) +lon0+180.


for i=0, n_elements(ufiles)-1 do begin
    loop_bar, i, n_elements(ufiles)-1
    restore, ufiles[i]
    if (lon0 - arcminperpixel*imsize[0]/2./60.) lt 0 then mh.ra_halfsec = ((mh.ra_halfsec+12-lon0/15.) mod 24) +lon0/15.-12.
;    if (lon0 - arcminperpixel*imsize[0]/2./60.) lt 0 then mh.ra_halfsec = ((mh.ra_halfsec+lon0/15.) mod 24) -lon0/15.
    if (lon0 + arcminperpixel*imsize[0]/2./60.) gt 360 then mh.ra_halfsec = ((mh.ra_halfsec-lon0/15.-12) mod 24) +lon0/15.+12.
    sheepdog, org_cube, a, d, mh,spbox;, ampl=ampl
    save, spbox, f= ufiles[i] + '.SL_'+ NorW+'.sav'
endfor

fls = ufiles + '.SL_'+ NorW+'.sav'

end
