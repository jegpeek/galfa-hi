;+
; Name:
;  WHICHRX
; PURPOSE:
;  A code to tell you which receivers are bad at a given moment.
;
; CALLING SEQUENCE:
;   whichrx,  utc, rxgood, badrxfile=badrxfile
;
; INPUTS:
;  UTC -- the utc second of interest. Usually just the first second in a file,
;         as this should not vary too much in time
;
; KEYWORD PARAMETERS:
;  BADRXFILE -- Any auxilliary file you wish to include
; OUTPUTS:
;  rxgood -- A [2,7] array - 0 for bad, 1 for good
;-

pro whichrx, utc, rxgood, badrxfile=badrxfile

restore, getenv('GSRPATH') + 'savfiles/badrx.sav'
if (keyword_set(badrxfile)) then begin
    badrx2 = badrx
    restore, badrxfile
    badrx = [badrx2, badrx]
endif

rxgood = fltarr(2, 7) + 1.
wh = where((utc le badrx.utcend) and (utc ge badrx.utcstart))
if (wh[0] ne -1) then for i=0, n_elements(wh)-1 do rxgood[ badrx[wh[i]].badpol, badrx[wh[i]].badbeam] = 0.

; NOTE - if both pols are marked bad, this wreaks serious havoc. double_blank.pro should take care of this, so we set a fail-safe below.
;wh = where(total(rxgood, 1) eq 0, ct)
;if ct ne 0 then rxgood[0, wh] = 1.
; THIS SEEMS NOT TO HELP - AM EXCLUDING.

end
