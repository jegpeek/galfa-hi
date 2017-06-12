pro linkdays, root, region, scans, proj, xday


path = root + proj + '/' + region + '/'
; reads in standard data files
restore, path + 'todarr.sav'     
restore, path + 'xing/xday.sav'

rng = fltarr(scans)
med = fltarr(scans)

for i=0, scans-1 do begin
	loop_bar, i, scans
	wh = where(mht.day eq i, ct)
	med[i] = median(mht[wh].dec_halfsec[0])
        ; finding if things are in drift.
	mars[i] = total(abs(med[i]-mht[wh].dec_halfsec[0]))/ct
endfor

; all drifts have mmax less than 1 degree
mmax = 1.

; all the drifts
whmars = where(mars lt mmax, ndr)

; ndr = # of days in drift
if ndr ne 0 then begin

;differences?
mdiff = fltarr(ndr, ndr)
mdrift = med[whmars]

mn = fltarr(ndr)
whmn = fltarr(ndr)

d1 = [0]
d2 = [0]
for i=0, ndr-1 do begin
	mask = fltarr(ndr)+1
	mask[i] = 0
	wh =  where(abs(mdrift*mask-mdrift[i]) lt 2/60., ct)
	if ct ne 0 then begin
		d1 = [d1, fltarr(ct)+whmars[i]]
		d2 = [d2, whmars[wh]]
	endif
endfor

d1 = d1[1:*]
d2 = d2[1:*]

nmat = n_elements(d1)

xdaylink = fltarr(ndr, ndr)

for i=0, nmat-1 do begin
	wh1 = where(mht.day eq d1[i])
	wh2 = where(mht.day eq d2[i])
	h1 = histogram(mht[wh1].ra_halfsec[0], min=0, max=24-1d-6, nbin=24*15.*60/5.)
	h2 = histogram(mht[wh2].ra_halfsec[0], min=0, max=24-1d-6, nbin=24*15.*60/5.)
	xdaylink[d1[i], d2[i]] = total(h2 < h1)
endfor

xdaylink = (xdaylink gt 10)*2.
for i=0, ndr-1 do begin
	for j=i, ndr-1 do begin
		xdaylink[j, i] = 0
	endfor
endfor

xday = xday + xdaylink

;save, xday, f=path + 'xing/xday.sav'

endif


end
