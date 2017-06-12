;+
; NAME:
;  UNWRAP
;
;
; PURPOSE:
;  To reformat a latitude dimension centered at a position to minimize discontinuity.
;
;
; CALLING SEQUENCE:
;  result = UNWRAP(lons, [lon0])
;
;
; INPUTS:
;  lons - a list of longitudes in degrees [0, 360), to unwrap
;
; OPTIONAL INPUTS:
;  lon0 - the center point around which to unwrap. If not set then assumed to be mean(lons)
;
; OUTPUTS:
;  result - unwrapped longitudes in degrees
;
; MODIFICATION HISTORY:
;  Conceived by Louis Desroches and Josh Peek. Written by Josh Peek, 5/2/7
;-

function unwrap, lons, lon0

if n_elements(lon0) eq 0 then lon0 = mean(lons)

return, (lons - (lon0 - 180) + 360) mod 360 +lon0 -180

end

