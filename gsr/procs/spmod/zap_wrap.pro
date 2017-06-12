pro zap_wrap, root, region, scans, proj, times, aggr, zapped, userrxfile=userrxfile

zapped = fltarr(8192, 2, 7, scans)
window, 0
print, 'Please rezise window to your liking and type ".cont" '
stop
for k=0, scans-1 do begin
    whichrx, times, rxgood, file=userrxfile
    
    !p.multi=[0,2,8]
    bad = 1.
    while (bad eq 1.) do begin
   
        for j=0,6 do begin
            for i=0,1 do begin 
                plot, aggr[*,i,j,k]- zapped[*,i,j,k], yra=[-1, 1], /xs
                if rxgood[i,j] eq 0 then xyouts, 1000, 0, 'BAD RX - NOT USED', charsize=min([!d.x_size/1280.*12.,!d.y_size/1000.*12.])-2. , charthick=min([!d.x_size/1280.*5.,!d.y_size/1000.*5.]), color=128
            endfor
        endfor
        plot, findgen(2), /nodata, xtickname=replicate(' ', 10), ytickname=replicate(' ', 10), xs=2, ys=2
        xyouts, 0.5, 0.3, 'Go to next day', charsize=min([!d.x_size/1280.*13.,!d.y_size/1000.*13.])-5., charthick=min([!d.x_size/1280.*5.,!d.y_size/1000.*5.]), alignment = 0.5, color=200.
        
        print, 'Click on region to fix (or go to next day)'
        cursor, x0, y0, /normal
        if (floor(y0*8) eq 0.) then bad = 0.
        wait, 0.2
        if (bad eq 1.) then begin
            x = x0 
            y = (y0 - 1./8.)*8./7.
            badpol = floor(x*2.)
            badbeam = floor((1.-y)*7)
            !p.multi=0.
            plots, [badpol, badpol+1, badpol+1, badpol, badpol]/2.,  (1- [badbeam+1, badbeam+1, badbeam, badbeam, badbeam+1.]/8.), /normal, color=128, thick=3.
            !p.multi=[0,2,8]
            badspectrum = reform(aggr[*,badpol,badbeam,k])
            mask = fltarr(8192)+1.
            mask(where(badspectrum eq 0)) = 0.
            frq = (dindgen(8192) -8192.d/2.d)*100.d/(14.*8192.)
; NOTE - this currently does not fit only the non-zeroed part of the spectrum
; and therefore does not remove the component completely. This is due to an 
; unresolved problem in zapft (e.g. zapcom.pro) - goldston dec 4, 2005
            zapft,frq(where(mask eq 1.)),badspectrum(where(mask eq 1.)),18,coeffs,sigcoeffs,yfit,residbad=3,yfit_fourier=yfit_fourier
            zspec = fltarr(8192)
            zspec(where(mask eq 1)) = yfit_fourier
            zapped[*, badpol, badbeam, k] = zspec
            yfit=0.
            sigcoeffs=0.
            coeffs=0.
        endif
    endwhile

endfor

print, 'All days corrected'

end
