;+
; NAME:
;   stripe_to_eta
; PURPOSE:
;   find the central eta value for a stripe; hardwired to what astrotools 
;   v5_6 does
; CALLING SEQUENCE:
;   stripe_to_eta, stripe, eta
; INPUTS:
;   stripe   Survey Stripe #
; OUTPUTS:
;   eta      Central value of eta (survey lat) in deg
; BUGS:
;   Location of the survey center is hard-wired, not read from astrotools.
; REVISION HISTORY:
;   2002-Feb-20  written by Blanton (NYU)
;-
pro stripe_to_eta,stripe,eta

stripe_separation=2.5D
if(n_elements(stripe) eq 1) then begin
  if(stripe le 46) then begin
    eta=stripe*stripe_separation-(57.5D)
  endif else begin
    eta=stripe*stripe_separation-(57.5D)-(180.D)
  endelse
endif else begin
  nindx=where(stripe le 46,ncount)
  sindx=where(stripe gt 46,scount)
	eta=dblarr(n_elements(stripe))
	if(ncount gt 0) then eta[nindx]=stripe[nindx]*stripe_separation-(57.5D)
	if(scount gt 0) then eta[sindx]=stripe[sindx]*stripe_separation-(57.5D) $
	   -(180.D)
endelse

end

