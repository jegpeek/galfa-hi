;+
;NAME:
;colorinfo - return info on current color setup.
;SYNTAX: colorinfo
;ARGS:
;DESCRIPTION:
;   Queries idl on the current color setup. Output sent to stdout.
;-
;
; commands to set:
;  device,direct=nbits
;  device,true_color=nbits
;  device,psuedo_color=nbits
;  device,decompoted=1,0
;  device,get_visual_depth=depth .. this will request a visual if none selected 
;
pro colorinfo,all=all,trantabl=trantbl,lut=lut,print=print
    if keyword_set(print) then all=1
	device,get_decomposed=decomp,get_visual_name=scrnvis
	device,translation=trantbl			; if shared color map.
	trantbl=reform(trantbl,n_elements(trantbl)/3,3)
	print,'Decomposed   :',decomp
	print,'scrnVisual   :',scrnvis
	print,'!d.N_colors  :',!d.n_colors
	print,'!d.table_size:',!d.table_size
	print,string(format='("foregroundInd:",z," hex")',!p.color)
	if keyword_set(all) then begin
		device,get_visual_depth=visdepth
		lut=lindgen(256,3)
		tvlct,lut,/get
		print,'vis_depth    ',visdepth
    endif
	if keyword_set(print) then begin
	 for i=0,255 do begin
	    lab=string(format=$
		'(i3,3i4," tr",3z9)',i,lut[i,*],trantbl[i,*])
	    print,lab
     endfor
	 endif

    return
end
