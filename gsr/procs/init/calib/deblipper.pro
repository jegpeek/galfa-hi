;+
; NAME:
;  DEBLIPPER
;
;
; PURPOSE:
;  To remove spectrally compact signals repeating on a 12 second timescale
;
;
; CALLING SEQUENCE:
;  deblipper, data
;
;
; INPUTS:
;  data -- a [7679, 2, 7, N] spectral array, where N is the number of seconds
;
;
; OPTIONAL INPUTS:
;
;
; KEYWORD PARAMETERS:
;
;
; MODIFICATION HISTORY:
;
;-


pro deblipper, data

; OK, So first we need to decide if the data are big enough to deblip:

sz = size(data)
min_len = 100.

if sz[4] gt min_len then begin
    
; deblippos has three functions: determine whether the blips are detectable in this data set
; and if so, find the first second upon which they start and the best choice for a central channel
; perhaps to within 50 channels or so. If there is no detectable signal to remove, returns s1 = -1, ch=0

deblip_pos, data, s1, ch, nc

if s1 ne -1 then begin
    
; given the data, the first second and the central channel, the deblip_slist returns a [2,7,sz[4]] array
; of the amplitudes of the blips in K. seconds in which there are no blips have amplitude = 0

deblip_slist, data, s1, ch, nc, slist, bl_data

; this code takes in the various parameters and makes a spectrum of the blip to be removed

deblip_makesp, data, s1, slist, sp, bl_data, wblp, offx

; given the spectrum and amplitudes, this code does the final step of fitting out the spectrum
; and returning a cleaned data set

deblip_clean, data, slist, sp, offx


endif
endif

end
