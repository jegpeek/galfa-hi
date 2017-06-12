;+
; NAME:
;   fast_fit_sersic
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
function fast_fit_sersic_func, x, p

common com_fast_fit_sersic,ffs_seeing_amp,ffs_seeing_width,ffs_seestruct, $
  ffs_profmean,ffs_proferr,ffs_nprof,ffs_meanprofradius,ffs_model_profmean, $
  ffs_amp,ffs_faststruct,ffs_nseeing,ffs_kindx,ffs_skindx, ffs_nnv, $
  ffs_nr50v, ffs_nswv

ffs_model_profmean=dblarr(15)

iindx=long((ffs_nnv-1.)*(p[0]-ffs_faststruct.sersic_n_vals[0])/ $
           (ffs_faststruct.sersic_n_vals[ffs_nnv-1]- $
            ffs_faststruct.sersic_n_vals[0]))
if(iindx lt 0) then iindx=0L
if(iindx gt ffs_nnv-2L) then iindx=ffs_nnv-2L
jindx=long((ffs_nr50v-1.)*(p[1]-ffs_faststruct.sersic_r50_vals[0])/ $
           (ffs_faststruct.sersic_r50_vals[ffs_nr50v-1]- $
            ffs_faststruct.sersic_r50_vals[0]))
if(jindx lt 0) then jindx=0L
if(jindx gt ffs_nr50v-2L) then jindx=ffs_nr50v-2L

siindx=(p[0]-ffs_faststruct.sersic_n_vals[iindx])/ $
  (ffs_faststruct.sersic_n_vals[iindx+1L]-ffs_faststruct.sersic_n_vals[iindx])
sjindx=(p[1]-ffs_faststruct.sersic_r50_vals[jindx])/ $
  (ffs_faststruct.sersic_r50_vals[jindx+1L]- $
   ffs_faststruct.sersic_r50_vals[jindx])

ffs_model_profmean=dblarr(15)
for j = 0L, ffs_nseeing-1L do begin

; perform the interpolation
    tmp_pmt= $
      ffs_faststruct.profmeantable[*,iindx:iindx+1L,jindx, $
                                   ffs_kindx[j]:ffs_kindx[j]+1L] $
      +sjindx*(ffs_faststruct.profmeantable[*,iindx:iindx+1L,jindx+1L, $
                                            ffs_kindx[j]:ffs_kindx[j]+1L]- $
               ffs_faststruct.profmeantable[*,iindx:iindx+1L,jindx, $
                                            ffs_kindx[j]:ffs_kindx[j]+1L])
    tmp_pmt=reform(tmp_pmt,15,2,2)
    tmp_pmt2=tmp_pmt[*,0,*]+siindx*(tmp_pmt[*,1L,*]-tmp_pmt[*,0L,*])
    tmp_pmt2=reform(tmp_pmt2,15,2)
    ffs_model_profmean=ffs_model_profmean+ffs_seeing_amp[j]* $
      (tmp_pmt2[*,0]+ffs_skindx[j]*(tmp_pmt2[*,1L]-tmp_pmt2[*,0L]))
endfor
ffs_model_profmean=ffs_model_profmean[0L:ffs_nprof-1L]

; set amplitude
ffs_amp=total(ffs_model_profmean*ffs_profmean/ffs_proferr^2,/double)/ $
  total(ffs_model_profmean^2/ffs_proferr^2,/double)
ffs_model_profmean=ffs_model_profmean*ffs_amp

return,ffs_model_profmean

end
;
pro fast_fit_sersic,nprof,profmean,proferr,seeing_width,seeing_amp,sersic, $
                    seestruct=seestruct,nprofile=nprofile, nbands=nbands, $
                    savseestruct=savseestruct, savfaststruct=savfaststruct, $
                    canonical=canonical

common com_fast_fit_sersic

; set keywords
if(NOT keyword_set(maxnprof)) then maxnprof=11L
if(NOT keyword_set(nbands)) then nbands=5L
if(NOT keyword_set(canonical)) then canonical=3L
if(NOT keyword_set(nprofile)) then nprofile=100L
if(NOT keyword_set(profradius)) then $
  profradius=[0., 0.564190, 1.692569, 2.585442, 4.406462, $
              7.506054, 11.576202, 18.584032, 28.551561, $
              45.503910, 70.510155, 110.530769, 172.493530, $
              269.519104, 420.510529, 652.500061]*0.396

