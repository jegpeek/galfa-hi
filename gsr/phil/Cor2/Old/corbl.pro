;+
;NAME:
;corbl - baseline a correlator data set
; 
;SYNTAX:  istat=corbl(bdat,blfit,maskused,deg=deg,mask=mask,$
;                     edgefract=edgefract,auto=auto,sub=sub,svd=svd)
;ARGS:   
; bdat[n]:{corget}   input data to baseline. n can be >=1
;
;KEYWORDS :   
;      deg: int       user can pass in polynomial degree for fit.
;     mask: {cormask} user can pass in cormask structure to use for mask 
;                    (see cormask()).
;edgefract[n]: float The fraction of each edge of the bandpass to not use
;				  in the fit. if n=1 then use the same fraction for both
;				  sides. If n=2 then use [0] for the left edge and [1] for
;				  the right edge. If both mask= and edgefr=  are specified
;				  then mask= will be used.
;     auto:       if set then automatically do the baselining from the 
;                 user's input data, don't query the user for the parameters.
;     sub :       if set then return the data-blfit rather than the fit.
;     svd :       if set then use svdfit rather than poly_fit for the
;                 fitting. This works better for higher order polynomials
;                 but it is slower.
;RETURNS  :
; blfit[n]:{corget}  the baselined fits or bdat-bfit if /sub set.
; maskused:{cormask} the mask used for the fits.
;   istat : int      1 if all the fits done, 0 if one or more sbc not fit.
;
;DESCRIPTION:
;   corbl will baseline a correlator data set. bdat can be a single
;corget structure or an array of corget structures. By default the routine
;will interactively baseline the spectra for each correlator board. The user
;supplies the board, mask, and fit order from a menu.
;On exit, the routine will return the fit values in a corget structure. 
;If the /sub keyword is set then the difference bdat-bfit will be returned. 
;The mask that was used will be returned in maskused. If bdat is an array 
;then the averages will be used for the plotting (data and fits) but the 
;fits will be done separately for each record.
;
;   The auto keyword will do the fit without prompting the user. In this
;case you must enter the keywords:
; deg=   as the polynomial degree for fit. It will use the same for all boards.
;You must also specify the mask to use by passing in mask or setting
;edgefract to the fraction of the bandpass to ignore on each edge (the same
;value will be used for all boards).
;
;   For interactive use the program menu is:
;KEY  ARGS     FUNCTION
;m          .. define mask
;f    n     .. fit polynomial degree n
;h    h1 h2 .. change horizontal scale for plot to h1,h2
;v    v1 v2 .. change vertical  scale for plot to v1,v2
;b    brd   .. switch to board..1->nboards
;q          .. quit
;     current board:       1
; 
;     brdsLeftToDo: Brd1  Brd2  Brd3  Brd4 
;   The plots are color coded as:
;   White : first polarization of this board
;   Red   : 2nd polarization of this board (if there is one).
;   Green : fits to the data.
;   yellow: the mask that is used for the fit
;
;An example of using the program is:
;
;   print,corbl(bdat,bfit,/usesvd)
;
;1. Adjust the horizontal and vertical range of the plot with:
;    h  h1 h2
;    v  v1 v2
;
;2. define the mask for the current board:
;   m
;    then use the left button to start,stop a range and the left button to
;    quit.
;
;3. try fitting various orders to the data and mask:
;   f 3 
;   when the fit has been done, an extra line is output giving stats of the fit:
;     FitInfo  deg: 3 usesvd:1 mask%: 75.7 Rms: 0.0602  0.0581
;
;   We used a 3rd order fit, the mask is 75.7% of the entire range, and the
;   residual rms's are .06 and .058 in whatever units your spectrum is.
;   Trying a 7th order fit would give:
;   f 7
;     FitInfo  deg: 7 usesvd:1 mask%: 75.7 Rms: 0.0461  0.0455
;   Here the residuals have decreased to .046 .
;
;4. Move to another board:
;   b 3
;5. define the mask for this board then fit.    
;6. repeat for all boards. To exit enter q
;
;   If you do not used the /sub keyword, then the fits are returned. The
;baseline can then be removed using:
;
;   bldat=cormath(bdat,blfit,/sub) 
;
;   Idl has 2 polynomial fitting routines: poly_fit that uses matrix inversion
;and svdfit that uses singular value decomposition. poly_fit is faster while
;svdfit is more robust for larger order fits. The fits are done in double
;precision using the xrange 0. to 1.
;
;
;SEE ALSO: cormask, blmask (in general routines),cormath
;-
;history:
; 31aug02 started
; 01sep02 switched to svdfit to see if higher orders works better.
;
function corbl,bdat,blfit,maskused,edgefract=edgefract,deg=deg,auto=auto,$
                    sub=sub,mask=mask,svd=svd
