;+
;NAME:
;fitsin - fit to Asin(Nx-phi) where N=1 to 6.
;SYNTAX:result=fitsin(x,y,N)
;ARGS:
;       x  - independent var. (x values for fit). should already be in radians
;       y  - measured dependent variable.
;       N  - 1..6 .. integral  period to fit . 1 to 6.
;RETURN:
;   result[]: float
;            [0] constant coefficient
;            [1] amplitude
;            [2] phase in radians
;DESCRIPTION:
;   Do a linear least squares fit (svdfit) to a sin wave with integral
;values of the frequency (1 through 6 are allowable values). Return
;the coefficients of the fit.
;
;NOTES:   
; Asin(Nt-phi)= Asin(Nt)cos(phi) - Acos(Nt)sin(phi) =  Bsin(Nt) + Ccos(Nt)
;      B=Acos(phi)
;      C=-Asin(phi)
;    phi      = atan(sin(phi)/cos(phi))/ = atan(-c,b)
;    amplitude=sqrt(B^2+C^2)
; so the fit for B,C is linear.
;
; result from svd:
;  a[0] - constant
;  a[1] - sin coef
;  a[2] - cos coef
;-           
;  
function fitsin,x,y,N
;
;   could not seem to embed quote in the string 
    strn=string(format='(I0)',n)
    str="a=svdfit(x,y,3,function_name='fitsin"+strn+"',singular=sng)"
    sng=0
    z=execute(str)
    if z eq 0  then message,"couldn't compile request.. n can be 1..6 "
;
    if  sng ne 0 then  message,"svdfit returned singularity"
; go 0 to pi
    ph=(atan(-a[2],a[1]))
    if ph lt 0 then ph=ph+ 2*!pi
    amp=sqrt(a[1]*a[1]+a[2]*a[2])
    return,[a[0],amp,ph]
end
;
;   here are the function to evaluate
;
function fitsin1,x,m
    return,[[1.],[sin(x)],[cos(x)]]
end
function fitsin2,x,m
    return,[[1.],[sin(2.*x)],[cos(2.*x)]]
end
function fitsin3,x,m
    return,[[1.],[sin(3.*x)],[cos(3.*x)]]
end
function fitsin4,x,m
    return,[[1.],[sin(4.*x)],[cos(4.*x)]]
end
function fitsin5,x,m
    return,[[1.],[sin(5.*x)],[cos(5.*x)]]
end
function fitsin6,x,m
    return,[[1.],[sin(6.*x)],[cos(6.*x)]]
end
