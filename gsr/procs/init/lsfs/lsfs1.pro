 pro lsfs1, m1s, lofrqs_lsfs_out, indxbreak, pwrwb, $
	pwrwb_avg, g_wide_avg, $
	pwrnb_avg, g_nb_avg, error=error

;+
;NAME:
;LSFS1 -- yet another filter for SMARTF spectra; also calculate some
;average spectra for input to LSFS processing.
;
;PURPOSE: given the set of spectra that has pattern SMARTF, 
;some of these aren't really SMARTF because the pattern name hangs around.
;truncate it to the real set. return spectral and power arrays. 

;the most important output is INDXBREAK. We have N values of M1S, each 
;identified by an index INDX. The elements of INDXBREAK identify
;spectra having specific values of lofrq, calonoff, and cycle. These
;are used by subsequent programs to derive the LSFS stuff.
;
;CALLING SEQUENCE:
;	LSFS1, m1s, lofrqs_lsfs_out, indxbreak, pwrwb, $
;	pwrwb_avg, g_wide_avg, $
;	pwrnb_avg, g_nb_avg, error=error
;
;INPUTS:
;	M1S: the data structure preselected so most of its elements are
;in the pattern FSMART. The proc selects only those that are REALLY in
;FSMART and returns M1S as this truncated set.
;
;OUTPUTS:
;
;	LOFRQS_LSFS_OUT[7], the set of 7 lo freqs
;
;	INDXBREAK[ 2, 7, 2, 4] DESCRIBES ALL SPECTRA THAT EXCLUDE
;TRANSITIONS BETWEEN CAL ON AND OFF AND ALSO FREQ CHANGING.
;
;	INDXBREAK[ indx, frq, cal, cycle]. the two indices give the
;beginning and ending indx corresponding to the chosen values for
;frq, cal, and cycle. thus
;
;	PWRWB[ 2, 7, nspectra] is the total power in each wb spectrum, i.e. 
;the avg over chnls for each feed and pol nspectra. PWRWB[ pol, feed, nsp]
;
;	PWRWB_AVG[2,7,7,2,4] IS PWRWB FOR EACH COMBO OF CAL, LO, CYCLE
;AVGD OVER EACH ONE'S ~10 CONTRIBS. PWRWB_AVF[ pol, feed, frq, cal, cycle]
;
;	G_WIDE_AVG[512, 2, 7, 7, 2, 4] IS THE SPECTRUM FOR EACH COMBO OF
;CAL, LO, CYCLE AVGD OVER EACH ONE'S ~10 CONTRIBS.
;G_WIDE_AVF[ chnls,pol, feed, frq, cal, cycle]
;
;	PWRNB_AVG[2,7,7,2,4] IS PWRNB FOR EACH COMBO OF CAL, LO, CYCLE
;AVGD OVER EACH ONE'S ~10 CONTRIBS. PWRNB_AVF[ pol, feed, frq, cal, cycle]
;
;	G_NB_AVG[ 7680, 2, 7, 7, 2, 4] IS THE SPECTRUM FOR EACH COMBO OF
;CAL, LO, CYCLE AVGD OVER EACH ONE'S ~10 CONTRIBS.
;G_NB_AVF[ chnls,pol, feed, frq, cal, cycle]
;
;OPTIONAL OUTPUT:
;
;       ERROR. nonzero if there is an error and need to bypass.
;
;HISTORY:
;	written for nov 2004 data when we had only a few examples.
;	may 2005: carl corrected and modified for more generality.
;	july16 2005: fixed problem on frq calcs. enabled ERROR.
;	12 oct 05: carl checked COUNTJNDX1 which must be ge 14 for a full cycle
;       9 jul 08: Josh put in a kludge to fix non divisible by 14 m1s.
;-

timeoffset=0L
if m1s[0,0,0].g_time[0] lt 0l then timeoffset= 2ll^31ll

error=0
; KLUDGE BY JOSH: SOMETIMES THIS CODE DOESN'T GET FED N*14
; SPECTRA. FIXING THAT.
nel = n_elements(m1s)
if nel/14.0 ne nel/14l then m1s = (temporary(m1s))[0:floor(nel/14.)*14.-1]

