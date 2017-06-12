pro adu_to_tsys, tcal, calon, caloff, adu, tsys, fctr

;+
;TURNS ADU INTO KELVINS FOR A SINGLE POWER CHANNEL
;INPUTS ARE:
;	TCAL: THE CAL VALUE.
;	CALON, the calon adu values
;	CALOFF, the caloff adu values
;	ADU, the array of adu values to turn into tsys
;
;OUTPUTS:
;	tsys, calibrated adu values (units kelvins)
;- 

fctr= tcal/(calon- caloff)
tsys= fctr* adu

return
end
