;+
; NAME:
;   seeing_radial
;
; PURPOSE:
;   Convolves a radial profile with seeing (expressed as a sum of
;   gaussians) assuming axisymmetry
;
; CALLING SEQUENCE:
;   profmeansee=seeing_radial(nprof, profmean, seeing_width, $
;                             [seeing=, seegrid=, /setseestruct])
;
; INPUTS:
;   nprof - number of entries to use in profmean [N]
;   profmean - radial profile [15,N]
;   seeing_width - absolute width of seeing [N]
;
; OPTIONAL INPUTS:
;   seeing - relative widths and amplitudes of seeing gaussians
;   setseestruct - if set, reset the seegrid
;
; OUTPUTS:
;
; OPTIONAL INPUT/OUTPUTS:
;   seegrid - matrix of seeing_width and radius
;
; COMMENTS:
;
; EXAMPLES:
;
; BUGS:
;  Fails for at large radii when seeing is small (round-off issues?).
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;   23-Mar-2002  Written by Mike Blanton, NYU
;-
;------------------------------------------------------------------------------
pro seeing_radial,profile,seeing_width,seeing_amp,seeing_profmean,seestruct=seestruct,setseestruct=setseestruct,profradius=profradius,radius_vals=radius_vals,seeing_width_vals=seeing_width_vals,nintegral=nintegral,max_radius_vals=max_radius_vals

if(NOT keyword_set(profradius)) then $
  profradius=[0., 0.564190, 1.692569, 2.585442, 4.406462, $
              7.506054, 11.576202, 18.584032, 28.551561, $
              45.503910, 70.510155, 110.530769, 172.493530, $
              269.519104, 420.510529, 652.500061]*0.396

PI=3.14159265358979d

if(size(profile,/n_dimensions) eq 1) then begin
    profile=reform(profile,n_elements(profile),1)
endif
nprofiles=(size(profile,/dimensions))[1]
nradius_vals=(size(profile,/dimensions))[0]
nrad=long(n_elements(profradius))
nannuli=nrad-1L
nseeing=long(n_elements(seeing_width)/nprofiles)

; Create seeing grid for each radius and seeing
if(n_tags(seestruct) EQ 0 OR keyword_set(setseestruct)) then begin
    ; set sizes of grids
    if(NOT keyword_set(nseeing_width_vals)) then nseeing_width_vals=20L
    if(NOT keyword_set(nradius_vals)) then nradius_vals=800L
    if(NOT keyword_set(nintegral)) then nintegral=300L

    ; set grids in seeing_width and radius
    if(NOT keyword_set(seeing_width_vals)) then $
      seeing_width_vals=0.5*min(seeing_width)+(1.1*max(seeing_width)- $
                                               0.5*min(seeing_width)) $
      *dindgen(nseeing_width_vals)/double(nseeing_width_vals-1L)
    if(NOT keyword_set(max_radius_vals)) then $
       max_radius_vals=1.1*max(profradius[1:nrad-1])
    if(NOT keyword_set(radius_vals)) then $
      radius_vals=exp(alog(0.05*min(profradius[1:nrad-1]))+ $
                      (alog(max_radius_vals)- $
                       alog(0.05*min(profradius[1:nrad-1]))) $
                      *(dindgen(nradius_vals)+0.5)/double(nradius_vals-1L))
    nradius_vals=n_elements(radius_vals)
    nseeing_width_vals=n_elements(seeing_width_vals)
                               
    dradius_vals= $
      exp(alog(0.05*min(profradius[1:nrad-1]))+ $
          (alog(1.1*max(profradius[1:nrad-1]))- $
           alog(0.05*min(profradius[1:nrad-1]))) $
          *(dindgen(nradius_vals)+1.d)/double(nradius_vals-1L))- $
      exp(alog(0.05*min(profradius[1:nrad-1]))+ $
          (alog(1.1*max(profradius[1:nrad-1]))- $
           alog(0.05*min(profradius[1:nrad-1]))) $
          *(dindgen(nradius_vals))/double(nradius_vals-1L))
    
    ; set seeing grid
    seegrid=dblarr(nradius_vals,nseeing_width_vals,nannuli)
    for i=0L, nannuli-1L do begin 
        r1=profradius[i]
        r2=profradius[i+1]
        for j=0L, nseeing_width_vals-1L do begin 
            splog,i,j
            for k=0L, nradius_vals-1L do begin 
                radius=radius_vals[k]

                ; perform integral from r1 to r2
                int_rad=r1+dindgen(nintegral)*(r2-r1)/double(nintegral)
                
                ; get bessel result over the range
                beselfact=dblarr(nintegral)
                beselarg=int_rad*radius/seeing_width_vals[j]^2
                indx=where(beselarg gt 20.,count)
                if(count gt 0) then $
                  beselfact[indx]=seeing_width_vals[j]* $
                  exp((int_rad[indx]*radius-0.5*int_rad[indx]^2-0.5*radius^2) $
                      /seeing_width_vals[j]^2)/ $
                  sqrt(2.*PI*int_rad[indx]*radius)
                indx=where(beselarg le 20.,count)
                if(count gt 0) then $
                  beselfact[indx]=beseli(beselarg[indx],0L)* $
                  exp(-0.5*(int_rad[indx]^2+radius^2)/seeing_width_vals[j]^2)
                
                ; actually calculate and store integral
                int_del=int_rad[1]-int_rad[0]
                int_val=int_rad*beselfact
                indx=where(int_val ne int_val,count)
                seegrid[k,j,i]=dradius_vals[k]*radius* $
                  total(int_val*int_del,/double)/(seeing_width_vals[j]^2)
            endfor
        endfor
        seegrid[*,*,i]=seegrid[*,*,i]/(PI*(r2^2-r1^2))
    endfor
    seegrid=(2.*PI)*seegrid

    seestruct={seestr,seegrid:seegrid,seeing_width_vals:seeing_width_vals, $
               radius_vals:radius_vals}
    if(keyword_set(setseestruct)) then return
endif
if(nradius_vals ne n_elements(seestruct.radius_vals)) then begin
    splog,'profile does not conform to seestruct size'
    return
endif
nseeing_width_vals=n_elements(seestruct.seeing_width_vals)
nradius_vals=n_elements(seestruct.radius_vals)

; now that we have the seeing structure, let's calculate the new 
; profmean for each object
seeing_profmean=dblarr(nannuli,nprofiles)
for i=0L, nprofiles-1L do begin
    
    for j=0L, nseeing-1L do begin
; get seeing grid at this value of the seeing
        isee=long((seeing_width[j,i]-seestruct.seeing_width_vals[0])/ $
                  (seestruct.seeing_width_vals[nseeing_width_vals-1] $
                   -seestruct.seeing_width_vals[0])* $
                  double(nseeing_width_vals))
        if(isee ge nseeing_width_vals-1L) then isee=nseeing_width_vals-2L
        ssee=(seeing_width[j,i]-seestruct.seeing_width_vals[isee])/ $
          (seestruct.seeing_width_vals[isee+1] $
           -seestruct.seeing_width_vals[isee])
        seegrid=seestruct.seegrid[*,isee,*]+ $
          (seestruct.seegrid[*,isee+1,*]-seestruct.seegrid[*,isee,*])*ssee
        seegrid=reform(seegrid,nradius_vals,nannuli)

; get flux through each annulus
        for k=0L, nannuli-1L do begin
            seeing_profmean[k,i]=seeing_profmean[k,i]+ $
              seeing_amp[j]*total(seegrid[*,k]*profile,/double)
        endfor
    endfor
endfor

end