; 
;    on_error,1
    a={finfo,   brd   :0        , $
                donefit: 0      , $ we've done fit at least once
                nsbc  :0        , $
                nlags :0        , $
                usesvd:0        , $
                deg   :0        , $ ; degree of fit
                rms   : dblarr(2), $ ; inside the mask residuals
                maskFract:    0.}   ;fraction of band used for fit
    
    nrecs=n_elements(bdat)
    bigErr=1e5                  ; measure error for mask.. vs 1.
    if nrecs gt 1 then begin
        bavg=coravg(bdat)
    endif else begin
        bavg=bdat
    endelse
    bavgfit=bavg
    blfit=bdat
    nbrds=n_tags(bavg)
    degloc=1
    if keyword_set(deg) then degloc=deg
    usesvd=0
    if keyword_set(svd) then usesvd=1
;
;   create the mask
;
    if keyword_set(mask) then begin
        maskused=mask
    endif else begin
        case nbrds of
            1 : maskused={b1:fltarr(bdat[0].b1.h.cor.lagsbcout)}
            2 : maskused={b1:fltarr(bdat[0].b1.h.cor.lagsbcout) ,$
                   b2:fltarr(bdat[0].b2.h.cor.lagsbcout)}
            3 : maskused={b1:fltarr(bdat[0].b1.h.cor.lagsbcout) ,$
                   b2:fltarr(bdat[0].b2.h.cor.lagsbcout) ,$ 
                   b3:fltarr(bdat[0].b3.h.cor.lagsbcout)}
            4 : maskused={b1:fltarr(bdat[0].b1.h.cor.lagsbcout) ,$
                   b2:fltarr(bdat[0].b2.h.cor.lagsbcout) ,$ 
                   b3:fltarr(bdat[0].b3.h.cor.lagsbcout) ,$ 
                   b4:fltarr(bdat[0].b4.h.cor.lagsbcout)}
        endcase
        if n_elements(edgefract)  ne 0 then begin 
			 edg1=edgefract[0]
			 edg2=edgefract[0]
		     if n_elements(edgefract) gt 1 then edg2=edgefract[1]
            for i=0,nbrds-1 do begin
                nlags=n_elements(maskused.(i))
                i1=((long(edg1*nlags+.5)) > 0) < (nlags/2-1)
				i2=((long(edg2*nlags+.5)) > 0) < (nlags/2-1)
				i2=nlags-i2-1
                if i1 le i2 then maskused.(i)[i1:i2]=1.
            endfor
        endif
    endelse
