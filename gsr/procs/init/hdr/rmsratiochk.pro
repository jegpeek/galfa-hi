pro rmsratiochk, nindx, rmsratio, rxbad

;+
;chk rcvrs for ratio of rms to mean.
;return 0 for each rx if no problem.
; inputs: rmsratio
; outputs: rxbad
;-

rxbad= intarr( 14)

IF (NINDX LT 25) THEN RETURN

rmsmedian= median( rmsratio)
rr= rmsratio/rmsmedian

indxrr= where ( rr gt 2. or rr lt .5, countrr)
if countrr ne 0 then rxbad[ indxrr]= 1

return

ccfmod= ccf
ccfmod[ indgen( 14)*15]= 0.

maxi= fltarr( 14)
ndxmaxi= intarr( 14)

for nr=0,13 do begin
maxi[ nr]= max( ccfmod[ nr,*], indxmaxi)
ndxmaxi[ nr]= indxmaxi
endfor

ndxmaxi= reform( ndxmaxi, 2, 7)
maxi= reform( maxi, 2, 7)

feedbad00= where( maxi[0,*] ne maxi[ 1,*], count00)
feedbad11= where( (ndxmaxi[ 0,*] -1) ne ndxmaxi[ 1,*], count11)

feedbad0=  intarr( 7)
feedbad1=  intarr( 7)

if count00 ne 0 then feedbad0[ feedbad00] = 1
if count11 ne 0 then feedbad1[ feedbad11] = 1

return

end
