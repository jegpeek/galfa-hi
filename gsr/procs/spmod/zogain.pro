
;+
; NAME:
;   ZOGAIN
; PURPOSE:
;   To get zeroeth-order gain corrections without crossing points.
;
; CALLING SEQUENCE:
;  zogain, aggr, times, zogains, rxmultiplier, badrxfile=badrxfile
; INPUTS:
;   aggr -- the aggregate spectrum ,as generated by aggr.pro
;   times -- the day start times, as generate by gettimes.pro
;   
;   
; KEYWORD PARAMETERS:
;   badrxfile -- If you have your own file for bad receivers, put its
;                 full path here.
;
; OUTPUTS:
;  zogains -- The zeroeth order gains.
;  rxmultiplier -- a matrix that can be multiplied by the spectra to get rid
;                  bad receivers.
; old_zg -- a keyword to use the old-style zero-gains procedure.
;      Otherwise, use the proposal of KD.
; MODIFICATION HISTORY
;
;  Initial documentation, January 16, 2006
;  Narrowed the fitting area in spect_rat to 3072:5119 to avoid most of the RFI issues, March 14th, 2007
;  Added a fix to handle single-day scans, with non 4D aggr arrays;
;  JEGP 6/13/13
;  Joshua E. Goldston, goldston@astro.berkeley.edu
;-

pro zogain, aggr, times, zogains, rxmultiplier, badrxfile=badrxfile, old_zg=old_zg

sz = size(aggr)

if sz[0] eq 3 then begin
    aggr = reform(aggr, sz[1], sz[2], sz[3], 1)
    sz = size(aggr)
endif

allrxgood = fltarr(2,7, sz[4])
for k=0, sz[4]-1 do begin
    whichrx, times[k], rxgood, badrxfile=badrxfile
    allrxgood[*,*, k] = rxgood
endfor

; turn [1,1] and [0,1] into [1,1] and [0,2]
rxmultiplier = reform(rebin(reform((3- total(allrxgood, 1)), 1, 1, 7, sz[4]), 8192, 2, 7, sz[4])*rebin(reform(allrxgood, 1, 2, 7, sz[4]), 8192, 2, 7, sz[4]), 8192, 2, 7, sz[4]) 

overall = total(total(total(reform(aggr*rxmultiplier, 8192, 2, 7, sz[4]) , 4), 3), 2)/(14.*sz[4])

beam = total(aggr*rxmultiplier, 2)/2.
xaxis = findgen(8192)- 4096 + 0.5
zogains = fltarr(7, sz[4])
for k=0, sz[4]-1 do begin
    if not keyword_set(old_zg) then overall = (total(total(aggr*rxmultiplier, 2), 2)/(total(total(rxmultiplier, 2), 2)))[*, k]
    for i=0,6 do begin
        print, k, i
        if max(beam[3072:5119,i,k]) eq 0. then beam [3072:5119,i,k] = overall[3072:5119]
        spect_rat,  overall[3072:5119], beam[3072:5119,i,k], 3, a, b, sig_a_b, xaxis, /nozero
        zogains[i,k] = b
    endfor
endfor

end
