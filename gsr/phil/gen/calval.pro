;+
;NAME:
;calval - return the cal value for a given freq.
;
;SYNTAX:
;   istat=calval(freqReq,calData,calV,hybrid=hybrid,swappol=swappol)
;
;ARGS:
;    freqReq:  float     frequency in Mhz for cal
;    calData:  {calData} already input via calInpData()
;KEYWORDS:
;     hybrid:    if keyword set, then average the polA,polb values 
;               together (used when linear receivers are converted to circular
;               by a hybrid after the dewar).
;    swappol:   if set then swap the polA, polb calvalues in the calV array
;			    on return. This can be used to correct for the 
;				1320 hipass polarization cable switch or the use of 
;			    one of the xfer switches.
; alfapixnum:   if this is alfa data, then the pixel number (0 thru 6) of
;			    the alfa pixel to use. If the cal values are alfa data
;               and this is not specified, use pixel 0.
;
;RETURNS:
;      istat:  1 ok within range, 0 outside range used edge,-1 all zeros
;    calV[2]:  float array of [2] floats holding interpolated cal values for
;                    polA and polB. If this is alfa then the calV is 
;				     dimensioned 2,7  for the 7 pixels.
;
;DESCRIPTION:
;   Interpolate the cal value to the requested frequency. The calData 
;should have already been read in with calInpData. If the requested
;frequency is outside the data range, return the cal values at the
;edge (no extrapolation is done). The data is returned in an array
;of two values.
;
;   The normal way to get cal values is via corhcalval() or calget().
;They call this routine.
;
;SEE ALSO:corhcalval, calget, calinpdata.
;-
;history:
;5jul00 - added hybrid keyword
;
function calval,freqReq,calData,calV,hybrid=hybrid,swappol=swappol
;
;   on_error,1
	useAlfa=calData.rcvnum eq 17
    gotit=0
    eps=1e-4
    calV=(useAlfa)?fltarr(2,7):fltarr(2)
    if (calData.numFreq eq 1) then begin
        calV[0]=calData.calA[0]
        calV[1]=calData.calB[0]
        retstat=0
        if  abs(calData.freq[0]-freqReq) lt eps then restat=1
        goto,done
    endif
;
;   find all freq indices less than requested
;
    ila= where(((calData.freq-eps) le freqReq) and (calData.calA ne 0.),countla)
    ilb= where(((calData.freq-eps) le freqReq) and (calData.calB ne 0.),countlb)
;
;   find all the freq indices where freq > then requested freq
;
    iha= where(((calData.freq+eps) ge freqReq) and (calData.calA ne 0.),countha)
    ihb= where(((calData.freq+eps) ge freqReq) and (calData.calB ne 0.),counthb)

    retstatA=1
    if (countla le 0 ) or ( countha le 0) then begin
        retstatA=0
        case 1 of 
            countla gt 0: calV[0,*]=calData.calA[ila[countla-1],*];all < freqReq
            countha gt 0: calV[0,*]=calData.calA[iha[0],*]        ;all > freqReq
            else        : begin & calV[0]=0 & retStatA=-1 & end;no freq this cal
        endcase
    endif else begin
        il=ila[countla-1]
        ih=iha[0]
        dfrq=calData.freq[ih]-calData.freq[il]  ; dfreq between indices
;       print,"freq,il,ih,dfrq",freqReq,il,ih,dfrq
        if (dfrq lt eps) then begin             ; reqFreq matches measured
            calV[0,*]=calData.calA[il,*]
        endif else begin
            calV[0,*]=caldata.calA[il,*] + (calData.calA[ih,*] $
					- calData.calA[il,*])*(freqReq- calData.freq[il]) / dfrq
        endelse
    endelse
;
;   pol B
;
     retstatB=1
     if (countlb le 0 ) or ( counthb le 0) then begin
        retstatB=0
        case 1 of
            countlb gt 0: calV[1,*]=calData.calB[ilb[countlb-1],*]; all< freqReq
            counthb gt 0: calV[1,*]=calData.calB[ihb[0],*]        ; all> freqReq
            else        : begin & calV[1]=0 & retStatB=-1 & end;no freq this cal
        endcase
    endif else begin
        il=ilb[countlb-1]
        ih=ihb[0]
        dfrq=calData.freq[ih]-calData.freq[il]  ; dfreq between indices
        if (dfrq lt eps) then begin             ; reqFreq matches measured
            calV[1,*]=calData.calB[il,*]
        endif else begin
            calV[1,*]=caldata.calB[il,*] + $
				(calData.calB[ih,*] - calData.calB[il,*])*$
            (freqReq- calData.freq[il]) / dfrq
        endelse
    endelse
    retstat= retstatA < retstatB
done:
;
;    if hybrid active, average polA, polB
;
	if keyword_set(swappol) then begin
		calV=[calV[1],calV[0]]			;swap pols
	endif
    if keyword_set(hybrid) and (retstat ge 0) then begin 
        calV[0]=(calV[0]+calV[1]) * .5
        calV[1]=calV[0]
    endif

    return,retstat
end
