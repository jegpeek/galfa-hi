;+
;NAME:
;corposonoff - process a position switch scan
;SYNTAX: istat=corposonoff(lun,b,t,cals,bonrecs,boffrecs,sclcal=sclcal,
;                          scan=scan,maxrecs=maxrecs,sl=sl,dbg=dbg,han=han)
;ARGS  :
;       lun:    int .. assigned to open file.
;         b:    {corget} return (on-off)*X here..
;               X is: 
;                   sclCal true : (kelvins/corcnt)/<off>.. units are then K
;                   sclcal false: off                   .. units are TsysOff
;         t:    {temps} total power temp info contains..
;                   t.bN.src  .. on/off-1 (same as lag0pwrratio)
;                   t.bN.on   .. temp on src
;                   t.bN.off  .. temp off
;                   units are Kelvins if /sclcal else Tsys Off
;     cals[]    {cal} return cal info. see coronoffcal..
;                   this is an optional argument
;     bonrecs[]  {corget} return individual on records. This is an 
;                   optional argument. The units will be K (if /sclcal) or
;                   correlator units.
;     boffrecs[] {corget} return individual off records. This is an 
;                   optional argument. The units will be K (if /sclcal) or
;                   correlator units.
;KEYWORDS:
;       sclcal: if not zero then scale to kelvins using the cal on/off
;               that follows the scan
;       scan:   position to first record of scan before reading.     
;       sl[]:   {sl} returned from getsl(). If provided then direct
;                    access is available for scan.
;    maxrecs:   maximum records in a scan. default 300.
;    han    :   if set then hannin smooth data
;    _extra :  calval=caltouse[2,nbrds] .. for corcalonoff..
;RETURNS:
;       istat  int   1 gotit, 0 didnot complete
;                       cal value to use polA,B by board instead of
;                       value in file
;DESCRIPTION:
;   Process a position switch on,off pair. Return a single spectrum
;per sbc of  (posOn-posOff)/posOff. The units will be Tsys of the off
;positionf or Kelvins (if /sclcal) is set. The t structure holds the 
;total power info for (on/off -1), on source, and off source. 
;The units are either Kelvins (/usecal set) or TsysOff.
;The cal record info is also returned in the cals structure.
;
;   The header will be that from the first record of the on with the
;following modifications:
;   h.std.gr,az,chttd is the average for the on scan
;   h.cor.lag0pwratio is the average of (on-off)/off the units will be
;                     TsysPosOff or kelvins depending on /sclcal.
;
;   If bonrecs is specified then the individual on records will also
;be returned. If boffrecs is specified then the individual off records 
;will be returned. The units will be Kelvins (if /sclcal is set) or
;correlator units (linear in power).
;
;structures:
;   b - holds the spectral data and headers: has N elements:
;   b.b1 - board 1 thru
;   b.bn - board n
;   each b.bN has:
;        b.bN.h  - header
;        b.bN.d[nlags,nsbc] - spectral data
;
;   t- holds temperature/power data . has N elements
;   t.b1 board 1 thru
;   t.bN board N
;   each t.bN has: 
;        t.bN.src[nsbc] (on-off)*X power
;        t.bN.on[nsbc]             on  power
;        t.bN.off[nsbc]            off power
;        The power units will be Kelvins if /corscl is set. If not,
;        the units will be  TsysOffPos. nsbc can be 1 or 2 depending
;        on the number of sbc in each board.
;   
;  cals[nbrds] holds the cal info. it is an array of {cal} structures:
;   cals[i].h          - header from first cal on.
;   cals[i].calval[2]  - cal value for each sbc this board
;   cals[i].calscl[2]  - to convert corunits to kelvins sbc,1,2
;       cals[i].h.cor.calOn  - has the total power calOn
;       cals[i].h.cor.calOff - has the total power calOff .. units are
;                              correlator units.
; Note.. there is a difference between < on/off - 1> and
;        <on>/<off> namely the bandpass shape .. let f be the bandpass shape:
;        then < f*on/(f*off) -1> doesnot have the bandpass
;        but   <f*on>/<f*off> does  the basic problem is that
;        <a>/<b> is not equal to <a/b>
;-
;modhistory
;31jun00 - updated for new corget
; 4jul00 - added t struct
;13jul00 - added bonrecs, boffrecs, test for numrecs on,off equal
;15may02 - When sclcal not used, not returning polB same sbc for src value
;
function corposonoff,lun,b,t,cals,bonrecs,boffrecs,sclcal=sclcal,scan=scan,$
                     dbg=dbg,sl=sl,han=han,_extra=e
;
;
;   
    on_error,1
    if not keyword_set(scan)    then scan=0
    if not keyword_set(dbg)     then dbg=0
    if not keyword_set(sclcal)  then sclcal=0
    if not keyword_set(maxrecs)  then maxrecs=0
    if not keyword_set(sl)       then sl=0
    if not keyword_set(han)       then han=0
    usecals   = 0
    useonrecs = 0
    useoffrecs= 0
    if (n_params() ge 4) then usecals=1
    if (n_params() ge 5) then useonrecs=1 
    if (n_params() ge 6) then useoffrecs=1
