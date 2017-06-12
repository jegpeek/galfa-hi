function mxdefine

;+
;PURPOSE:
;	define the data-checker header structure mx
;
;CALLING SEQUENCE: 
;	mx = mxdefine
;INPUTS: none
;
;OUTPUTS: MX
;
;REVISIONS:
;	written oct05 by carlh.
;-

mxx= { $

;------------- added 2005oct6 --------------------------------------
julstamp		:0.d0, $ julian day at beginning of fits 
nindx			:0l  , $ nr datapts included in analysis. <25 means no analysis
ccfwb			:fltarr( 14,14), $ ccf of the wb rcvrs--interchanged cables
ccfnb			:fltarr( 14,14), $ ccf of the nb rcvrs--interchanged cables
acfwb			:fltarr( 128,14), $ acf of the rcvrs to chk for radar
acfnb			:fltarr( 128,14), $ acf of the rcvrs to chk for radar
rmsratiowb		:fltarr( 14), $ rms/mean of rx wb pwrs
rmsrationb		:fltarr( 14), $ rms/mean of rx nb pwrs
feedbadwb		:intarr( 7), $ if systematically 1 for a feed, cables interchanged
feedbadnb		:intarr( 7), $ if systematically 1 for a feed, cables interchanged
rxbadwb			:intarr( 14),$ if systematically 1 for an rx, probably dead
rxbadnb			:intarr( 14),$ if systematically 1 for an rx, probably dead
rxradarwb		:fltarr(2,14), $ radar period and pwr ratio for each rx
rxradarnb		:fltarr(2,14), $ radar period and pwr ratio for each rx
sjuwb			:fltarr(14), $ the ccf of the pwrs with 12 sec pulse train
sjunb			:fltarr(14), $ the ccf of the pwrs with 12 sec pulse train
fitsfilename		:'', $ the name of the fits file
versiondate		:0l         } ; date of revised mh-generated software yyyymmdd


return, mxx
end
