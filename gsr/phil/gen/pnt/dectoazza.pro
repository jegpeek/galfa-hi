;+
;NAME:
;decToAzZa - convert from dec to az,za for a strip.
;
;SYNTAX: decToAzZa,dec,az,za,step=step
;
;ARGS:
;   dec[3,npts] : declination,degrees,minutes,seconds
;
;KEYWORDS:
;           step: float. seconds per step   
;
;RETURNS:
;   az[npts]    : encoder azimuth angle in degrees. 
;   za[npts]    : encoder zenith  angle in degrees. 
;
;DESCRIPTION:
;   Convert from declination to azimuth, zenith angle for a 
;complete decstrip across the arecibo dish (latitude 18:21:14.2).
;The points will be spaced step sidereal seconds in time. The routine
;computes the track for +/- 2 hours and then limits the output points
;to zenith angle <= 19.69 degrees.
;-
pro decToAzZa,dec,az,za,step=step
    if n_elements(step) eq 0 then begin
        step=1.                 ; 1 sec step size
    endif
    latRd= (18. + 21./60. + 14.2/3600.)/360. * 2.*!pi
    th=latRd - !pi/2.
    costh=cos(th)
    sinth=sin(th)
;
; generate ha vector once a step +/- 2 hours
;
    npts  =long(2.* (2.*3600./step) + 1.)
    haRd  = step*(findgen(npts) - npts/2L) /(3600.*24) * 2.*!pi
    decRd =  (dec[0] + dec[1]/60. + dec[2]/3600.)*!dtor
    azElV=fltarr(3,npts)
;
;   convert ha,dec to 3 vector
;
    haDec=fltarr(3,npts)
    cosDec=cos(decRd)
    haDec[0,*]= cos(haRd)*cosDec
    haDec[1,*]= sin(haRd)*cosDec
    haDec[2,*]= fltarr(npts) + sin(decRd)
;
;   rotate to az,el
;
    azElV[0,*]=  -(costh*haDec[0,*])                  -(sinth * haDec[2,*])
    azElV[1,*]=                      -haDec[1,*]                 
    azElV[2,*]=  -(sinth*haDec[0,*])                  +(costh * haDec[2,*])
;
; now convert back to angles 
;
   c1Rad=atan(reform(azElV[1,*]),reform(azElV[0,*])); /* atan y/x */
;
;   azimuth convert from source to encoder (at dome)
    az=c1Rad* !radeg - 180.     ;
    ind=where( az lt 0.,count)
    if count gt 0 then begin
        az=az + 360.
    endif
    ind=where( az le 90.,count)
    if count gt 0 then begin
        az[ind]=az[ind] + 360.
    endif
    za=90. - !radeg*asin(azElV[2,*]) ;
    ind=where(za lt 19.69)
    az=az[ind]
    za=za[ind]
    return;
end
