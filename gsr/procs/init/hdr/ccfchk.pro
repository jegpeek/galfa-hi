pro ccfchk, nindx, ccf, feedbad

;+
;NAME:
;ccfchk -- examine the ccf (really structure fcn) to make sure
;rx cables are not interchanged.
;
;CALLING SEQUENCE:
;ccfchk, nindx, ccf, feedbad
;
;INPUT PARAMETERS:
;NINDX, the nr of records used by rxdiagnostics.pro. if lt 25, can it.
;CCF, the ccf (really a structure fcn)
;
;OUTPUT PARAMTERS:
;FEEDBAD, an integer array of 7 elements, one for each feed. a 1 indicates
;a possible problem.
;
;-

feedbad= intarr( 7)

IF (NINDX LT 25) THEN RETURN

ccfmod= ccf

diags= indgen(14)* 15
ccfmod[diags]=1e6

for nrfd=0,6 do begin
column= ccfmod[ 2*nrfd,*]
minim= min( column, indxminim)
if ( indxminim ne 2*nrfd+1) then feedbad[ nrfd]=1
endfor

return

end
