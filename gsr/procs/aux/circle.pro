
pro circle,size=size,thick=thick,fill=fill

;+
;
; CIRCLE
; A program to create a user-defined circle for psym=8 plotting.
;
; Call Sequence:
; CIRCLE [, SIZE = Value] [, THICK = Value] [, /FILL]
;
; Keywords:
; SIZE - Set equal to size of circle desired (relative to charsize 1).
;         Default 1.2.
; THICK - Set equal to desired thickness of circles (relative to 1).
;         Default 1.
; FILL - Set /FILL for filled circles.
;
; Katie Peek / January 2006
;
;-

; Deal with keywords.
if keyword_set(size) then r = size else r = 1.2
if ~keyword_set(thick) then thick=0
if ~keyword_set(fill) then fill=0

; Construct evenly-spaced x & y for circle.
theta = findgen(41)/40.*2*!pi
x = r*cos(theta)
y = r*sin(theta)

; Define symbol with USERSYM procedure.
usersym,x,y,fill=fill,thick=thick

end
