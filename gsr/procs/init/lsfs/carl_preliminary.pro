pro carl_preliminary, sta_in, frq0a, indx0a, fnew, stamod, frq0amod, indxtot

;+
;PURPOSE: for lsfs data, generate the necessary arrays.
;
;INPUTS:
;	STA_IN[ nch, nlo], the input set of spectral powers with nch chnls, nlo
;lo frqs. 
;	FR0A[ nch, nlo], the input set of spectral freqs with nch chnls, nlo
;lo frqs. 
;	
;OUTPUTS:
;	INDX0A[ nch, nlo], the set of indices that define the frequencies in
;terms of the new frequency array FNEW.  That is, FNEW[ INDX0A] are equal
;to FRQ0AMOD (except possibly at ends of spectra where interpolation
;fails... 
;	FNEW [X*nch], defines a new frequenc axis that covers the full range of
;frequencies in FRQ0AMOD.  for example, if FRQ0A[*,0] covers a total
;range of 1 MHz, and the full range of all FRQ0A[*,*] is 1.4 MHz because
;the lo changes by a total of 0.4 MHz, then FEW spans 1.4 MHz and has
;1.4*nch elements. 
;	STAMOD, identical to STA_IN but interpolated in case the lo freq
;offsets don't fall on chnl centers... 
;	FRQ0AMOD, identical to FRQ0A but interpolated in case the lo freq
;offsets don't fall on chnl centers... 
;	INDXTOT, the nr of elements in fnew
;-

n736= (size( sta_in))[1]
nfsw= (size( sta_in))[2]

sta= sta_in

;CALCULATE THE FREQUENCY RANGE AT IF, AND ITS SHIFTED COUNTERPART...
delf= frq0a[ 1]- frq0a[ 0]  
frq_rng_total= n736* delf
frq_if= frq0a[ *,0]- frq0a[ n736/2-1,0]-delf
frq_if_shft= shift( frq_if, n736/2)


;INTERPOLATE FREQUENCIES ONTO A UNIFORM GRID (ORIGINAL FRQ OFFSETS NOT
;	AN INTEGRAL CHANNEL, UNFORTUNATELY)
fcntr= frq0a[ n736/2-1,1] 
fdiffneg= fcntr- min( frq0a)
fdiffpos= max( frq0a)- fcntr
indxneg= round(fdiffneg/ delf)
indxpos= round(fdiffpos/ delf)
indxtot= indxneg+ indxpos+ 1l
flow= fcntr- indxneg* delf
fnew= flow+ dindgen( indxtot)* delf
indx0a= round( (frq0a- fnew[ 0])/ delf)

frq0amod= 0.* frq0a
stamod= 0.* sta

FOR NF=0,NFSW-1 DO BEGIN
dx= indx0a[ 0,nf]
frac= (fnew[dx]- frq0a[0, nf])/delf
fmod= (1.- frac)* frq0a[*, nf]+ frac* shift( frq0a[*, nf], -1)
fmod[ n736- 1]= frq0a[ n736-1, nf]
smod= (1.- frac)* sta[*, nf]+ frac* shift( sta[*, nf], -1)
smod[ n736- 1]= sta[ n736-1, nf]
frq0amod[ *,nf]= fmod
stamod[ *,nf]= smod
ENDFOR

;AT THIS POINT, EVERYTHING IS ON A COMMON FREQUENCY GRID

sta= stamod
frq0a= frq0amod

return
end
