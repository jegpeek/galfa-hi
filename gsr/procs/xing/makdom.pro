pro makdom, ralist, mdst, time=time

;+
; NAME:
;  MAKDOM
; PURPOSE:
;  To genearte domain structue, called mdst, that defines the domains
;  over which to input RAs exist. This is a standardaized format for BW
;  reduction.
; CALLING SEQUENCE:
;  makdom, ralist, mdst
; INPUTS:
;  ralist -- An RA, or list of RAs, in decimal house, to establish the
;            domain structure
; KEYWORD PARAMETERS
;  time -- If this is set it is assumed that we are interested in time, not RA
; OUTPUTS
;  mdst -- A special structure that defines a region in RA (time) space
;
; MODIFICATION HISTORY
;
;  Initial documentation October 17, 2005
;  JE Goldston, goldston@astro.berkeley.edu
;-

if max(ralist) - min(ralist) gt 12 then begin
    fixlist = ralist
    fixlist(where(ralist gt 12)) = fixlist(where(ralist gt 12)) - 24
    ctr = (max(fixlist)+min(fixlist))/2.
    rng = (max(fixlist)-min(fixlist))/2.
    cyc=1.
endif
if max(ralist)-min(ralist) le 12 then begin
    fixlist = ralist
    ctr = (max(fixlist)+min(fixlist))/2.
    rng = (max(fixlist)-min(fixlist))/2.
    cyc = 0.
endif

if keyword_set(time) then begin
    ctr = mean(ralist)
    rnf = mean(ralist) - min(ralist)
    cyc=0.
endif


mdst = {ctr:ctr, rng:rng,cyc:cyc}

end