nspectra= n_elements(m1s)/14l
m1s= reform( temporary( m1s), 2, 7, nspectra)

; SECOND JOSH KLUDGE: GET RID OF 'NOSCAN  '
wh = where(((m1s.obs_name eq 'NOSCAN  ') and (m1s.obsmode eq 'SMARTF  ')), ct)
if ct ne 0 then begin
   m1s[wh].obs_name = m1s[wh-14].obs_name
endif

;FIND THE UNIQUE LOFRQS...THERE SHOULD BE 7.
;IF THERE ARE MORE, THEN ELIMINATE ALL AFTER THE 7TH.
lofrqs_m1s= reform( m1s[0,0,*].g_lo1) 

;IT SEEMS THAT DOPPLER CORRECTION WAS ON! ROUND FREQS TO NEAREST 1 KHZ
;TO CHECK FOR UNIQUENESS.
lofrqs= long(lofrqs_m1s)/1000l

;IT SEEMS THAT DOPPLER CORRECTION WAS ON! ROUND FREQS TO NEAREST 0.11 KHZ
;TO CHECK FOR UNIQUENESS.
lofrqs= long(lofrqs_m1s)/100l

;FIND THE UNIQUE LO FREQS (THAT TRUNCATE TO 0.1 KHZ)
indxq= uniq( lofrqs, sort( lofrqs))
lofrqs_lsfs= lofrqs[ indxq[ sort(indxq)]]

;CHK FOR TOO FEW LO FRQS...INCOMPLETE CALIBRATION.
IF N_ELEMENTS( indxq) LT 7 THEN BEGIN
	print, 'NOT A FULL SMARTF. RETURNING AND NO LSFS OUTPUT FILE.'
	error=1
;	stop
	return
ENDIF

;stop, 'lsfs1 -- one'

;HANDLE CASE OF MORE THAN 7 LO FRQS. 
;ALLOW SLOP OF 1 khz (BECAUSE DOPP CORR ON?)
;THE ARRAY INDX_INDEP TELLS WHETHER A PARTICULAR LO FREQ IS
;REDUNDDANT WITH ANOTHER. IF EQUAL TO 1 IT IS REDUNDANT AND NOT INDEPENDENT.

;IF N_ELEMENTS( LOFRQS_LSFS) GT 7 THEN BEGIN   				;if1
nels= n_elements( lofrqs_lsfs)
indx_indep= intarr( nels)
FOR NR=0, NELS-1 DO BEGIN
	indx= where( abs( lofrqs_lsfs[ nr:*] - lofrqs_lsfs[nr]) eq 1, count)
	if count ne 0 then indx_indep[ indx+ nr]= 1
ENDFOR

;stop, 'lsfs1 -- 1.25'

;RETAIN ONLY THOSE LOFRQS THAT ARE INDEPENDENT.
indxy= where( indx_indep eq 0)
lofrqs_lsfs= lofrqs_lsfs[ indxy]
nels= n_elements( indxy)

;FIND FIRST OCCURANCE OF EACH INDEPENDENT LO FREQUENCY...
firstindx= intarr( nels)
FOR NRF= 0, NELS-1 DO BEGIN
indxf= where( abs (lofrqs- lofrqs_lsfs[nrf]) le 1, count)
if count eq 0 then stop, 'STOP PROBLEM 1 IN LSFS1'
firstindx[ nrf]= indxf[ 0]
ENDFOR

;stop, 'lsfs1 -- 1.255

;GET THE TIME-SORTED UNIQUE LO FREQUENCIES...
indxsort= firstindx[sort( firstindx)]

;### THE FOLLOWING DISCARDED IN FAVOR OF WHAT COMES LATER 14JUL05 ####
;RETAIN ONLY THE FIRST 7 OF THE TIME SORTED LO FREQUENCIES...
;indxsort= indxsort[ 0:6]
;lofrqs_lsfs_sort= lofrqs[ indxsort]

;#### ADDED 14 JUL 05 #####
;CHK THE TIME SORTED FRQS. FIND THE LOWEST AMONG THE FIRST 3, IN
;CASE THE FIRST ONE OR TWO WERE THERE DURING SETUP.... 
lofrqs_lsfs_sort= lofrqs[ indxsort]
lowest= min( lofrqs_lsfs_sort[0:2], indxlow)
lofrqs_lsfs_sort= lofrqs_lsfs_sort[ indxlow: indxlow+6 ]

