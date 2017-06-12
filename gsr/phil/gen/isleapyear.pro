;+
;NAME:
;isleapyear - check if year is a leap year.
;SYNTAX: istat=isleapyear(year)
; ARGS:   year: int/long 4 digit year
; Returns:
;         istat: int  0 if not a leap year.
;                     1 if  a leap year.
;DESCRIPTION:
; Determine whether a year is a leap year in the gregorian calendar.
; Leap years are those years 
;  divisible by 4 and (!(divisible by 100) or (divisible by 400)).
; eg. (1900 is not a leap year, 2000 is).
;-
function isleapyear,year
; 
    if (year mod 4  ) ne 0 then return,0
    if (year mod 100) ne 0 then return,1
    if (year mod 400) eq 0 then return,1
    return,0
end