; deal with shapes of arrays
nprofiles=n_elements(nprof)/nbands
ffs_nseeing=long(n_elements(seeing_width)/nprofiles/nbands)
profmean=reform(profmean,15,nbands,nprofiles)
proferr=reform(proferr,15,nbands,nprofiles)
nprof=reform(nprof,nbands,nprofiles)
seeing_width=reform(seeing_width,ffs_nseeing,nbands,nprofiles)
seeing_amp=reform(seeing_amp,ffs_nseeing,nbands,nprofiles)

; initialize seestruct
if(keyword_set(savseestruct)) then $
  if(file_test(savseestruct)) then restore,savseestruct
if(n_tags(seestruct) eq 0) then $
  seeing_radial,dblarr(nprofile),seeing_width,seeing_amp, $
  ffs_model_profmean,seestruct=seestruct,/setseestruct, $
  max_radius_vals=1.1*profradius[maxnprof+1]
if(keyword_set(savseestruct)) then $
  save,seestruct,filename=savseestruct
ffs_seestruct=seestruct
meanprofradius=0.5*(profradius[0:14]+profradius[1:15])

; make grid of n and r50
if(keyword_set(savfaststruct)) then $
  if(file_test(savfaststruct)) then restore,savfaststruct
if(n_tags(faststruct) eq 0) then begin
    faststruct={faststr, sersic_n_vals:dblarr(60), $
                sersic_r50_vals:dblarr(60), seeing_width_vals:dblarr(60), $
                profmeantable:dblarr(15L,60L,60L,60L)}
    faststruct.sersic_n_vals=0.2+(6.0-0.2)*dindgen(60L)/60.d
    faststruct.sersic_r50_vals=0.05+(10.0-0.05)*dindgen(60L)/60.d
    faststruct.seeing_width_vals=0.2+(4.-0.2)*dindgen(60L)/60.d
    for i=0L, n_elements(faststruct.sersic_n_vals)-1L do begin
        sersic_params,1.,faststruct.sersic_n_vals[i],1.,r50=r50
        for j=0L, n_elements(faststruct.sersic_r50_vals)-1L do begin
            splog,i,j
            r0=(faststruct.sersic_r50_vals[j]/r50)[0]
            rv=seestruct.radius_vals
            n=faststruct.sersic_n_vals[i]
            profile=sersic(rv,1.,n,r0)
            for k=0L, n_elements(faststruct.seeing_width_vals)-1L do begin
                seeing_radial,profile,faststruct.seeing_width_vals[k],1., $
                  model_profmean,seestruct=seestruct
                faststruct.profmeantable[*,i,j,k]=model_profmean
            endfor
        endfor
    endfor
endif
if(keyword_set(savfaststruct)) then $
  save,faststruct,filename=savfaststruct

; set global variables
ffs_faststruct=faststruct
ffs_nswv=n_elements(ffs_faststruct.seeing_width_vals)
ffs_nr50v=n_elements(ffs_faststruct.sersic_r50_vals)
ffs_nnv=n_elements(ffs_faststruct.sersic_n_vals)
ffs_kindx=lonarr(ffs_nseeing)
ffs_skindx=dblarr(ffs_nseeing)

; create sersic structure
sersic_one={sersic_struct, $
            sersic_amp:dblarr(5), $
            sersic_canon_amp:dblarr(5), $
            sersic_n:dblarr(5), $
            sersic_r0:dblarr(5), $
            sersic_covar:dblarr(5,2,2), $
            chi2:dblarr(5), $
            nprof:lonarr(5)}
sersic=replicate(sersic_one,nprofiles)

; implement constraints
pi = replicate({fixed:0, limited:[0,0], limits:[0.D,0.D]},2)
pi.limited=1
pi[0].limits=[faststruct.sersic_n_vals[0], $
              faststruct.sersic_n_vals[ffs_nnv-1L]]
pi[1].limits=[faststruct.sersic_r50_vals[0], $
              faststruct.sersic_r50_vals[ffs_nr50v-1L]]

