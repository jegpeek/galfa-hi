pro mxfeedlook, mxxx, juldayrange, mxindxrange, abs_julian=abs_julian

;+
;NAME:
;mxfeedlook -- look at radar analyses, mxx.rmswb and mxx.rmsnb
;
;CALLING SEQUENCE
;mxfeedlook, mxxx, juldayrange, [relative_julian]
;
;INPUTS:
;MXXX, the mx structure
;JULDAYRANGE, the plotting range in julian days.
;MXINDXRANGE, the plotting range in mx index units; this overrides 
;	juldayrange if it is specified
;OPTIONAL INPUT
;ABS_JULIAN, set if the plotting range is jul day instead of days
;       from the first the beginning of the series.
;
;OUTPUTS: none
;
;ACTION: one color for each feed.
;if points appear in lower part they are ok with feedbad eq 0
;if points appear in upper part they are bad with feedbad eq 1
;ideally most of the upper part is black with only two rcvrs filled in.
;
;if you want to stop plotting and return, hit a lowercase q
;-

indx= sort( mxxx.julstamp)
mxx= mxxx[indx]
nrdata= n_elements( mxx)

;DEAL WITH DATE INFO; PRINT IT...
dateinfo, mxx, juldayrange, mxindxrange, first, last, deltajulday

;MAKE FEED PLOTFOR EACH RX...
!p.multi=[0,1,2]
!p.charsize=1.2
;pclrs= [!gray, !red, !green, !blue, !cyan, !magenta, !yellow]
pclrs= [!white, !red, !green, !blue, !cyan, !magenta, !yellow]

plot, mxx.feedbadnb[0], yra=[-.05,1.8], $
	ysty=8, ytit='UPPER IS BAD, LOWER IS GOOD', $ 
        xtit='MX INDEX NUMBER; WIDEBAND', xra=[first,last], /xsty, /nodata
for nr=0,6 do $   
	oplot, mxx.feedbadnb[nr]+ .1*nr, psym=4, color=pclrs[nr]
;axis, /yaxis, yra=minmax(deltajulday), /ysty, /save
axis, /yaxis, yra=[deltajulday[ first], deltajulday[ last]], /ysty, /save
oplot, deltajulday

plot, mxx.feedbadnb[0], yra=[-.05,1.8], $
	ysty=8, ytit='UPPER IS BAD, LOWER IS GOOD', $ 
        xtit='MX INDEX NUMBER; NARROWBAND', xra=[first,last], /xsty, /nodata
for nr=0,6 do $
	oplot, mxx.feedbadwb[nr]+ .1*nr, psym=4, color=pclrs[nr]
;axis, /yaxis, yra=minmax(deltajulday), /ysty, /save
axis, /yaxis, yra=[deltajulday[ first], deltajulday[ last]], /ysty, /save
oplot, deltajulday

!p.multi=0
!p.charsize=0

return
end
