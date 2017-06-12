pro fit_foureight, root, region, scans, proj, tdf=tdf, scannum=scannum

ind0 = 0
ind1 = scans-1

; if scannum set, just do scannum
if keyword_set(scannum) then begin
	ind0 = scannum
	ind1 = scannum
endif 


if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)' 

for l=ind0, ind1 do begin
	restore, root + '/' +  proj + '/' + region + '/' + region + '_'  + string(l, format=scnfmt) + '/foureight_'+ string(l, format=scnfmt) + '.sav'
                                ; the average spectrum, after zogains
                                ; and rxm, across all beams, for a
                                ; scan
        print, 'difference amplitude is ' + string(mx)
        print, 'The "diff" spectrum is shown below, and should be a single peaked triangle'
        plot, diff, title='SCAN = ' +string(l, f='(I3.3)')
        plots, ind, mx, psym=2
        print, 'We suggest you skip scans with difference amplitude < 0.01, as they are unlikely to have the foureight glitch'
        print, 'Would you like to fit for foureight correction? (L=no, R = yes)'
        !mouse.button=-1
        cursor, a, d, /up
	if !mouse.button eq 1 then continue
	avdiff = on-off
	avfit = fltarr(8192, 2, 7)
	restore, getenv('GSRPATH') + 'savfiles/one_xarr_six.sav'
	wgt0 = (on[*,0, 0] ne 0)*(off[*,0, 0] ne 0)
	wgt0 = rebin( wgt0, 8192) 
	wgt0[0:350] = 0
	wgt0[8192-350:*]=0
	for i=0, 1 do begin
		for j=0, 6 do begin
			print, 'POL ' + string(i, f=scnfmt) + ', BEAM' + string(j, f=scnfmt) + ' : Left click to select HI line bounds, middle click when you are done'
			blinter, rebin(avdiff[*, i, j], 8192), wgt0, x01, 'POL ' + string(i, f=scnfmt) + ', BEAM' + string(j, f=scnfmt), LRval, pfit
			avfit[*, i, j] = pfit		
		endfor
	endfor
        save, avfit, f=root + '/' +  proj + '/' + region + '/' + region + '_'  + string(l, format=scnfmt) + '/foureight_avfit_'+ string(l, format=scnfmt) + '.sav'
endfor


end
