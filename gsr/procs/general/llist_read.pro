
pro llist_read, fcnl, lvar, arrvar, i
;+
; NAME:
;   llist_read
; PURPOSE:
;   Used to read out an linked list as generated with llist_loop. Also cleans up
;   heap variables
;
; CALLING SEQUENCE:
;   llist_read, fcnl, lvar, arrvar, i
;
; INPUTS:
;   FCNL - Arbitrary (initally empty) variable that passes the 'first',
;           'current', 'next' and 'last' pointers from program to program
;   LVAR - A blank variable in the form of the variable being aggregated, 
;          e.g. 0., fltarr(12) or {carl:fltarr(10), snez:'', josh:dblarr(3,3)}
;   I    - Arbitrary (initially empty) varible that passes iteration information
;          from program to program
; KEYWORDS:
;   NONE
;
; OUTPUTS:
;   ARRVAR - The final output array.
;
; MODIFICATION HISTORY:
;   Initial Documentation Wednesday, August 26, 2005
;   Joshua E. Goldston, goldston@astro.berkeley.edu
;-

;Free the dangling 'next' pointer at the end of the list. 
IF PTR_VALID(fcnl.next) THEN PTR_FREE, fcnl.next
 
arrvar = replicate(lvar, i)
fcnl.current = fcnl.first

for j=0d,i-1 do begin 
    arrvar[j] = (*fcnl.current).lvar
    fcnl.next = (*fcnl.current).next
    ptr_free, fcnl.current
    fcnl.current = fcnl.next
endfor

end