indxyes = where((abs (lofrqs- lofrqs_lsfs_sort[0]) le 1) or $
		(abs (lofrqs- lofrqs_lsfs_sort[1]) le 1) or $
		(abs (lofrqs- lofrqs_lsfs_sort[2]) le 1) or $
		(abs (lofrqs- lofrqs_lsfs_sort[3]) le 1) or $
		(abs (lofrqs- lofrqs_lsfs_sort[4]) le 1) or $
		(abs (lofrqs- lofrqs_lsfs_sort[5]) le 1) or $
		(abs (lofrqs- lofrqs_lsfs_sort[6]) le 1) , count)

indxstop= where( indxyes - shift(indxyes,1) gt 1, countstop)
if countstop ne 0 then indxyes= indxyes[ 0: indxstop[ 0]-1]

;stop, 'lsfs1 -- 1.26;

m1s= temporary( m1s[ *, *, indxyes])
;ENDIF									;if1

nspectra= n_elements( m1s)/14l
lofrqs= lofrqs[ indxyes]

;DETERMINE WHICH FREQUENCY EACH ARRAY ELEMENT HAS...
whichfreq= -1 + intarr( nspectra)
FOR NR=0, 6 DO BEGIN
indxyy= where( abs( lofrqs - lofrqs_lsfs_sort[ nr]) le 1, count)
if (count ne 0) then whichfreq[ indxyy]= nr
ENDFOR

diffs= dblarr( 7)

FOR NDIF= 0, 6 DO BEGIN
inddif= where( whichfreq eq ndif, count)
if ( ndif eq 0) then frqs_zero= lofrqs_m1s[ indxyes[ inddif[ 0]]]
if count eq 0 then stop, 'STOP PROGLEM 2 IN LSFS1!!!!!'
;;;;;;; 15may2005 diffs[ ndif]= lofrqs_m1s[ inddif[0]]- lofrqs_m1s[ 0]
diffs[ ndif]= lofrqs_m1s[ indxyes[ inddif[0]]]- frqs_zero
ENDFOR

;stop, 'lsfs1 -- 1.39'

;FIND TEH FIRST OCCURRANCE OF THE LOWEST LOFRQ_LSFS_SORT...
indxzro= ( where( whichfreq eq 0))[0]

diffs= round( diffs/( 100.d6/512.d))
lofrqs_lsfs_out= m1s[0,0,indxzro].g_lo1 + diffs* (100.d6/512.d)
lofrqs_lsfs_out= 1.d-6* lofrqs_lsfs_out

;stop, 'lsfs1 -- 1.4'

;thoroughly checked up to here...

;NOW WE HAVE GENERATED THE SET HAVING GOOD LO FRQS. 

calonoff= 1+ intarr( nspectra)

;NOW FIND PLACES WHERE CAL IS ON AND OFF...
;TAKE CARE OF OLDER DATA FORMAT WHERE OBS_NAME DIDN'T EXIST...
;IF OBS_NAME EXISTS, USE 'ON' TO DETERMINE WHEN CAL WAS ON
indx= where( tag_names( m1s) eq 'OBS_NAME', count_exist)
IF (COUNT_EXIST GT 0) THEN BEGIN
indx= where( m1s[0,0,*].obs_name eq 'OFF     ')
calonoff[ indx]= 0
ENDIF ELSE BEGIN
indxlo0= where( lofrqs eq lofrqs_lsfs_sort[0],count)
indxdlo0= where( indxlo0- shift( indxlo0,1) ne 1, count)

;INCLUDE ONLY EVEN NR OF HALF-CYCLES...
nrhalfcycles= n_elements( indxdlo0)
nrhalfcycles= nrhalfcycles- (nrhalfcycles mod 2)
for nindxd= 0, nrhalfcycles- 1, 2 do $
  calonoff[ indxlo0[ indxdlo0[ nindxd]]: indxlo0[ indxdlo0[nindxd+ 1]] -1] = 0
ENDELSE

