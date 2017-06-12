pro srcprops, srcname, freq, ra, dec, flux

;+
;purpose
;given a srcname, and freq in MHz, 
;use phil's routine to get ra (hr), dec (deg) (2000 equinox) and flux
;
;this is just a wrapper: phil's routine gives 1950 positions.
;-

flux= fluxsrc( srcname, freq, radec=radec)

IF (FLUX NE 0.) THEN BEGIN
ra= 15.d*radec[ 0]
dec= radec[1]
precess, ra, dec, 1950., 2000.
ra= ra/ 15.d
ENDIF ELSE BEGIN
ra=0.
dec=0.
ENDELSE

return
end
