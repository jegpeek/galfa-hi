;+ 
;NAME:
;ver -- change vertical scale for all plots.

;------------------------------------------------------------------------------
;ver - ymin, ymax  set min,max plotting range
;-

pro ver,ymin,ymax
	if N_PARAMS() eq 0 then  begin
		!y.range=0
		return
	endif
	!y.range=[ymin,ymax]
	return
end
