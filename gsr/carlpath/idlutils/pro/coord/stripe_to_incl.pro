;+
; NAME:
;   stripe_to_incl
; PURPOSE:
;   given a stripe number, produce the inclination for the great circle; 
;   hardwired to what astrotools v5_6 does
; CALLING SEQUENCE:
;   stripe_to_incl, eta, stripe
; INPUTS:
;   stripe   Survey Stripe
; OUTPUTS:
;   incl     Inlination of the great circle (deg)
; BUGS:
;   Location of the survey center is hard-wired, not read from astrotools.
; REVISION HISTORY:
;   2002-Feb-20  written by Blanton (NYU)
;-
pro stripe_to_incl,stripe,incl

dec_center=32.5D

stripe_to_eta,stripe,etacenter
incl=etacenter+dec_center

end

