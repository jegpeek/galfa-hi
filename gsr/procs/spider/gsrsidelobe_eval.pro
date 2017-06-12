pro gsrsidelobe_eval, nterms, fhgt, fcen, fhpbw, az, za, sidelobe, $
	noreform=noreform, noconvol=noconvol, rotangle=rotangle

;+
;
;PURPOSE: evaluate the sidelobes at an arbitrary set of az, za given the
;Fourier coefficients describing hgt, cen, and wid.
;
;CALLING SEQUENCE:
;SIDELOBE_EVAL, nterms, fhgt, fcen, fhpbw, az, za, sidelobe
;
;INPUTS:
;
;	NTERMS, the number of terms to use in evaluating the inverse
;FFT. For our application ALFA, we use NTERMS=8 and delete unwanted
;terms by setting them equal to zero).
;
;	FHGT, FCEN, FWID, the set of complex Fourier coefficients for
;the height, center, and width of the Gaussians that describe the
;sidelobes.
;
;	AZ,ZA: the position at which to evaluate the sidelobes. Units
;are ARCMIN. These can be arrays, but must be identical in form.
;
;KEYWORDS:
;	NOREFORM. if NOT set, reforms the output to a 60 by 60 array.
;NORMALLY, SET THIS KEYWORD!!	
;
;	NOCONVOL: if NOT set, it returns the convolution of the beam
;pattern. If it IS set, it reeturns the actual beam pattern on the sky.
;these differ by a reflection about the origin (equivalent to a rotation
;by 180 deg)
;
;OPTIONAL INPUTS:
;
;	ROTANGLE, the ALFA array rotation anglein DEGREES. Default is zero.
;
;************************ CAUTION ********************************
;
;	As of 20 dec 2004 ROTANGLE has not been tested.
;
;
;	Moreover, its effects are recommended, not measured.  See GALFA
;technical memo 2004-01. 
;
;*****************************************************************
;
;OUTPUT:	
;
;	SIDELOBE, the amplitude of the sidelobe.
;
;NOTE ON UNITS FOR THE WIDTH: The input width is in in units of HPBW. In
;the evaluation, we use 1/e widths, which is why we multiply by 0.6...
;
;-

radius= sqrt( az^2 + za^2)
angle = atan( za, az)

if keyword_set( rotangle) then angle= angle+ !dtor*rotangle

if keyword_set( noconvol) then angle= angle+ !pi

hgt= dfteval( nterms, fhgt, angle)
cen= dfteval( nterms, fcen, angle)
wid= 0.6005612* dfteval( nterms, fhpbw, angle)

sidelobe= hgt* exp( -((radius-cen)/wid)^2)

if keyword_set( noreform) eq 0 then sidelobe= reform( sidelobe, 60, 60)

return
end
