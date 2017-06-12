pro mxrmslook, mxxx, juldayrange, mxindxrange, abs_julian=abs_julian

;+
;NAME:
;mxrmslook -- look at radar analyses, mxx.rmswb and mxx.rmsnb
;
;CALLING SEQUENCE
;mxrmslook, mxxx, juldayrange, [relative_julian]
;
;INPUTS:
;MXXX, the mx structure
;JULDAYRANGE, the plotting range in julian days.
;ABS_JULIAN, set if the plotting range is jul day instead of days
;       from the first the beginning of the series.
;
;OUTPUTS: none
;
;ACTION: for wb and nb, plots each receivers rms/mean power versus
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

;PLOT RMS RATIOS FOR EACH RX...
!p.multi=[0,1,2]
!p.charsize=1.2

FOR NR=0,13 DO BEGIN

plot, mxx.rmsratiowb[nr,*], yra=[0,.1], psym=1, ysty=8, $
	xtit='MX INDEX NUMBER; WIDEBAND', ytit='RMS/MEAN POWER', $
	xra=[first,last], symsize=.2, /xsty
axis, /yaxis, yra=[deltajulday[ first], deltajulday[ last]], $
	/ysty, /save, color=!red
;axis, /yaxis, yra=jdrange, /ysty, /save, color=!red
oplot, deltajulday, color=!red

plot, mxx.rmsrationb[nr,*], yra=[0,.1], psym=1, ysty=8, $
	xtit='MX INDEX NUMBER; NARROWBAND', ytit='RMS/MEAN POWER', $
	xra=[first,last], symsize=.2, /xsty
porig=!p
yorig=!y
;axis, /yaxis, yra=minmax(deltajulday), /ysty, /save, color=!red
axis, /yaxis, yra=[deltajulday[ first], deltajulday[ last]], $
	/ysty, /save, color=!red
;axis, /yaxis, yra=jdrange, /ysty, /save, color=!red
oplot, deltajulday, color=!red

xyouts, .5,.5, 'receiver number ' + strtrim(string(nr),2), $
	/norm, color=!green, align=.5
!p=porig
!y=yorig
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
