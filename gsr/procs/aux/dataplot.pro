;+
; NAME:
; DATAPLOT
;
; PURPOSE:
;  Plot all TOD on an RA/Dec grid
;
; CALLING SEQUENCE:
;   dataplot, root, region, scans, proj, name, thin=thin, _EXTRA=ex
;
; INPUTS:
;   root -- The main directory in which the project directory
;             resides (e.g. '/dzd4/heiles/gsrdata/' )
;   region -- The name of the source as entered into BW_fm (e.g. 'lwa')
;   scans -- Number of days the project consists of
;   proj -- The Arecibo project code (e.g. 'a2050')
;   
;
; KEYWORD PARAMETERS:
;   thin -- if you have a big data set, set this keyword to thin out the plotted
;           data bya factor of thin. (i.e. thin = 10 plots one in ten data points)
;
; OUTPUTS:
;   plots.
;
; MODIFICATION HISTORY:
;   Written by Josh Goldston Peek June 4, 2006
;-


pro dataplot, root, region, scans, proj, name, thin=thin, _EXTRA=ex

if (not(keyword_set(thin))) then thin = 1

path = root + proj + '/' + region + '/'

restore, path + 'todarr.sav';, /ver

wh = findgen(n_elements(mht)/thin)*thin

plot, mht[wh].ra_halfsec[0], mht[wh].dec_halfsec[0], _EXTRA=ex, psym=3, /ynozero


end
