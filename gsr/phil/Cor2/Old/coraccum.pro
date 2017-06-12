;+
;NAME:
;coraccum - accumulate a record in a summary rec
;SYNTAX: coraccum,binp,badd,new=new,scl=scl,array=array
;ARGS:   binp[]: {corget} input data
;          badd: {corget} accumulate data here
;KEYWORDS:
;       new    : if keyword set then this is the first call, alloc badd.
;       scl    : float if provided, then scale the brec data by scl before
;                      adding. This can be used to weight data by g/t.
;      array   : if set then treat badd as an array and add element wise
;                the array binp[n] to badd[n]. Use with the new keyword.
;                By default if badd is an array then binp will be added
;                element wise.
;DESCRIPTION:
;  Accumulate 1 or more records worth of data into badd. If keyword 
;/new is set then allocate badd before adding. The header values in 
;badd will come from the first record added into badd. 
;   The badd.b1.accum variable will be incremented by numrecs(binp)*scl for
;each call. When corplot is called, it will scale the data by 1./badd.b1.accum.
;   When calling coraccum with the new keyword, you can include the
;array keyword. This will allocate badd to be the same dimension of
;binp. All future calls using badd will add binp element wise to badd.
;
;Example:
;  
;   print,corget(lun,b)
;   coraccum,b,badd,/new
;   print,corget(lun,b)
;   coraccum,b,badd
;   corplot,badd
;
;; Add n scans together element wise:
;  for i=0,n-1 do begin
;       print,corinpscan(lun,b)
;       coraccum,b,bsum,new=(i eq 0),/array
;  endfor
;;
;; input an entire scan and then plot the average of the records
;; (this can also be done directly by corinpscan).
;   print,corinpscan(lun,b,scan=scan)
;   coraccum,b,bsum,/new
;   corplot,bsum
;
;
; help,badd.b1,/st
;** Structure <3957c8>, 4 tags, length=9200, refs=2:
;  H               STRUCT    -> HDR Array[1]
;  P               INT       Array[2]
; ACCUM           DOUBLE       2.00000
;  D               FLOAT     Array[1024, 2]
;-
pro coraccum,b,baccum,new=new,scl=scl,array=array
;
    on_error,1
	if n_elements(scl) eq 0 then scl=1.
    mult=1.
    if keyword_set(new) then begin
        if keyword_set(array) then begin
            baccum=b
        endif else begin
            baccum=b[0]
        endelse
        mult=0.             ; to zero it out
        for i=0,n_tags(baccum[0])-1 do begin
            baccum.(i).accum=0.
        endfor
    endif 
    numrecsinp=(size(b))[1]
    numrecsout=n_elements(baccum)
    outarray=0L
    if (numrecsout gt 1) then begin
        if (numrecsinp ne numrecsout) then $
            message,'array accumlation requires matching inp,accum dimensions'
        outarray=1L
    endif
    numbrds=n_tags(b)
   	for i=0,numrecsinp-1 do begin
		for j=0,numbrds-1 do begin
   	  		baccum[i*outarray].(j).d=baccum[i*outarray].(j).d*mult + $
					b[i].(j).d*scl
       	endfor
       	if outarray eq 0 then mult=1.
    endfor
    if outarray then begin 
    	inc=scl
    endif else begin
       	inc=scl*numrecsinp
    endelse
    for i=0,n_tags(baccum)-1 do baccum.(i).accum=baccum.(i).accum + inc
    return
end
