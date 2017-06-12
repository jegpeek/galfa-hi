function mwb_hdr, mh, m1

;+
;PURPOSE:
;	generate a header structure that contains MH and, also, $
;the 512 chnl wb spectra
;
;CALLING SEQUENCE:
;	mwb= mwb_hdr( mh, m1)
;
;INPUTS 
;	MH, the original condensed header
;	M1, the original data header
;
;RETURNS
;	MW = MW.MH and MW.G_WIDE
;
;REVISION HISTORY:
;	oct04 by carlh
;
;-

timeoffset= 2ll^31ll
IF (M1[0].G_TIME[0] GT 0) THEN BEGIN
timeoffset= 0l
ENDIF


mwb= { mh : mh[0] , $
	g_wide : fltarr( 512, 2, 7) }

mw= replicate( mwb, n_elements( mh))

mw.mh= mh
mw.g_wide= m1.g_wide + timeoffset

return, mw

end
