pro findspiders, mx, indxstrt, indxstop, npatt

;+
;PURPOSE: given the array of structures mx in which there are spider
;calib scans, find the indices that mark the beginning and ends of each
;individual spider scan. 
;
;INPUTS: 
;	MX, the array of structures.
;
;OUTPUTS:
;	indxstrt, the array of beginning index nrs of the scans
;	indxstop, the arrray of ending index nrs of the scans.
;
;-


;DEFINE OUTPUT ARRAYS--ASSUME NEVER MORE THAN 300 SPIDERS SCANS IN MX...
indxstrt= lonarr( 300)
indxstop= lonarr( 300)

nrpatt=0
indx3=-1

;EACH SPIDER SCAN BEGINS WITH CAL ON. FIND THESE INDICES...
indxcalon= where( mx.mh.obsmode eq  'CAL     ' and $
		  mx.mh.obs_name eq 'ON      ', countcalon)
;EACH SPIDER SCAN ENDS AT THE END OF ONZA45. FIND THESE INDICES...
indxza45= where( mx.mh.obs_name eq   'ONZA45  ', countza45)

if (countcalon eq 0 or countza45 eq 0) then $
	stop, 'NO COMPLETE SPIDER SCANS HERE! STOPPING!!!'

;FIND THE TRANSITION POINTS...
;FIND WHERE WE HAVE TRANSITIONS TO INDXCALON...
indxcalon_chng= where( indxcalon ne shift(indxcalon,1) +1l)

;FIND WHERE WE HAVE TRANSITIONS AWAY FROM ONZA45...
indxza45_chng= where( indxza45 ne shift(indxza45,-1) -1l)

FOR NPATT=0, 299 DO BEGIN

indycalon_chng= where( indxcalon[ indxcalon_chng] ge indx3, countcalon_chng)
indyza45_chng= where( indxza45[ indxza45_chng] gt indx3, countza45_chng)

if (countcalon_chng eq 0 or countza45_chng eq 0) then BREAK

indxstrt[ npatt]= indxcalon[ indxcalon_chng[ min( indycalon_chng)]]
indxstop[ npatt]= indxza45[ indxza45_chng[ min( indyza45_chng)]]

;CHK CONTINUITY OF SOURCE NAME...
sourcenamestrt= mx[ indxstrt[ npatt]].mh.object
sourcenamestop= mx[ indxstop[ npatt]].mh.object
if (sourcenamestrt ne sourcenamestop) then print, npatt, '  SOURCE CHANGE!! 

indx3= indxstop[ npatt] 

print, 'pattern, indices: ', npatt, indxstrt[ npatt], indxstop[ npatt]
ENDFOR

indxstrt= indxstrt[ 0: npatt-1]
indxstop= indxstop[ 0: npatt-1]

END
