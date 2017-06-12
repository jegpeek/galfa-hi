;*************************************************************************
; pntquery - query bitmasks from pnt header. functions input
;             pnt header and return 1,0 for true,false
;
;*************************************************************************
;+
;NAME:
;pnthgrmaster - return 1 if greg is master, 0 if ch master
;SYNTAX: istat=pnthgrmaster(pnthdr)  
;ARGS:
;       pnthdr:{hdrpnt}   .. pnt portion of header.
;RETURNS:
;       istat: int 1 if greg master, 0 if ch master
;EXAMPLE:
;   suppose we have a correlator data:
;   print,corget(lun,b)
;   istat=pnthgrmaster(b.b1.h.pnt)
;-  
function pnthgrmaster,pnthdr
    on_error,1
    istat=0
    if  (pnthdr.stat and '00200000'XL) ne 0 then istat=1
    return, istat
end
