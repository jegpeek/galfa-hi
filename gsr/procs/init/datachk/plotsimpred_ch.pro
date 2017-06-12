pro plotsimpred_ch, csnb, cswb, csnbcont, cswbcont, rffrq_nb, rffrq_wb, $
	countyes, rffrq_wblsfs, rffrq_nblsfs, rffrq_wbm1, rffrq_nbm1, $
	yscl=yscl, dely=dely
;+
; NAME:
;PLOTSIMPRED_CH -- given SIPRED_CH OUTPUT, plot the spectra and print powers.
;
;CALLING SEQUENCE:
;simpred_ch, fitspath, lsfspath, fitsfile, lsfsfile, qckpath, $
;	csnb, cswb, csnbcont, cswbcont, rffrq_nb, rffrq_wb, $
;	saveall=saveall
;
;CALLING SEQUENCE
;plotsimpred_ch, csnb, cswb, csnbcont, cswbcont, rffrq_nb, rffrq_wb, countyes
;
; PURPOSE: plot avg spectra produced by simpred_ch. also print powers, etc.
;INPUTS:
;CSNB, CSWB, the nb and wideband spectra (baseline subtracted). units approx K
;CSNBCONT, CSWBCONT, the continuum levels. units approx K
;RFFRQ_NB, RFFRQ_WB, the freqs of the spectral chnls
;COUNTYES, the nr of spectra that went into the avgs
;
;OPTIONAL INPUT:
;YSCL, the y scale, e.g. 5 means 5 K. default is 5 K
;DELY, the offsets between spectra. default is 1.5 K
;-

if keyword_set( yscl) eq 0 then yscl=5
if keyword_set( dely) eq 0 then dely=1.5

yra= [-1, yscl + 14*dely]
csnb= reform( csnb, 7679, 14)
cswb= reform( cswb, 512, 14)
csnbcont= reform( csnbcont, 14)
cswbcont= reform( cswbcont, 14)

!p.multi=[0,2,1]

plot, rffrq_wb, cswb[*,0], /nodata, $
	/xsty, xtit= 'RF FREQ, WODEBAND', $
	yra=yra, /ysty, $
	ytit='KELVINS, OFFSETS ' + string(dely, format='(f2.4)')+ ' K'
for nr=0,13 do oplot, rffrq_wb, cswb[*,nr]+ nr*dely
oplot, rffrq_wb, total(cswb,2)/14.+ nr*dely, color=!red

plot, rffrq_nb, csnb[*,0], /nodata, $
	/xsty, xtit= 'RF FREQ, NARROWBAND', $
	yra=yra, /ysty, $
	ytit='KELVINS, OFFSETS ' + string(dely, format='(f2.4)')+ ' K'
for nr=0,13 do oplot, rffrq_nb, csnb[*,nr] + nr*dely
oplot, rffrq_nb, total(csnb,2)/14.+ nr*dely, color=!red

!p.multi=0

print, ''
rffrqdiff= rffrq_wblsfs-rffrq_wbm1
if abs( rffrqdiff gt 6.) then $
	for nr=0,4 do print, '******************** CAUTION ********************'
print, 'RF FRQ DIFF BETWEEN LSFS AND M1 IS ', rffrqdiff, ' MHz'
if abs( rffrqdiff gt 6.) then $
	for nr=0,4 do print, '******************** CAUTION ********************'

print, ''
print, 'THE RESULTS ARE AVG OF ', strtrim(string(countyes),2), ' SPECTRA'
print, 'IN THE PLOTS, RECEIVER NR INCREASES UPWARDS; RED IS AVG OF ALL RX'
print, ''

print, 'FOR THE 14 RX, THE WB AND NB POWERS ARE...'
for nr=0, 13 do print, nr, csnbcont[nr], cswbcont[nr]
print, '      avg', mean(csnbcont), mean(cswbcont)

;stop

return
end
