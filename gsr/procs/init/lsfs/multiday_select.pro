pro multiday_select, fitsfiles, nr0, nr1

;+
;purpose: for a list of fits files with monotonically increasing dates and file
;nrs, select the groups that belong together for a given lsfs analysis.
;
;use the sequence number--when it no longer increasees monotincallyh,
;start a new group.
;-

res= strpos( fitsfiles[ 0], 'fits')
seqnrs= fix( strmid( fitsfiles, res-5,4))
diff= seqnrs-shift(seqnrs,-1)
indx= where( diff ne -1, count)

nr0= intarr( count)
nr1= intarr( count)

if count eq  0 then begin
nr0=0
nr1= n_elements( fitsfiles)-1
return
endif

nr0[ 0]= 0
nr1[ 0]= indx[ 0]

for nr=1, count-1 do begin
nr0[ nr]= indx[ nr-1]+1
nr1[ nr]= indx[ nr]
endfor

;stop
end
