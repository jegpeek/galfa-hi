;+
; NAME:
;   EXTRACT_CUBE
;
;
; PURPOSE:
;   To create usefully-sized cubes from the GALFA-HI data set. To use
;   this code, you need a directory full of `survey cubes' and to have
;   run fill_T_all.pro in that directory to produce `cube maps'
;
;
;
; CALLING SEQUENCE:
;  extract_cube, ra, dec, minv, maxv, norw, $
;  ctitle=ctitle, dust=dust, xcs=xcs, ycs=ycs, binv=binv
;  nofits=nofits, nosav=nosav
;
; INPUTS:
;  RA - Right Ascension of the the center of the requested 
;       data cube, in degrees
;  Dec - The Declination of the center of the requested data cube
;        in degrees
;  Minv - The minimum velocity desired in the data cube. Note that for
;         wide data cubes (dv = 0.74 km/s) the available range is
;         -753.4 to 753.4 km/s and for narrow data (dv = 0.18 km/s) 
;          cubes the range is -188.3 to 188.3 km/s. As yet this code 
;          does not access the dec-slice data. 
;  Maxv - The maximum velocity desired in the data cube.
;  norw - 'N' or 'W'? Do you want to use the Narrow data or the
;         Wide data? You must use W if you wish to have
;         velocities beyond the range of the Narrow cubes.  
;
; OPTIONAL INPUTS:
;
;
;
; KEYWORD PARAMETERS:
;    ctitle - the name of the cube you make - e.g. if you set this to
;             'joshiscool' you get a cubes called 'joshiscool.sav' and 
;             'joshiscool.fits'. These specific cube names are
;             recommended. 
;    xcs - pixels in x for the cube (a.k.a. small circle arcminutes in RA)
;    ycs - pixels in y for the cube (a.k.a. arcminutes in dec)
;    binv - the binning factor - e.g. if you have norw set to 'W' and
;           you set binv to 4, you get 0.74 km/s * 4 = 2.96 km/s bins
;    nosav - if set, don't make an evil, corporate .sav file
;    nofits - if set, don't make an unweildy, bloated .fits
;             file. Note that if you set both nosav and nofits you
;             will get nocubes, which will make you nohappy. 
;    dustdir - if set, get the equivalent dust data from the dust
;              IRIS/IRAS data set and save it in the .sav file
;    datadir - if your raw cubes and cube maps (allT.fits and
;              tilenames.sav) aren't in your current directory, set
;              this to the local directory where they live - e.g '/nuala/goldston/allTs/'
;    hdrpath - If set use this path to the header info file, hdr.sav.
; OUTPUTS:
;   delicious, delicious data cubes
;
; MODIFICATION HISTORY:
;   Finally documented by JEG Peek Dec 7 2007
;   added hdrpath JEG Peek May 29 2009
;-

pro extract_cube, ra, dec, minv, maxv, norw, ctitle=ctitle, xcs=xcs, ycs=ycs, binv=binv, nosav=nosav, nofits=nofits, dustdir=dustdir, datadir=datadir, hdrpath=hdrpath

if not keyword_set(datadir) then datadir = './'

; determining the half-size of the cube
if keyword_set(xcs) then hx = ceil(xcs/2.) else hx = 256
if keyword_set(ycs) then hy = ceil(ycs/2.) else hy = 256

;if keyword_set(dust) then df = dust else df = '100'

allT = readfits(datadir + 'allT.fits', hdr0, /silent)
ras = fltarr( 21632, 2432)
decs = fltarr( 21632, 2432)
extast, hdr0, astr
for i=0, 15 do begin
    xx = rebin(reform(findgen(1352)+i*1352., 1352, 1), 1352, 2432)
    yy = rebin(reform(findgen(2432), 1, 2432), 1352, 2432)
    xy2ad, xx, yy, astr, ras0, decs0
    ras[i*1352:1351+i*1352, *] = ras0
    decs[i*1352:1351+i*1352, *] = decs0
endfor
xx=0.
yy=0.
ra0 = ras[*, 0]
dec0 = decs[0, *]

restore, datadir + 'tilenames.sav'

mn = min(abs(ra0-ra), x)
rapt = x
mn = min(abs(dec0-dec), y)
decpt = y

; find region to inspect
time = allT[(x-hx+1) > 0:(x+hx)<21631,(y-hy+1)>0:(y+hy) < 2431]
tx = tilex[(x-hx+1) > 0:(x+hx)<21631,(y-hy+1)>0:(y+hy) < 2431]
ty = tiley[(x-hx+1) > 0:(x+hx)<21631,(y-hy+1)>0:(y+hy) < 2431]
pos = tilepos[(x-hx+1) > 0:(x+hx)<21631,(y-hy+1)>0:(y+hy) < 2431]
raf = ras[(x-hx+1) > 0:(x+hx)<21631,(y-hy+1)>0:(y+hy) < 2431]
decf = decs[(x-hx+1) > 0:(x+hx)<21631,(y-hy+1)>0:(y+hy) < 2431]
sz = size(time)
; get the names of the cubes given the x and y positions in the TOGS grid
name = reform(cname(tx, ty), sz[1], sz[2])

allT = 0.
tilepos=0.
tilex=0.
tiley=0.

ras=0.
decs=0.

; unique names
uname = name(uniq(name, sort(name)))

fname = datadir + uname + '_' + norw + '.fits'

;moved into dust loop
;dname100 = dustdir + '/IRIS' + strmid(uname, 8, 20) + '_100.fits'
;dname060 = dustdir + '/IRIS' + strmid(uname, 8, 20) + '_060.fits'

