pro m1_to_m1s_s0, path, inputfiles, m1s, startndx=startndx

;+
;NAME
;m1_to_m1s_s0 - given a list of files, determine which contain SMARTF data
;
;PURPOSE: given a list of files some of which contain SMARTF, extract the 
;specific structures M1 that actually ARE SMARTF and return in structure M1S.
;
;NOTE: this does selection that should be done earlier in FIND_SMARTF.
;job for the future?
;
;CALLING SEQUENCE:
;m1_to_m1s_s0, path, inputfiles, m1s
;
;INPUTS:
;	path, the path to the data files
;	files, an array of datafile names
;
;OUTPUTS:
;	M1S, an array of M1 structures that are truly SMARTF.
;
;HISTORY:
;	28 may 2005 carl fixed a little bug. no longer needs 5 recs
;in the first file.
;
;	13oct05 carl added stuff to limit array sizes. in particlar,
;truncate long pperiod of SMARTF with CALON (which are at the end of 
;a SMARTF and things were just left 'on'). 
;	also, limit number of files to treat to 5. otherewise we
;run into memory problems. 
;
;********************************************************************
;*both of the above should be done in FIND_SMARTF instead of here,  *
;*	which wold be a lot quicker and more logical.              *
;*******************************************************************
;
;-

if keyword_set( startndx) eq 0 then startndx=0

;READ THE INPUT FILES AND CONCATENATE THE M1 STRUCTURES INTO M1S...
nrfiles= n_elements( inputfiles)

;KLUGE TO GET AROUND MEMORY PROBLEM. THIS SHOULD BE DONE IN FIND_SMARTF...
nrfiles= nrfiles < 5

FOR NRF= 0, NRFILES-1 DO BEGIN   ;;;nrf

;READ THE FITS FILE...
filenm = path+ inputfiles[ nrf]
print, 'input file is... ', filenm
m1= mrdfits(filenm,1,hdr1)

;IF NOT DEFINED YET, USE M1 FROM FITS FILE TO DEFINE M1S, THE 'OUTPUT' ARRAY...
;IF N_ELEMENTS( M1S) EQ 0 THEN BEGIN
IF NRF EQ 0 THEN BEGIN
m1= temporary( m1[ 14l*startndx:*])
m1s= replicate( m1[ 0], nrfiles* 14l* 600l)
indxm1s= 0l
ENDIF

indx_smartf= where( m1.obsmode eq 'SMARTF  ', count_smartf)
if ( count_smartf ne 0) then $
	m1s[ indxm1s:indxm1s+ count_smartf- 1l]= m1[ indx_smartf]
indxm1s= indxm1s+ count_smartf
                                                                                
ENDFOR				   ;;;nrf

FINISHED:

;TRIM THE M1S ARRAY TO SIZE...
;FIRST, TRIM THE CALON ELEMENTS AT THE BEGINNING BECAUSE THEY ARE NO GOOD...
;obs_name= reform(( reform( m1s.obs_name, 14, nrfiles*600l))[ 0,*])
;obsmode= reform(( reform( m1s.obsmode, 14, nrfiles*600l))[ 0,*])
obs_name= m1s.obs_name
obsmode= m1s.obsmode
indxstrt= where( strpos(obs_name, 'OFF') ne -1 and $
	strpos( obsmode, 'SMARTF') ne -1, countstrt)
IF COUNTSTRT EQ 0 THEN BEGIN
	m1s= m1s[0:13]
	return
ENDIF

;stop, 'm1_to_m1s..., 0'

;NEXT, IF THERE ARE MORE THAN 180*14 CONTIGUOUS CALON'S, TRUNCATE...
calon= fix(strpos(obs_name, 'ON') ne -1)
calon[ indxstrt[ 0]]= 0
calchange= calon- shift( calon,1)
calonstart= where( calchange[ indxstrt[ 0]+1:*] eq 1, countstart)+ indxstrt[ 0]+ 1l
calonend= where( calchange[ indxstrt[ 0]+1:*] eq -1, countend)+ indxstrt[ 0]
;calonstart= where( calchange[1:*] eq 1, countstart)
;calonend= where( calchange[1:*] eq -1, countend)

IF COUNTSTART NE 0 THEN BEGIN
if countend eq 0 then calonend= 14l*600l*nrfiles-1l else $
	if countstart gt countend then calonend= [calonend, 14l*600l*nrfiles-1l]
length= (calonend- calonstart)
indxlength= where( length gt 180l*14l, countlength)
if countlength ne 0 then indxm1s= calonstart[ indxlength[ 0]]+ 14l*180l
END

indxm1s= indxm1s - ( indxm1s mod 14)
m1s= temporary( m1s[ indxstrt[0]: indxm1s-1])
;m1s= temporary( m1s[ 14l*indxstrt[0]: indxm1s-1])
;m1s= temporary( m1s[ 0: indxm1s-1])

;BECAUSE THE LOFRQ TAKES LONGER TO CHANGE THAN THE OBSMODE, CHECK FOR THIS...
;BY ASSUMING THAT 5 SPECTRA AFTER SMARTF APPEARS THE LO IS THE PROPER VALUE.
indxnotsmart= where( m1s[ 0:5*14-1].g_lo1 eq m1s[ 5*14-1].g_lo1, countnotsmart)
IF (COUNTNOTSMART NE 5*14) THEN BEGIN
firstindx= indxnotsmart[ 0]
if (firstindx mod 14) ne 0 then firstindx= 14*((firstindx/14) + 1)
m1s= temporary( m1s[ firstindx:*])
print, 'countnotsmart, firstindx = ', countnotsmart, firstindx
ENDIF

return
end

