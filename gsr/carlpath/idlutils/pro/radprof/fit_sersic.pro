;+
; NAME:
;   fit_sersic
;
; PURPOSE:
;
; CALLING SEQUENCE:
;
; INPUTS:
;
; OPTIONAL INPUTS:
;
; OUTPUTS:
;
; OPTIONAL INPUT/OUTPUTS:
;
; COMMENTS:
;
; EXAMPLES:
;
; BUGS:
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;   24-Mar-2002  Written by Mike Blanton, NYU
;-
;------------------------------------------------------------------------------
function fit_sersic_func, x, p

common com_fit_sersic,fs_seeing_amp,fs_seeing_width,fs_seestruct, $
  fs_profmean,fs_proferr,fs_nprof,fs_meanprofradius,fs_model_profmean, $
  fs_amp

; construct sersic profile
profile=sersic(fs_seestruct.radius_vals,1.,p[0],exp(p[1]))

; convolve with seeing
seeing_radial,profile,fs_seeing_width,fs_seeing_amp,fs_model_profmean, $
  seestruct=fs_seestruct
fs_model_profmean=fs_model_profmean[0L:fs_nprof-1L]

; set amplitude
fs_amp=total(fs_model_profmean*fs_profmean/fs_proferr^2,/double)/ $
  total(fs_model_profmean^2/fs_proferr^2,/double)
fs_model_profmean=fs_model_profmean*fs_amp

return,fs_model_profmean

end
;
pro fit_sersic,nprof,profmean,proferr,seeing_width,seeing_amp,sersic, $
               seestruct=seestruct,nprofile=nprofile,savseestruct=savseestruct

common com_fit_sersic

if(NOT keyword_set(maxnprof)) then maxnprof=11L
if(NOT keyword_set(nprofile)) then nprofile=100L
if(NOT keyword_set(profradius)) then $
  profradius=[0., 0.564190, 1.692569, 2.585442, 4.406462, $
              7.506054, 11.576202, 18.584032, 28.551561, $
              45.503910, 70.510155, 110.530769, 172.493530, $
              269.519104, 420.510529, 652.500061]*0.396

; initialize seestruct
if(keyword_set(savseestruct)) then $
   if(file_test(savseestruct)) then $
   restore,savseestruct
if(n_tags(seestruct) eq 0) then $
  seeing_radial,dblarr(nprofile),seeing_width,seeing_amp, $
  fs_model_profmean,seestruct=seestruct,/setseestruct, $
  max_radius_vals=1.1*profradius[maxnprof+1]
if(keyword_set(savseestruct)) then $
   save,seestruct,filename=savseestruct
fs_seestruct=seestruct
meanprofradius=0.5*(profradius[0:14]+profradius[1:15])

; for each profile, run mpfit
nprofiles=n_elements(nprof)
profmean=reform(profmean,15,nprofiles)
proferr=reform(proferr,15,nprofiles)
sersic_one={sersic_struct, sersic_amp:0.d, sersic_n:0.d, sersic_r0:0.d, $
            chi2:0.d, nprof:0L}
sersic=replicate(sersic_one,nprofiles)
for i=0L, nprofiles-1L do begin
    splog,i
    start=[2.,alog(3.)]
    fs_seeing_amp=seeing_amp[*,i]
    fs_seeing_width=seeing_width[*,i]
    fs_nprof=min([maxnprof,nprof[i]])
    fs_profmean=profmean[0:fs_nprof-1L,i]
    fs_proferr=proferr[0:fs_nprof-1L,i]
    fs_meanprofradius=meanprofradius[0:fs_nprof-1L]
    p=mpfitfun('fit_sersic_func', fs_meanprofradius, fs_profmean, fs_proferr, $
               start,/quiet,ftol=1.e-7,bestnorm=chi2)
    splog,'chi^2 = '+string(chi2)
    splog,'nprof = '+string(fs_nprof)
    fs_model_profmean=fit_sersic_func(fs_meanprofradius,p)
    sersic[i].sersic_amp=fs_amp
    sersic[i].sersic_n=p[0]
    sersic[i].sersic_r0=exp(p[1])
    sersic[i].chi2=chi2
    sersic[i].nprof=fs_nprof
endfor

end
