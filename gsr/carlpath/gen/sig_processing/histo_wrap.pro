pro histo_wrap, x, min, max, nbins, bin_edges, bin_cntrs, hx

;+
;NAME:
;histo_wrap -- wrapper for histogram that returns the bin edges and centers
;
;PURPOSE: wrapper for histogram that returns the bin edges and centers
;**** NOTE FIXED INPUTS: MAX, MIN, NBINS ****** aviods the
;awkwardness of specifying binsize. 
;
;
;NOTE ALSO: if a point falls exactly on a bn boundary, it is put into
;the higher bin.  Thus, if you set MAX equal to the highest data value,
;there will be exactly one entry in the highest bin (assuming that only
;one data value has this maximum value). 
;
;CALLING SEQUENCE:
;	histo_wrap, x, min, max, nbins, bin_edges, bin_cntrs, hx
;
;INPUTS:
;	X, the input array
;	MIN, the min value of the right-hand bin edge in the histogram
;	MAX, the max value of the right-hand bin edge in the histogram
;	NBINS, the nr of bins in the histogram
;
;**************** IMPORTANT NOTE **********************************
;	if MAX is larger than the largest data value, there will be no
;entries in the last bin
;
;OUTPUTS
;	BIN_EDGES
;	BIN_CNTRS
;	HX, the histogram of the input array x
;-
;

dmin= double(min)
dmax= double(max)
;dx= double( x)

bin_edges= dmin+ (dmax-dmin)* (dindgen( nbins)/ ( nbins-1l))
bin_cntrs= dmin+ (dmax-dmin)* ( (dindgen( nbins)+0.5d)/ ( nbins-1l))
hx = histogram( x, nbins= nbins, min=dmin, max=dmax)

return
end
