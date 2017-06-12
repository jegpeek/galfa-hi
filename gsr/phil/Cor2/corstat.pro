;+
;NAME:
;corstat - compute mean,rms by sbc 
; 
;SYNTAX    : corstat=corstat(b,mask=mask,/print,/median)
;
;ARGS      :   
;      b[n]: {corget} correlator data
;KEYWORDS  :   
;      mask: {cormask}  Compute mean, rms within mask (see cormask).
;     print:            If set then output info to stdout.
;    median:            If set then use median rather than the mean.
;RETURNS   :
;corstat[n]: {corstat} stat info
;
;DESCRIPTION:
;   corstat computes the mean and rms by sbc for a correlator dataset. The
;input data b can be a single {corget} structure or an array of {corget}
;structures. The mean,avg will be computed for each record of b[n]. If
;a mask is provided then the mean and average will be computed within the
;non-zero elements of the mask (see cormask()). The same mask will be used
;for all records in b[n].
;   The returned data structure corstat consists of:
;  corstat.avg[2,8] the averages
;  corstat.rms[2,8] the rms's
;  corstat.fracMask[8]  fraction of the bandpass that the mask covered.
;                   a single mask is used for each board. 
;  corstat.p[2,8]   This will contain a 1 if pola, 2 if polB and 0 if this
;                   entry is not used.
;EXAMPLES:
;   Process a position switch scan then compute the rms and mean using a mask
;that the user defines.
;   istat=corposonoff(lun,b,t,cals,/sclcal,scan=scan)
;   cormask,b,mask
;   cstat=corstat(b,mask=mask,/print)
;-
;history:
function corstat,b,mask=mask,print=print,median=median
; 
;    on_error,2
    nrecs=n_elements(b)
    nbrds=n_tags(b)
    if nrecs eq 1 then begin
        cstat={corstat}
    endif else begin
        cstat=replicate({corstat},nrecs)
    endelse
;
;   loop over boards
;
    for i=0,nbrds-1 do begin
        nlags=b[0].(i).h.cor.lagsbcout
        nsbc =(b[0].(i).h.cor.numsbcout < 2)
        nmask=1
        if keyword_set(mask) then begin
            if (size(mask.(i)))[0] eq 1 then begin
                ind1=where(mask.(i) ne 0.,count1)
                count2=count1
            endif else  begin
                ind1=where(mask.(i)[*,0] ne 0.,count1)
                ind2=where(mask.(i)[*,1] ne 0.,count2)
                nmask=2
            endelse
        endif else begin
            ind1=lindgen(nlags)
            count1=nlags
            count2=count1
        endelse
        cstat.fractMask[i]=(count1+count2)*.5/(nlags*1.)
;
;   loop over sbc of board
;
        for j=0,nsbc-1 do begin
            cstat.p[j,i]=b[0].(i).p[j]
            for k=0,nrecs-1 do begin
                if (j eq 0) or (nmask eq 1) then begin
                    a=rms(b[k].(i).d[ind1,j],/quiet)
                    if keyword_set(median) then a[0]=median(b[k].(i).d[ind1,j])
                endif else begin
                    a=rms(b[k].(i).d[ind2,j],/quiet)
                    if keyword_set(median) then a[0]=median(b[k].(i).d[ind2,j])
                endelse
                cstat[k].avg[j,i]=a[0]
                cstat[k].rms[j,i]=a[1]
            endfor
        endfor
    endfor
;
;avg1a avg1b avg2a avg2b avg3a avg3b avg4a avg4b
;sbc1a   sbcNA    rms2a rms2b rms3a rms3b rms4a rms4b
;avgnnn ddd.dddd ddd.dddd ddd.dddd ddd.dddd ddd.dddd ddd.dddd ddd.dddd ddd.dddd
;rmsnnn ddd.dddd ddd.dddd ddd.dddd ddd.dddd ddd.dddd ddd.dddd ddd.dddd ddd.dddd
    if keyword_set(print) then begin 
        polar=[' ','A','B']
        lab='       '
        labM='maskFraction of bandpass:'
        for i=0,nbrds-1 do begin
            labM=labM + string(format='(f5.3," ")',cstat[0].fractMask[i])
            for j=0,1 do begin
                pol=polar[b[0].(i).p[j]]
                if pol ne ' ' then begin
                    lab=lab+ string(format='("  sbc",i1,A1,"  ")',i+1,pol)
                endif else begin
                    lab=lab + '         '
                endelse
            endfor
        endfor
        print,labM
        print,lab
        for i=0,nrecs-1 do begin
            labavg=string(format='("avg",i3," ",8(f9.4))',i+1,cstat[i].avg)
            rmsavg=string(format='("rms",i3," ",8(f9.4))',i+1,cstat[i].rms)
            print,labavg
            print,rmsavg
        endfor
    endif
    return,cstat 
end