;
;    if they want auto processing, do it here
;
    if keyword_set(auto) then begin
        for ibrd=0,nbrds-1 do begin
            nlags=bavg.(ibrd).h.cor.lagsbcout
            nsbc =bavg.(ibrd).h.cor.numsbcout
            x=dindgen(nlags)/nlags 
            if !version.release gt '5.3' then begin 
                measure_errors=( -(maskused.(ibrd)-1.)*bigErr+1.D)
            endif else begin
                if usesvd then  begin
                    ignore=1.D/bigErr
                    weights=(maskused.(ibrd) > ignore)
                endif 
            endelse
            for isbc=0,nsbc-1 do begin
                for irec=0,nrecs-1 do begin
                     if (!version.release) le '5.3' then begin
                        if usesvd then begin
                        coef=svdfit(x,bdat[irec].(ibrd).d[*,isbc],degloc+1,$
                                weights=weights,yfit=yfit,/double)
                        endif else begin
                          coef=polyfitw(x,bdat[irec].(ibrd).d[*,isbc],$
                                maskused.(ibrd),degloc,yfit)
                        endelse
                    endif else begin
                        if usesvd then begin
                           coef=svdfit(x,bdat[irec].(ibrd).d[*,isbc],degloc+1,$
                              yfit=yfit,measure_errors=measure_errors,/double)
                        endif else begin
                            coef=poly_fit(x,bdat[irec].(ibrd).d[*,isbc],degloc,$
                              yfit=yfit,measure_errors=measure_errors,/double)
                        endelse
                    endelse
                    if keyword_set(sub) then begin
                        blfit[irec].(ibrd).d[*,isbc]=$
                            bdat[irec].(ibrd).d[*,isbc]-yfit    
                    endif else begin
                        blfit[irec].(ibrd).d[*,isbc]=yfit
                    endelse
                endfor
            endfor
        endfor
        return,1
    endif
;
;   They want to do interactive processin
;
    !p.multi=0
    !x.style=1
    !y.style=1
    ldcolph                     ; load the color map
    lnstyle=2
    colmask=5
    colfit =3
    colpol2=2
    brdsdone=intarr(nbrds)
    curbrd=0
    maskHght=.25
    newbrd=1
    maskCur=fltarr(4096)+1.
    brdsToDo=[' ',' ',' ',' ']
;
;    fill in fit info finfo array
;
    finfo=replicate({finfo},2,4)    ; 2sbc by 4 brds
    for i=0,nbrds-1 do begin
        brdsToDo[i]=string(format='("Brd",i1," ")',i+1)
        finfo[i].brd  = i+1
        finfo[i].nlags=bdat[0].(i).h.cor.lagsbcout
        finfo[i].nsbc =bdat[0].(i).h.cor.numsbcout
        finfo[i].usesvd=usesvd
        finfo[i].donefit=0
    endfor
    newfit=0                ; set to 1 after a new fit
    while 1 do begin
        if newbrd then begin
            nlags=finfo[curbrd].nlags
            nsbc =finfo[curbrd].nsbc
            x=dindgen(nlags)/nlags
            frq=corfrq(bavg.(curbrd).h)
            y =bavg.(curbrd).d[*,0]
            if nsbc gt 1 then y2=bavg.(curbrd).d[*,1]
            if finfo[curbrd].donefit then newfit=1
            newbrd=0
        endif
        if newfit then begin
            yfit=bavgfit.(curbrd).d[*,0]
            ind= where(maskused.(curbrd) ne 0)
            finfo[curbrd].donefit=1
            finfo[curbrd].maskFract=total(maskused.(curbrd)[ind])/(nlags*1.)
            finfo[curbrd].deg=degloc
            a=rms(yfit[ind]-bavg.(curbrd).d[ind,0],/quiet)
            finfo[curbrd].rms[0]=a[1]
            if nsbc gt 1 then begin
                    yfit2=bavgfit.(curbrd).d[*,1]
                    a=rms(yfit2[ind]-bavg.(curbrd).d[ind,1],/quiet)
                    finfo[curbrd].rms[1]=a[1]
            endif
            newfit=0
       endif
        plot,frq,y,_extra=e,/ystyle,/xstyle,title='current board:'+$
                string(curbrd+1)
        if nsbc gt 1 then oplot,frq,y2,color=colpol2    
        oplot,frq,maskused.(curbrd)*(!y.crange[1]-!y.crange[0])*maskHght + $
            !y.crange[0],_extra=e,color=colmask,linestyle=2
        if brdsdone[curbrd] then begin 
            oplot,frq,yfit,color=colfit,_extra=e
            if nsbc gt 1 then oplot,frq,yfit2,color=colfit,_extra=e
        endif
        if finfo[curbrd].donefit then begin
            labfi=string(format=$
'("     FitInfo  deg:",i2," usesvd:",i1," mask%:",f5.1," Rms:",f7.4," ",f7.4)',$
        finfo[curbrd].deg,finfo[curbrd].usesvd,finfo[curbrd].maskFract*100.,$
            finfo[curbrd].rms)
        endif else begin
            labfi=' '
        endelse
        
        print,' '
        print,'KEY  ARGS     FUNCTION'
        print,'m          .. define mask'
        print,'f    n     .. fit polynomial degree n'
        print,'h    h1 h2 .. change horizontal scale for plot to h1,h2'
        print,'v    v1 v2 .. change vertical  scale for plot to v1,v2'
        print,'b    brd   .. switch to board..1->nboards'
        print,'q          .. quit'
        print,'     current board:',curbrd+1
        print,labfi
        print,'     brdsLeftToDo:',brdsToDo
        line=' '
        read,'?',line
        line=strtrim(strlowcase(line),1)
        itemp=strpos(line,' ')
        len=strlen(line)
        if (itemp ne -1) and ((itemp+1) le len) then begin
            lineargs=strmid(line,itemp+1,len-(itemp))
        endif else begin
            lineargs=''
        endelse
