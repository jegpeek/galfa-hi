;+
;NAME:
;wappgethdr - read a wapp header from the start of a file
;
;SYNTAX: istat=wappgethdr(lun,hdr,dataswapped,wappcpuI=wappcpuI,hdrb=hdrb)
;
;ARGS:
;    lun: int   file number to read
;keywords: 
;wappcpuI: {wappcpuinfo} use wappcpuI for the file to use. It will
;                        open the file,scan the header, and return
;                        the lun in lun. see wappgetfileinfo().
;    hdrb: {wapphdrb}    header input before massaging (bytes converted to 
;                        strings,etc)
;
;RETURNS:
;   istat:int       1-gothdr, 0 not a wapp file or we don't support this
;                   version.
;     hdr:{wapphdr} wapp header input
;dataswapped: int   1 we had to swap the header, 0 we did not have to 
;                   swap it.
;
;DESCRIPTION:
;   Read the wapp header from the start of the file into the 
;hdr variable. The routine will position to the start of the file
;before reading. It will leave the file positioned at the start of the first
;data record. The variable dataswapped will be set to one if the
;the routine had to swap the data on input (little/big endian). If the
;file does not contain a wapp hdr then 0 will be returned in istat.
;
;EXAMPLE:
;1. 
;   file='/share/wapp25/adleo.wapp2.52803.049'
;   openr,lun,file,/get_lun
;   istat=wappgethdr(lun,hdr)
;2. scan the logfile, use the wappI structure to select a cpuhdr to open.
;   logfile='/share/obs4/usr/pulsar/a1730/a1730.cimalog'
;   nsets=wappgetfileinfo(lun,wi,logfile=logfile)
;   istat=wappgethdr(lun,hdr,wappcpuI=wi[0].wapp[0])
;
;THE WAPPHDR CONTAINS:
;
;    header_version  : 5L    ,$; header revision currently 5
;    header_size     : 0L    ,$; bytes in binary hdr (nom 2048)
;    obs_type        : ''    ,$;what kind of observation this is
;                                  PULSAR_SEARCH
;                                  PULSAR_FOLDING
;                                  SPECTRA_TOTALPOWER
;
;    The following are obtained from current telescope status display
;    note that start AST/LST are for reference purposes only and should
;    not be taken as accurate time stamps. The time stamp can be derived
;    from the obs_date/start_time variables further down in the structure.
;
;    src_ra          : 0.D   ,$; req ra  J2000 hhmmss.sss
;    src_dec         : 0.D   ,$; req dec J2000 ddmmss.sss
;    start_az        : 0.D   ,$; deg az start of scan
;    start_za        : 0.D   ,$; deg za start of scan
;    start_ast       : 0.D   ,$; AST at start of scan (secs)
;    start_lst       : 0.D   ,$; LST at start of scan (secs)
;
;    cent_freq       : 0.D   ,$; CFR on sky Mhz (coord sys topo??)
;    obs_time        : 0.D   ,$; usr req period of observation secs
;    samp_time       : 0.D   ,$; usr req sample time usecs
;    wapp_time       : 0.D   ,$; actual sample time. usrreq + dead time
;    bandwidth       : 0.D   ,$; total bandwidth mhz for this obs 50 or 100
;
;    num_lags        : 0L    ,$; usrReq lags per dump per spectrum
;    scan_number     : 0L    ,$; year + daynumber + 3 digitnumber (*100,1000??)
;
;    src_name        : ''    ,$;srcname
;    obs_date        : ''    ,$;yyyymmdd
;    start_time      : ''    ,$;utsecs from midnite (start on 1 sec tick)
;    proj_id         : ''    ,$;user supplied ao proposal number
;    observers       : ''    ,$;user supplied observers names
;
;    nifs            : 0L        ,$;number of IF'S 1,2, 4=fullstokes
;    level           : 0L        ,$;1=3level, 2=9level quantization
;    sum             : 0L        ,$;1=Summation 2ifs (pols?), 0--> no
;    freqinversion   : 0L        ,$;1=yes, 0=no
;    timeoff         : 0LL       ,$;# of reads between obs start and snap block
;;                                  tm offsetStart of observation.
;;                                  wapp_time*numrecs. usecs??
;    lagformat       : 0L        ,$;0=16bit uint lags, 1=32bit uint lags
;;                                  2=32bit float lags, 3=32bit float spectra
;   lagtrunc        : 0L        ,$;we truncate data (0 no trunc)
;;                                  for 16 bit lagmux modes, selects which
;;                                  16 bits of the 32 are included as data
;;                                   0 is bits 15-0 1,16-1 2,17-2...7,22-7
;;
;    firstchannel    : 0L        ,$;0 polA first, 1 if polB is first
;    nbins           : 0L        ,$;# of time bins for pulsar folding mode
;;                                    doubles as maxrecs for snap mode
;    dumptime        : 0.D       ,$;folded integrations for this period of time
;    power_analog    : dblarr(2) ,$; power measured by analog detector
;;
;;    In the following, pulsar-specific information is recorded for use
;;    by folding programs e.g. the quick-look software. This is passed to
;;    WAPP by psrcontrol at the start of the observation.
;;
;;    The apparent pulse phase and frequency at time "dt" minutes with
;;    respect to the start of the observation are then calculated as:
;;
;;    phase = rphase + dt*60*f0 + coeff[0] + dt*coeff[1] + dt*dt*coeff[2] + ...
;;    freq(Hz) = f0 + (1/60)*(coeff[1] + 2*dt*coeff[2] + 3*dt*dt*coeff[3] + ...)
;;
;;    where the C notation has been used (i.e. coeff[0] is first coefficient etc)
;;    for details, see TEMPO notes (http://www.naic.edu/~pulsar/docs/tempo.txt)
;
;    psr_dm          : 0.D       ,$;dispersion measure (pc/cm^3)
;    rphase          : dblarr(16) ,$;reference phase of pulse 0-1
;    psr_f0          : dblarr(16) ,$;pulse freq at referenche epoch (hz)
;    poly_tmid       : dblarr(16) ,$;midpnt of polyco (in MJD)
;    coef            : dblarr(192),$;polynomial coef calculated by tempo [9,16]
;    num_coef        : lonarr(16)  ,$;number of coefficients
;    hostname        : bytarr(24)  ,$; filler to get to 2048
;;
;;   additions for idl processing
;;
;    obs_type_code   : 0L          ,$;1-srch,2=fold,3=spctoppwr, -1 unknown
;    byteOffData     : 0L          ,$; byte offset start of data.
;    needSwap        : 0L          ,$; 1 if data needs to be swapped.
;    filler          : 0L          } ;  
;- ;
;history:
; 15jun03 = switched filler to hostname
;           added obs_type_code so you can test the type of data faster
; 18sep03 = version 6 hdr
; 02mar04 - switched to use the tag names
;
function wappgethdr,lun,rethdr,dataswapped,wappcpuI=wappcpuI,hdrb=rethdrb
;   
    on_ioerror,nohdr
    hdrkey='struct WAPP_HEADER'
    versionkey='HEADER_VERSION '
    usewappcpuI=0
    if n_elements(wappcpuI) gt 0 then begin
        usewappcpuI=1
        fname=wappcpuI.dir+wappcpuI.fname
        lun=-1
        openr,lun,fname,/get_lun
    endif
    rew,lun
    cbuf=string(bytarr(12288)+1B)
    readu,lun,cbuf
