pro plotmh, name,_EXTRA=ex, mht, noplot=noplot, mhtfile=mhtfile, cutoff=cutoff

;+
;set noplot to not plot
;set mhtfile to use specified mht file.
;if mhtfile is not set it writes '/share/galfa/josh/mhtfile.sav'
;ctbl is the colortable nr. default is 5
;if you plot, it sets decomposed to 0 and invokes setcolors
;-
                                                                                
if keyword_set(mhtfile) then begin
print, 'restoring ' + mhtfile
restore, mhtfile
endif else begin
                                                                                
names = file_search('/share/galfa/galfamh/', '*' + name + '*')
nn = n_elements(names)
print, 'restoring ' + string( nn) + ' mh files...'
restore, names[0]
pvar = llist_init(fcnl, mh[0], ii)
for k=0, n_elements(mh) -1 do llist_loop, fcnl, pvar, mh[k], ii
cr = string('15'OB)
for i=1, nn-1 do begin
     print, i, names[i], cr, format='($,I5,3x, a, A)'
;    print, 'restoring ' + names[i]
    restore, names[i]
;    mht = [mht, mh]
    for k=0, n_elements(mh)-1 do  llist_loop, fcnl, pvar, mh[k], ii
endfor
llist_read, fcnl, mh[0], mht, ii
objs = mht.object
objnum = fltarr(n_elements(mht))
ra_halfsec= mht.ra_halfsec
dec_halfsec= mht.dec_halfsec
print, 'finished restoring mh files;' 
                                                                                
endelse
if keyword_set(cutoff) then begin
    keepobj = fltarr(n_elements(objnames))
    for i=0, n_elements(objnames) -1 do keepobj[i] = n_elements(where(objnames[i] eq objs)) gt cutoff
    objnames = objnames(where(keepobj eq 1))
endif

print, 'Last object was ', objs[ n_elements( objs)-1]

cols = 55+ findgen(n_elements(objnames))/n_elements(objnames)*200.
nelname = fltarr(n_elements(objnames))

for j=0, n_elements(objnames)-1 do begin
    objnum(where(objs eq objnames[j])) =cols[j]
    nelname[j] = n_elements(where(objs eq objnames[j]))
endfor

if keyword_set( noplot) eq 0 then begin
device, decomposed=0
setcolors, /sys
plot, ra_halfsec, dec_halfsec, psym=3, /ynozero, _EXTRA=ex
for k=0, 6 do plots, ra_halfsec[k,*], dec_halfsec[k,*], psym=3, color=objnum
legend, objnames+string(nelname, format='(I7.0)'), psym=-3, color=cols
endif
                                                                                
if keyword_set(mhtfile) eq 0 then begin
  save, objs, objnames, objnum, ra_halfsec, dec_halfsec, $
  file='/share/galfa/mhtfile.sav'
print, 'wrote ', '/share/galfa/josh/mhtfile.sav'
endif



return
end
