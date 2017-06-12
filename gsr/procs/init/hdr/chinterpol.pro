function chinterpol, v, x, u

;+
;purpose:
;prepare inputs for interpol.
;
;x is the array of input x values, v the input array of data values.
;interpol returns NaN when the first two values of x are identical
;
;here we test for that and cut the array size down when this happens.
;
;inputs:
;	v, the input vector of data values
;	x, tht input vector of x values
;	u, the vector of x values at which interpolated data values 
;are returned.
;-

;;stop

FOR NR=0l, N_ELEMENTS( X)/2l DO BEGIN
if x[0] ne x[1] then break
v= v[1:*]
x= x[1:*]
ENDFOR

return, interpol( v, x, u)

end
