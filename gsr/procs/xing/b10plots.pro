restore, 'gau1.sav'
restore, 'gau2.sav'
; make the plots from Begum et al 2010
plot=5
ps =0
;f1
; sky positions plot (?) ra vs. dec. 
if plot eq 1 then begin
if ps eq 1 then psopen, 'f1', /encapsulated, /helvetica
if ps eq 1 then psclose
endif


;f5
; three panels: histograms of angular size, V_LSR, Tpk
if plot eq 5 then begin
if ps eq 1 then psopen, 'f5', /encapsulated, /helvetica
!p.multi=[0,3,1]
loadct, 0
remargin, 3, 10, 3, mgns
      plothist, [gau1.size, gau2.size]*180./!pi*60., xhist, yhist, /NOPLOT, /AUTOBIN
      make_poly_hist, xhist, yhist, px, py
      !x.margin=mgns[*, 0]
      plot, px, py, /nodata
      polyfill, px, py, color=100
  !x.margin=mgns[*, 1]
      plot, px, py, /nodata
      polyfill, px, py, color=100
  !x.margin=mgns[*, 1]
      plot, px, py, /nodata
      polyfill, px, py, color=100

if ps eq 1 then psclose

endif

;f7
;histogram of the ratio of the abolsute difference between the
;velocities of the two components divided by fwhm
if plot eq 7 then begin
if ps eq 1 then psopen, 'f7', /encapsulated, /helvetica
if ps eq 1 then psclose

endif

;f8
; 3 histograms: fwhm, n_hi, kinetic T
if plot eq 8 then begin
if ps eq 1 then psopen, 'f8', /encapsulated, /helvetica
if ps eq 1 then psclose
endif

;f9
; scatter plot: central velocity vs. fwhm; crosses for 1 comp, triangle
; for narrow, square for broad
if plot eq 9 then begin
if ps eq 1 then psopen, 'f9', /encapsulated, /helvetica
if ps eq 1 then psclose
endif

;f10
; 2 histograms: volume density, log pressure
if plot eq 10 then begin
if ps eq 1 then psopen, 'f10', /encapsulated, /helvetica
if ps eq 1 then psclose
endif

;f13
; 2 histograms: HI mass, virial mass
if plot eq 13 then begin
if ps eq 1 then psopen, 'f13', /encapsulated, /helvetica
if ps eq 1 then psclose
endif

; histogram: virial to HI mass


end
