;+
;NAME:
;coravg - average correlator records
;SYNTAX: bavg=coravg(binp,pol=pol,max=max,min=min,norm=norm)
;ARGS:   binp[]: {corget} input data
;KEYWORDS:
;       pol    : if set then average polarizations together
;       max    : return max of each channel rather than average
;       min    : return min of each channel rather than average
;       norm   : if set then normalize each returned sbc to a mean of 1
;                (used when making bandpass correction spectra).
;RETURNS:
;       bavg   : {corget} averaged data.    
;DESCRIPTION:
;  coravg() will average correlator data. It has 3 basic functions:
; 1. average multiple records in a array together.
; 2. compute the average of an accumulated record (output of coraccum)
;    After doing this, it will set the bavg.b1.accum value to be the
;    negative of what was there (so corplot does not get confused).
; 3. average polarizations. This can be done on a single record, or
;    data from steps 1 or 2 above.
;The data is returned in bavg.
;   Polarization averaging will average the two polarizations on all boards
;that have two polarization data. If polarizations are on separate correlator
;boards then the routine will average all boards that have the same setup: 
;nlags, freq, and bandwidth. It will not combine boards that have two 
;polarizations per board.
;
;   If polarization averaging is used then the following header fields will
;be modified.
;   b.(i).h.std.grptotrecs     to the number of boards returned
;   b.(i).h.std.grpcurrec      renumber 1..grptotrecs
;   b.(i).h.cor.numsbcout 2->1 for dual pol sbc
;   b.(i).h.cor.numbrdsused    to the number of returned brds after averaging.
;   b.(i).h.cor.numsbcout      to the number of returned sbc in each brd after
;                              averaging
;   b.(i).h.dop.freqoffsets    in case we reduce the number of boars from 
;                              pol averaging.
;
;   If binp contains multiple records then the max or min keyword can be
;used to return the max or minimum of each channel. This will not work
;on data from coraccum since the sum has already been performed.
;
;Example:
;  
;;  average polarizations:  
;
;   print,corget(lun,b)
;   bavg=coravg(b,/pol)
;;
;; average a scan and then average polarizations
;;
;   print,corinpscan(lun,b)
;   bavg=coravg(b,/pol)
;;
;;  average the data accumulated by coraccum
;;  then average polarizations
;;
;   print,corinpscan(lun,b)
;   coraccum,b,baccum,/new
;   print,corinpscan(lun,b)
;   coraccum,b,baccum
;   bavg=coravg(baccum,/pol)
;;
;; return max value from each channel
;;
;   print,corinpscan(lun,b)
;   bmax=coravg(b,/max)
;-
; history:
; 27may02 - added, min,max keywords to coravg
; 04jun02 - need to modify freq offsets in dop.frqoffsets if we
;           do pol averaging with 1 pol per board.
function coravg,b,pol=pol,max=max,min=min,norm=norm
;
;   see how many records are in b
;
    on_error,1
    nrec=n_elements(b)
    ntags=n_tags(b[0])
;
;   average records of array
;
    if nrec gt 1 then begin
        bavg=b[0]
        for i=0,ntags-1 do begin
            case 1 of 
              keyword_set(max) : begin  
                    for k=1,nrec-1 do begin
                        bavg.(i).d=bavg.(i).d > b[k].(i).d
                    endfor
                end
              keyword_set(min) : begin  
                    for k=1,nrec-1 do begin
                        bavg.(i).d=bavg.(i).d < b[k].(i).d
                    endfor
                end
              else : begin
                for j=0,bavg.(i).h.cor.numsbcout-1 do begin
                    bavg.(i).d[*,j]=total(b.(i).d[*,j],2)/(nrec*1.)
                endfor
              end
            endcase
        endfor
;
;   divide by accum count 
;
    endif else begin
        if b.b1.accum gt 0 then begin
            bavg=b
            for i=0,ntags-1 do begin
                scale=abs(bavg.(i).accum)
                bavg.(i).d=bavg.(i).d/scale
                bavg.(i).accum=-scale
            endfor
        endif else begin
            bavg=b
        endelse
    endelse
;
;   see if they want polarization averaging
;
    if not keyword_set(pol) then begin 
        if keyword_set(norm) then begin
           nbrds=n_tags(bavg[0])
           for i=0,nbrds-1 do begin
              for j=0,bavg.(i).h.cor.numsbcout-1 do begin
                  bavg.(i).d[*,j]= bavg.(i).d[*,j]/mean(bavg.(i).d[*,j])
              endfor
            endfor
        endif
        return,bavg
    endif
;
;
    brdsused=intarr(ntags)
    numsbckeep=0
    gooddata=intarr(4)
    singlepolconfig=[0,1,6,7]
    dualpolconfig  =[5,8,9]
    for i=0,ntags-1 do begin
        if brdsused[i] eq 0 then begin
