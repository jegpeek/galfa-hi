;------------------------------------------------------------------------------
;flag - xvalues.. flag each x value with a veritcal dotted line.
;
pro flag,x,_extra=e
    len      =n_elements(x)
    for i=0L,len-1 do begin
        xx=[x[i],x[i]]
        oplot,xx,!y.crange,_extra=e
    endfor
    return
end
