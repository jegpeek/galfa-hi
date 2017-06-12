pro makepatt, nspdr, cfr, mwt, beamin_arr, beamout_arr, nbins, $
	rffrq_wb_bin, tsys_bins

;+
;purpose
;	generate the organized data for a single spider paattern. does
;both pols simultaneously.
;
;inputs:
;	nspdr, the sequential nr of the spider pattern (begins w 0)
;	mwt, the data structure for this spider pattern
;	beamin_arr, beamout_arr, the usual data structures
;	nbins, the nr of bins to treat in freq-resolved solution
;	rffrq_wb_bin, the center frq of the freq-resolved bins.
;outputs:
;	beamin_arr, beam_outarr
;	tsys_bins, the freq-resolved powers.
;-

;EXTRACT PARAMETERS...
hpbw_guess= beamin_arr[ nspdr].hpbw_guess
rx= beamin_arr[ nspdr].rx

;GENERATE THE INDXS FOR CALON, CALOFF THAT WE WILL ACTUALLY USE...
indxcalon= where( mwt.mh.obsmode eq 'CAL     ' and $
                  mwt.mh.obs_name eq 'ON      ', countcalon)
indxcaloff= where( mwt.mh.obsmode eq 'CAL     ' and $
                  mwt.mh.obs_name eq 'OFF     ', countcaloff)
indxcalon= indxcalon[ 1:4]
indxcaloff= indxcaloff[ 1:4]
 
;LOOK AT THE POSITIONS...
indxaz= where(  mwt.mh.obs_name eq 'ONAZ    ', countonaz)
indxza= where(  mwt.mh.obs_name eq 'ONZA    ', countonza)
indxaz45= where(  mwt.mh.obs_name eq 'ONAZ45  ', countonaz45)
indxza45= where(  mwt.mh.obs_name eq 'ONZA45  ', countonza45)
 
;GET HA AT CNTR OF INTEGRATION--DON'T FORGET TO ADD THE HALFSEC!
rafeed= mwt.mh.ra_halfsec[ rx]
hafeed= (mwt.mh.lst_appstamp+ 0.5/3600.)- rafeed
decfeed= mwt.mh.dec_halfsec[ rx]

;GENERATE AZZA OFFSETS OF EACH POINT FROM THE SOURCE...
rasrc= beamin_arr[ nspdr].rasrc
decsrc= beamin_arr[ nspdr].decsrc
eqtoaz, hafeed,  decfeed, azfeed, zafeed, 1
hasrc= (mwt.mh.lst_appstamp+ 0.5/3600.)- rasrc
eqtoaz, hasrc, decsrc, azsrc, zasrc, 1
delaz= sin( !dtor*zafeed)*(azfeed-azsrc)
delza=zafeed-zasrc

;GENERATE THE 60 POINTS IN EACH STRIP. FIND THE CNTR, TAKE CNTR-29 TO CNTR+30
;TO FIND CNTRS, RESTRICT THE POINTS EXAMINED TO THOSE NEAR THE CENTER TO AVOID
;ACCIDENTAL PASS NEAR SOURCE WHILE MOVING TO THE BEGINNING OF THE STRIP...

;FIRST, CREATE THE ARRAYS TO STORE STUFF...
stripadu= fltarr( 2, 60,4)
striptsys= fltarr( 2, 60,4)
stripadu_chnls= fltarr( beamin_arr[ nspdr].nchnls, 2, 60, 4)
striptys_bins= fltarr( nbins, 2, 60, 4)

stripazfeed= fltarr( 60,4)
stripzafeed= fltarr( 60,4)
stripdelaz= fltarr( 60,4)
stripdelza= fltarr( 60,4)
stripdelang= fltarr( 60,4)
stripdeltot= fltarr( 60,4)

;WE ORIGINALLY DEFINED THE NR OF POINTS IN EACH STRIP FROM THE CENTER TWO...
;width= 0.5*( n_elements( indxza)+ n_elements( indxaz45))
;NOW WE HARD WIRE TO 90...
width= 90.
swid= 0.6*width
 
;FIND THE CENTERS OF EACH STRIP FROM THE MINIMUM OF AZZA OFFSET TO SOURCE...
tmpaz= min( abs( delaz[ indxaz[0]:indxaz[0]+swid])+ $
          abs( delza[ indxaz[0]:indxaz[0]+swid]), azcntr)
tmpza= min( abs( delza[ indxza[0]:indxza[0]+swid])+ $
          abs( delza[ indxza[0]:indxza[0]+swid]), zacntr)
tmpaz45= min( abs( delaz[ indxaz45[0]:indxaz45[0]+swid])+ $
          abs( delza[ indxaz45[0]:indxaz45[0]+swid]), az45cntr)
tmpza45= min( abs( delaz[ indxza45[0]:indxza45[0]+swid])+ $
          abs( delza[ indxza45[0]:indxza45[0]+swid]), za45cntr)

;DEFINE EACH STRIP TO BE 60 POINTS CENTERED ON THE AZZA OFFSET MINIMUM...
stripdelaz[ *,0]= delaz[ indxaz[0]+azcntr-29: indxaz[0]+azcntr+30]
stripdelza[ *,0]= delza[ indxaz[0]+azcntr-29: indxaz[0]+azcntr+30]
stripdelaz[ *,1]= delaz[ indxza[0]+zacntr-29: indxza[0]+zacntr+30]
stripdelza[ *,1]= delza[ indxza[0]+zacntr-29: indxza[0]+zacntr+30]
stripdelaz[ *,2]= delaz[ indxaz45[0]+az45cntr-29: indxaz45[0]+az45cntr+30]
stripdelza[ *,2]= delza[ indxaz45[0]+az45cntr-29: indxaz45[0]+az45cntr+30]
stripdelaz[ *,3]= delaz[ indxza45[0]+za45cntr-29: indxza45[0]+za45cntr+30]
stripdelza[ *,3]= delza[ indxza45[0]+za45cntr-29: indxza45[0]+za45cntr+30]
 
