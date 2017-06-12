;+
;NAME:
;coraccumint - accumulate a record in a summary rec
;SYNTAX: coraccumint(brec,baccum,new=new,scl=scl)
;ARGS:   bnew  : {corget} input data
;        baccum: {corget} accumulate data here
;KEYWORDS:
;       new    : if keyword set then this is the first call, alloc baccum.
;       scl    : float if provided, then scale the brec data by scl before
;                      adding. This can be used to weight data by g/t.
;DESCRIPTION:
;  Accumulate a records worth of data in baccum. If keyword /new set then
;copy brec into baccum. This will be the header for the accumulated data.
;Example:
;   print,corget(lun,b)
;   print,coraccumint(b,baccum,/new)
;   print,corget(lun,b)
;   print,coraccumint(b,baccum)
;   ...
;   to plot the dat out you need to normalize the data to the number
;   of records accumulated.
;-
pro coraccumint,b,baccum,new=new,scl=scl
;
    if n_elements(scl) eq 0 then scl=1.
    mult=1.
    if keyword_set(new) then begin
        baccum=b
        mult=0.             ; to zero it out
    endif

    numin=(size(b))[1]
    numbrds=b.b1.h.cor.numbrdsused
    numpols=b.b1.h.cor.numbrdsused
    for j=0,numbrds-1 do begin
        baccum.(j).d= baccum.(j).d*mult + b.(j).d*scl
    endfor
    return
end
