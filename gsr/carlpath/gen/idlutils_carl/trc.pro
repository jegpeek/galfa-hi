pro trc, data=data, device=device, normal=normal, noclip=noclip, _extra=_extra

;+
;name:
;TRC -- a wrapper for tim's full-screen cursos with carl's preferred features.
;keywords: data, device, normal, noclip

;for full documentation: doc_library, 'tr_rdplot'
;-

device, get_decomposed=decomposed_original

device, decomposed=1
setcolors, /system, /silent

tr_rdplot, /print, /full, color=!green, thick=3, data=data, device=device, $
	normal=normal, noclip=noclip, _extra=_extra

device, cursor_standard=46

device, decomposed=decomposed_original
setcolors, /system, /silent

return
end