stripazfeed[ *,0]= azfeed[ indxaz[0]+azcntr-29: indxaz[0]+azcntr+30]
stripzafeed[ *,0]= zafeed[ indxaz[0]+azcntr-29: indxaz[0]+azcntr+30]
stripazfeed[ *,1]= azfeed[ indxza[0]+zacntr-29: indxza[0]+zacntr+30]
stripzafeed[ *,1]= zafeed[ indxza[0]+zacntr-29: indxza[0]+zacntr+30]
stripazfeed[ *,2]= azfeed[ indxaz45[0]+az45cntr-29: indxaz45[0]+az45cntr+30]
stripzafeed[ *,2]= zafeed[ indxaz45[0]+az45cntr-29: indxaz45[0]+az45cntr+30]
stripazfeed[ *,3]= azfeed[ indxza45[0]+za45cntr-29: indxza45[0]+za45cntr+30]
stripzafeed[ *,3]= zafeed[ indxza45[0]+za45cntr-29: indxza45[0]+za45cntr+30]

stripdeltot[ *,0] = stripdelaz[*,0]
stripdeltot[ *,1] = stripdelza[*,1]

stripdeltot[ *,2:3] = sqrt( stripdelaz[ *,2:3]^2 + stripdelza[ *,2:3]^2)
temp_tot = stripdeltot[*,2:3]
temp_az = stripdelaz[*,2:3]
indx = where( temp_az lt 0.)
temp_tot[ indx] = temp_tot[ indx] * (-1.)
stripdeltot[ *,2:3] = temp_tot

;CONVERT ALL offset ANGLES FROM DEGREES TO ARCMIN...
stripdelaz= 60.* stripdelaz
stripdelza= 60.* stripdelza
stripdeltot= 60.* stripdeltot

stripadu[ *,*,0]= $
mwt[ indxaz[0]+azcntr-29: indxaz[0]+azcntr+30].mh.pwr_wb[*,rx]
stripadu[ *,*,1]= $
mwt[ indxza[0]+zacntr-29: indxza[0]+zacntr+30].mh.pwr_wb[*,rx]
stripadu[ *,*,2]= $
mwt[ indxaz45[0]+az45cntr-29: indxaz45[0]+az45cntr+30].mh.pwr_wb[*,rx]
stripadu[ *,*,3]= $
mwt[ indxza45[0]+za45cntr-29: indxza45[0]+za45cntr+30].mh.pwr_wb[*,rx]

stripadu_chnls[ *,*,*,0]= $
mwt[ indxaz[0]+azcntr-29: indxaz[0]+azcntr+30].g_wide[ *,*,rx]
stripadu_chnls[ *,*,*,1]= $
mwt[ indxza[0]+zacntr-29: indxza[0]+zacntr+30].g_wide[ *,*,rx]
stripadu_chnls[ *,*,*,2]= $
mwt[ indxaz45[0]+az45cntr-29: indxaz45[0]+az45cntr+30].g_wide[ *,*,rx]
stripadu_chnls[ *,*,*,3]= $
mwt[ indxza45[0]+za45cntr-29: indxza45[0]+za45cntr+30].g_wide[ *,*,rx]

beamin_arr[ nspdr].azencoders= stripazfeed
beamin_arr[ nspdr].zaencoders= stripzafeed
beamin_arr[ nspdr].azoffsets= stripdelaz
beamin_arr[ nspdr].zaoffsets= stripdelza
beamin_arr[ nspdr].totoffsets= stripdeltot

;------------------ CAL MATTERS FOR AVG OF ALL CHNLS -------------------

;GET THE CAL TEMP...
rcvnum=17               ; rcvr num i use for alfa
caltype=1               ; hcorcal .. but alfa just has the 1 high cal.
istat=calget1(rcvnum,caltype,cfr,calval)
beamin_arr[ nspdr].tcal= calval[ *, rx]

;DEFINE CALON AND CALOFF...
calon0= mean( mwt[ indxcalon].mh.pwr_wb[ 0, rx])
caloff0= mean( mwt[ indxcaloff].mh.pwr_wb[ 0, rx])
calon1= mean( mwt[ indxcalon].mh.pwr_wb[ 1, rx])
caloff1= mean( mwt[ indxcaloff].mh.pwr_wb[ 1, rx])

adu_to_tsys, calval[ 0,rx], calon0, caloff0, stripadu[ 0,*,*], tsys0, fctr0
adu_to_tsys, calval[ 1,rx], calon1, caloff1, stripadu[ 1,*,*], tsys1, fctr1
striptsys[ 0,*,*]= tsys0
striptsys[ 1,*,*]= tsys1

beamin_arr[ nspdr].tsys= striptsys
beamin_arr[ nspdr].utcstamp= mwt[ indxcalon[0]].mh.utcstamp
beamout_arr[ nspdr].(0).fctr= fctr0
beamout_arr[ nspdr].(1).fctr= fctr1

for nr=0,1 do beamout_arr[ nspdr].(nr).cal= calval[ nr, rx]

;------------------ CAL MATTERS FOR BINS OF CHNLS -------------------
define_bins, nspdr, rx, rffrq_wb_bin, indxcalon, indxcaloff, nbins, mwt, $
        stripadu_chnls, tsys_bins, beamout_arr

end
