;+
;NAME:
;cmgaincor  - gain correct map(s)
;
;SYNTAX: cmgaincor,m,gaincor,jy=jy,undo=undo
;
;ARGS:   
;   m[2,nsmp,nstrips,(nmaps)]: array of map structure. routine will work with
;                               a single map or an array of maps
;RETURNS:
;   gaincor[nsmp,nstrips,nmaps]: float. The gain correction done at each point.
;                           m.d: the data that is gain corrected.
;
;KEYWORDS:
;   jy      : if set then gain correct and return in Janskies. The default
;             is to do a relative gain correction leaving the data in the
;             input units (normally kelvins)
;   undo    : if set then routine will undo a previous gain correction. In this
;             case the user passes in m and gaincor.
;             note: undo is not currently implemented..
;
;DESCRIPTION:
;   The gain of the telescope in kelvins/Jy is modeled in the routine
;corhgainget. This routine will remove the telescope gain variation with
;azimuth and za. 
;   By default it will do a relative correction normalizing to the average
;gain begin between 5 and 10 degrees za. If the /jy keyword is set then it
;will convert the input data (which should already be in Kelvins) to 
;janskies after correcting for the gain response of the telescope.
;   The routine performs  the following operation on each spectra:
;
; 
;; get the gain value for each az,za position of the map
; stat=corhgainget(m.h,gainval)     ;here gainval is in K/Jy
; if jy keyword is set then 
;      gainCor=gainval      ; this is Kelvain/Jy
; else
;      gainCor=(gainval/avggainval)
; endelse
; m.d=m.d/gainCor
;
;NOTE:
;   If you input multiple maps, they should be for the same data set 
;parameters (frequency and receiver).
;WARNING:
;   cmgaincor modifies the input map. You should not call cmgaincor using
;already corrected data.  eg..
;   numbpedge=2                   ; use 2 spectra each edge for bandpass
;   mbpc=cormapbc(m,numbpedge)
;   corgaincor,m,gaincor
;   corgaincor,m,gaincor          ; this is illegal to call a second time
;;  but..
;   mbpc=cormapbc(m,numbpedge)
;   corgaincor,m,gaincor
;   mbpc=cormapbc(m,numbpedge)
;   corgaincor,m,gaincor          ; this is Ok
;-
;16dec02 - switched from lbgain it corhgainget().
;20dec02 - added jy keyword, switched from max to avg gain 5 to 10 deg
;04oct03 - switched how the dimensions were computed..
;07jan04 - fixed bug 040ct03 patch. if nchn gt 1, idim was wrong
;30jan04 - fixed type rm -> m
;
pro cmgaincor,m,gaincor,undo=undo,jy=jy
;
    a      =size(m.d)
    idim=a[1:1+a[0]-1]              ;get the dimensions for later
    nchn=n_elements(m[0].d)
    if nchn ne 1 then idim=idim[1:*]; get rid of channel dimension
    npnts=n_elements(m)/2L          ; since two  pol
    m=temporary(reform(m,2,npnts,/overwrite))

    stat=corhgainget(m[0,*].h,gaincor)
    if keyword_set(jy) then begin
        gaincor=1./(gaincor)   ; it is quicker to multiply
    endif else begin
;
;       lookup and avg gain 5 to 10 deg avg over az
;
        gainavg=0.
        for i=5,10 do begin
            stat=corhgainget(m[0].h,cgain,az=0.,za=i,/onlyza)
            gainavg=gainavg+cgain
        endfor
        gainavg=gainavg/6.
        gaincor=1./(gaincor/gainavg)   ; it is quicker to multiply
    endelse
;
    for i=0L,npnts-1 do begin
        m[0,i].d=m[0,i].d*gaincor[i]
        m[1,i].d=m[1,i].d*gaincor[i]
    endfor
    m=temporary(reform(m,idim,/overwrite))
    gaincor=reform(1./gaincor)           ; return the way we said it would be
return
end
