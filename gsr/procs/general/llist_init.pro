function llist_init, fcnl, lvar, i
;+
; NAME:
;   llist_init
; PURPOSE:
;   Initialized a linked list loop for speedy aggregation of unkown length
;   array in loop. Replaces var = [var, x]
;
; CALLING SEQUENCE:
;   result = llist_init(fcnl, lvar, i)
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
;   NONE
;
; MODIFICATION HISTORY:
;   Initial Documentation Wednesday, August 26, 2005
;   Joshua E. Goldston, goldston@astro.berkeley.edu
;-

pvar = {lvar:lvar, next:PTR_NEW()}
fcnl = {first:PTR_NEW(), current:PTR_NEW(), next:PTR_NEW(), last:PTR_NEW()}
i=0d
return, pvar
end

