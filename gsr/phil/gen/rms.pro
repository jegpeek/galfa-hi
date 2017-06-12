;+
;NAME:
;rms - compute the mean and standard deviation
;SYNTAX:  result=rms(x,quiet=quiet)
;  ARGS:
;     x[]  : array to compute rms
;KEYWORDS:
;     quiet: if set then don't print the rms,mean to stdout.    
;   
; RETURNS:
;     result[2]: result[0]=mean, result[1]= std deviation
; DESCTRIPTION:
;    compute the mean and standard deviation. Print the results to
; stdio, and return in result[2]
;-
function rms,x,quiet=quiet
	nx=n_elements(x)
	meanx=total(x,/double)/nx
	res=x-meanx
	var=total(res^2,/double)/(nx-1.0)
	stddev=sqrt(var)
    if not keyword_set(quiet) then print,"Mean:",meanx," stddev:",stddev
    return,[meanx,stddev]
end
