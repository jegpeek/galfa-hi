pro GSSSadxy,gsa,ra,dec,x,y, PRINT = print
;+
; NAME:
;	GSSSADXY
; PURPOSE:
;	Converts RA and DEC (J2000) to (X,Y) for an STScI GuideStar image.   
; EXPLANATION:
;	The sky coordinates may be printed and/or returned in variables.
;
; CALLING SEQEUNCE:
;	GSSSADXY, GSA, Ra,Dec, [ X, Y, /Print ] 

; INPUT:
;	GSA - the GSSS Astrometry structure created by GSSSEXTAST
;	RA  - the RA coordinate(s) in *degrees*, scalar or vector
;	DEC - the DEC coordinate(s) in *degrees*, scalar or vector
;
; OPTIONAL KEYWORD INPUT:
;	PRINT - If this keyword is set and non-zero, then coordinates will be
;		displayed at the terminal
; OUTPUT:
;	X - the corresponding X pixel coordinate(s), double precision
;	Y - the corresponding Y pixel coordinate(s), double precision
;
; EXAMPLE:
;	Given a FITS header, hdr, from the STScI Guidestar Survey, determine
;	the X,Y coordinates of 3C 273 (RA = 12 29 6.7  +02 03 08)
;
;	IDL> GSSSEXTAST, hdr, gsa          ;Extract astrometry structure
;	IDL> GSSSADXY, gsa, ten(12,29,6.7)*15,ten(2,3,8),/print
;
; NOTES:
;	For most purpose users can simply use ADXY, which will call GSSSADXY
;	if it is passed a GSS header.
;
; PROCEDURES CALLED:
;	ASTDISP - Print RA, Dec in standard format
; HISTORY:
;	10-JUL-90 Version 1 written by Eric W. Deutsch
;		Derived from procedures written by Brian McLean
;	Vectorized code   W. Landsman        March, 1991
;	14-AUG-91 Fixed error which caused returned X and Y to be .5 pixels too
;		large.  Now X,Y follows same protocol as ADXY.
;	June 1994 - Dropped PRFLAG parameter, added /PRINT  W. Landsman (HSTX)
;	Converted to IDL V5.0   W. Landsman   September 1997
;-
  On_error,2
  arg = N_params()
  if (arg lt 5) then begin
    print,'Syntax - GSSSADXY, GSSS_Astrom_struct, ra, dec, x, y, print_flag
    print,'e.g.: IDL> GSSSADXY, gsa, ra, dec, x, y, 1
    return
    endif

; Set Constants
  iters = 0 & maxiters=50 & tolerance=0.0000005
  radeg = 180.0d/!DPI  & arcsec_per_radian= 3600.0d*radeg

  dec_rad = dec/radeg & ra_rad = ra/radeg
  pltra = gsa.crval[0]/radeg
  pltdec = gsa.crval[1]/radeg

  cosd = cos(dec_rad) & sind = sin(dec_rad) & ra_dif = ra_rad - pltra

  div = ( sind*sin(pltdec) + cosd*cos(pltdec)*cos(ra_dif))
  xi = cosd*sin(ra_dif)*arcsec_per_radian/div
  eta = ( sind*cos(pltdec)-cosd*sin(pltdec)*cos(ra_dif))*arcsec_per_radian/div

  obx = xi/gsa.pltscl
  oby = eta/gsa.pltscl

  repeat begin
    iters = iters+1

    f= gsa.amdx[0]*obx+			$
       gsa.amdx[1]*oby+			$
       gsa.amdx[2]+			$
       gsa.amdx[3]*obx*obx+		$
       gsa.amdx[4]*obx*oby+		$
       gsa.amdx[5]*oby*oby+		$
       gsa.amdx[6]*(obx*obx+oby*oby)+	$
       gsa.amdx[7]*obx*obx*obx+		$
       gsa.amdx[8]*obx*obx*oby+		$
       gsa.amdx[9]*obx*oby*oby+		$
       gsa.amdx[10]*oby*oby*oby

    fx=gsa.amdx[0]+			$
       gsa.amdx[3]*2.0*obx+		$
       gsa.amdx[4]*oby+			$
       gsa.amdx[6]*2.0*obx+		$
       gsa.amdx[7]*3.0*obx*obx+		$
       gsa.amdx[8]*2.0*obx*oby+		$
       gsa.amdx[9]*oby*oby

    fy=gsa.amdx[1]+			$
       gsa.amdx[4]*obx+			$
       gsa.amdx[5]*2.0*oby+		$
       gsa.amdx[6]*2.0*oby+		$
       gsa.amdx[8]*obx*obx+		$
       gsa.amdx[9]*obx*2.0*oby+		$
       gsa.amdx[10]*3.0*oby*oby

    g= gsa.amdy[0]*oby+			$
       gsa.amdy[1]*obx+			$
       gsa.amdy[2]+			$
       gsa.amdy[3]*oby*oby+		$
       gsa.amdy[4]*oby*obx+		$
       gsa.amdy[5]*obx*obx+		$
       gsa.amdy[6]*(obx*obx+oby*oby)+	$
       gsa.amdy[7]*oby*oby*oby+		$
       gsa.amdy[8]*oby*oby*obx+		$
       gsa.amdy[9]*oby*obx*obx+		$
       gsa.amdy[10]*obx*obx*obx

    gx=gsa.amdy[1]+			$
       gsa.amdy[4]*oby+			$
       gsa.amdy[5]*2.0*obx+		$
       gsa.amdy[6]*2.0*obx+		$
       gsa.amdy[8]*oby*oby+		$
       gsa.amdy[9]*oby*2.0*obx+		$
       gsa.amdy[10]*3.0*obx*obx

    gy=gsa.amdy[0]+			$
       gsa.amdy[3]*2.0*oby+		$
       gsa.amdy[4]*obx+			$
       gsa.amdy[6]*2.0*oby+		$
       gsa.amdy[7]*3.0*oby*oby+		$
       gsa.amdy[8]*2.0*oby*obx+		$
       gsa.amdy[9]*obx*obx

    f = f-xi
    g = g-eta
    deltx = (-f*gy+g*fy) / (fx*gy-fy*gx)
    delty = (-g*fx+f*gx) / (fx*gy-fy*gx)
    obx = obx + deltx
    oby = oby + delty

    endrep until (min([deltx,delty]) lt tolerance) or (iters gt maxiters)

  x = (gsa.ppo3-obx*1000.0)/gsa.xsz-gsa.xll
  y = (gsa.ppo6+oby*1000.0)/gsa.ysz-gsa.yll
  x = x - 0.5 & y = y - 0.5

  if keyword_set(PRINT) then AstDisp, x, y, ra, dec

  return
  end