; run each profile
start=[2.,alog(3.)]
for i=0L, nprofiles-1L do begin
    splog,i

    ; do all bands separately
    for k=0L, nbands-1L do begin
        ffs_seeing_amp=seeing_amp[*,k,i]
        ffs_seeing_width=seeing_width[*,k,i]
        ffs_nprof=min([maxnprof,nprof[k,i]])
        ffs_profmean=profmean[0:ffs_nprof-1L,k,i]
        ffs_proferr=proferr[0:ffs_nprof-1L,k,i]
        ffs_meanprofradius=meanprofradius[0:ffs_nprof-1L]
        for j = 0L, ffs_nseeing-1L do begin
            ffs_kindx[j]=long((ffs_nswv-1.)* $
                              (ffs_seeing_width[j]- $
                               ffs_faststruct.seeing_width_vals[0])/ $
                              (ffs_faststruct.seeing_width_vals[ffs_nswv-1]- $
                               ffs_faststruct.seeing_width_vals[0]))
            if(ffs_kindx[j] lt 0) then ffs_kindx[j]=0L
            if(ffs_kindx[j] gt ffs_nswv-2L) then ffs_kindx[j]=ffs_nswv-2L
            ffs_skindx[j]=(ffs_seeing_width[j]- $
                           ffs_faststruct.seeing_width_vals[ffs_kindx[j]])/ $
              (ffs_faststruct.seeing_width_vals[ffs_kindx[j]+1L]- $
               ffs_faststruct.seeing_width_vals[ffs_kindx[j]])
        endfor
        p=mpfitfun('fast_fit_sersic_func', ffs_meanprofradius, ffs_profmean, $
                   ffs_proferr, start,/quiet,ftol=1.e-7,bestnorm=chi2, $
                   parinfo=pi,covar=covar)
        ;splog,'chi^2 = '+string(chi2)
        ;splog,'nprof = '+string(ffs_nprof)
        ffs_model_profmean=fast_fit_sersic_func(ffs_meanprofradius,p)
        sersic_params,1.,p[0],1.,r50=r50
        sersic[i].sersic_amp[k]=ffs_amp
        sersic[i].sersic_n[k]=p[0]
        sersic[i].sersic_r0[k]=p[1]/r50
        sersic[i].chi2[k]=chi2
        sersic[i].nprof[k]=ffs_nprof
        sersic[i].sersic_covar[k,*,*]=covar
    endfor

    ; calculate amplitude assuming canonical fit
    p[0]=sersic[i].sersic_n[canonical]
    sersic_params,1.,p[0],1.,r50=r50
    p[1]=sersic[i].sersic_r0[canonical]*r50
    for k=0L, nbands-1L do begin
        ffs_seeing_amp=seeing_amp[*,k,i]
        ffs_seeing_width=seeing_width[*,k,i]
        ffs_nprof=min([maxnprof,nprof[k,i]])
        ffs_profmean=profmean[0:ffs_nprof-1L,k,i]
        ffs_proferr=proferr[0:ffs_nprof-1L,k,i]
        ffs_meanprofradius=meanprofradius[0:ffs_nprof-1L]
        for j = 0L, ffs_nseeing-1L do begin
            ffs_kindx[j]=long((ffs_nswv-1.)* $
                              (ffs_seeing_width[j]- $
                               ffs_faststruct.seeing_width_vals[0])/ $
                              (ffs_faststruct.seeing_width_vals[ffs_nswv-1]- $
                               ffs_faststruct.seeing_width_vals[0]))
            if(ffs_kindx[j] lt 0) then ffs_kindx[j]=0L
            if(ffs_kindx[j] gt ffs_nswv-2L) then ffs_kindx[j]=ffs_nswv-2L
            ffs_skindx[j]=(ffs_seeing_width[j]- $
                           ffs_faststruct.seeing_width_vals[ffs_kindx[j]])/ $
              (ffs_faststruct.seeing_width_vals[ffs_kindx[j]+1L]- $
               ffs_faststruct.seeing_width_vals[ffs_kindx[j]])
        endfor
        ffs_model_profmean=fast_fit_sersic_func(ffs_meanprofradius,p)
        sersic[i].sersic_canon_amp[k]=ffs_amp
    endfor
endfor

end
