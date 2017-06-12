
pro rew,lun
	on_error,2
;
; 	check if this is a was data descriptro rather than
;   an lun
;
	a=size(lun)
	if (a[n_elements(a)-2] eq 8  ) then begin      
        lun.curpos=0L
	endif else begin
    	point_lun,lun,0
	endelse
    return
end
