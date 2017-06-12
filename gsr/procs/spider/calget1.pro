function calget1,rfnum,calnum,freq,calval,date=date,hybrid=hybrid,$
            fname=fname,swappol=swappol, stage1=stage1
;
; return the cal value for this freq
; retstat: -1 error, ge 0 ok
;
;+
;NAME:
;calget1 - return the cal value given rcvr,frq,type.
;
;THIS IS CARL'S VERSION AND WORKS ONLY FOR ALFA.
;
;IMPORTRANT NOTE: WE HAD NO DATA FOR RX 4 SO WE SCALE ITS VALUES BY 1.036,
;	WHICH IS ABOUT SQRT OF THE FACTOR 1.075 REQUIRED TO GET AGREEMENT
;	WITH LDS. 
;
;
;SYNTAX: stat=calget1(rcvrNum,caltype,freq,calval,date=date,hybrid=hybrid, 
;                     fname=fname,swappol=swappol) 
;
;ARGS:
;     rcvrNum: int receiver number must be 17, this is for ALFA only.
;     calType: int type of cal used 0 through 7. must be 1 for alfa.
;     freq: float  freq in Mhz for cal value.
;
;OPTIONAL INPUTS:
;	FNAME, filename where the coefficients are stored. default is
;		getenv('GSRPROCDATAPATH') + 'bgplot_coeffs_tcal.sav'
;	STAGE1, SET IT for the stage1 calibration, which sets the cal
;equal to ostensible values at 1420 MHz. these are the ones that reproduce
;the LDS values (but multiplied by 0.9 to account for eta_local)--see
;GALFA tech memo 2004-02.
;
;RETURNS:
;calval[2,7]: float .. calValues in deg K for polA,polB and 7 rx's
;     stat: int   .. -1 error, 0 got the values ok.
;
;EXAMPLES:
;   Get the cal values for lbw (rcvrNum=5) using the high correlated cal 
;(caltype=1) at 1400. Mhz.
;   stat=calget1(5,1,1400.,calval)
;
;HISTORY: MODIFIED ON 24DEC2004 TO MATCH LDS SCALING (FACTOR 1.075) AND ALSO
;	TO FIX RCVR 4 TO JOSH'S VALUE AT 1420.
;	LATER ON THAT DAY, CHANGED FACTOR TO 1.036...
;	on 29 dec, changed factor to 1./1.025...
;-

stop, 'STOPPING: THIS PROGRAM NEEDS WORK AND IS INCORRECTD IN ITS PRESENT FORM'


if n_elements( fname) eq 0 then $
	fname= getenv('GSRPROCDATAPATH') + 'bgplot_coeffs_tcal.sav'

IF (RFNUM NE 17) THEN BEGIN
	print, 'THIS IS SPECIAL PROC FOR ALFA...YOU MUST USE RX 17...STOPPING!!'
	STOP
ENDIF

;stage1 = 1


;for stage 2, SKIP THE MANUALLY-ENTERED NUMBERS, WHICH ARE THE ORIGINALS 
;FROM JOSH...
if keyword_set( stage1) eq 0 then GOTO, SKIPJOSH

;THE FOLLOWING NUMBERS ARE JOSH'S, i.e. the web nrs scaled by his 
;relative rx-to-rx factors so that all HI temps are identical.
;they are NOT scaled to match LDS survey.
;as of 29 dec 04, to match LDS survey times 0.9, divide these by 1.025...
calval= $
[      11.0284  ,    10.3584,$
      10.0682  ,    10.8272,$
      11.5114  ,    10.4338,$
      10.8789  ,    9.79722,$
      10.3517  ,    10.6766,$
      9.88044  ,    10.3148,$
      10.6574  ,    10.5607]

calval= reform( calval, 2, 7)
calval= calval/1.025


SKIPJOSH:
;THE FOLLOWING USES COEFFS DETERINED BY BGPLOT.IDL...
restore, fname

degree= ( size( coeffs_tcal))[ 1]- 1
calval= fltarr( 2,7)

;DO THE POLYNOMIAL CORRECTION...
for nrd= 0, degree do calval= calval+ coeffs_tcal[ nrd,*,*]* ( freq- 1420.)^nrd 

;SPECIAL FIX FOR RX 4...as of 29dec04, we only had 1420 MHz values...
calval[ *,4]= [      10.3517  ,    10.6766]/ 1.025

return, 1

end
