function mrd_structtemp
return, $
replicate({ $
 DATA:lonarr(7679)$
,CRVAL1:0.d0$
,CDELT1:0.d0$
,CRPIX1:0.d0$
,CRVAL2A:0.d0$
,CRVAL3A:0.d0$
,CRVAL2B:0.d0$
,CRVAL3B:0.d0$
,CRVAL4:0.d0$
,BANDWID:0.d0$
,RESTFREQ:0.d0$
,FRONTEND:string(replicate(32b,8))$
,IFVAL:0B$
,ALFA_ANG:0.d0$
,OBSMODE:string(replicate(32b,8))$
,OBS_NAME:string(replicate(32b,8))$
,OBJECT:string(replicate(32b,16))$
,EQUINOX:0.d0$
,G_WIDE:lonarr(512)$
,G_ERR:0$
,G_SEQ:0$
,G_BEAM:0B$
,G_WSHIFT:0B$
,G_NSHIFT:0B$
,G_WPFB:0$
,G_NPFB:0$
,G_MIX:0.d0$
,G_EXT:0.d0$
,G_ADC:0.d0$
,G_WCENTER:0.d0$
,G_WBAND:0.d0$
,G_WDELT:0.d0$
,G_DAC:0B$
,G_TIME:lonarr(2)$
,G_LO1:0.d0$
,G_LO2:0.d0$
,G_POSTM:0.d0$
,G_AZZATM:0.d0$
}$
,8400)
end
