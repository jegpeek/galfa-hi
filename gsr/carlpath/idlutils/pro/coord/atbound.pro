;+
; NAME:
;   atbound
; PURPOSE:
;   routine to bound coords in the way astrotools v5_6 does
; CALLING SEQUENCE:
;   atbound, coord, lower, upper
; INPUTS:
;   coord   - coordinate
;   lower   - lower limit to bound by (using 360. periodicity)
;   upper   - upper limit
; OUTPUTS:
; BUGS:
;   Location of the survey center is hard-wired, not read from astrotools.
; REVISION HISTORY:
;   2002-Feb-21  written by Blanton (NYU)
;-
pro atbound, coord, lower, upper

offcoord=((coord-lower) mod (upper-lower))
lzindx=where(offcoord lt 0.D,lzcount)
if(lzcount gt 0.) then offcoord[lzindx]=offcoord[lzindx]+(upper-lower)
coord=lower+offcoord

end
