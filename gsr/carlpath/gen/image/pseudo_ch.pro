pro pseudo_ch, colr

;+
;NAME:
;	PSEUDO_CH -- apply a slightly modified pseudo (psychologically uniform lightnesss) colortable
;
;PURPOSE:
;	Replace the pure pseudo colortable of IDL with our modified one,
;	which subtracts some red to give a little more green
;
;CALLING SEQUENCE:
;	PSEUDO_CH, colr
;
;INPUTS: none
;
;OUTPUTS: 
;	COLR, the 256 X 3 colortable
;
;SIDE EFFECTS:
;	redefines r_curr and r_orig (and the grn and blue counterparts),
;which are in the COLORS common block; and loads the new thing into IDL's
;colortable using TVLCT. 
;-

COMMON colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr

pseudo, 100, 100, 100, 100, 22.5, 0.68, colr
colr[*,0]= bytscl( colr[*,0], min=100,max=255)
r_orig = colr[*,0] & g_orig = colr[*,1] & b_orig=colr[*,2]
r_curr = r_orig & g_curr = g_orig & b_curr = b_orig
tvlct,r_orig,g_orig,b_orig

return
end
