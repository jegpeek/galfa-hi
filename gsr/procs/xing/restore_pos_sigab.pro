pro restore_pos_sigab, root, region, scans, proj

filenames = file_search(root + proj + '/' + region + '/xing/', '*_f.sav*')

nf = n_elements(filenames)

for i=0, nf-1 do begin
	restore, filenames[i]
	wh = where(xfit.sigab[1] lt 0, ctneg)
	if ctneg gt 0 then begin
		print, 'there are ' + string(ctneg) + ' negatives in ' + filenames[i]
		xfit[wh].sigab[1] = (-1)*xfit[wh].sigab[1]
		save, xfit, appl_xing, file=filenames[i]
	endif
endfor

end

