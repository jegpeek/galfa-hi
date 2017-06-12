;+
;NAME:
;fisecmidhms3 - secs from midnite to hh:mm:ss
;SYNTAX: label=fisecmidhms3(secsMidnite,hour,min,sec,float=float)
;ARGS:
;   secsMidnite:    long  seconds from midnite to format.
;KEYWORD:
;	float:			if set then return secs at float
;
;RETURNS:
;   hour:   long    hour of day.
;    min:   long    minute of hour.
;    sec:   long    sec of hour.
;    lab:  string   formatted string: hh:mm:ss
;
;DESCRIPTION:
;   Convert seconds from midnight to hours, minutes, seconds and then
;return a formatted string hh:mm:ss. The 2 digit numbers are 0 filled to the
;left. If the input data is float/double, it is first converted to long.
;-
function fisecmidhms3 , secs,h,m,s,float=float
	
    i=long(secs)
    h=i/3600
    m =(i - (h*3600))/60
	if not keyword_set(float) then begin
 	   s =i   mod 60
   	   return,string(format='(i2.2,":",i2.2,":",i2.2)',h,m,s)
	endif else begin
 	   s =secs  mod 60
   	   return,string(format='(i2.2,":",i2.2,":",f5.2)',h,m,s)
	endelse
		
end
