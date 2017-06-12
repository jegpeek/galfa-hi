pro polycorr, ggwb, ggnb_7679, rffrq_wb, rffrq_nb, m1, $
	snb_c, swb_c, pnb_uc, pwb_uc, degree=degree

;+
;PURPOSE:
;	correct raw spectra for i.f. gains and subtract polynomials.
;INPUTS:
;   GGWB[512,14,2], the wb if bandpass. ggwb[chnls, nrprx, calonoff]
;   GGNB_7679[7679,14,2], the nb if bandpass. ggwb_7679[chnls, nrprx, calonoff]
;
;KEYWORD:
;	DEGREE, degree of polyfit. default = 8
;
;OUTPUTS:
;	SWB_C[ 512, 2, 7, nspectra]. the gain-corr, poly-removed wb spectra
;	SNB_C[ 7679, 2, 7, nspectra], the gain-corr, poly-removed nb spectra.
;	PWB_UC[ 2, 7, nspectra], the set of UNcorrected nb powers [2, 7, 600]
;	PNB_UC[ 2, 7, nspectra], the set of UNcorrected wb powers [2, 7, 600]
;(EXCEPTIION: THE DC SPIKE IN CHNL 256 IS INTERPOLATED OVER)
;       (power is the integral over the spectrum)
;
;-

if (keyword_set( degree) ne 1) then degree= 8

;add 2^31 or not?
offset= 0ll
if ( m1[ 0,0].g_time[ 0] lt 0ll) then offset= 2ll^31ll

;DEFINE OUTPUT ARRAYS...
nspectra= (size( m1))[2]
swb_c= fltarr( 512, 14, nspectra)
snb_c= fltarr( 7679, 14, nspectra)
pwb_uc= fltarr( 14, nspectra)
pnb_uc= fltarr( 14, nspectra)

;FIND FRQ RANGE AND INDICES THAT ARE COMMON TO BOTH WB AND NB SPECTRA...
indxwb= where( rffrq_wb gt min(rffrq_nb) and rffrq_wb lt max( rffrq_nb), $
        complement=indxwb_incl)
fwb= rffrq_wb[indxwb]
indxnb= where( rffrq_nb gt min(fwb) and rffrq_nb le max(fwb))
fnb= rffrq_nb[indxnb]

;CYCLE THRU ALL SPECTRA...
FOR NRPRX=0, 13 DO BEGIN
;WANT MEANS OF IF GAINS TO EQUAL 1, SO FORCE THAT ***BUT ONLY FOR CALOFF***
ggwb[ *, nrprx, 0]= ggwb[*, nrprx, 0]/ mean( ggwb[*, nrprx, 0])
ggnb_7679[ *, nrprx, 0]= ggnb_7679[*, nrprx, 0]/ mean( ggnb_7679[*, nrprx, 0])

FOR NSP= 0, NSPECTRA-1 DO BEGIN
;FOR NSP= 0, 0 DO BEGIN
spwb= float( m1[ nrprx, nsp].g_wide+ offset)
spnb= float( m1[ nrprx, nsp].data+ offset)

;INTERPOLATE OVER DC SPIKE IN WB...
spwb[ 256]= 0.5*( spwb[ 255]+ spwb[ 257])

;GET THE UNCORRECTED SPECTRAL INTEGRALS...
pnb_uc[ nrprx, nsp]= total( spnb)
pwb_uc[ nrprx, nsp]= total( spwb)

;CORRECT SPECTRA FOR BANDPASSES...
spwb_c= spwb/ ggwb[ *,nrprx,0]
spnb_c= spnb/ ggnb_7679[ *,nrprx,0]

;NORMALIZE WB POWER TO NB...
pwb= mean( spwb_c[ indxwb])
pnb= mean( spnb_c[ indxnb])
fctr= pnb/pwb
spwb_c= fctr* spwb_c
                                                                                
;WE WANT TO RETAIN THE INTEGRAL UNDER THE SPECTRUM AFTER SUBTRACTING
;THE POLYNOMIAL, SO CALCULATE THESE NOW FOR LATER USE...
mean_spwb_c= mean( spwb_c)
mean_spnb_c= mean( spnb_c)

;wset,4
;plot, rffrq_wb, spwb_c,xtit=nrprx, charsize=1.5
;oplot, rffrq_nb, spnb_c, color=red
;oplot, rffrq_wb[ indxwb], spwb_c[ indxwb],color=blue

;DO THE POLY FIT TO WB SPECTRUM...
degree=8
delrf= rffrq_wb- rffrq_wb[ 255]
polyfit, delrf[indxwb_incl], spwb_c[ indxwb_incl], degree, $
        coeffs, sigcoeffs, yfit

;APPLY COEFFICIENTS TO WB SPECTRUM...
rfpoly_wb= fltarr( 512)
for nr=0, degree do rfpoly_wb= rfpoly_wb+ coeffs[ nr]*delrf^nr

;oplot, rffrq_wb, rfpoly_wb, color=red, thick=2
;wset,2
;plot, rffrq_wb, spwb_c-rfpoly_wb, yra=2e5*[-1,1], xtit=nrprx, charsize=1.5
;res=get_kbrd( 1)
;if res eq 'q' then break
;print, nr

;APPLY COEFFICIENTS TO NB SPECTRUM...
rfpoly_nb= fltarr( 7679)
for nr=0, degree do rfpoly_nb= rfpoly_nb+ $
	coeffs[ nr]*( rffrq_nb- rffrq_wb[255])^nr

;wset,4
;plot, rffrq_nb, spnb_c
;oplot, rffrq_nb, rfpoly_nb, color=red, thick=2
;wset,2
;plot, rffrq_nb, spnb_c-rfpoly_nb, xtit=nrprx, charsize=1.5 ;;, yra=2e5*[-1,1]

;print, nrprx
;res=get_kbrd( 1)
;if res eq 'q' then break

swb_c[ *, nrprx, nsp]= spwb_c- rfpoly_wb+ mean_spwb_c
snb_c[ *, nrprx, nsp]= spnb_c- rfpoly_nb+ mean_spnb_c


ENDFOR
ENDFOR


end                                                                         

