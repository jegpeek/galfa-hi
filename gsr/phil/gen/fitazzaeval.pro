;+
;NAME:
;fitazzaeval - evaluate the fitazza fit at az,za positions.
;SYNTAX: val=fitazzaeval(az,za,fitI,azonly=azonly,zaonly=zaonly)
;ARGS:
;   az[n]   : float azimuth positions to evaluate fit.
;   za[n]   : float zenith angle positions to evaluate fit.
;  fitI     :{fitazza} fit info returned from fitazza.
;KEYWORDS:
;   azonly:   if set then only evaluate the az terms of the fit.
;   zaonly:   if set then only evaluate the za terms of the fit.
;DESCRIPTION:
;   fitazza() will do a fit to data points as a function of azimuth and
; zenith angle. This routine will allow you to evaluate that fit at
; any az,za you want. The azonly, zaonly keywords limit the evaluation
; to only the az or za terms of the fit.
;SEE ALSO:
; fitazza
;-
function fitazzaeval,az,za,fitI,azonly=azonly,zaonly=zaonly
    if n_elements(zaonly) eq 0 then zaonly=0
    zaonlyLoc=zaOnly
    case fiti.fittype of
;
;       (za-14)
             1: begin
             fza= fitI.coef[0] + fitI.coef[1]*za
            ind=where(za gt fitI.zaSet,count)
            if count gt 0 then begin
                zap=za[ind] - fitI.zaSet
                fza[ind]=fza[ind] + zap*zap*fitI.coef[2] +$
                        zap*zap*zap*fitI.coef[3]
            endif
        end
             4: begin
                fza= fitI.coef[0] + fitI.coef[1]*za
                ind=where(za gt fitI.zaSet,count)
                if count gt 0 then begin
                    zap=za[ind] - fitI.zaSet
                    fza[ind]=fza[ind] + zap*zap*fitI.coef[2] + $
                            zap*zap*zap*fitI.coef[3]
                endif
                zaonlyLoc=1
                end
;
;           (za-10)
;
             2: begin
            zap=za-fitI.zaSet
            fza= fitI.coef[0] + zap*(fitI.coef[1] + zap*(fitI.coef[2] +$
                    zap*fitI.coef[3]))
                end
             6: begin
            zap=za-fitI.zaSet
            fza= fitI.coef[0] + zap*(fitI.coef[1] + zap*(fitI.coef[2] +$
                    zap*fitI.coef[3]))
                zaonlyLoc=1
                end
;
;       chebyshev 3rd order in za
;
             3: begin
                zap=(za-fitI.zaSet)/fitI.zaSet
            fza= fitI.coef[0] + zap*fitI.coef[1] + $
                    (2.*zap*zap    -     1.)*fitI.coef[2]+ $
                    (4.*zap*zap*zap -3.*zap)*fitI.coef[3]
                end
;
;       (za)  with sin(za)*cos(3az)
             5: begin
                zap=za-fitI.zaSet
                fza= fitI.coef[0] + zap*(fitI.coef[1] + zap*(fitI.coef[2] +$
                    zap*fitI.coef[3]))
               end
          else: message,'fitazzaeval: fittype should be 1 thru 5'
    endcase
    if (zaonlyLoc) then return,fza

    azrd=!dtor*az
    if (fiti.fittype  eq 5 ) then begin
        sinza=sin(zap*!dtor)
     faz=   fitI.coef[4]*cos(   azrd)  + fitI.coef[5]*sin(   azrd) + $
        fitI.coef[6]*cos(3.*azrd)  + fitI.coef[7]*sin(3.*azrd) + $
        fitI.coef[8]*sinza*cos(3.*azrd)  + fitI.coef[9]*sinza*sin(3.*azrd) 
    endif else begin

     faz=   fitI.coef[4]*cos(   azrd)  + fitI.coef[5]*sin(   azrd) + $
        fitI.coef[6]*cos(2.*azrd)  + fitI.coef[7]*sin(2.*azrd) + $
        fitI.coef[8]*cos(3.*azrd)  + fitI.coef[9]*sin(3.*azrd) 
    endelse
    if keyword_set(azonly) then return,faz
    return,faz+fza
end