;
;    a wapp file??
;
    if strpos(cbuf,hdrkey)     eq -1 then goto,nohdr
    i=strpos(cbuf,versionkey) 
    if  i eq -1 then goto,noversion
    version=long(strmid(cbuf,i+15,2))
;
;   position of null string
;
    point_lun,lun,strlen(cbuf)+1L
;
;   verions. array dimension changes are ok, the assignment
;   will leave the unused part 0 filled.
;
    case version of
        2 : begin
            rethdrB={hdrwapp2Byte}
            end
        3 : begin
            rethdrB={hdrwapp3Byte}
            end
        4 : begin
            rethdrB={hdrwapp4Byte}
            end
        5 : begin
            rethdrB={hdrwapp5Byte}
            end
        6 : begin
            rethdrB={hdrwapp6Byte}
            end
        7 : begin
            rethdrB={hdrwapp7Byte}
            end
        8 : begin
            rethdrB={hdrwapp8Byte}
            end
      else: begin
        print,'warning.. this hdr version not supported:',version
        retstat=0
        goto,nohdr
            end
    endcase
    readu,lun,rethdrB
;
;    do we need to flip it
;
    dataswapped= (rethdrB.nifs ge 2L^16) ? 1 : 0
    if dataswapped then rethdrB=swap_endian(rethdrB)
    rethdr={hdrwapp}
;
;    move to the string version one field at a time
;    define string as byte array gt 4 elements..

    n=n_tags(rethdrb)
    tagNB=tag_names(rethdrb)    ; tagnames byte version of header
    tagNS=tag_names(rethdr)     ; tagnames string (current) version 
    for i=0,n-1 do begin
        ind=where(tagNB[i] eq tagNS,count) ; find name in string version
        if count eq 1 then begin
            rethdr.(ind[0])=(size(rethdr.(ind[0]),/type) eq 7) $
                ? string(rethdrb.(i)) : rethdrb.(i)
        endif
    endfor
    point_lun,-lun,curpos
    rethdr.byteOffData=curpos
    rethdr.needSwap   =dataswapped
    case 1 of
        strcmp(rethdr.obs_type,'PULSAR_SEARCH') : icode=1
        strcmp(rethdr.obs_type,'PULSAR_FOLDING'): icode=2
        strcmp(rethdr.obs_type,'SPECTRA_TOTALPOWER'): icode=3
        else:icode=-1
    endcase
    rethdr.obs_type_code=icode
    retstat=1
    goto,done
noversion: print,'no #define HEADER_VERSION found..(old hdr??)'
nohdr: retstat=0
    if usewappcpuI and (lun ne -1) then free_lun,lun
done: on_ioerror,NULL
    return,retstat
end
