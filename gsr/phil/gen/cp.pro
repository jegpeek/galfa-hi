;+
;NAME:
;cp - read cursor position after button press.
;
;SYNTAX: cp,x=x,y=y
;ARGS  : none
;KEYWORDS:
;	x  : float return x value here
;	y  : float return y value here
;EXAMPLE:
;   plot,findgen(100)
;   cp
;   .. user clicks left button at desired position on plot.
;   24.0208   23.2295   .. x,y positions printed out.
;
;NOTE:
;   If the window system is set so that the window focus follows the cursor, 
;then you must make sure that the cursor is in the idl input window before
;you enter the command cp. 
;-
pro cp,x=x,y=y

cursor,x,y
print,x,y
return
end
