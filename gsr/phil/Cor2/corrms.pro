;+
;NAME:
;corrms - compute rms/Mean  by channel
;SYNTAX: brms=corrms(bin)
;ARGS:   bin[] : {corget} array of corget structures
;RETURNS:
;       brms : {corget} where brms.bN.d[] is now the rms/mean by channel.
;DESCRIPTION
;   The input bin should be an array of {corget} structures. corrms will
;compute the rms/Mean by channel for each frequency bin.
;if bin[] has 300 records with 2048 freq channels in brd 1 then:
;
; brms.b1.d[i]  is  rms(bin[0:299].b1.d[i])/mean(bin[0:299].b1.d[i]
;where the mean and rms is computed over the 300 records for each 
;frequency channel.
;-
function corrms,b,rembase=rembase
;
    on_error,2
    nbrds=b[0].b1.h.cor.numbrdsused
    npnts = (size(b))[1]
    c=b[0]
    ident=fltarr(npnts)+1.
    if keyword_set(rembase) then x=findgen(npnts)

    for i=0,nbrds-1 do begin
        lensbc=b[0].(i).h.cor.lagsbcout
        numsbc=b[0].(i).h.cor.numsbcout
        for j=0,numsbc-1 do begin
            bloc=''
            bloc=transpose(b.(i).d[*,j])
            if not keyword_set(rembase) then begin
;
;           compute mean,sdev for 1 sbc in 1 shot(hope we have enough mem)
;
                Mean=total(bloc,1,/double)/(npnts*1.)   ; avg over N time points
                sdev=sqrt(total((bloc - (ident#Mean))^2,1,/double)/(npnts -1.0))
                c.(i).d[*,j]=sdev/Mean   
            endif else begin
                for k=0,lensbc-1 do begin
                    aa=poly_fit(x,bloc[*,k],1,yfit)
                    a=(bloc[*,k]/yfit)*(yfit[npnts/2])
                    mean=total(a)/(npnts*1.)
                    sdev=sqrt(total((a- mean)^2)/(npnts-1.))
                    c.(i).d[k,j]=sdev/mean
                endfor
            endelse
            if (check_math() ne 0) then begin
          ind=where(finite(c.(i).d[*,j]) eq 0,count)
                   if (count gt 0) then c.(i).d[ind,j]=0.
            endif
        endfor
    endfor
    return,c
end
