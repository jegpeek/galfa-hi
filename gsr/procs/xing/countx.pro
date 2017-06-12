function countx, root, region, scans, proj, tdf=tdf

matrix = fltarr(scans, scans)
if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)' 

for i=0, scans-1 do begin
	for j=i+1, scans-1 do begin
		if file_exists(root + proj + '/' + region + '/xing/' + region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '_f.sav') then begin
			restore, root + proj + '/' + region + '/xing/' + region + string(i, format=scnfmt) + '-'+  string(j, format=scnfmt)  + '_f.sav'	
			matrix[i, j] = n_elements(xfit)
		endif
	endfor
endfor

return, matrix

end