function dilshod, method, fit, spectrum, mode

chnum = findgen(8192)

; modes of operation:
;   (1) take in a spectrum and some set of input parameters from fit and find the best fit results
;   (2) take in complete fit results and return a modified spectrum. If the supplied spectrum is
;       blank a returned spectrum will just be that which is added to the original to get the fixed
;       spectrum
;   (3) just return the name of the method
;   (4) just return the number of methods

nmeth = 2

if mode eq 4 then return, nmeth

case method of

0: begin
	; the name of the method
	name = 'Blanking'
	if mode eq 1 then return, 1
	if mode eq 2 then spectrum[fit[1]:fit[2]] = !values.f_nan
end

1: begin
	; the name of the method
	name = 'Gaussian'
	; if we want to find the fit parameters for a spectrum
	if mode eq 1 then begin		
		; run the fitting code
		parinfo= replicate({limited:fltarr(2), limits:fltarr(2)}, 5)
		parinfo[1].limited = 1.
		parinfo[1].limits[0] = chnum[fit[1]]
		parinfo[1].limits[1] = chnum[fit[2]]
		parinfo[2].limited[1] = 1.
		parinfo[2].limited[0] = 1.
		parinfo[2].limits[1] = abs((chnum[fit[2]] - chnum[fit[1]])/3.)
		parinfo[2].limits[0] = 0.
		fspec = mpfitpeak(chnum[fit[1]:fit[2]], spectrum[fit[1]:fit[2]], fparm, nterms=5, parinfo=parinfo, perror=perror)
		; save the fit values
		whf = where(finite([fspec, fparm]) eq 0, ctf)
		if ctf gt 0 then return, -1
		whp0 = where(perror eq 0, ct)
		if ct ne 0 then return, -1
		fit[3:7] = fparm
		return, 1
	endif
	if mode eq 2 then begin
		if n_elements(spectrum) ne 8192 then spectrum = fltarr(8192)
		; we ignore the offset and slope, as we don't want to remove those
		A = fit[3:5]
		u = (chnum[fit[1]:fit[2]] - A[1])/A[2]
		; the spectrum to remove, defined in mpfitpeak
		remspec = A[0]*exp(-0.5*u^2)
		; modify the spectrum by removing the gaussian
		spectrum[fit[1]:fit[2]] = spectrum[fit[1]:fit[2]] - remspec
		return, 1
	endif
	end
ELSE: begin
	; if you put in a method we don't have, we notify you.
	name = 'Undefined'
	print, 'Method selected is undefined'
	if mode eq 3 then return, name else return, (-1)
	end
ENDCASE
if mode eq 3 then return, name
end