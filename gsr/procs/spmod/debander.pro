; a code to modify fpn files to deal with overall banding in the baseline ripple
; exceptscans -- an integer or array of integers of scans to ignore

pro debander, root, region, scans, project, spname, exceptscans=exceptscans

restore, root + project + '/' + region + '/spcor_' + spname + '.sav'

ndec = (size(fpn.(0).fpn))[3]
allav = fltarr(8192, ndec)
denom = n_tags(fpn)
if keyword_set(exceptscans) then denom = denom - n_elements(exceptscans)

for i=0, n_tags(fpn)-1 do begin
	if keyword_set(exceptscans) then begin
		whex = where(exceptscans eq i, ctex)
		if ctex ne 0 then continue
	endif
	; sins of the father... which is just me in the past #cries
	; the transpose of the .aggr tag, which is stupidly backward?
	traggr = transpose(fpn.(i).aggr, [0, 2, 1, 3])
	; it's size
	sz = size(traggr)
	; correct for zogains and rxmultiplier
	allaggr = total(traggr*rebin(reform(fpn.(i).rxg, 1, 2, 7, 1), sz[1], 2, 7, sz[4]), 2)*rebin(reform(fpn.(i).zgn, 1, 7, 1), sz[1], 7, sz[4])/2.
	; get rid of the overall average
	lessav = total(allaggr, 2)/7.-rebin(reform(fpn.(i).av, 8192, 1), 8192, ndec)
	; add em all up
	allav = allav+lessav/denom
endfor
avfit=allav*0
restore, getenv('GSRPATH') + 'savfiles/one_xarr_eight.sav'
for i=0, ndec-1 do begin
		print, 'Dec band ' + string(i, f=scnfmt) + ' : Left click to select HI line bounds, middle click when you are done'
		wgt0 = allav[*, i] ne 0
		wgt0[0:499] = 0
		wgt0[8192-500:*] =0
		blinter, allav[*, i], wgt0, x01, string(i, f=scnfmt), LRval, pfit
		avfit[*, i] = pfit
endfor

for i=0, n_tags(fpn)-1 do begin
	if keyword_set(exceptscans) then begin
		whex = where(exceptscans eq i, ctex)
		if ctex ne 0 then continue
	endif
	fpn.(i).fpn = fpn.(i).fpn + rebin(reform(avfit, 8192, 1, ndec), 8192, 7, ndec)
endfor

save, aggr, zogains, fpn, rxmultiplier, f=root + project + '/' + region + '/spcor_' + spname + '_db.sav'

end