;
;       2 pol 1 board, just average
;
            ind=where(bavg.(i).h.cor.lagconfig eq dualpolconfig,count)
            if count gt 0 then begin
                case 1 of 
                    keyword_set(max) : begin
                       bavg.(i).d[*,0]= bavg.(i).d[*,0]>bavg.(i).d[*,1]
                       end
                    keyword_set(min) : begin
                       bavg.(i).d[*,0]= bavg.(i).d[*,0]<bavg.(i).d[*,1]
                       end
                    else: bavg.(i).d[*,0]=total(bavg.(i).d,2)*.5
                endcase
                bavg.(i).p=[1,0]
                bavg.(i).h.cor.numsbcout=1
                brdsused[i]=1
                gooddata[i]=1
            endif else begin 
                ind=where(bavg.(i).h.cor.lagconfig eq singlepolconfig,count)
;
;               stokes or complex leave alone
;
                if count eq 0 then begin
                     brdsused[i]=1
                     gooddata[i]=1
                endif else begin
;
;       single pol, check for another pol that matches it..
;
                bw       =bavg.(i).h.cor.bwnum
                numlags  =bavg.(i).h.cor.lagsbcout
                frqoff   =bavg.(i).h.dop.freqoffsets[i]
                brdsused[i] =1
                gooddata[i]=1
                bavg.(i).p=[1,0]
                found=0
                for j=i+1,ntags-1 do begin
                    if (bw      eq bavg.(j).h.cor.bwnum)      and  $
                       (numlags eq bavg.(j).h.cor.lagsbcout) and  $
                       (frqoff  eq bavg.(j).h.dop.freqoffsets[j]) and  $
                       (brdsused[j] eq 0) then begin
                       case 1 of 
                        keyword_set(max) : bavg.(i).d= bavg.(i).d>bavg.(j).d
                        keyword_set(min) : bavg.(i).d= bavg.(i).d<bavg.(j).d
                        else: bavg.(i).d=bavg.(i).d + bavg.(j).d
                       endcase
                       found=found+1
                       brdsused[j]=1
                    endif
                endfor
                if (found gt 0) and (not keyword_set(min)) and $
                        (not keyword_set(max)) then $
                        bavg.(i).d=bavg.(i).d/(found+1.)
           endelse
           endelse
        endif
    endfor
;
;   now recreate structure with fewer entries..
;
    ind=where(gooddata eq 1,count)
    case count of
        1: begin
            i=ind[0]
            bret={b1:{h:bavg.(i).h,$
                      p:bavg.(i).p,$
                  accum:bavg.(i).accum,$
                      d:bavg.(i).d[*,0] }}
           end
        2: begin
            i1=ind[0]
            i2=ind[1]
            bret={b1:{h:bavg.(i1).h,$
                      p:bavg.(i1).p,$
                  accum:bavg.(i1).accum,$
                      d:bavg.(i1).d[*,0] },$
                  b2:{h:bavg.(i2).h,$
                      p:bavg.(i2).p,$
                  accum:bavg.(i2).accum,$
                      d:bavg.(i2).d[*,0] }}
           end
        3: begin
            i1=ind[0]
            i2=ind[1]
            i3=ind[2]
            bret={b1:{h:bavg.(i1).h,$
                      p:bavg.(i1).p,$
                  accum:bavg.(i1).accum,$
                      d:bavg.(i1).d[*,0] },$
                  b2:{h:bavg.(i2).h,$
                      p:bavg.(i2).p,$
                  accum:bavg.(i2).accum,$
                      d:bavg.(i2).d[*,0] },$
                  b3:{h:bavg.(i3).h,$
                      p:bavg.(i3).p,$
                  accum:bavg.(i3).accum,$
                      d:bavg.(i3).d[*,0] }}
            end
         4: begin
            i1=0&i2=1&i3=2&i4=3
            bret={b1:{h:bavg.(i1).h,$
                      p:bavg.(i1).p,$
                  accum:bavg.(i1).accum,$
                      d:bavg.(i1).d[*,0] },$
                  b2:{h:bavg.(i2).h,$
                      p:bavg.(i2).p,$
                  accum:bavg.(i2).accum,$
                      d:bavg.(i2).d[*,0] },$
                  b3:{h:bavg.(i3).h,$
                      p:bavg.(i3).p,$
                  accum:bavg.(i3).accum,$
                      d:bavg.(i3).d[*,0] },$
                  b4:{h:bavg.(i4).h,$
                      p:bavg.(i4).p,$
                  accum:bavg.(i4).accum,$
                      d:bavg.(i4).d[*,0] }}
            end
        endcase
;
;   clean up some header locations
;
;   each board has all 4 freqoffsets, if we moved boards around
;   (via ind) we need to also move these frequency offsets around
;   
    freqoffsets=bavg.b1.h.dop.freqoffsets
    freqoffsets[0:count-1]=freqoffsets[ind]
    nbrds=n_tags(bret[0])
    for i=0,nbrds-1 do begin
        bret.(i).h.std.grptotrecs=nbrds
        bret.(i).h.std.grpcurrec =i+1
        bret.(i).h.cor.numbrdsused =nbrds
        bret.(i).h.cor.numsbcout   =(size(bret[0].(i).d))[0]
        bret.(i).h.dop.freqoffsets=freqoffsets
        if keyword_set(norm) then begin
            for j=0,bret.(i).h.cor.numsbcout-1 do begin
                bret.(i).d[*,j]= bret.(i).d[*,j]/mean(bret.(i).d[*,j])
            endfor
        endif
    endfor
    return,bret
end
