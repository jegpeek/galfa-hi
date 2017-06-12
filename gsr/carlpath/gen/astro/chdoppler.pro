function chdoppler, ra, dec, julday, $
	obspos_deg=obspos_deg, path=path, light=light, nlat=nlat, wlong=wlong

;+
; NAME: chdoppler
;       
; PURPOSE: 
;       computes the projected velocity of the telescope wrt 
;       four coordinate systems: geo, helio, bary, lsr.
;	negative velocities mean approach
;
;       the standard LSR is defined as follows: the sun moves at 20.0 km/s
;       toward ra=18.0h, dec=30.0 deg in 1900 epoch coords
;
; CALLING SEQUENCE:
;        result = chdoppler( ra, dec, julday, obspos_deg=obspos_deg, path=path, light=light)
;
; INPUTS: fully vectorized...
;       ra[n] - the source ra in decimal hours, equinox 2000
;       dec[n] - the source dec in decimal degrees, equinox 2000
;	julday[n] - the julian day
;
; KEYWORDS:
;	/obspos_deg: observatory [lat, wlong] in degrees. default is arecibo.
;	/path - path for the station file. obspos_deg takes precedence.
;       /light - returns the velocity as a fraction of c
;	/nlat, /wlong - specify nlat and wlong of obs in degrees.
;if you set one, you must set the other also.
;
; NOTE:
;	if path is not specified, default long, lat are arecibo. if
;path is specified, it reads long, lat from the file
;		path + .station
;
; OUTPUTS: 
;       program returns the velocity in km/s, or as a faction of c if
;       the keyword /light is specified. the result is a 4-element
;	vector whose elements are [geo, helio, bary, lsr]. quick
;	comparison with phil's C doppler routines gives agreement to 
;	better than 100 m/s one arbitrary case.
;
; REVISION HISTORY: carlh 29oct04. 
;	from idoppler_ch; changed calculation epoch to 2000
;	19nov04: correct bad earth spin calculation
;	7 jun 2005: vectorize to make faster for quantity calculations.
;-

;------------------ORBITAL SECTION-------------------------
nin= n_elements( ra)

;GET THE COMPONENTS OF RA AND DEC, 2000u EPOCH
rasource=ra*15.*!dtor
decsource=dec*!dtor

xxsource = fltarr( 3, nin)
xxsource[0, *] = cos(decsource) * cos(rasource)
xxsource[1, *] = cos(decsource) * sin(rasource)
xxsource[2, *] = sin(decsource)
pvorbit_helio= dblarr( nin)
pvorbit_bary= dblarr( nin)
pvlsr= dblarr( nin)

;GET THE EARTH VELOCITY WRT THE SUN CENTER
;THEN MULTIPLY BY SSSOURCE TO GET $
;	PROJECTED VELOCITY OF EARTH CENTER WRT SUN TO THE SOURCE
FOR NR=0, NIN-1 DO BEGIN
baryvel, julday[nr], 2000.,vvorbit,velb
pvorbit_helio[ nr]= total(vvorbit* xxsource[ *,nr])
pvorbit_bary[ nr]= total(velb* xxsource[ *,nr])
ENDFOR

;stop

;-----------------------LSR SECTION-------------------------
;THE STANDARD LSR IS DEFINED AS FOLLOWS: THE SUN MOVES AT 20.0 KM/S
;TOWARD RA=18.0H, DEC=30.0 DEG IN 1900 EPOCH COORDS
;using PRECESS, this works out to ra=18.063955 dec=30.004661 in 2000 coords.
ralsr_rad= 2.*!pi*18./24.
declsr_rad= !dtor*30.
precess, ralsr_rad, declsr_rad, 1900., 2000.,/radian

;FIND THE COMPONENTS OF THE VELOCITY OF THE SUN WRT THE LSR FRAME 
xxlsr = fltarr( 3, nin)
xxlsr[ 0, *] = cos(declsr_rad) * cos(ralsr_rad)
xxlsr[ 1, *] = cos(declsr_rad) * sin(ralsr_rad)
xxlsr[ 2, *] = sin(declsr_rad)
vvlsr = 20.*xxlsr

;PROJECTED VELOCITY OF THE SUN WRT LSR TO THE SOURCE
for nr=0, nin-1 do pvlsr[ nr]=total(vvlsr*xxsource[ *, nr])

;---------------------EARTH SPIN SECTION------------------------
;NOTE: THE ORIGINAL VERSION WAS FLAWED. WE comment out those bad statements...

;ARECIBO COORDS...
lat= 18.3539444444d
long= 15.d* (4.D +  27.d/60.d + .720D/3600.D)
obspos_deg= [lat, long]

;COORDS FROM .STATION FILE...
IF KEYWORD_SET( PATH) THEN BEGIN
	station,lat,long, path=path
	obspos_deg= [ lat, long]
ENDIF 

;COORDS FROM NLAT, WLONG INPUT...
if n_elements( nlat) ne 0  then obspos_deg= [nlat, wlong]

;GET THE LATITUDE...
lat= obspos_deg[0]

if (n_elements( obspos_deg) ne 0) then $
   lst_mean= 24./(2.*!pi)* chjuldaytolmst( julday, obspos_deg=obspos_deg) $
else lst_mean= 24./(2.*!pi)* chjuldaytolmst( julday)

;MODIFIED EARTH SPIN FROM GREEN PAGE 270
pvspin= -0.465* cos( !dtor* lat) * cos( decsource) * $
	sin(( lst_mean- ra)* 15.* !dtor)

;stop

;---------------------NOW PUT IT ALL TOGETHER------------------

vtotal= fltarr( 4, nin)
vtotal[ 0,*]= -pvspin
vtotal[ 1,*]= -pvspin- pvorbit_helio
vtotal[ 2,*]= -pvspin- pvorbit_bary
vtotal[ 3,*]= -pvspin- pvorbit_bary- pvlsr

if keyword_set(light) then vtotal=vtotal/(2.99792458e5)

;print, pvorbit, pvspin, vtotal, keyword_set( geo), keyword_set( helio)

;stop

return,vtotal
end






