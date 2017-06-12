;+
; NAME:
;   atbound2
; PURPOSE:
;   routine to bound coords like astrotools v5_6 does
; CALLING SEQUENCE:
;   atbound2, ra,dec
; INPUTS:
;   ra      Eq. 2000 coords (deg) (or mu,nu or lambda,eta)
;   dec
; OUTPUTS:
;   ra      Bounded version
;   dec     
; BUGS:
;   Location of the survey center is hard-wired, not read from astrotools.
; REVISION HISTORY:
;   2002-Feb-20  written by Blanton (NYU)
;-
pro atbound2, dec, ra

atbound,dec,-180.D,180.D
lindx=where(abs(dec) gt 90.D,lcount)
if(lcount gt 0) then begin
    dec[lindx]=(180.D)-dec[lindx]
    ra[lindx]=ra[lindx]+180.D
endif

atbound,dec,-180.D,180.D
atbound,ra,0.D,360.D
pindx=where(abs(dec) eq 90.D,pcount)
if(pcount gt 0) then ra[pindx]=0.D

end
