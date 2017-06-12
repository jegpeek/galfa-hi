pro apply_foureight, root, region, scans, proj,  tdf=tdf, scannum=scannum, undo=undo, eng=eng
if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)' 

; indices over which to loop

ind0 = 0
ind1 = scans-1

; if scannum set, just do scannum
if keyword_set(scannum) then begin
	ind0 = scannum
	ind1 = scannum
endif 

; now loop over all scans of interest
for l=ind0, ind1 do begin
	; search for the fit file
	avfile = file_search(root + '/' +  proj + '/' + region + '/' + region + '_'  + string(l, format=scnfmt) + '/','foureight_avfit_'+ string(l, format=scnfmt) + '.sav')
	; if it's not there, skip out
	if avfile eq '' then begin
		print, 'No foureight fitted spectrum file found for scan ' + string(l, f='(I3.3)')
		print, 'skipping...'
		continue
	endif
	; get rid of any "foureight_applied" variable
	blarg= temporary(foureight_applied)

	; read in the fit file
	restore, avfile
	; and the main foureight data file
	restore, root + '/' +  proj + '/' + region + '/' + region + '_'  + string(l, format=scnfmt) + '/'+'foureight_'+ string(l, format=scnfmt) + '.sav'
	; and the scan hdrs file
	restore, root + '/' +  proj + '/' + region + '/' + region + '_'  + string(l, format=scnfmt) + '/*hdrs*.sav'
	; if you applied the correction before, ABORT!!

	if n_elements(foureight_applied) eq 1 then begin
		if foureight_applied eq 1  and not (keyword_set(undo)) then begin
			print, 'youve already applied this correction, you turkey! Skipping scan' + string(l, f='(I3.3)')
			continue
		endif
		if foureight_applied eq 0  and (keyword_set(undo)) then begin
			print, 'youve havent applied this correction, you turkey! I cant undo it! Skipping scan' + string(l, f='(I3.3)')
			continue
		endif
	endif
	; find the first second of this data set
	utc0 = mh[0].utcstamp
	; and all the filenames
	ufns = fn[uniq(fn, sort(fn))]
	nufns = n_elements(ufns)
	for k=0, nufns-1 do begin
		loop_bar, k, nufns
		; read in the data
		data = readfits(strmid(ufns[k],0, strlen(ufns[k])-3)+'fits', hdr)
		; and get the size of the array
		szd = size(data)
		; restore the mh data
		restore, ufns[k]
		; find where we are in the phase as compared to utc0
		dutc = (mh.utcstamp- utc0 + ind + 1200) mod 1200
		; and which n1200 we are on
		n1200 = floor((mh.utcstamp- utc0)/1200.)
		; the seconds to correct ; could be none at all
		wh400 = where(dutc ge 0 and dutc lt 400, ct400)
		if keyword_set(eng) then stop
		if ct400 ne 0 then begin
			nwh = n1200[wh400[0]]
			whinfes = where(nwh eq fes, ison)
			if ison then begin
				if keyword_set(undo) then data[*, *, *, wh400] = data[*, *, *, wh400] + (rebin(reform(avfit, 8192, 2, 7, 1), 8192, 2, 7, szd[4]))[*, *, *, wh400] else data[*, *, *, wh400] = data[*, *, *, wh400] - (rebin(reform(avfit, 8192, 2, 7, 1), 8192, 2, 7, szd[4]))[*, *, *, wh400]
				writefits, strmid(ufns[k],0, strlen(ufns[k])-3)+'fits', data, hdr
			endif
		endif
	endfor	
		
	if keyword_set(undo) then foureight_applied =0 else foureight_applied =1 

	save, avfit, foureight_applied, f=avfile
endfor


end

