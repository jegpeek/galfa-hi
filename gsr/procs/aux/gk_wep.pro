;+
; NAME:
;  GK_WEP
;
; PURPOSE:
;  To remove a selection of tod data over a range of ra, dec, and channel number that meet some set of criteria.
;
;
; CALLING SEQUENCE:
; pro gk_wep, raminmax, decminmax, chminmax, todarr, spblfile
; INPUTS:
;   RAMINMAX -- A 2-element array specifying the upper and lower bounds to the effect in RA  
;   DECMINMAX -- Same in dec.
;   CHMINMAX -- Same in channel number. Remember that channel number in data cubes is in velocity order
;               but in tod, where we are specifying, is in frequency order!
;   TODARR -- Either the MHT structure, or the full path to the todarr.sav file that contains it
;   SPBLFILE -- The name of the spbl file to write to with full path
; OPTIONAL INPUTS:
;    NONE.
;
; KEYWORD PARAMETERS:
;   BADRXFILE -- Any badrx file to use with full path
; MODIFICATION HISTORY:
;  Inital documentation Februrary 16th, 2012, JEGP

pro gk_wep, raminmax, decminmax, chminmax, todarr, spblfile, badrxfile=badrxfile

; restore the file if it's not already a structure
if n_elements(todarr) eq 1 then restore, todarr else mht = todarr

;where the data are in the range of interest. Note that we are just
; looking at beam 0 here, so there will be some 'fuzziness' at the edges
wh = where((mht.ra_halfsec[0]*15. gt raminmax[0]) and (mht.ra_halfsec[0]*15. lt raminmax[1]) and (mht.dec_halfsec[0] gt decminmax[0]) and (mht.dec_halfsec[0] le decminmax[1]), ct)

; the cube to store all the TOD of interest, over the channel range of interest
speccube = fltarr(chminmax[1]-chminmax[0]+1, 2, 7, ct)

; The UTCs for each second of interest
autcs = lonarr(ct)

; list of the filenames of interest
allfiles = mht[wh].fn

; same, but the unique list
ufiles = allfiles(uniq( allfiles, sort(allfiles)))

; the number of unique file names
nuf = n_elements(ufiles)

; initializing a dummy variable
q=0.
for i=0, nuf-1 do begin
	; to visually keep track of the process of file reading
	loop_bar, i, nuf
	; the list of seconds that are in this file
	whsec =where(allfiles eq ufiles[i], ctsec)
	; read in the mh file
	restore, ufiles[i]
	; a blank index list, one for each second
	whsmh = fltarr(ctsec)
	; fill in this list, creating a list of seconds to pull from the TOD file
	for j=0, ctsec-1 do whsmh[j] = where(mh.utcstamp eq mht[wh[whsec[j]]].utcstamp)
	; read in the data file, but only take the specified seconds
	data = (gsrfits(ufiles[i], /savname))[*, *, *, whsmh]
	; runt the standard badrx fixing, by overwriting bad polarizations with good ones
	if keyword_set(badrxfile) then begin
		whichrx, mh[0].UTCSTAMP, goodrx, badrxfile=badrxfile
		fixrx, data, goodrx
		data = reform(data)
	endif	
	; fill in the UTCs
	autcs[q:q+ctsec-1] = mh[whsmh].utcstamp
	; and fill in the spectra into the big data array
	speccube[*, *, *, q:q+ctsec-1]= data[chminmax[0]:chminmax[1], *, *, *]
	; update the dummy variable
	q = q+ctsec
endfor

; shape and size of the speccube array
sz = float(size(speccube))

; build a blank cube with the fitting information. There are 20 available slots for fitting parameters,
; but in practice we only use a few
fits = fltarr(20, sz[2], sz[3], sz[4])

; initialize the fitting parameters as inputs
fits[0, *, *, *] = 1
fits[1, *, *, *] = chminmax[0]
fits[2, *, *, *] = chminmax[1]
;for each polarization 
for i=0, sz[2]-1 do begin
	; beam
	for j=0, sz[3]-1 do begin
		; and second
		for k=0, sz[4]-1 do begin
			; make a blank spectrum
			sp = fltarr(8192)
			; with the spectral chunk of interest put into it
			sp[chminmax[0]:chminmax[1]] = speccube[*,i,j,k]
			; and extract the fit input parameters
			ft = fits[*, i, j, k]
			; run the gaussian fit
			ds = dilshod(1, ft, sp, 1)
			; and store the results in the fits array
			fits[*, i, j, k] = ft
		endfor
	endfor
endfor

; now, make a copy of the fits array in a [20 x long] format
rf = reform(fits, 20, sz[2]*sz[3]*sz[4])

; here's where the magic happens: select some subset of the points based on whatever you choose.
; in this case, I have chosen a sub region in the amplitude [3], center [4], and width [5] Gaussian
; space, but one could use any information here. If you want access to all the mh information, you would
; have to have concatenated it in the first loop: line 52 or so.
wh = where((rf[4, *] lt 5859) and (rf[4, *] gt 5723) and (rf[3, *] gt 0.55) and (rf[3, *] lt 5) and (rf[5, *] lt 104) and (rf[5, *] gt 45))
; a stop, so you can fuck around if you like. Type ".cont" to get started again
stop

; set these parameters to 0 so that the blanker knows to eliminate these data, rather than removing a Gaussian 
rf[0, *] = 0.
rf[3:*, *] = 0.

; I am using various functions of wh here to extract the second, beam number and pol number. 
; There are other less short handed ways of doing this, but I hope this makes sense.
edspblanks, spblfile, autcs[wh/(2*7)], wh/2. mod 7, wh mod 2, rf[*, wh]

end