;
;   on 
;
    if dbg then start=systime(1)
    if (useonrecs) then begin
        if (corinpscan(lun,b,bonrecs,/sum,scan=scan,maxrecs=maxrecs,dbg=dbg,$
                sl=sl,han=han) eq 0 ) then goto,errinp
    endif else begin
        if (corinpscan(lun,b,/sum,scan=scan,maxrecs=maxrecs,dbg=dbg,sl=sl,$
                    han=han) eq 0 ) then goto,errinp
    endelse
    print,'on scan:',b.b1.h.std.scannumber
    if dbg then begin
        endtm=systime(1)
        print,'corinpscan on',endtm-start
    endif
    if ( string(b.(0).h.proc.car[*,0]) ne 'on') then begin
        print,'1st scan not an on',b.(0).h.std.scannumber
        goto,errinp
    endif
;
;   off
;
    if dbg then start=systime(1)
    if (useoffrecs) then begin
        if (corinpscan(lun,boff,boffrecs,/sum,maxrecs=maxrecs,dbg=dbg,han=han)$
            eq 0 ) then goto,errinp
    endif else begin
        if (corinpscan(lun,boff,maxrecs=maxrecs,/sum,dbg=dbg,han=han) eq 0 ) $
                then goto,errinp
    endelse
    if dbg then begin
        endtm=systime(1)
        print,'corinpscan off',endtm-start
    endif
    if ( string(boff.b1.h.proc.car[*,0]) ne 'off') then begin
        print,'2nd scan not an off',boff.b1.h.std.scannumber
        goto,errinp 
    endif
    if boff.b1.h.std.grpnum ne b.b1.h.std.grpnum then begin
        print,'Recs on:',b.b1.h.std.grpnum,' != recs off ',boff.b1.h.std.grpnum
        goto,errinp 
    endif
;
    if dbg then start=systime(1)
;
;   input calOnOff if they have cals, or /sclcal
;
    if  usecals or sclcal  then begin
        if ((b.b1.h.proc.iar[1] and 1) eq 0 ) then begin
            print,'no cal records to input'
            goto,errinp
        endif
        if corcalonoff(lun,cals,_extra=e) ne 1 then begin
            print,'error processing cal on,off'
            goto,errinp
        endif
    endif 
;
;     compute on/off - 1 we are in units of Tsys Off
;
    nbrds=b.b1.h.cor.numbrdsused
    for i=0,nbrds-1 do b.(i).d=b.(i).d/boff.(i).d - 1.          ; (on-off)/off
;
    if sclcal then begin
;
;       loop over each board. calscl is K/corCnts. the summary record 
;       is in TsysOff units (since we divided by posOff). 
;       multiply back by lag0pwrratio posOff to get back to corUnits. 
;       Note that corinpscan computed the average value of lag0pwrratio for us.
;       If they asked for onrecs/offrecs, we just multiply by the
;       scaling factor.
;
        for i=0,nbrds-1 do begin
            b.(i).d[*,0]= b.(i).d[*,0] * (cals[i].calscl[0]* $
                          boff.(i).h.cor.lag0pwrratio[0])
             if b.(i).p[1] ne 0 then begin
                b.(i).d[*,1]= b.(i).d[*,1] * (cals[i].calscl[1]* $
                          boff.(i).h.cor.lag0pwrratio[1])
            endif
            if (useonrecs) then begin 
                bonrecs.(i).d[*,0] =bonrecs.(i).d[*,0]  * cals[i].calscl[0]
                if b.(i).p[1] ne 0 then $
                    bonrecs.(i).d[*,1] =bonrecs.(i).d[*,1]  * cals[i].calscl[1]
            endif
            if (useoffrecs) then begin
                boffrecs.(i).d[*,0]=boffrecs.(i).d[*,0] * cals[i].calscl[0]
                if b.(i).p[1] ne 0 then $
                    boffrecs.(i).d[*,1] =boffrecs.(i).d[*,1]*cals[i].calscl[1]
            endif
        endfor
    endif
;
;   store the temps in t. also duplicate  on/off-1 in h.cor.lag0pwrratio
;   note that ton/toff - 1  will not equal Tsrc because <a/b> != <a>/<b>
;
    t={cortmp}
    if sclcal then t.k=1
    for i=0,nbrds-1 do begin
        t.p[*,i] =b.(i).p
        nsbc=1
        if t.p[1,i] ne 0 then nsbc=2
        if t.k then begin
            t.on[*,i]  =   b.(i).h.cor.lag0pwrratio * cals[i].calscl
            t.off[*,i] =boff.(i).h.cor.lag0pwrratio * cals[i].calscl
        endif else begin
        for j=0,nsbc-1 do begin
             t.on[j,i]  =b.(i).h.cor.lag0pwrratio[j]/ $
                         boff.(i).h.cor.lag0pwrratio[j]
             t.off[j,i]=1.
        endfor
        endelse
;
;   do the source separately .. we've removed the bandpass shape
;   the lag0pwratios .. still have it..
;
        scl=1.D/b.(i).h.cor.lagsbcout
        a=total(b.(i).d,1,/double)*scl 
        t.src[0,i]=a[0]
        if nsbc gt 1 then  t.src[1,i]=a[1]
        if sclcal then begin
            t.calscl[0,i]=cals[i].calscl[0]
            t.calval[0,i]=cals[i].calval[0]
            if nsbc gt 1 then  begin
                t.calscl[1,i]=cals[i].calscl[1]
                t.calval[1,i]=cals[i].calval[1]
            endif
        endif
        b.(i).h.cor.lag0pwrratio=t.src[*,i]
    endfor
    if dbg then begin
        endtm=systime(1)
        print,'computing',endtm-start
    endif
    return,1
errinp:
    return,0
end