if norw eq 'W' then vs = (findgen(2048)-1024+0.5)*736.122839600*1d-3 else vs = (findgen(2048)-1024+0.5)*736.122839600*1d-3/4.

mx = min(abs(maxv-vs), v1)
mn = min(abs(minv-vs), v0)
if keyword_set(binv) then vrng = rebin(vs[v0: v0 + ceil(abs(v1-v0+1)/binv)*binv -1], ceil(abs(v1-v0+1)/binv)) else vrng = vs[v0:v1]

if keyword_set(binv) then begin
fcube = fltarr(sz[1], sz[2], ceil(abs(v1-v0+1)/binv))
sz = size(fcube)
for j=0, sz[3]-1 do begin
    loop_bar, j, sz[3]-1
    for k=0, binv-1 do begin
        blank = fltarr(sz[1], sz[2])
        for i=0, n_elements(uname)-1 do begin
            slice = readfits(fname[i], hdr, nslice=v0+j*binv+k, /silent, /noscale)
            blank(where(name eq uname[i])) = slice(pos(where(name eq uname[i])))
        endfor
        fcube[*, *, j] =  fcube[*, *, j] + blank

    endfor
    fcube[*, *, j] = fcube[*, *, j]/binv
endfor

endif else begin
fcube = intarr(sz[1], sz[2], abs(v1-v0+1))
for j=0, abs(v1-v0+1)-1 do begin
    loop_bar, j, abs(v1-v0+1)-1
    blank = intarr(sz[1], sz[2])
    for i=0, n_elements(uname)-1 do begin
        slice = readfits(fname[i], hdr, nslice=v0+j, /silent, /noscale)
        blank(where(name eq uname[i])) = slice(pos(where(name eq uname[i])))
    endfor
    fcube[*, *, j] = blank
endfor
endelse

if keyword_set(dustdir) then begin
dname100 = dustdir + '/IRIS' + strmid(uname, 8, 20) + '_100.fits'
dname060 = dustdir + '/IRIS' + strmid(uname, 8, 20) + '_060.fits'

c100 = fltarr(sz[1], sz[2])
for i=0, n_elements(uname)-1 do begin
    slice = readfits(dname100[i], /silent)
    c100(where(name eq uname[i])) = slice(pos(where(name eq uname[i])))
endfor

c060 = fltarr(sz[1], sz[2])
for i=0, n_elements(uname)-1 do begin
    slice = readfits(dname060[i], /silent)
    c060(where(name eq uname[i])) = slice(pos(where(name eq uname[i])))
endfor
endif

scl = sxpar(hdr, 'BSCALE')
;write the fits file
if not keyword_set(nofits) then begin
if not keyword_set(hdrpath) then restore,  getenv('GSRPATH') + 'savfiles/hdr.sav' else restore, hdrpath + '/hdr.sav'
sxaddpar, hdr, 'NAXIS1', sz[1]
sxaddpar, hdr, 'NAXIS2', sz[2]
sxaddpar, hdr, 'NAXIS3', sz[3]
sxaddpar, hdr, 'OBJECT', 'GALFA-HI RA+DEC Custom ' + strcompress(string(ra), /rem) +' +'+  strcompress(string(dec), /rem)
sxaddpar, hdr, 'CRPIX1', 10816.5 - ((x-hx+1) >0.)
sxaddpar, hdr, 'CRPIX2', 115.5 - ((y-hy+1)>0)
sxaddpar, hdr, 'CRPIX3', 1
sxaddpar, hdr, 'CRVAL3', min(vrng)*1000.
sxaddpar, hdr, 'CDELT3', (vrng[1]-vrng[0])*1000.
sxaddpar, hdr, 'BSCALE', float(scl)

usecut = [-200, 200]            ; K, limits.
;intf = intscl(fcube, bz, bs,cut=usecut, /force)
;intf = fcube

caldat,systime(/julian), month ,day, year       
dt = string(year, f='(I4.4)') + '-' + string(month, f='(I2.2)') + '-' + string(day, f='(I2.2)')


;sxaddpar, hdr, 'BSCALE', bs 
;sxaddpar, hdr, 'BZERO', bz
sxaddpar, hdr, 'DATE', dt, 'Date data cube was created'

if keyword_set(ctitle) then fits_write, ctitle+'.fits', fcube, hdr else fits_write,'SC_' + string(ra0[x], format='(G6.5)')+ '_' + string(dec0[y], format='(G6.5)') + 'fits', fcube, hdr
endif

; write the .sav file
if not keyword_set(nosav) then begin
;    wh = where(fcube eq (-32768.), ct)
;help
;help,/mem
    fcube *= scl
;    if ct ne 0 then fcube[wh] = 0.
   if keyword_set(dustdir) then begin
        if keyword_set(ctitle) then save, fcube, c100, c060, vrng, raf, decf, f=ctitle+ '.sav' else  save, fcube, c100, c060, vrng,  raf, decf,f='SC_' + string(ra0[x], format='(G6.5)')+ '_' + string(dec0[y], format='(G6.5)') + '.sav'
    endif else begin
        if keyword_set(ctitle) then save, fcube, vrng, raf, decf, f=ctitle+ '.sav' else  save, fcube, vrng,  raf, decf,f='SC_' + string(ra0[x], format='(G6.5)')+ '_' + string(dec0[y], format='(G6.5)') + '.sav'
    endelse
endif


end


