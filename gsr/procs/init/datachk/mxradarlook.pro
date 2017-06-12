pro mxradarlook, mxxx, juldayrange, mxindxrange, abs_julian=abs_julian

;+
;NAME:
;mxradarlook -- look at radar analyses, mxx.radarwb and mxx.radarnb
;
;CALLING SEQUENCE
;mxradarlook, mxxx, juldayrange, [relative_julian]
;
;INPUTS:
;MXXX, the mx structure
;JULDAYRANGE, the plotting range in julian days.
;ABS_JULIAN, set if the plotting range is jul day instead of days 
;	from the first the beginning of the series.
;
;OUTPUTS: none
;
;ACTION: for wb and nb, plots largest periodic signal period versus
;the relative julian day number (julian day measured with 0 the earliest
;in the series)
;
;plots the receivers sequentially, waiting for a keystroke to do the
;next plot.
;
;if you want to stop plotting and return, hit a lowercase q
;-

indx= sort( mxxx.julstamp)
mxx= mxxx[indx]
nrdata= n_elements( mxx)

;DEAL WITH DATE INFO; PRINT IT...
dateinfo, mxx, juldayrange, mxindxrange, first, last, deltajulday

;LOOK AT RADAR PERIODS AND INTENSITIES...
!p.multi=[0,1,2]
!p.charsize=1.2

plotsym, 0, /fill
maxsymsize= 4.
symsizefctr= .05
ndx= findgen( n_elements( mxx))
for nr=0,13 do begin
plot, mxx.rxradarwb[0,nr], yra=[0,60],psym=2, /nodata, $  
        YTIT= 'PERIOD', xra=[first,last], /xsty, ysty=9, $ 
        xtit='MX INDEX NUMBER; WIDEBAND'
for nrp=0, n_elements( mxx)-1 do $
        plots, nrp,mxx[nrp].rxradarwb[0,nr], psym=8, $
        symsize=( (symsizefctr*mxx[nrp].rxradarwb[1,nr]) < maxsymsize)>0, $
	/data, noclip=0
axis, /yaxis, yra=[deltajulday[ first], deltajulday[ last]], /ysty, /save
oplot, deltajulday, color=!red
;axis, /yaxis, yra=jdrange, /ysty, /save, color=!red
oplot, deltajulday, color=!red

plot, mxx.rxradarnb[0,nr], yra=[0,60], psym=2, /nodata, $
        YTIT= 'PERIOD', xra=[first,last], /xsty, ysty=9, $ 
        xtit='MX INDEX NUMBER; NARROWBAND'
for nrp=0, n_elements( mxx)-1 do $
        plots, nrp,mxx[nrp].rxradarnb[0,nr], psym=8, $
        symsize=( (symsizefctr*mxx[nrp].rxradarnb[1,nr]) < maxsymsize)>0, $
	/data, noclip=0
axis, /yaxis, yra=[deltajulday[ first], deltajulday[ last]], /ysty, /save
oplot, deltajulday, color=!red
;axis, /yaxis, yra=jdrange, /ysty, /save, color=!red
oplot, deltajulday, color=!red
;plot, deltajulday, ytit= 'DELTA JULIAN DAY', xra=[first,last], /xsty, /ysty

xyouts, .5,.5, 'receiver number ' + strtrim(string(nr),2), $
        /norm, color=!green, align=.5

print, 'SYMSIZE PROPTO RADAR POWER. RX NR ', strtrim( string(nr),2), ' ; HIT ANY KEY TO PROCEED, Q TO QUIT'

print, 'plots for rcvr ', strtrim(string(nr),2), $
        '; hit any key for more, q to quit'
res=get_kbrd(1)
if res eq 'q' then break
if res eq 's' then stop

endfor

!p.multi=0
!p.charsize=0

return
end
