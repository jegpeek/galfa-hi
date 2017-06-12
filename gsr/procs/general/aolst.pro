function aolst, Time, Day, Mon, Year

;+
;gives lst in hours at arecibo given the AO standard time, day, mon, and year.
;
;CALLING SEQUENCE: aolst, time, day, mon, year
;
;INPUTS:
;	TIME, AO time in hours
;	DAY, number day of month 
;	MON, number month of year
;	YEAR, year 
;
;RETURNS: lst in hours.
;
;EXAMPLE:
;
;	get lst for 5 jun 2005 at 11:10 am
;
;	lsthours= aolst( ten( 11,10), 5, 6, 2005)
;HISTORY:
;        24 OCT 2006. MODIFIED longitude to easts longitude so it works
;with current goddard ct2lst. 
;-

obslong= -66.753000d0

ct2lst, lst, obslong, 4., time, day, mon, year

return, lst

end

