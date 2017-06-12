function locdom, mdst, ras, time=time

;+
; NAME:
;  LOCDOM
; PURPOSE:
;   To return a normalized value for the location of an array of
;   RAs in a given range, as defined by an input structure.
;
; CALLING SEQUENCE:
;   result = locdom(mdst, ras)
; INPUTS:
;  mdst -- A special structure that defines a region in RA space. See
;          MAKDOM
;  ras -- An RA, or list of RAs, in decimal hours, to convert to a 
;         normalized position or array of normalized postions
;
; KEYWORD PARAMETERS:
;  time -- If this is set it is assumed that we are interested in time, not RA
; 
; OUTPUTS:
;  An (array of) normalized position(s).
;
; MODIFICATION HISTORY
;
;  Initial documentation Ocotober 17, 2005
;  Joshua E. Goldston, goldston@astro.berkeley.edu
;-

if keyword_set(time) then return, (ras - mdst.ctr)/mdst.rng else return, (ras - (ras gt 12)*24*mdst.cyc - mdst.ctr)/(mdst.rng)

end
