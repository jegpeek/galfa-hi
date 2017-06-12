pro dateinfo, mxx, juldayrange, mxindxrange, first, last, deltajulday

;+
;NAME:
;dateinfo -- from mxx structure array, print dates and juldays for beg, end
;
;CALLING SEQUENCE:
;DATEINFO, mxx, juldayrange
;
;INPUTS:
;	MXX, the array of structures
;	JULDAYRANGE, the range of relative jul days to cover
;	MXINDXRANGE, the range of index nrs to cover. overrides JULDAYRANGE
;
;OUTPUTS: 
;	FIRST, the first indx to plot
;	LAST, the last indx to plot
;
;-
nrdata= n_elements( mxx)

deltajulday= mxx.julstamp- mxx[ 0].julstamp
if keyword_set( mxindxrange) then begin
	first= mxindxrange[ 0]
	last= mxindxrange[ 1]
	goto, mxindxrange
endif

if n_elements( juldayrange) eq 0 then $
        jdrange= minmax( mxx.julstamp)- mxx.julstamp[ 0] $
        else jdrange= juldayrange
ndx= lindgen( nrdata)
indxmin= where( deltajulday ge jdrange[ 0], countmin)
if countmin eq 0 then first=0 else first= indxmin[ 0]
indxmax= where( deltajulday ge jdrange[ 1], countmax)
if countmax eq 0 then last=nrdata-1 else last= indxmax[0]-1

MXINDXRANGE:
;caldat, min( mxx[ 0].julstamp), mon0, day0, yr0
;caldat, max( mxx[ nrdata-1].julstamp), mon1, day1, yr1
caldat, min( mxx[ first].julstamp), mon0, day0, yr0
caldat, max( mxx[ last].julstamp), mon1, day1, yr1
datstring0= string(mon0, format='(2i2)') + '/' + $
        string(day0, format='(2i2)') + '/' + $
        string(yr0, format='(4i4)')
datstring1= string(mon1, format='(2i2)') + '/' + $
        string(day1, format='(2i2)') + '/' + $
        string(yr1, format='(4i4)')

print, 'begin and end julian days are ', $
	mxx[first].julstamp, mxx[last].julstamp
print, 'begin and end dates are mm/dd/yr = ', datstring0, ' - ', datstring1

return
end