;DETERMINE NR OF ONOFF CAL CYCLES...
tmp= calonoff-shift(calonoff,1)
indxchng= where( tmp gt 0, countindxchng)
ncycs= countindxchng

;stop, 'lsfs1 -- two'

jndx1= where( lofrqs - shift( lofrqs,1) ne 0, countjndx1)

;#####TAKE CARE OF CASE WHERE NOT A COMPLETE CYCLE (add 12 oct 05)...
IF COUNTJNDX1 LT 14 THEN BEGIN
	print, 'NOT A FULL SMARTF. RETURNING AND NO LSFS OUTPUT FILE.'
	error=1
;	stop
	return
ENDIF

;TAKE CARE OF CASE WHERE THERE ARE EXTRA FREQ JUMPS...
if countjndx1 mod 14 ne 0 then begin
	jndx1= jndx1[ 0: n_elements( jndx1)-1-(countjndx1 mod 14)]
	ncycs= n_elements( jndx1)/14
     endif

;#####TAKE CARE OF WEIRD FAILURE CASE: JEGP AUG 2 2009
IF ncycs*2 ne n_elements(jndx1)/7 THEN BEGIN
	print, 'FAILED: ncycs bad'
	error=1
;	stop
	return
ENDIF


jndx1= reform( jndx1, 7, ncycs*2)

;DEFINE A 4D ARRAY WITH BEGINNING AND ENDING INDX NRS FOR each state...
;indxbreak= intarr( [begin.end]2, lofrqvalue, calvalue, cyclenr)
indxbreak= intarr( 2, 7, 2* ncycs)

indxbreak[ 0, *, *]= jndx1
for lonr=0, 5 do indxbreak[ 1, lonr, *, *]= indxbreak[ 0, lonr+1, *, *]
lonr=6
indxbreak[ 1, 6, 0:2*ncycs-2]= indxbreak[ 0, 0, 1:2*ncycs-1]
indxbreak= reform( indxbreak, 2, 7, 2, ncycs)
indxbreak[ 1,6,0,ncycs-1]= jndx1[ 0,2*ncycs-1]
indxbreak[ 1,6,1,ncycs-1]= n_elements( lofrqs)

;stop, 'lsfs1 -- three'

;NOW THESE NEED TO BE FIXED UP: SUBTRACT 1 FROM ALL BEGINNINGS, BECAUSE
;WE HAD SET THEM EQUAL TO THE ENDS OF TEH PREVIOUS LO...

indxbreak[ 1,*,*,*]= indxbreak[ 1,*,*,*]- 1

;ADD 1 TO BEGINNINGS, SUBTRACT 1 FROM ENDS...
indxbreak[ 0,*,*,*]= indxbreak[ 0,*,*,*]+ 1
indxbreak[ 1,*,*,*]= indxbreak[ 1,*,*,*]- 1

;;DO IT AGAIN???
;indxbreak[ 0,*,*,*]= indxbreak[ 0,*,*,*]+ 1
;indxbreak[ 1,*,*,*]= indxbreak[ 1,*,*,*]- 1

;IF ANY SET HAS MORE THAN THE MEDIAN NR OF SPECTRA, CUT OFF THE END...
;THIS IS NECESSARY FOR THE LAST ONE...
indxbreak= reform( indxbreak, 2, 7*2*ncycs)
diff= indxbreak[1,*]-indxbreak[0,*]
indx= where( diff gt median( diff), count)
if (count ne 0) then indxbreak[ 1,indx] = indxbreak[ 0,indx]+ median(diff)-1
indxbreak= reform( indxbreak, 2, 7, 2, ncycs)  
 
;AT THIS POINT, INDXBREAK DESCRIBES ALL SPECTRA THAT EXCLUDE TRANSITIONS
;BETWEEN CAL ON AND OFF AND ALSO FREQ CHANGING.

;----------------------GET WIDEBAND QUANTITIES-------------------------

;PWRWB IS AVG OVER CHNLS FOR EACH RCVR AND POL NSPECTRA
pwrwb= (total( long64(m1s.g_wide), 1) - $
	long64( (m1s.g_wide)[ 256,*,*,*]) + $
( long64( (m1s.g_wide)[ 255,*,*,*])+ long64( (m1s.g_wide)[ 257,*,*,*]))/ 2l)/512.d $
	+ timeoffset

