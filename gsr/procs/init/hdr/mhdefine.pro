function mhdefine, m1

;+
;PURPOSE:
;	define the enhanced header structure mh
;
;CALLING SEQUENCE: 
;	mh = mhdefine( m1)
;INPUTS: M1
;
;OUTPUTS: MH
;
;REVISIONS:
;	written oct04 by carlh.
;-

mhh= { $
errs		: intarr(6,2,7) , $    ; decoded errors
utcstamp   	:  0l , $	;utc since 1971 in sec. long integral sec
julstamp		:  0.d , $	;julday aat utcstamp
lst_meanstamp	:  0.d , $	;meanlst at utcstamp, hr
lst_appstamp		:  0.d , $	;app lst at utcstamp, hr

az_halfsec		:  0.d , $	;az at utcstamp + .5sec, deg
za_halfsec		:  0.d , $	;za at utcstamp + .5sec, deg
ra_halfsec		:dblarr(7) , $	;ra of the 7 beams at utcstamp + .5sec, hr
dec_halfsec		:dblarr(7) , $	;dec of the 7 beams at utcstamp + .5sec, hr
vlsr			:fltarr(7),  $  ;vel of telescope towards src wrt lsr
vbary			:fltarr(7), $  ;vel of telescope towards src wrt bary
pwr_wb			:fltarr(2,7), $ avg of 512 wideband channels
pwr_nb			:fltarr(2,7), $ avg of 512 narrowband channels

;------------- added 2005oct6 --------------------------------------
fitsfilename		:''	, $ name of the fits file
versiondate		:0l         , $ date of revised mh-generated software yyyymmdd

;---------below are copies of what is in original m1 files--------
CRVAL1      :	m1[0].CRVAL1		, $
CDELT1      :	m1[0].CDELT1		, $
CRPIX1      :	m1[0].CRPIX1		, $
CRVAL2A     :	m1[0].CRVAL2A		, $
CRVAL3A     :	m1[0].CRVAL3A		, $
CRVAL2B     :	m1[0].CRVAL2B		, $
CRVAL3B     :	m1[0].CRVAL3B		, $
;;;;;CRVAL4      :	m1[0].CRVAL4		, $
BANDWID     :	m1[0].BANDWID		, $
RESTFREQ    :	m1[0].RESTFREQ		, $
FRONTEND    :	m1[0].FRONTEND		, $
;;;;;IFVAL       :	m1[0].IFVAL		, $
ALFA_ANG    :	m1[0].ALFA_ANG		, $
OBSMODE     :	'DATAMISS'		, $
OBS_NAME    :   'DATAMISS'		, $
OBJECT      :   'DATAMISS'		, $
EQUINOX     :	m1[0].EQUINOX		, $
;;;;;G_ERR       :	m1[*,*,0].G_ERR       		, $
G_SEQ       :	m1[0].G_SEQ       		, $
;;;;;G_BEAM      :	m1[0].G_BEAM      		, $
G_WSHIFT    :	m1[0].G_WSHIFT    		, $
G_NSHIFT    :	m1[0].G_NSHIFT    		, $
G_WPFB      :	m1[0].G_WPFB      		, $
G_NPFB      :	m1[0].G_NPFB      		, $
G_MIX       :	m1[0].G_MIX       		, $
G_EXT       :	m1[0].G_EXT       		, $
G_ADC       :	m1[0].G_ADC       		, $
G_WCENTER   :	m1[0].G_WCENTER   		, $
G_WBAND     :	m1[0].G_WBAND     		, $
G_WDELT     :	m1[0].G_WDELT     		, $
G_DAC       :	m1[*,*,0].G_DAC       		, $
G_TIME      :	m1[0].G_TIME      		, $
G_LO1       :	m1[0].G_LO1       		, $
G_LO2       :	m1[0].G_LO2       		, $
G_POSTM     :	m1[0].G_POSTM     		, $
G_AZZATM    :	m1[0].G_AZZATM    		}


return, mhh
end
