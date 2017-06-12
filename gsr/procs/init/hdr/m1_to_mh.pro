pro m1_to_mh, m1, mh

;+
;PURPOSE:
;	extract the hdr tags of interest from the original data
;structure M1 and insert them into the condensed header MH.
;
;CALLING SEQWUENCE
;	m1_to_mh, m1, mh
;
;INPUTS:
;	M1, the original data structure
;
;OUTPUTS:
;	MH, various tags of interest
;
;HISTORY:
;	written oct04 by carlh. modified incrementally as tags of 
;M1 are incrementally added 
;	09NOV04, check tag names OBS_NAME and OBJECT; carlh
;-

mh.CRVAL1      =       reform( m1[0,0,*].CRVAL1)
mh.CDELT1      =       reform( m1[0,0,*].CDELT1            )
mh.CRPIX1      =       reform( m1[0,0,*].CRPIX1            )
mh.CRVAL2A     =       reform( m1[0,0,*].CRVAL2A           )
mh.CRVAL3A     =       reform( m1[0,0,*].CRVAL3A           )
mh.CRVAL2B     =       reform( m1[0,0,*].CRVAL2B           )
mh.CRVAL3B     =       reform( m1[0,0,*].CRVAL3B           )
;;;;;mh.CRVAL4      =       reform( m1[0,0,*].CRVAL4            )
mh.BANDWID     =       reform( m1[0,0,*].BANDWID           )
mh.RESTFREQ    =       reform( m1[0,0,*].RESTFREQ          )
mh.FRONTEND    =       reform( m1[0,0,*].FRONTEND          )
;;;;;mh.IFVAL       =       m1.IFVAL             
mh.ALFA_ANG    =       reform( m1[0,0,*].ALFA_ANG          )
mh.OBSMODE     =       reform( m1[0,0,*].OBSMODE           )

;check tag names of m1 to see if present...
tst= tag_names( m1)
indx= where( tst eq 'OBS_NAME', count)
if (count ne 0) then $
mh.OBS_NAME    =       reform( m1[0,0,*].OBS_NAME	)

indx= where( tst eq 'OBJECT', count)
if (count ne 0) then $
mh.OBJECT      =       reform( m1[0,0,*].OBJECT		)

mh.EQUINOX     =       reform( m1[0,0,*].EQUINOX           )
;;;;;mh.G_ERR       =       m1.G_ERR                     
mh.G_SEQ       =       reform( m1[0,0,*].G_SEQ                     )
;;;;;mh.G_BEAM      =       m1.G_BEAM                    
mh.G_WSHIFT    =       reform( m1[0,0,*].G_WSHIFT                  )
mh.G_NSHIFT    =       reform( m1[0,0,*].G_NSHIFT                  )
mh.G_WPFB      =       reform( m1[0,0,*].G_WPFB                    )
mh.G_NPFB      =       reform( m1[0,0,*].G_NPFB                    )
mh.G_MIX       =       reform( m1[0,0,*].G_MIX                     )
mh.G_EXT       =       reform( m1[0,0,*].G_EXT                     )
mh.G_ADC       =       reform( m1[0,0,*].G_ADC                     )
mh.G_WCENTER   =       reform( m1[0,0,*].G_WCENTER                 )
mh.G_WBAND     =       reform( m1[0,0,*].G_WBAND                   )
mh.G_WDELT     =       reform( m1[0,0,*].G_WDELT                   )

mh.G_DAC       =       m1.G_DAC 
mh.G_TIME      =       reform( m1[0,0,*].G_TIME			)

mh.G_LO1       =       reform( m1[0,0,*].G_LO1                     )
mh.G_LO2       =       reform( m1[0,0,*].G_LO2                     )

mh.G_POSTM     =       reform( m1[0,0,*].G_POSTM                 )  
mh.G_AZZATM    =       reform( m1[0,0,*].G_AZZATM                 ) 

return
end

