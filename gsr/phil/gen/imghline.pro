;+
;imghline : draw horizontal line on an image 
;SYNTAX: imghline,img,linind,dashlen,vlines,val
;ARGS:  
;   img[n,m] : float    image to display
;   linind[k]: int   vertical indices into img array for horizontal lines 
;                    (count from 0)
;   dashlen  : int  number of pixels for on dash. 2*dashlen needs to divide
;                   n.
;   vlines   : int  number of vertical lines for each dash. def:1
;   val      : float value to use for dash.
;   
pro imghline,img,linind,dashlen,vlines,val

if n_elements(vlines) eq 0 then vlines=1
if n_elements(val)    eq 0 then val=255
xl=(size(img))[1]
if n_elements(dashlen) eq 0 then dashlen=xl/(4)
xx=lindgen(vlines) - vlines/2
x=fltarr(xl)
x=reform(x,dashlen,2,xl/(dashlen*2))
x[*,0,*]=val
for i=0,n_elements(linind)-1 do begin
    for j=0,vlines-1 do begin
        k=xx[j]+linind[i]
        img[*,k]=x
    endfor
endfor
return
end
