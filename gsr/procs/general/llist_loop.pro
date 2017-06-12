pro llist_loop, fcnl, pvar, val, i
;+
; NAME:
;   llist_loop
; PURPOSE:
;   Used to increment a linked list, as initialized with llist_init.
;
; CALLING SEQUENCE:
;   llist_loop, fcnl, pvar, val, i
;
; INPUTS:
;   FCNL - Arbitrary (initally empty) variable that passes the 'first',
;           'current', 'next' and 'last' pointers from program to program
;   PVAR - A template structure, including a pointer and the varible in question. Yhe output of llist_init.  
;   VAL  - The actual value you wish to add the the linked list. Must be of the form
;          of lvar, the empty variable input the llist_init
;   I    - Arbitrary (initially empty) varible that passes iteration information
;          from program to program. Cannot be a variable that is incremented in the loop
;          in which llist_loop runs, or any other varaible.
;   
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

IF (not PTR_VALID(fcnl.first)) THEN BEGIN 
    fcnl.first = PTR_NEW(pvar)
    fcnl.current = fcnl.first 
ENDIF 
;Create a pointer to the fcnl.next list element. 
fcnl.next = PTR_NEW(pvar) 
    
;Set the lvar field of fcnl.current to the current variable. 
(*fcnl.current).lvar = val

;Set the next field of fcnl.current to the pointer to the next list element. 
(*fcnl.current).next = fcnl.next 
 
;Store the "current" pointer as the "last" pointer. 
fcnl.last = fcnl.current 
 
;Make the "next" pointer the "current" pointer. 
fcnl.current = fcnl.next 
i=i+1d
end
