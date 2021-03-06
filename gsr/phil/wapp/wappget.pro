;+
;NAME:
;wappget - input wapp data
;SYNTAX: istat=wappget(lun,hdr,d,nrec=nrec,posrec=posrec,retpwr=retpwr,raw=raw,$
;                       han=han,avg=avg,lvlcor=lvlcor)
;ARGS:
;   lun:    long      logical unit number for file to read
;   hdr:    {wapphdr} wapp header user passes in (see wappgethdr)
;  d[] :    float     return data here   
;
;KEYWORDS:
;   nrec:   long    number of acfs/spectra to input
; posrec:   long    position to this spectra before reading(count from 1) 
;                   if posrec is not supplied (or equals 0) then no 
;                   positioning is done.
; retpwr:           if set then just return total power (0lags)
;                   d[npol,nrecs] where npol is 1 or 2 (ignore crosspol)
;    raw:           just return the data read from disc, no processing
;    han:           if set then hanning window before transforming.
;    avg:           if set and nrec is greater than 1, then average the data 
;                   before returning. This is done in the time domain so
;                   it can speed up the processing (since fewer ffts needed)
;   lvlc:           If set then do the level correction for the lags
;                   (for now it only works for 3 level)
;RETURNS:
;   istat: > 0 number of recs found
;          -1 illegal lag format found
;
;DESCRIPTION:
;   Input wapp data from the logical unit number LUN. The user must have
;already input the file header and stored it in the hdr variable (see 
;wappgethdr). By default the routine will read from the current position
;in the file. You can use the posrec keyword to position to a particular
;record in the file. By default 1 record (integration)  of data will be input.
;You can input multiple records using the nrec keyword.
;
;   For acf data the routine will remove the bias, normalize the acf,
;compute the spectral density (SPD), and then scale the SPD to the
;mean power in the acf/nlags. There is currently no 3 or nine level correction.
;
;   The  data is returned in the d array as float numbers. 
;It is dimensioned as d[nlags,npol,nrecs] where nrecs are just the consecutive
;spectra (or acfs'). 
;
;EXAMPLES:
;   file='/share/wapp25/adleo.wapp2.52803.049'
;   openr,lun,file,/get_lun
;   istat=wappgethdr(lun,hdr)
;   nrec=wappget(lun,d,nrec=50)         ; read 50 records
;;  d is now dimensioned:  d[128,2,50]   
;   nrec=wappget(lun,d,nrec=1000,/avg)  ; read in 1000 recs, average
;   d is now dimensioned:  d[128,2]  and is the average of 1000 samples
;
;NOTES:
;   Not all wapp modes are supported. Things that won't work:
;1. It does not correct for lagtruncation.
;2. spectral total power mode has not been checked out.
;3. in stokes mode, only the two auto correlations are returned.
;4. No level correction is done. 
;
;   Be careful with file positioning. The following will cause problems:
;
; istat=wappgethdr(lun,hdr)             ok
; nrec=wappget(lun,hdr,d,nrec=50)       ok
;
; rew,lun                               positioned at hdr not data..
;;  the line below returns bad data. It is positioned at the hdr, not
;;  the first record of data.
; nrec=wappget(lun,hdr,d,nrec=50)       bad data returned.
;
; In the above case use:
; rew,lun
; nrec=wappget(lun,hdr,d,nrec=50,posrec=1)
;-
;history
;11oct03 - add 9 level 0 lag correction
;03dec03 - see if the data needs to be swapped..
;31jan04 - if we ask for more record than are available, just return
;          the available recs
;04mar04 - if lag0 eq 0, don't process the fft
function wappget,lun,hdr,d,nrec=nrec,posrec=posrec,retpwr=retpwr,raw=raw,$
                 han=han,avg=avg,lvlcor=lvlcor
;     
;
;   some constants that belong in an include file
;   ADS_OPTM_3LEV=.6115059
;   ADS_OPTM_9LEV=.266916
;
    folding=hdr.obs_type_code eq 2
    search =hdr.obs_type_code eq 1
    deadTimeUsec=.34                ; wapp dead time on dump
    if n_elements(nrec) eq 0 then nrec=1
    doavg=( keyword_set(avg) and (nrec gt 1))
    if n_elements(retpwr) eq 0  then retpwr=0
    nlags=hdr.num_lags
    nifs=hdr.nifs
    stokes=nifs eq 4
    nbrds  = (hdr.isalfa)? 2:1
    nifsBrds= nifs*nbrds
    cmpspc=1
    levels=(hdr.level eq 1)? 3:9
    hansmooth=keyword_set(han)
;
;   allocate the input array type depending on the lagformat
;   need to work on the shift ..
;
    case hdr.lagformat of

        0: begin                ; unsigned int 16 bit
            inp=uintarr(nlags,nifsBrds*nrec)
            bytelen=2UL
           end

        1: begin                ; unsigned long 32 bit
            inp=ulonarr(nlags,nifsBrds*nrec)
            bytelen=4UL
           end

        2: begin                ; floats
             inp=fltarr(nlags,nifsBrds*nrec)
             bytelen=4UL
           end
        3: begin                ; unsigned long 32 bit
             inp=fltarr(nlags,nifsBrds*nrec)
             bytelen=4Ul
             cmpspc=0           ; already spectra
           end
        else: return,-1
    endcase
;
;   position in file: should really check the positioning..
;
    if keyword_set(posrec) then begin
        point_lun,lun,(hdr.byteOffData+ (posrec-1L)*bytelen*nlags*nifsBrds)
    endif
    point_lun,-lun,startpos  ; remember where we started    
;   
;   get the data
;
    on_ioerror,ioerr
    readu,lun,inp,transfer_count=nfound
ioerr: 
    recinp=nfound/(nifsBrds*nlags)
    if recinp ne nrec then begin
        point_lun,-lun,curpos
        byteInp = (curpos-startpos)
        if byteInp eq 0 then begin
            if eof(lun) then return,0
            return,-1
        endif
        recinp=byteInp/(nifsBrds*nlags*bytelen)
        point_lun,lun,startpos+(recinp*(nlags*nifsBrds)*bytelen)
        inp=inp[*,0:recinp*nifsBrds-1L]
    endif
;
;   swap and average if needed
;
    if hdr.needswap then  inp=swap_endian(inp)
    if doavg then begin
        inp=total(reform(inp,nlags,nifsBrds,recinp),3)/recinp
        recinp=1
    endif
        
    if keyword_set(raw) then begin
        d=inp
        return,recinp
    endif
;
;-------------------------------------------------------------------
; setups for wapp
;
; name:    level    numifs  stokes  bw   maxlags  sumPol  
; CH1LEV3   3       1         0     100  8192      0,1
; CH2LEV3   3       2         0     100  4096      0
; CH1LEV9   9       1         0     100  2048      0
; CH4LEV3P  3       4         1     100  2048      0
;
; CH1LEV3   3       1         0     50   16384     0,1
; CH2LEV3   3       2         0     50   8192      0
;
; CH1LEV9   9       1         0     50   4096      0,1
; CH2LEV9   9       2         0     50   2048      0
;
; CH4LEV3P  3       4         1     50   4096      0
; CH4LEV9P  9       4         1     50   4096      0
;-------------------------------------------------------------------
;    process the data.. 0 lag and then spectra
;
;  computing the bias..
;
;   The wapp clock is 100 Mhz. It always multiplies at this rate.
;   Lower bandwidths have a slower shift rate, but the multiply
;   rate is always 100 Mhz.
;
;   A 100 Mhz clock can give a max of 50Mhz bandwidth. For 100 Mhz
;   bandwidth you need to use interleaved mode. This ends up doubling
;   the bias since you combine two sets of correlations. oo,ee, eo,oe
;
;   The correlator does not read out the lowest bit of the accumulator
;   so we multiply by .5
;
;   If we sum polariztions, then the value increases by another factor
;   of 2.
;   If 9 level, then increase by 16.
;
    if retpwr or cmpspc then begin
        if search then begin ; search data
            bias=float(100. * (hdr.wapp_time-deadTimeUsec) * (hdr.sum+1.))*.5
        endif else begin        ; folded data, acf's
;
;   !!note if folded 9 level data has not been divided by 16. we need
;          to do it here..
            bias=0.D
        endelse
        if  hdr.bandwidth eq 100. then bias=bias*2.
        if  levels eq 9        then bias=bias*16.   
        if hansmooth then w=(hanning(nlags*2))[nlags:*]     
;
;       for now ignore cross correlations
;       create index for sbc to return 
;
        nifsreturn=nifs*nbrds
        if (stokes)  then begin
            nifsreturn=nifsreturn/2
            nsbcTot=nifsreturn*recinp
            indSbc=reform((lindgen(4,nbrds,recinp))[0:1,*,*],nsbcTot)
            lag0=reform(inp[0,indSbc]) - bias
        endif else begin    
            nsbcTot=nifsreturn*recinp
            indSbc=lindgen(nsbcTot)
            lag0=reform(inp[0,*],nsbcTot) - bias
        endelse
;
;   -->NOTE: I think the  folded data acf's have been scaled to:
;           for each lag , phase bin that is added in
;           acf[i]= [acf[i] - bias ] / bias
;           at the end:
;           acf[i]=acf[i]/numTimesBinIncremented
;
;           It does not look like the 3 or 9 level correction is done
;           and the 9 level data is not divided by 16 (it probably should
;           be. A bias = 0 for 9level will work if the times 16 has been 
;           removed.
;
        wappads,lag0,bias,(levels eq 9),ads,pwrratio
        if retpwr then begin
            d=reform(pwrratio,nifsreturn,recinp)
            return,recinp
        endif
;
;       see if we do the 3 level correction 
;

        if (keyword_set(lvlcor) and (levels eq 3)) then begin
            inp=cor3lvl(reform(inp[*,indsbc],nlags,nsbcTot),$
                    nlags,nsbcTot,bias,ads=ads,/double)
            stokes=0                ; we go rid of cross correl
            indSbc=lindgen(nsbcTot)
            lag0=lag0*0. + 1;           ; cor3lv normalized it  to 1
            bias=0.                     ; it's been removed
        endif
        d=fltarr(nlags,recinp*nifsreturn)
;
;           Scaling:
;               bias - remove the bias 
;               2     since zero extended
;               2*nlags  (scaling of fft)length used
;               divide lag0 to normalize to zero lag
;               pwrratio - to make it linear in power
;               y[0]=y[0]*.5 since factor of two above was for non zero lags
;                 
        fftscl=float(2.* (2.*nlags))/(lag0)*pwrratio ; fft scales by nlags, 
        acf=fltarr(nlags*2)             ; this zeroextends
        for i=0,nifsreturn*recinp-1 do begin
            if lag0[i] ne 0. then begin
                if hansmooth then begin
                    acf[0:nlags-1]=w*(inp[*,indSbc[i]]-bias)*fftscl[i] 
                endif else begin
                    acf[0:nlags-1]=  (inp[*,indSbc[i]]-bias)*fftscl[i] 
                endelse
                acf[0]=acf[0]*.5    ; correct for factor 2 on 0lag
                d[*,i]=(float(fft(acf)))[0:nlags-1]
            endif else begin
                d[*,i]=0.
            endelse
        endfor
    endif else begin
        nifsreturn=nifsBrds
        d=inp
    endelse

    if (nifsreturn gt 1) and ( not retpwr) then begin
            if recinp eq 1 then begin
                d=reform(d,nlags,nifsreturn,/overwrite)
            endif else begin
                d=reform(d,nlags,nifsreturn,recinp,/overwrite)
            endelse
    endif
    return,recinp
end