;stop

;WHY DID I EVER PUT IN THE FOLLOWING STATEMENT?????
;pwrwb= reform( pwrwb, 2, 7, nspectra, ncycs)

;PWRWB_AVG IS PWR FOR EACH COMBO OF CAL, LO, CYCLE AVGD OVER EACH
;       ONE'S ~10 CONTRIBS
pwrwb_avg= fltarr( 2,7,7,2,ncycs)
pwrwb_avg= reform( pwrwb_avg, 2,7, 7*2*ncycs)
idb= reform( indxbreak, 2, 7*2*ncycs)

;CHECK TGO MAKE SURE IDB INCREASES MONOTONICALLY...
indxidb = where( (idb[1,*]-idb[0,*]) le 0, countidb)
IF COUNTIDB NE 0 THEN BEGIN
	print, 'SWITCHING SEQUENCE IS INCOMPRENSIBLE. RETURNING AND NO LSFS OUTPUT FILE.'
	error=2
	return
ENDIF

for nr=0, 7*2*ncycs-1 do pwrwb_avg[ *,*,nr]= $
        total( pwrwb[*,*,idb[0,nr]:idb[1,nr]],3)/(idb[1,nr]-idb[0,nr]+1.0)
pwrwb_avg= reform( pwrwb_avg, 2, 7, 7, 2, ncycs)

;G_WIDE_AVG IS THE SPECTRUM FOR EACH COMBO OF CAL, LO, CYCLE AVGD OVER EACH
;       ONE'S ~10 CONTRIBS
g_wide_avg= fltarr( 512,2,7, 7*2*ncycs)
for nr=0, 7*2*ncycs-1 do g_wide_avg[ *,*,*,nr]= $
        total( long64( (m1s.g_wide)[*,*,*,idb[0,nr]:idb[1,nr]]),4)/(idb[1,nr]-idb[0,nr]+1.0) $
	+ timeoffset
g_wide_avg[ 256,*,*,*]= 0.5* (g_wide_avg[ 257,*,*,*]+ g_wide_avg[ 255,*,*,*])

;stop, 'LSFS1 -- WB end'

g_wide_avg= reform( g_wide_avg, 512, 2, 7, 7, 2, ncycs)

;----------------------GET nBAND QUANTITIES-------------------------

;;PWRNB IS AVG OVER CHNLS FOR EACH RCVR AND POL NSPECTRA
;USING THE LONG64 GIVES EXACT ANSWER BUT TO SAVE MEMORY WE DON'T DO IT...
;pwrnb= (total( long64(m1s[*,*,0:max( indxbreak)].data), 1) )/7679.d + timeoffset
pwrnb= (total( m1s.data, 1) )/7679.d + timeoffset

;PWRNB_AVG IS PWR FOR EACH COMBO OF CAL, LO, CYCLE AVGD OVER EACH
;       ONE'S ~10 CONTRIBS
pwrnb_avg= fltarr( 2,7,7,2,ncycs)
pwrnb_avg= reform( pwrnb_avg, 2,7, 7*2*ncycs)
idb= reform( indxbreak, 2, 7*2*ncycs)
for nr=0, 7*2*ncycs-1 do pwrnb_avg[ *,*,nr]= $
        total( pwrnb[*,*,idb[0,nr]:idb[1,nr]],3)/(idb[1,nr]-idb[0,nr]+1.0)
pwrnb_avg= reform( pwrnb_avg, 2, 7, 7, 2, ncycs)

;G_NB_AVG IS THE SPECTRUM FOR EACH COMBO OF CAL, LO, CYCLE AVGD OVER EACH
;       ONE'S ~10 CONTRIBS
g_nb_avg= fltarr( 7679, 2,7, 7*2*ncycs)
for nr=0, 7*2*ncycs-1 do g_nb_avg[ *,*,*,nr]= $
        total( long64(m1s[*,*,idb[0,nr]:idb[1,nr]].data),4)/(idb[1,nr]-idb[0,nr]+1.0) $
	+ timeoffset

;stop, 'LSFS1 -- NB END'

g_nb_avg= reform( g_nb_avg, 7679, 2, 7, 7, 2, ncycs)

return
end