;
        newboard=0
        case strmid(line,0,1) of
            'q': goto,done
            'm': begin
                 print,'use cursor to specify mask'
                 if nsbc gt 1 then begin
                    istat=blmask(x,y,maskCur,_extra=e,y2=y2)
                 endif else begin
                    istat=blmask(x,y,maskCur,_extra=e)
                 endelse
                 if istat eq 1 then maskused.(curbrd)=maskCur
                 end
            'h': begin
                  if lineargs ne '' then begin
                    reads,lineargs,h1,h2
                     hor,h1,h2
                 endif else begin
                     hor
                 endelse
                 end
            'v': begin
                  if lineargs ne '' then begin
                    reads,lineargs,v1,v2
                     ver,v1,v2
                 endif else begin
                     ver
                 endelse
                 end
            'b': begin
                  if lineargs ne '' then begin
                    reads,lineargs,i
                    if (i gt 0) and (i le nbrds) then begin
                        curbrd=i-1
                        newbrd=1
                    endif
                  endif
                end
            'f': begin
                 reads,lineargs,degloc
                 if !version.release gt '5.3' then begin
                    measure_errors=( -(maskused.(curbrd)-1.)*bigErr+1.D)
                 endif else begin
                    if usesvd then begin
                        ignore=1.D/bigErr
                        weights=(maskused.(curbrd) > ignore)
                    endif
                endelse
                 for isbc=0,nsbc-1 do begin
                    for irec=0,nrecs-1 do begin
                        if (!version.release) le '5.3' then begin
                             if usesvd then begin
                                coef=svdfit(x,bdat[irec].(curbrd).d[*,isbc],$
                                    degloc+1,weights=weights,yfit=yfit,/double)
                             endif else begin
                                coef=polyfitw(x,bdat[irec].(curbrd).d[*,isbc],$
                                    maskused.(curbrd),degloc,yfit)
                             endelse
                        endif else begin
                              if usesvd then begin
                                coef=svdfit(x,bdat[irec].(curbrd).d[*,isbc],$
                                    degloc+1,yfit=yfit,$
                                    measure_errors=measure_errors,/double)
                              endif else begin
                                 coef=poly_fit(x,bdat[irec].(curbrd).d[*,isbc],$
                                    degloc,yfit=yfit,$
                                  measure_errors=measure_errors,/double)
                              endelse
                        endelse
                        if keyword_set(sub) then begin
                            blfit[irec].(curbrd).d[*,isbc]=$
                            bdat[irec].(curbrd).d[*,isbc]-yfit
                        endif else begin
                            blfit[irec].(curbrd).d[*,isbc]=yfit
                        endelse
                    endfor
                endfor
                if nrecs gt 1 then begin
                    bavgfit=coravg(blfit)
                endif else begin
                    bavgfit=blfit
                endelse
                newfit=1            ; so it recomputes fit
                brdsToDo[curbrd]=' '
                brdsdone[curbrd]=1  
                end 
            else:print,'bad input.. enter:m,h,v,b, or q'
        endcase
botloop:
    endwhile
done:
    if total(brdsdone) eq nbrds then return,1
    return,0
end
