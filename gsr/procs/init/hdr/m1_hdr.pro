pro m1_hdr, m1, mh, mx, nochdoppler=nochdoppler

;+
;NAME:
;M1_HDR . Generates the mh and mx files

;PURPOSE
;	take all hdr values from the original fits structure, called m1
;make a TWO NEW STRUCTURES, called mh and mx. 
;the new structure MH contains enhanced info:
;	the relevant integer offsets are added to integer arrays
;	the times are correctly interpolated
;	accurate mean lst and other time info are supplied
;	accurate ra, dec for each beam are supplied
;	all times refer to the one-sec utc tick
;	all positions relate to the center of the integration, i.e. 
;		evaluated at the 1-sec tick plus 0.5 s.
;the new structure MX contains statistical information on data quality
;obtained from analyuses of the frequency-integrated powers from
;each receiver, using only the non-calibration data. the analyses
;include:
;
;       fractional rms of each receiver. if this is low, then the receiver
;is not working (becauswe when you move around in the sky you see signals
;that add to the rms).
;
;       ACF and its FT to find period signals (i.e., radar).
;
;       CCF of recdeivers with one another, to see if cablese were
;interchanged (CCF of two receivers on a giveen feed should be largest(
;
;       SJU: crosscorrelaltion of power data with 12 sec period pulse
;to check seriousness of SJU radar.
;
;CALLING SEQUENCE
;	M1_HDR, m1, mh, mx, [nochdoppler]
;
;INPUTS:
;	M1, the original data structure. has dimensions m1[2,7,nspectra],
;where [2,7] are [pol, rcvr]
;
;KEYWORD:
;	NOCHDOPPLER. if set, does not compute doppler (it is time consuming)
;
;OUTPUT:
;	MH, the condensed and enhanced hdr data structure. has dimensions
;mh[nspectra]. most quantities refer to all pols, all rcvrs; 
;a few are arrays, some of size 7 and some of [2,7].
;
;       MX contains statistical linformation on data quality.
;
;ASSUMPTION:
;	M1 has been reformed to dimensions 2,7,nxpectra, 
;	(where nspectra is normally 600, but this program doesn't care
;
;HISTORY: carl h 28oct04
;	04nov04 carlh modified to use sequence nr to calculate utc instead
;of assuming that the rounded value is correct. carefully done but not
;checked on real data.
;
;	07 jun 2005. carlh modified alfabmpos and chdoppler calls to
;use arrays, thus speeding up things enormously
;
;	08sep2005, carl put in the completely screwy test for the sec_midnite
;being too large by 1 day. THE FUNDAMENTALS FOR THIS MUST BE UNDERSTOOD!
;see the test file... /dzd1/heiles/gsr/run/makemh/joshtst.idl
;
;	06oct2005. carl fixed the fundamentals about time above.
;
;	06oct2005. carl added several data check fields to mh. 
;
;	06oct200g. carl added MH.VERSIONDATE. 
;**************be sure to update VERSIONDATE IMMEDIATELY BELOW
;**************when you make software revisions!!!!!!!! 
;-

versiondate= 20051019

nspectra= ( size( m1))[ 3]

;TAKE CARE OF OFFSETS...
erroffset= 2l^15l
timeoffset= 2ll^31ll
IF (M1[0].G_TIME[0] GT 0) THEN BEGIN
erroffset= 0l
timeoffset= 0l
ENDIF

;DEFINE THE DIFFERENT TYPES OF ERROR...
errs_all =  m1.G_err
ertype = errs_all(uniq(errs_all, sort(errs_all)))+ erroffset  ;32768
errs= err_decode( m1.g_err+ erroffset)

;----------------------NOW DO THE TIMES--------------------
;SAVE ONLY ONE VALUE FOR EACH DIFFERENT SEQUENCE NUMBER; NOT 14!
;FIRST GET THE UTCSTAMP using sequence nr and median difference between
;	sequence number and the rounded time (04nov04)...
;UTCSTAMP IS THE CORRECTED UTC STAMP IN SECONDS FROM 1970 IT IS INTEGRAL SECS..
;JULSTAMP IS THE CORRECTED JULIAN DAY.
;LST_MEANSTAMP IS THE MEAN LST FOR CORRECTED UTCSTAMP.
;LST_APPSTAMP IS THE APPARENT LST FOR CORRECTED UTCSTAMP
;POSTM (UNITS SECS SINCE 1970) IS G_POSTM (UNITS HRS SINCE MIDNITE)
;AZZATM (UNITS SECS SINCE 1970) IS G_AZZATM (UNITS HRS SINCE MIDNITE)

utcstamp_round= reform( $
        round( double(m1[0,0,*].g_time[0]+ timeoffset)+ $
	(m1[0,0,*].g_time[1]+ timeoffset)*1.d-6))
seqnr= long( reform( m1[0,0,*].g_seq)+ erroffset)

;HANDLE CASE OF SEQUENCE NUMBER WRAPAROUND...
seqnrdiff= seqnr- shift( seqnr,1)
indx= where( seqnrdiff lt -16000l, count1)
if (count1 eq 1) then seqnr[ indx[0]:*]= seqnr[ indx[0]:*]- seqnrdiff[ indx[0]]+1l

;COMPARE SEQNR DIFF WITH UTC DIFF AND GENERATE NEW UTC...
seqdiff= total( double(utcstamp_round)- double(seqnr))/ $
;	n_elements( utcstamp_round) + .5d
	nspectra + .5d
utcstamp= seqnr+ long( seqdiff)

;CHK TO DETECT PROBLEMS...
indx= where(  utcstamp ne utcstamp_round, count2)
if (count1 ne 0) then print, 'count1'
if (count2 ne 0) then print, 'count2'

julstamp= julday( 1, 1, 1970, 0, 0, utcstamp)
lst_meanstamp= juldaytolmst( julstamp)
nutm= nutation_m( julstamp, eqOfEq=eqOfEq)
lst_appstamp= 24.d0* (lst_meanstamp+ eqOfEq)/(2.d0* !dpi)
lst_meanstamp= 24.d0* (lst_meanstamp)/(2.d0* !dpi)        

;CONVERT THE G_POSTM AND G_AZZATM TO SEC SINCE JAN 1 1970...
;THESE ARE NOW COMPARABLE EXACTLY TO UTCSTAMP...

;OLDE WAY...
sec_midnite_since1970= $
        86400d0* ( long(julstamp[3] + 0.5d) -0.5d - julday(1,1,1970,-4,0,0))
postm= 3600.d0* reform( m1[ 0,0,*].g_postm)+ sec_midnite_since1970
azzatm= 3600.d0* reform( m1[ 0,0,*].g_azzatm)+ sec_midnite_since1970
indazut=where(azzatm-utcstamp gt 86400./2., cazut)
if cazut ne 0 then azzatm[indazut]= azzatm[indazut]-86400.d0

azzatmolde= azzatm

;stop, 'M1_HDR, STOP 0'

;NEW WAY...
;nrmidnites_since1970= $
;	long(julstamp- julday(1,1,1970,0,0,0))
;azzatm= 3600.d0*reform( m1[ 0,0,*].g_azzatm + 4.d0)+ $
;	86400.d0* nrmidnites_since1970
nr_ast_midnites_since1970= $
	long(julstamp- julday(1,1,1970,0,0,0)- (4./24.))
azzatm= 3600.d0*reform( m1[ 0,0,*].g_azzatm + 4.d0)+ $
	86400.d0* nr_ast_midnites_since1970
postm= 3600.d0*reform( m1[ 0,0,*].g_postm + 4.d0)+ $
	86400.d0* nr_ast_midnites_since1970

;CRUDE FIX FOR PROBLEM OF SEC_MIDNITE_SINCE1970 BEING OFF BY 86400 SECS...
;if (azzatm[3] - utcstamp[3]) gt 86400./2. then azzatm= azzatm- 86400.d0
; Ji-Hyun's fix for 86400 problem:

;indazut=where(azzatm-utcstamp gt 86400./2., cazut)
;if cazut ne 0 then azzatm[indazut]= azzatm[indazut]-86400.d0

;CHK DIFFS BTWN OLDE AND NEW WAY...
diffs= where( abs( azzatm- azzatmolde) gt 0.01, countdiffs)
if (countdiffs ne 0) then for nr=1,10 do $
print, '****************nr diffs in azzatm = ', countdiffs, ' *******************************''

;stop, 'M1_HDR, STOP 1'

;-------NOW DO INTERPOLATION ON AZ,ZA AND RECOMPUTE RASTAMP, DECSTAMP-----
;RAM1_INTERP, ETC, ARE VALUES INTERPOLATED TO ONE-HALF SEC AFTER THE 1SEC TICK
;	THESE VALUES ARE APPROPRIATE FOR THE MIDDLE OF THE 1SEC INTEGRATION.
indxord= sort( azzatm)
azzatm_interp= chinterpol(azzatm[ indxord], azzatm[ indxord], utcstamp+ 0.5d)
azm1_interp= chinterpol(m1[ 0,0,indxord].crval2b, azzatm[ indxord], utcstamp+0.5d)
zam1_interp= chinterpol(m1[ 0,0,indxord].crval3b, azzatm[ indxord], utcstamp+0.5d)

time0= systime(1)

;DEFINE POSITIONS OF THE 7 BEAMS FOR EACH OBS...
rastamp_interp= dblarr( 7, nspectra)
decstamp_interp= dblarr( 7, nspectra)

;FIND UNIQUE VALUES OF ALFA ROTANGLE...
alfa_angs= reform( m1[0,0,*].alfa_ang)
alfa_angs_uniq= alfa_angs[ uniq( alfa_angs, sort( alfa_angs))]

;DO ARRAY CALL FOR EACH ROTANGLE SET...
FOR NR=0, N_ELEMENTS( ALFA_ANGS_UNIQ)-1 DO BEGIN
alfaindx= where( alfa_angs eq alfa_angs_uniq[ nr])
alfabmpos, azm1_interp[ alfaindx], zam1_interp[ alfaindx], $
	julstamp[ alfaindx], rastamp, decstamp, $
	rotangle= alfa_angs_uniq[ nr]
rastamp_interp[ *, alfaindx]= rastamp
decstamp_interp[ *, alfaindx]= decstamp
ENDFOR

;print, 'finished alfabmpos ', systime(1)-time0

;FINALLY, DO THE VELOCITIES, BOTH LSR AND HELIOCENTRIC. VELS ARE OF THE
;FEED WITH RESPECT TO THE SOURCE.

IF KEYWORD_SET( NOCHDOPPLER) eq 0  THEN BEGIN
rastamp_interp= reform( rastamp_interp, 7l* nspectra)
decstamp_interp= reform( decstamp_interp, 7l* nspectra)
juljul= dblarr( 7, nspectra)
for nr=0,6 do juljul[ nr,*]= julstamp
juljul= reform( juljul, 7l* nspectra)

res= chdoppler( rastamp_interp, decstamp_interp, juljul)
vlsr= reform( res[ 3, *], 7, nspectra)
vbary= reform( res[ 2, *], 7, nspectra)

rastamp_interp= reform( rastamp_interp, 7l, nspectra)
decstamp_interp= reform( decstamp_interp, 7l, nspectra)

;print, 'finished chdoppler', systime(1)-time0
ENDIF

mh= replicate( mhdefine( m1), nspectra)

m1_to_mh, m1, mh

mh.versiondate= versiondate
mh.errs= errs

mh.utcstamp= utcstamp
mh.julstamp= julstamp
mh.lst_meanstamp= lst_meanstamp
mh.lst_appstamp= lst_appstamp

mh.az_halfsec= azm1_interp
mh.za_halfsec= zam1_interp
mh.ra_halfsec= rastamp_interp
mh.dec_halfsec= decstamp_interp
mh.vlsr= vlsr
mh.vbary= vbary

;stop

g_wide= float( m1.g_wide+ timeoffset)
g_wide[ 256,*,*,*]= 0.5* (g_wide[ 255,*,*,*]+ g_wide[ 257,*,*,*])
mh.pwr_wb= total( g_wide, 1)/512.

mh.pwr_nb= total( (m1.data +  timeoffset ), 1)/7679.

;------------- added 2005oct6 --------------------------------------

;stop

;DO CROSS CORRELATION OF POWERS, AND RELATIVE RMS, 
;	WHEN SMARTF AND CAL ARE NOT BEING DONE...
rxdiagnostics, mh, ccfwb, acfwb, rmsratiowb, sjuwb, nindx
rxdiagnostics, mh, ccfnb, acfnb, rmsrationb, sjunb, nindx, /nb

;stop

;CHK FOR FEED INTERCHANGED RX'S USING CCF...
ccfchk, nindx, ccfwb, feedbadwb
ccfchk, nindx, ccfnb, feedbadnb

;stop, 'BEFORE RMSRATIOCHK'

;CHK FOR BAD RMS RATIO USING RMS/AVG...
rmsratiochk, nindx, rmsratiowb, rxbadwb
rmsratiochk, nindx, rmsrationb, rxbadnb

;stop

acfchksym, nindx, acfwb, rxradarwb
acfchksym, nindx, acfnb, rxradarnb

;stop

;------------- added 2005oct6 --------------------------------------

mx= mxdefine()
mx.julstamp= julstamp[ 0]
mx.versiondate= versiondate
mx.nindx= nindx
mx.ccfwb= ccfwb
mx.ccfnb= ccfnb
mx.acfwb= acfwb
mx.acfnb= acfnb
mx.rmsratiowb= rmsratiowb
mx.rmsrationb= rmsrationb
mx.feedbadwb= feedbadwb
mx.feedbadnb= feedbadnb
mx.rxbadwb= rxbadwb
mx.rxbadnb= rxbadnb
mx.rxradarwb= rxradarwb
mx.rxradarnb= rxradarnb
mx.sjuwb= sjuwb
mx.sjunb= sjunb


return
end
