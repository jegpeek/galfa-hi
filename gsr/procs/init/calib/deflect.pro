;+
; NAME:
;  DEFLECT
;
; PURPOSE:
;  To get rid of the effect of relections in the optical fibres 
;
; CALLING SEQUENCE:
;  deflect, data, refl=refl
;
; INPUTS:
;  data -- the baseline corrected but not doppler corrected data in
;          the [7679,2,7,N] format
;
; KEYWORD PARAMETERS:
;   refl -- The reflection structure
;
;
; OUTPUTS:
;
;
;
; OPTIONAL OUTPUTS:
;
;
;
; MODIFICATION HISTORY:
; Written dec 12 05, by Josh Goldston
; goldston@astro.berkeley.edu
;-


pro deflect, data, refl=refl

; size of data
sz  = size(data)
; limiting size of the data for a useful fit
nlim = 200.

if sz[4] gt nlim then begin
    refl = replicate({fcoeffs:fltarr(2), time:0., rmspect:fltarr(7679)}, 2, 7)
    dtot = total(data, 4)/sz[4]
    for j=0,1 do begin
        for i=0,6 do begin
            sp = dtot[*,j,i]
            frq = (dindgen(7679) -7679.d/2.d)*100.d/(14.*8192.)
            zapft,frq,sp,18,coeffs,sigcoeffs,yfit,residbad=3,yfit_fourier=yfit_fourier, times=times, fcoeffs=fcoeffs, deltat = deltat, sigtimes=sigtimes, yfit_poly=yfp
              ; for now we are going to use an amplitude cutoff to determine whether the fit is 
              ; at all reasonable
            nsp = sp - yfit_fourier-yfp
            stddevs=fltarr(20)
            for q=0, 19 do stddevs[q] = stddev(nsp[7679/20.*q: 7679/20.*(q+1)-1.])
            std = median(stddevs)
            amp = (fcoeffs[0]^2 + fcoeffs[1]^2)^0.5/std
            ;print, deltat/sigtimes 
            ;plot, frq, sp-yfp, yra=[-0.5,0.5], psym=3 
            ;oplot, frq, yfit_fourier,color=100
            
            if ((amp gt 0.15) and (deltat/sigtimes gt 50)) then begin
                print, deltat/sigtimes, amp
                !p.multi=[0,1,2]
                plot, frq, sp-yfp, yra=[-0.5,0.5], psym=3 
                oplot, frq, yfit_fourier,color=100
                xyouts, 2.0, 0.4, 'beam = ' + string(i, format='(I1.1)') + ' pol = ' +  string(j, format='(I1.1)')
                plot,  frq, sp-yfp-yfit_fourier, yra=[-0.5,0.5], psym=3 
                oplot, frq, yfit_fourier,color=100
                !p.multi=0.
                if amp gt 10. then  begin
                    print, 'large amplitude - ignoring this fit!'
                    times = times*0.
                    fcoeffs = fcoeffs*0.
                    yfit_fourier=yfit_fourier*0.
                endif
                refl[j,i].time = times
                refl[j,i].fcoeffs = fcoeffs
                refl[j,i].rmspect = yfit_fourier
                data[*,j,i,*] = reform(data[*,j,i,*]) - rebin(reform(refl[j,i].rmspect, 7679,1 ), 7679, sz[4])
            endif
            yfit=0.
            sigcoeffs=0.
            coeffs=0.
        endfor
    endfor
; if the file is too small to test, use a previous file's results
endif else begin

    print, 'this file too small - using previous files results'

    if keyword_set(refl) then data = data - rebin(reform(refl.rmspect, 7679,2,7, 1 ), 7679, 2, 7, sz[4]) else refl = replicate({fcoeffs:fltarr(2), time:0., rmspect: fltarr(7679)}, 2, 7)
      
        dtot = total(data, 4)/sz[4] 
endelse



end

