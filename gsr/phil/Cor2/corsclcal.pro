;+
;NAME:
;corsclcal - scale spectrum to the cal values
;SYNTAX: corsclcal,d,cals
;ARGS:   d[]    -{corget}  data input from corget.. single integration
;                          or an array of integrations
; cals[nbrds]   -{} structure returned from corcalonoff.
; DESCRIPTION
; scale spectra in b to kelvins using the cal scale factors 
;computed in cals. the {} cals is returned from the routine corcalonoff.
;b can be a single integration or an array of integrations. They must
;all be the same correlator configuration as the data in cals.
;-
pro   corsclcal,b,cals
;
    on_error,2
    nbrds=cals[0].h.cor.numbrdsused
    for i=0,nbrds-1 do begin
;
;       always have a first sbc
;
        b.(i).d[*,0]= b.(i).d[*,0]*cals[i].calscl[0]
;
        if (cals[i].h.cor.numsbcout gt 1) then begin
            b.(i).d[*,1]= b.(i).d[*,1]*cals[i].calscl[1]
        endif
    endfor
    return
end
