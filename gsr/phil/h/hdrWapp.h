;
; wapp header from the wapp home page
;
; hdrwappByte .. header def with bytarrs (input to here)
; hdrwapp     .. header def with strings instead of bytes
;
; some constants that idl uses 
;
;OBSTYPE_PSRSEARCH =1
;OBSTYPE_PSRFOLDING=2
;OBSTYPE_SPCTOTPWR =3
;OBSTYPE_UNKNOWN   =-1
;-----------------------------------------------------------------
; version 7 to version 8 29sep04
;    new
;    rfeed_offaz     : dblarr(7)   ,$;deg azRotatedOffset all alfaBmsm to center
;    rfeed_offza     : dblarr(7)   ,$;deg za rotated offset all alfa bm to center
;    prfeed_offaz    : 0D          ,$;deg az offset to center of alfa beam
;    prfeed_offza    : 0D          ,$;deg za offset to center of alfa beam
;    alfa_raj        :dblarr(7)    ,$; hr starting actual ra position of alfabeams
;    alfa_decj       :dblarr(7)    ,$; deg starting actual dec pos of alfa beams
;    alfa_az         :dblarr(7)    ,$; deg starting actual az pos of alfa beams
;    alfa_za         :dblarr(7)    ,$; deg starting actual za pos of alfa beams
;    alfa_ang        :0D           ,$; deg alfa rotation angle
;    para_ang        :0D           ,$; deg paralactic angle of center beam
;    frontend        :bytarr(24)   ,$; receiver abbrev name
;
;    prfeed         : 0b          ,$; centered alfa beam
;    fill[7]-> fill[6]

;
a={hdrwapp8Byte , $

	header_version	: 7L	,$; header revision currently 5
	header_size   	: 0L	,$; bytes in binary hdr (nom 2048)
	obs_type      	: bytarr(24),$;what kind of observation this is 
;                                  PULSAR_SEARCH
;						           PULSAR_FOLDING
;							       SPECTRA_TOTALPOWER
; 
;    The following are obtained from current telescope status display
;    note that start AST/LST are for reference purposes only and should 
;    not be taken as accurate time stamps. The time stamp can be derived
;    from the obs_date/start_time variables further down in the structure.
;
	src_ra			: 0.D	,$; req ra  J2000 hhmmss.sss
	src_dec		    : 0.D	,$; req dec J2000 ddmmss.sss
	start_az		: 0.D	,$; deg az start of scan
	start_za		: 0.D	,$; deg za start of scan
	start_ast       : 0.D	,$; AST at start of scan (secs)
	start_lst       : 0.D	,$; LST at start of scan (secs)




	cent_freq       : 0.D	,$; CFR on sky Mhz (coord sys topo??)
	obs_time        : 0.D	,$; usr req period of observation secs 
	samp_time       : 0.D	,$; usr req sample time usecs
	wapp_time       : 0.D	,$; actual sample time. usrreq + dead time
	bandwidth       : 0.D	,$; total bandwidth mhz for this obs 50 or 100

	num_lags        : 0L 	,$; usrReq lags per dump per spectrum 
	scan_number     : 0L 	,$; year + daynumber + 3 digitnumber (*100,1000??)

	src_name        : bytarr(24),$;srcname
	obs_date        : bytarr(24),$;yyyymmdd
	start_time      : bytarr(24) ,$;utsecs from midnite (start on 1 sec tick)
	proj_id         : bytarr(24) ,$;user supplied ao proposal number 
	observers       : bytarr(24),$;user supplied observers names

	nifs            : 0L        ,$;number of IF'S 1,2, 4=fullstokes
	level           : 0L        ,$;1=3level, 2=9level quantization
	sum             : 0L        ,$;1=Summation 2ifs (pols?), 0--> no
	freqinversion   : 0L        ,$;1=yes, 0=no
    timeoff         : 0LL       ,$;# of reads between obs start and snap block 
	lagformat       : 0L        ,$;0=16bit uint lags, 1=32bit uint lags
;                                  2=32bit float lags, 3=32bit float spectra
	lagtrunc        : 0L        ,$;we truncate data (0 no trunc)
;                                  for 16 bit lagmux modes, selects which
;                                  16 bits of the 32 are included as data  
;                                   0 is bits 15-0 1,16-1 2,17-2...7,22-7 
    firstchannel    : 0L        ,$;0 polA first, 1 if polB is first
    nbins           : 0L        ,$;# of time bins for pulsar folding mode 
;   new for version 7
	isfolding       : 0L        ,$;is folding selected
	isalfa          : 0L        ,$;is ALFA  selected
    dumptime        : 0.D       ,$;folded integrations for this period of time
	power_analog    : dblarr(2) ,$; power measured by analog detector
;    
;    In the following, pulsar-specific information is recorded for use 
;    by folding programs e.g. the quick-look software. This is passed to 
;    WAPP by psrcontrol at the start of the observation. 
;
;    The apparent pulse phase and frequency at time "dt" minutes with
;    respect to the start of the observation are then calculated as:
;
;    phase = rphase + dt*60*f0 + coeff[0] + dt*coeff[1] + dt*dt*coeff[2] + ...
;    freq(Hz) = f0 + (1/60)*(coeff[1] + 2*dt*coeff[2] + 3*dt*dt*coeff[3] + ...)
;
;    where the C notation has been used (i.e. coeff[0] is first coefficient etc)
;    for details, see TEMPO notes (http://www.naic.edu/~pulsar/docs/tempo.txt)

	psr_dm          : 0.D       ,$;dispersion measure (pc/cm^3)
	rphase          : dblarr(16) ,$;reference phase of pulse 0-1
	psr_f0          : dblarr(16) ,$;pulse freq at referenche epoch (hz)
	poly_tmid       : dblarr(16) ,$;midpnt of polyco (in MJD)
	coef            : dblarr(192),$;polynomial coef calculated by tempo [9,16]
	num_coef        : lonarr(16)  ,$;number of coefficients
	hostname        : bytarr(24)  ,$; computer data taken on
    fold_bits       : 0L          ,$;0 if 16 bits (old def) 1 if 32 bit folding
    iflo_flip       : 0L          ,$; consider entire iflo and determine flip 
	attena          : 0L          ,$; 1st board parallel port value
	attenb          : 0L          ,$; 2nd board parallel port value

; alfa info

    rfeed_offaz		: dblarr(7)   ,$;deg azRotatedOffset all alfaBmsm to center 
    rfeed_offza		: dblarr(7)   ,$;deg za rotated offset all alfa bm to center 
    prfeed_offaz	: 0D		  ,$;deg az offset to center of alfa beam 
    prfeed_offza	: 0D		  ,$;deg za offset to center of alfa beam 
    alfa_raj		:dblarr(7)    ,$; hr starting actual ra position of alfabeams 
    alfa_decj		:dblarr(7)	  ,$; deg starting actual dec pos of alfa beams 
    alfa_az			:dblarr(7)	  ,$; deg starting actual az pos of alfa beams 
    alfa_za			:dblarr(7)    ,$; deg starting actual za pos of alfa beams 
    alfa_ang		:0D			  ,$; deg alfa rotation angle  
    para_ang		:0D			  ,$; deg paralactic angle of center beam 
    frontend        :bytarr(24)   ,$; receiver abbrev name 

; add iflo data */

    syn1           : 0.D         ,$; upstairs synthesizer freq Hz 
    synfrq         : dblarr(4)   ,$; downstairs synthesizers (Hz)


	prfeed		   : 0b          ,$; centered alfa beam
    shcl           : 0b          ,$; true if receiver shutter closed 
    sbshcl         : 0b          ,$; true if Sband receiver shutter closed 

    rfnum          : 0b          ,$; position of the receiver selectror 
    zmnormal       : 0b          ,$; true normal position, false switched
    rfattn         : bytarr(2)   ,$; attenuator position db 
    ifnum          : 0b          ,$; ifSel 1/300,2/750,3/1500,4/10GHz, 5-thru 
    ifattn         : bytarr(2)   ,$; IF attenuator positions  
    fiber          : 0b          ,$;true fi fiber is chosen 
    ac2sw          : 0b          ,$; ac pwr to various instrm and other stuff
    if750nb        : 0b          ,$;narrow band 750 filter selected

    phbsig         : 0b          ,$; converter combiner signal phase adjust 
    hybrid         : 0b          ,$; converter combiner hybrid  
    phblo          : 0b          ,$; convert combiner lo phase adjust 

;/* downstairs */

    xfnormal       : 0b          ,$;  transfer switch true if normal downstairs
    noise          : 0b          ,$;  noise on 
    gain           : bytarr(2)   ,$;  gain of downstairs amps 
    inpfrq         : 0b          ,$;  input distributor position 
    mixer          : bytarr(4)   ,$;  mixer source switches 
    vlbainp        : 0b          ,$;  vlba input switch position 
    ampinp         : bytarr(4)   ,$;  amplifier input source switches 
    extinp         : bytarr(4)   ,$;  external input selector switches 
    syndest        : bytarr(4)   ,$;  synthesizer destinations 
    calsrc         : 0b          ,$;  cal source bit */

    vis30mhz       : 0b          ,$; greg 1 ch 0 
    pwrmet         : 0b          ,$; power meter input switch 
    blank430       : 0b          ,$;  430 blanking on 
	fill		   : bytarr(6)   }
;-----------------------------------------------------------------
; version 6 to version 7
;				isfolding    int   field 31 of version 7
;				isalfa       int         32
;	            attena       int         44
;	            attenb       int         45
;			    fill[7]      char 		at bottom
;
a={hdrwapp7Byte , $
	header_version	: 7L	,$; header revision currently 5
	header_size   	: 0L	,$; bytes in binary hdr (nom 2048)
	obs_type      	: bytarr(24),$;what kind of observation this is 
;                                  PULSAR_SEARCH
;						           PULSAR_FOLDING
;							       SPECTRA_TOTALPOWER
; 
;    The following are obtained from current telescope status display
;    note that start AST/LST are for reference purposes only and should 
;    not be taken as accurate time stamps. The time stamp can be derived
;    from the obs_date/start_time variables further down in the structure.
;
	src_ra			: 0.D	,$; req ra  J2000 hhmmss.sss
	src_dec		    : 0.D	,$; req dec J2000 ddmmss.sss
	start_az		: 0.D	,$; deg az start of scan
	start_za		: 0.D	,$; deg za start of scan
	start_ast       : 0.D	,$; AST at start of scan (secs)
	start_lst       : 0.D	,$; LST at start of scan (secs)

	cent_freq       : 0.D	,$; CFR on sky Mhz (coord sys topo??)
	obs_time        : 0.D	,$; usr req period of observation secs 
	samp_time       : 0.D	,$; usr req sample time usecs
	wapp_time       : 0.D	,$; actual sample time. usrreq + dead time
	bandwidth       : 0.D	,$; total bandwidth mhz for this obs 50 or 100

	num_lags        : 0L 	,$; usrReq lags per dump per spectrum 
	scan_number     : 0L 	,$; year + daynumber + 3 digitnumber (*100,1000??)

	src_name        : bytarr(24),$;srcname
	obs_date        : bytarr(24),$;yyyymmdd
	start_time      : bytarr(24) ,$;utsecs from midnite (start on 1 sec tick)
	proj_id         : bytarr(24) ,$;user supplied ao proposal number 
	observers       : bytarr(24),$;user supplied observers names

	nifs            : 0L        ,$;number of IF'S 1,2, 4=fullstokes
	level           : 0L        ,$;1=3level, 2=9level quantization
	sum             : 0L        ,$;1=Summation 2ifs (pols?), 0--> no
	freqinversion   : 0L        ,$;1=yes, 0=no
    timeoff         : 0LL       ,$;# of reads between obs start and snap block 
;                                  tm offsetStart of observation.
;							       wapp_time*numrecs. usecs??
	lagformat       : 0L        ,$;0=16bit uint lags, 1=32bit uint lags
;                                  2=32bit float lags, 3=32bit float spectra
	lagtrunc        : 0L        ,$;we truncate data (0 no trunc)
;                                  for 16 bit lagmux modes, selects which
;                                  16 bits of the 32 are included as data  
;                                   0 is bits 15-0 1,16-1 2,17-2...7,22-7 
;
    firstchannel    : 0L        ,$;0 polA first, 1 if polB is first
    nbins           : 0L        ,$;# of time bins for pulsar folding mode 
;                                    doubles as maxrecs for snap mode 
;   new for version 7
	isfolding       : 0L        ,$;is folding selected
	isalfa          : 0L        ,$;is ALFA  selected

    dumptime        : 0.D       ,$;folded integrations for this period of time
	power_analog    : dblarr(2) ,$; power measured by analog detector
;    
;    In the following, pulsar-specific information is recorded for use 
;    by folding programs e.g. the quick-look software. This is passed to 
;    WAPP by psrcontrol at the start of the observation. 
;
;    The apparent pulse phase and frequency at time "dt" minutes with
;    respect to the start of the observation are then calculated as:
;
;    phase = rphase + dt*60*f0 + coeff[0] + dt*coeff[1] + dt*dt*coeff[2] + ...
;    freq(Hz) = f0 + (1/60)*(coeff[1] + 2*dt*coeff[2] + 3*dt*dt*coeff[3] + ...)
;
;    where the C notation has been used (i.e. coeff[0] is first coefficient etc)
;    for details, see TEMPO notes (http://www.naic.edu/~pulsar/docs/tempo.txt)

	psr_dm          : 0.D       ,$;dispersion measure (pc/cm^3)
	rphase          : dblarr(16) ,$;reference phase of pulse 0-1
	psr_f0          : dblarr(16) ,$;pulse freq at referenche epoch (hz)
	poly_tmid       : dblarr(16) ,$;midpnt of polyco (in MJD)
	coef            : dblarr(192),$;polynomial coef calculated by tempo [9,16]
	num_coef        : lonarr(16)  ,$;number of coefficients
	hostname        : bytarr(24)  ,$; computer data taken on
; new data hdr 6
    fold_bits       : 0L          ,$;0 if 16 bits (old def) 1 if 32 bit folding
    iflo_flip       : 0L          ,$; consider entire iflo and determine flip 
; new version 7
	attena          : 0L          ,$; 1st board parallel port value
	attenb          : 0L          ,$; 2nd board parallel port value

; add iflo data */

    syn1           : 0.D         ,$; upstairs synthesizer freq Hz 
    synfrq         : dblarr(4)   ,$; downstairs synthesizers (Hz)
    shcl           : 0b          ,$; true if receiver shutter closed 
    sbshcl         : 0b          ,$; true if Sband receiver shutter closed 
    rfnum          : 0b          ,$; position of the receiver selectror 
    zmnormal       : 0b          ,$; true normal position, false switched
    rfattn         : bytarr(2)   ,$; attenuator position db 
    ifnum          : 0b          ,$; ifSel 1/300,2/750,3/1500,4/10GHz, 5-thru 
    ifattn         : bytarr(2)   ,$; IF attenuator positions  
    fiber          : 0b          ,$;true fi fiber is chosen 
    ac2sw          : 0b          ,$; ac pwr to various instrm and other stuff
    if750nb        : 0b          ,$;narrow band 750 filter selected
    phbsig         : 0b          ,$; converter combiner signal phase adjust 
    hybrid         : 0b          ,$; converter combiner hybrid  
    phblo          : 0b          ,$; convert combiner lo phase adjust 
;/* downstairs */
    xfnormal       : 0b          ,$;  transfer switch true if normal downstairs
    noise          : 0b          ,$;  noise on 
    gain           : bytarr(2)   ,$;  gain of downstairs amps 
    inpfrq         : 0b          ,$;  input distributor position 
    mixer          : bytarr(4)   ,$;  mixer source switches 
    vlbainp        : 0b          ,$;  vlba input switch position 
    ampinp         : bytarr(4)   ,$;  amplifier input source switches 
    extinp         : bytarr(4)   ,$;  external input selector switches 
    syndest        : bytarr(4)   ,$;  synthesizer destinations 
    calsrc         : 0b          ,$;  cal source bit */
    vis30mhz       : 0b          ,$; greg 1 ch 0 
    pwrmet         : 0b          ,$; power meter input switch 
    blank430       : 0b          ,$;  430 blanking on 
	fill		   : bytarr(7)   }
;-----------------------------------------------------------------
; version 6
a={hdrwapp6Byte , $
	header_version	: 6L	,$; header revision currently 5
	header_size   	: 0L	,$; bytes in binary hdr (nom 2048)
	obs_type      	: bytarr(24),$;what kind of observation this is 
;                                  PULSAR_SEARCH
;						           PULSAR_FOLDING
;							       SPECTRA_TOTALPOWER
; 
;    The following are obtained from current telescope status display
;    note that start AST/LST are for reference purposes only and should 
;    not be taken as accurate time stamps. The time stamp can be derived
;    from the obs_date/start_time variables further down in the structure.
;
	src_ra			: 0.D	,$; req ra  J2000 hhmmss.sss
	src_dec		    : 0.D	,$; req dec J2000 ddmmss.sss
	start_az		: 0.D	,$; deg az start of scan
	start_za		: 0.D	,$; deg za start of scan
	start_ast       : 0.D	,$; AST at start of scan (secs)
	start_lst       : 0.D	,$; LST at start of scan (secs)

	cent_freq       : 0.D	,$; CFR on sky Mhz (coord sys topo??)
	obs_time        : 0.D	,$; usr req period of observation secs 
	samp_time       : 0.D	,$; usr req sample time usecs
	wapp_time       : 0.D	,$; actual sample time. usrreq + dead time
	bandwidth       : 0.D	,$; total bandwidth mhz for this obs 50 or 100

	num_lags        : 0L 	,$; usrReq lags per dump per spectrum 
	scan_number     : 0L 	,$; year + daynumber + 3 digitnumber (*100,1000??)

	src_name        : bytarr(24),$;srcname
	obs_date        : bytarr(24),$;yyyymmdd
	start_time      : bytarr(24) ,$;utsecs from midnite (start on 1 sec tick)
	proj_id         : bytarr(24) ,$;user supplied ao proposal number 
	observers       : bytarr(24),$;user supplied observers names

	nifs            : 0L        ,$;number of IF'S 1,2, 4=fullstokes
	level           : 0L        ,$;1=3level, 2=9level quantization
	sum             : 0L        ,$;1=Summation 2ifs (pols?), 0--> no
	freqinversion   : 0L        ,$;1=yes, 0=no
    timeoff         : 0LL       ,$;# of reads between obs start and snap block 
;                                  tm offsetStart of observation.
;							       wapp_time*numrecs. usecs??
	lagformat       : 0L        ,$;0=16bit uint lags, 1=32bit uint lags
;                                  2=32bit float lags, 3=32bit float spectra
	lagtrunc        : 0L        ,$;we truncate data (0 no trunc)
;                                  for 16 bit lagmux modes, selects which
;                                  16 bits of the 32 are included as data  
;                                   0 is bits 15-0 1,16-1 2,17-2...7,22-7 
;
    firstchannel    : 0L        ,$;0 polA first, 1 if polB is first
    nbins           : 0L        ,$;# of time bins for pulsar folding mode 
;                                    doubles as maxrecs for snap mode 
    dumptime        : 0.D       ,$;folded integrations for this period of time
	power_analog    : dblarr(2) ,$; power measured by analog detector
;    
;    In the following, pulsar-specific information is recorded for use 
;    by folding programs e.g. the quick-look software. This is passed to 
;    WAPP by psrcontrol at the start of the observation. 
;
;    The apparent pulse phase and frequency at time "dt" minutes with
;    respect to the start of the observation are then calculated as:
;
;    phase = rphase + dt*60*f0 + coeff[0] + dt*coeff[1] + dt*dt*coeff[2] + ...
;    freq(Hz) = f0 + (1/60)*(coeff[1] + 2*dt*coeff[2] + 3*dt*dt*coeff[3] + ...)
;
;    where the C notation has been used (i.e. coeff[0] is first coefficient etc)
;    for details, see TEMPO notes (http://www.naic.edu/~pulsar/docs/tempo.txt)

	psr_dm          : 0.D       ,$;dispersion measure (pc/cm^3)
	rphase          : dblarr(16) ,$;reference phase of pulse 0-1
	psr_f0          : dblarr(16) ,$;pulse freq at referenche epoch (hz)
	poly_tmid       : dblarr(16) ,$;midpnt of polyco (in MJD)
	coef            : dblarr(192),$;polynomial coef calculated by tempo [9,16]
	num_coef        : lonarr(16)  ,$;number of coefficients
	hostname        : bytarr(24)  ,$; computer data taken on
; new data hdr 6
    fold_bits       : 0L          ,$;0 if 16 bits (old def) 1 if 32 bit folding
    iflo_flip       : 0L          ,$; consider entire iflo and determine flip 

; add iflo data */

    syn1           : 0.D         ,$; upstairs synthesizer freq Hz 
    synfrq         : dblarr(4)   ,$; downstairs synthesizers (Hz)
    shcl           : 0b          ,$; true if receiver shutter closed 
    sbshcl         : 0b          ,$; true if Sband receiver shutter closed 
    rfnum          : 0b          ,$; position of the receiver selectror 
    zmnormal       : 0b          ,$; true normal position, false switched
    rfattn         : bytarr(2)   ,$; attenuator position db 
    ifnum          : 0b          ,$; ifSel 1/300,2/750,3/1500,4/10GHz, 5-thru 
    ifattn         : bytarr(2)   ,$; IF attenuator positions  
    fiber          : 0b          ,$;true fi fiber is chosen 
    ac2sw          : 0b          ,$; ac pwr to various instrm and other stuff
    phbsig         : 0b          ,$; converter combiner signal phase adjust 
    hybrid         : 0b          ,$; converter combiner hybrid  
    phblo          : 0b          ,$; convert combiner lo phase adjust 
;/* downstairs */
    xfnormal       : 0b          ,$;  transfer switch true if normal downstairs
    noise          : 0b          ,$;  noise on 
    gain           : bytarr(2)   ,$;  gain of downstairs amps 
    inpfrq         : 0b          ,$;  input distributor position 
    mixer          : bytarr(4)   ,$;  mixer source switches 
    vlbainp        : 0b          ,$;  vlba input switch position 
    ampinp         : bytarr(4)   ,$;  amplifier input source switches 
    extinp         : bytarr(4)   ,$;  external input selector switches 
    syndest        : bytarr(4)   ,$;  synthesizer destinations 
    calsrc         : 0b          ,$;  cal source bit */
    vis30mhz       : 0b          ,$; greg 1 ch 0 
    pwrmet         : 0b          ,$; power meter input switch 
    blank430       : 0b          } ; 430 blanking on 
;-----------------------------------------------------------------
; version 5
;   ver 5        ver 6
;   none         22*4 =88  more bytes
;
a={hdrwapp5Byte , $
	header_version	: 5L	,$; header revision currently 5
	header_size   	: 0L	,$; bytes in binary hdr (nom 2048)
	obs_type      	: bytarr(24),$;what kind of observation this is 
;                                  PULSAR_SEARCH
;						           PULSAR_FOLDING
;							       SPECTRA_TOTALPOWER
; 
;    The following are obtained from current telescope status display
;    note that start AST/LST are for reference purposes only and should 
;    not be taken as accurate time stamps. The time stamp can be derived
;    from the obs_date/start_time variables further down in the structure.
;
	src_ra			: 0.D	,$; req ra  J2000 hhmmss.sss
	src_dec		    : 0.D	,$; req dec J2000 ddmmss.sss
	start_az		: 0.D	,$; deg az start of scan
	start_za		: 0.D	,$; deg za start of scan
	start_ast       : 0.D	,$; AST at start of scan (secs)
	start_lst       : 0.D	,$; LST at start of scan (secs)

	cent_freq       : 0.D	,$; CFR on sky Mhz (coord sys topo??)
	obs_time        : 0.D	,$; usr req period of observation secs 
	samp_time       : 0.D	,$; usr req sample time usecs
	wapp_time       : 0.D	,$; actual sample time. usrreq + dead time
	bandwidth       : 0.D	,$; total bandwidth mhz for this obs 50 or 100

	num_lags        : 0L 	,$; usrReq lags per dump per spectrum 
	scan_number     : 0L 	,$; year + daynumber + 3 digitnumber (*100,1000??)

	src_name        : bytarr(24),$;srcname
	obs_date        : bytarr(24),$;yyyymmdd
	start_time      : bytarr(24) ,$;utsecs from midnite (start on 1 sec tick)
	proj_id         : bytarr(24) ,$;user supplied ao proposal number 
	observers       : bytarr(24),$;user supplied observers names

	nifs            : 0L        ,$;number of IF'S 1,2, 4=fullstokes
	level           : 0L        ,$;1=3level, 2=9level quantization
	sum             : 0L        ,$;1=Summation 2ifs (pols?), 0--> no
	freqinversion   : 0L        ,$;1=yes, 0=no
    timeoff         : 0LL       ,$;# of reads between obs start and snap block 
;                                  tm offsetStart of observation.
;							       wapp_time*numrecs. usecs??
	lagformat       : 0L        ,$;0=16bit uint lags, 1=32bit uint lags
;                                  2=32bit float lags, 3=32bit float spectra
	lagtrunc        : 0L        ,$;we truncate data (0 no trunc)
;                                  for 16 bit lagmux modes, selects which
;                                  16 bits of the 32 are included as data  
;                                   0 is bits 15-0 1,16-1 2,17-2...7,22-7 
;
    firstchannel    : 0L        ,$;0 polA first, 1 if polB is first
    nbins           : 0L        ,$;# of time bins for pulsar folding mode 
;                                    doubles as maxrecs for snap mode 
    dumptime        : 0.D       ,$;folded integrations for this period of time
	power_analog    : dblarr(2) ,$; power measured by analog detector
;    
;    In the following, pulsar-specific information is recorded for use 
;    by folding programs e.g. the quick-look software. This is passed to 
;    WAPP by psrcontrol at the start of the observation. 
;
;    The apparent pulse phase and frequency at time "dt" minutes with
;    respect to the start of the observation are then calculated as:
;
;    phase = rphase + dt*60*f0 + coeff[0] + dt*coeff[1] + dt*dt*coeff[2] + ...
;    freq(Hz) = f0 + (1/60)*(coeff[1] + 2*dt*coeff[2] + 3*dt*dt*coeff[3] + ...)
;
;    where the C notation has been used (i.e. coeff[0] is first coefficient etc)
;    for details, see TEMPO notes (http://www.naic.edu/~pulsar/docs/tempo.txt)

	psr_dm          : 0.D       ,$;dispersion measure (pc/cm^3)
	rphase          : dblarr(16) ,$;reference phase of pulse 0-1
	psr_f0          : dblarr(16) ,$;pulse freq at referenche epoch (hz)
	poly_tmid       : dblarr(16) ,$;midpnt of polyco (in MJD)
	coef            : dblarr(192),$;polynomial coef calculated by tempo [9,16]
	num_coef        : lonarr(16)  ,$;number of coefficients
 	hostname        : bytarr(24)}; computer data taken on
;------------------------------------------------------------------------------
; VERSION 4
;   ver 4        ver 5
;   none         hostanme[24]
;
a={hdrwapp4Byte , $
    header_version  : 4L    ,$; header revision currently 5
    header_size     : 0L    ,$; bytes in binary hdr (nom 2048)
    obs_type        : bytarr(24),$;what kind of observation this is
    src_ra          : 0.D   ,$; req ra  J2000 hhmmss.sss
    src_dec         : 0.D   ,$; req dec J2000 ddmmss.sss
    start_az        : 0.D   ,$; deg az start of scan
    start_za        : 0.D   ,$; deg za start of scan
    start_ast       : 0.D   ,$; AST at start of scan (secs)
    start_lst       : 0.D   ,$; LST at start of scan (secs)
    cent_freq       : 0.D   ,$; CFR on sky Mhz (coord sys topo??)
    obs_time        : 0.D   ,$; usr req period of observation secs
    samp_time       : 0.D   ,$; usr req sample time usecs
    wapp_time       : 0.D   ,$; actual sample time. usrreq + dead time
    bandwidth       : 0.D   ,$; total bandwidth mhz for this obs 50 or 100
    num_lags        : 0L    ,$; usrReq lags per dump per spectrum
    scan_number     : 0L    ,$; year + daynumber + 3 digitnumber (*100,1000??)
    src_name        : bytarr(24),$;srcname
    obs_date        : bytarr(24),$;yyyymmdd
    start_time      : bytarr(24) ,$;utsecs from midnite (start on 1 sec tick)
    proj_id         : bytarr(24) ,$;user supplied ao proposal number
    observers       : bytarr(24),$;user supplied observers names
    nifs            : 0L        ,$;number of IF'S 1,2, 4=fullstokes
    level           : 0L        ,$;1=3level, 2=9level quantization
    sum             : 0L        ,$;1=Summation 2ifs (pols?), 0--> no
    freqinversion   : 0L        ,$;1=yes, 0=no
    timeoff         : 0LL       ,$;# of reads between obs start and snap block
    lagformat       : 0L        ,$;0=16bit uint lags, 1=32bit uint lags
    lagtrunc        : 0L        ,$;we truncate data (0 no trunc)
    firstchannel    : 0L        ,$;0 polA first, 1 if polB is first
    nbins           : 0L        ,$;# of time bins for pulsar folding mode
    dumptime        : 0.D       ,$;folded integrations for this period of time
    power_analog    : dblarr(2) ,$; power measured by analog detector
    psr_dm          : 0.D       ,$;dispersion measure (pc/cm^3)
    rphase          : dblarr(16) ,$;reference phase of pulse 0-1
    psr_f0          : dblarr(16) ,$;pulse freq at referenche epoch (hz)
    poly_tmid       : dblarr(16) ,$;midpnt of polyco (in MJD)
    coef            : dblarr(192),$;polynomial coef calculated by tempo [9,16]
    num_coef        : lonarr(16) } ;number of coefficients
; no hostname[24] bytes
;
;------------------------------------------------------------------------------
; VERSION 3
;   ver 3        ver 4
;  coef[144]   --> coef[192]
;  filler[120] --> removed
;
a={hdrwapp3Byte , $
    header_version  : 3L    ,$; header revision currently 5
    header_size     : 0L    ,$; bytes in binary hdr (nom 2048)
    obs_type        : bytarr(24),$;what kind of observation this is
    src_ra          : 0.D   ,$; req ra  J2000 hhmmss.sss
    src_dec         : 0.D   ,$; req dec J2000 ddmmss.sss
    start_az        : 0.D   ,$; deg az start of scan
    start_za        : 0.D   ,$; deg za start of scan
    start_ast       : 0.D   ,$; AST at start of scan (secs)
    start_lst       : 0.D   ,$; LST at start of scan (secs)
    cent_freq       : 0.D   ,$; CFR on sky Mhz (coord sys topo??)
    obs_time        : 0.D   ,$; usr req period of observation secs
    samp_time       : 0.D   ,$; usr req sample time usecs
    wapp_time       : 0.D   ,$; actual sample time. usrreq + dead time
    bandwidth       : 0.D   ,$; total bandwidth mhz for this obs 50 or 100
    num_lags        : 0L    ,$; usrReq lags per dump per spectrum
    scan_number     : 0L    ,$; year + daynumber + 3 digitnumber (*100,1000??)
    src_name        : bytarr(24),$;srcname
    obs_date        : bytarr(24),$;yyyymmdd
    start_time      : bytarr(24) ,$;utsecs from midnite (start on 1 sec tick)
    proj_id         : bytarr(24) ,$;user supplied ao proposal number
    observers       : bytarr(24),$;user supplied observers names
    nifs            : 0L        ,$;number of IF'S 1,2, 4=fullstokes
    level           : 0L        ,$;1=3level, 2=9level quantization
    sum             : 0L        ,$;1=Summation 2ifs (pols?), 0--> no
    freqinversion   : 0L        ,$;1=yes, 0=no
    timeoff         : 0LL       ,$;# of reads between obs start and snap block
    lagformat       : 0L        ,$;0=16bit uint lags, 1=32bit uint lags
    lagtrunc        : 0L        ,$;we truncate data (0 no trunc)
    firstchannel    : 0L        ,$;0 polA first, 1 if polB is first
    nbins           : 0L        ,$;# of time bins for pulsar folding mode
    dumptime        : 0.D       ,$;folded integrations for this period of time
    power_analog    : dblarr(2) ,$; power measured by analog detector
    psr_dm          : 0.D       ,$;dispersion measure (pc/cm^3)
    rphase          : dblarr(16) ,$;reference phase of pulse 0-1
    psr_f0          : dblarr(16) ,$;pulse freq at referenche epoch (hz)
    poly_tmid       : dblarr(16) ,$;midpnt of polyco (in MJD)
    coef            : dblarr(144),$;polynomial coef calculated by tempo [9,16]
    num_coef        : lonarr(16)  ,$;number of coefficients
	filler          : bytarr(120) }
;------------------------------------------------------------------------------
; VERSION 2
;   ver 2        ver 3
;   rphase[9];    rphase[16]
;   psr_f0[9];    psr_f0[16]
;   poly_tmid[9]  poly_tmid[16]
;   num_coefs[9]  num_coefs16]
;   filler[324]   filler[120]
;
a={hdrwapp2Byte , $
    header_version  : 2L    ,$; header revision currently 5
    header_size     : 0L    ,$; bytes in binary hdr (nom 2048)
    obs_type        : bytarr(24),$;what kind of observation this is
    src_ra          : 0.D   ,$; req ra  J2000 hhmmss.sss
    src_dec         : 0.D   ,$; req dec J2000 ddmmss.sss
    start_az        : 0.D   ,$; deg az start of scan
    start_za        : 0.D   ,$; deg za start of scan
    start_ast       : 0.D   ,$; AST at start of scan (secs)
    start_lst       : 0.D   ,$; LST at start of scan (secs)
    cent_freq       : 0.D   ,$; CFR on sky Mhz (coord sys topo??)
    obs_time        : 0.D   ,$; usr req period of observation secs
    samp_time       : 0.D   ,$; usr req sample time usecs
    wapp_time       : 0.D   ,$; actual sample time. usrreq + dead time
    bandwidth       : 0.D   ,$; total bandwidth mhz for this obs 50 or 100
    num_lags        : 0L    ,$; usrReq lags per dump per spectrum
    scan_number     : 0L    ,$; year + daynumber + 3 digitnumber (*100,1000??)
    src_name        : bytarr(24),$;srcname
    obs_date        : bytarr(24),$;yyyymmdd
    start_time      : bytarr(24) ,$;utsecs from midnite (start on 1 sec tick)
    proj_id         : bytarr(24) ,$;user supplied ao proposal number
    observers       : bytarr(24),$;user supplied observers names
    nifs            : 0L        ,$;number of IF'S 1,2, 4=fullstokes
    level           : 0L        ,$;1=3level, 2=9level quantization
    sum             : 0L        ,$;1=Summation 2ifs (pols?), 0--> no
    freqinversion   : 0L        ,$;1=yes, 0=no
    timeoff         : 0LL       ,$;# of reads between obs start and snap block
    lagformat       : 0L        ,$;0=16bit uint lags, 1=32bit uint lags
    lagtrunc        : 0L        ,$;we truncate data (0 no trunc)
    firstchannel    : 0L        ,$;0 polA first, 1 if polB is first
    nbins           : 0L        ,$;# of time bins for pulsar folding mode
    dumptime        : 0.D       ,$;folded integrations for this period of time
    power_analog    : dblarr(2) ,$; power measured by analog detector
    psr_dm          : 0.D       ,$;dispersion measure (pc/cm^3)
    rphase          : dblarr(9) ,$;reference phase of pulse 0-1
    psr_f0          : dblarr(9) ,$;pulse freq at referenche epoch (hz)
    poly_tmid       : dblarr(9) ,$;midpnt of polyco (in MJD)
    coef            : dblarr(144),$;polynomial coef calculated by tempo [9,16]
    num_coef        : lonarr(9)  ,$;number of coefficients
    filler          : bytarr(324) }
;------------------------------------------------------------------------------
; the header with strings rather than bytes
; and 4 extra fields added:
;
; byteOffData      .. byte offset start of data in this file
; needSwap         .. if true then spectra needs to be swapped on this machine
;
a={hdrwapp  , $
	header_version	: 8L	,$; header revision currently 7
	header_size   	: 0L	,$; bytes in binary hdr (nom 2048)
	obs_type      	: ''    ,$;what kind of observation this is 
;                                  PULSAR_SEARCH
;						           PULSAR_FOLDING
;							       SPECTRA_TOTALPOWER
; 
;    The following are obtained from current telescope status display
;    note that start AST/LST are for reference purposes only and should 
;    not be taken as accurate time stamps. The time stamp can be derived
;    from the obs_date/start_time variables further down in the structure.
;
	src_ra			: 0.D	,$; req ra  J2000 hhmmss.sss
	src_dec		    : 0.D	,$; req dec J2000 ddmmss.sss
	start_az		: 0.D	,$; deg az start of scan
	start_za		: 0.D	,$; deg za start of scan
	start_ast       : 0.D	,$; AST at start of scan (secs)
	start_lst       : 0.D	,$; LST at start of scan (secs)

	cent_freq       : 0.D	,$; CFR on sky Mhz (coord sys topo??)
	obs_time        : 0.D	,$; usr req period of observation secs 
	samp_time       : 0.D	,$; usr req sample time usecs
	wapp_time       : 0.D	,$; actual sample time. usrreq + dead time
	bandwidth       : 0.D	,$; total bandwidth mhz for this obs 50 or 100

	num_lags        : 0L 	,$; usrReq lags per dump per spectrum 
	scan_number     : 0L 	,$; year + daynumber + 3 digitnumber (*100,1000??)

	src_name        : ''    ,$;srcname
	obs_date        : ''    ,$;yyyymmdd
	start_time      : ''    ,$;utsecs from midnite (start on 1 sec tick)
	proj_id         : ''    ,$;user supplied ao proposal number 
	observers       : ''    ,$;user supplied observers names

	nifs            : 0L        ,$;number of IF'S 1,2, 4=fullstokes
	level           : 0L        ,$;1=3level, 2=9level quantization
	sum             : 0L        ,$;1=Summation 2ifs (pols?), 0--> no
	freqinversion   : 0L        ,$;1=yes, 0=no
    timeoff         : 0LL       ,$;# of reads between obs start and snap block 
;                                  tm offsetStart of observation.
;							       wapp_time*numrecs. usecs??
	lagformat       : 0L        ,$;0=16bit uint lags, 1=32bit uint lags
;                                  2=32bit float lags, 3=32bit float spectra
	lagtrunc        : 0L        ,$;we truncate data (0 no trunc)
;                                  for 16 bit lagmux modes, selects which
;                                  16 bits of the 32 are included as data  
;                                   0 is bits 15-0 1,16-1 2,17-2...7,22-7 
;
    firstchannel    : 0L        ,$;0 polA first, 1 if polB is first
    nbins           : 0L        ,$;# of time bins for pulsar folding mode 
;                                    doubles as maxrecs for snap mode
;   new for version 7
	isfolding       : 0L        ,$;is folding selected
    isalfa          : 0L        ,$;is ALFA  selected

;                                    doubles as maxrecs for snap mode 
    dumptime        : 0.D       ,$;folded integrations for this period of time
	power_analog    : dblarr(2) ,$; power measured by analog detector
;    
;    In the following, pulsar-specific information is recorded for use 
;    by folding programs e.g. the quick-look software. This is passed to 
;    WAPP by psrcontrol at the start of the observation. 
;
;    The apparent pulse phase and frequency at time "dt" minutes with
;    respect to the start of the observation are then calculated as:
;
;    phase = rphase + dt*60*f0 + coeff[0] + dt*coeff[1] + dt*dt*coeff[2] + ...
;    freq(Hz) = f0 + (1/60)*(coeff[1] + 2*dt*coeff[2] + 3*dt*dt*coeff[3] + ...)
;
;    where the C notation has been used (i.e. coeff[0] is first coefficient etc)
;    for details, see TEMPO notes (http://www.naic.edu/~pulsar/docs/tempo.txt)

	psr_dm          : 0.D       ,$;dispersion measure (pc/cm^3)
	rphase          : dblarr(16) ,$;reference phase of pulse 0-1
	psr_f0          : dblarr(16) ,$;pulse freq at referenche epoch (hz)
	poly_tmid       : dblarr(16) ,$;midpnt of polyco (in MJD)
	coef            : dblarr(192),$;polynomial coef calculated by tempo [9,16]
	num_coef        : lonarr(16)  ,$;number of coefficients
	hostname        : ''          ,$; hostname data taken on 
; new data hdr 6
    fold_bits       : 0L          ,$;0 if 16 bits (old def) 1 if 32 bit folding
    iflo_flip       : 0L          ,$; consider entire iflo and determine flip
; new version 7
	attena          : 0L          ,$; 1st board parallel port value
	attenb          : 0L          ,$; 2nd board parallel port value

; alfa info

    rfeed_offaz     : dblarr(7)   ,$;deg azRotatedOffset all alfaBmsm to center
    rfeed_offza     : dblarr(7)   ,$;deg za rotated offset all alfa bm to center
    prfeed_offaz    : 0D          ,$;deg az offset to center of alfa beam
    prfeed_offza    : 0D          ,$;deg za offset to center of alfa beam
    alfa_raj        :dblarr(7)    ,$; hr starting actual ra position of alfabeams
    alfa_decj       :dblarr(7)    ,$; deg starting actual dec pos of alfa beams
    alfa_az         :dblarr(7)    ,$; deg starting actual az pos of alfa beams
    alfa_za         :dblarr(7)    ,$; deg starting actual za pos of alfa beams
    alfa_ang        :0D           ,$; deg alfa rotation angle
    para_ang        :0D           ,$; deg paralactic angle of center beam
    frontend        :''    		  ,$; receiver abbrev name


; add iflo data */

    syn1           : 0.D         ,$; upstairs synthesizer freq Hz
    synfrq         : dblarr(4)   ,$; downstairs synthesizers (Hz)
	prfeed         : 0b          ,$; centered alfa beam
    shcl           : 0b          ,$; true if receiver shutter closed
    sbshcl         : 0b          ,$; true if Sband receiver shutter closed
    rfnum          : 0b          ,$; position of the receiver selectror
    zmnormal       : 0b          ,$; true normal position, false switched
    rfattn         : bytarr(2)   ,$; attenuator position db
    ifnum          : 0b          ,$; ifSel 1/300,2/750,3/1500,4/10GHz, 5-thru
    ifattn         : bytarr(2)   ,$; IF attenuator positions
    fiber          : 0b          ,$;true fi fiber is chosen
    ac2sw          : 0b          ,$; ac pwr to various instrm and other stuff
    if750nb        : 0b          ,$;narrow band 750 filter selected
    phbsig         : 0b          ,$; converter combiner signal phase adjust
    hybrid         : 0b          ,$; converter combiner hybrid
    phblo          : 0b          ,$; convert combiner lo phase adjust
; downstairs 
    xfnormal       : 0b          ,$;  transfer switch true if normal downstairs
    noise          : 0b          ,$;  noise on
    gain           : bytarr(2)   ,$;  gain of downstairs amps
    inpfrq         : 0b          ,$;  input distributor position
    mixer          : bytarr(4)   ,$;  mixer source switches
    vlbainp        : 0b          ,$;  vlba input switch position
    ampinp         : bytarr(4)   ,$;  amplifier input source switches
    extinp         : bytarr(4)   ,$;  external input selector switches
    syndest        : bytarr(4)   ,$;  synthesizer destinations
    calsrc         : 0b          ,$;  cal source bit */
    vis30mhz       : 0b          ,$; greg 1 ch 0
    pwrmet         : 0b          ,$; power meter input switch
    blank430       : 0b          ,$; 430 blanking on
;
;	additions for idl processing 
;
	obs_type_code   : 0L		  ,$;1  PULSAR_SEARCH
	                               $;2  PULSAR_FOLDING
	                               $;3  SPECTRA_TOTALPOWER

	byteOffData		: 0L		  ,$; byte offset start of data.
	needSwap   	    : 0L		  ,$; 1 if data is needs to be swapped
	filler          : 0L		  } ;
;
; structure for wappfileinfo
;
    a={wappfileCpu , dir    : ''    ,$; path including trailing /
                     fname  : ''    ,$; filename
                     hdr    : {hdrWapp}} ; wapp hdr this file
    a={wappfileInfo ,AstSec :      0L,$; start of this scan
                     nwapps :      0 ,$; number of wapps used
                    wappUsed: intarr(4),$; 0 not used,1 used
                    wapp    : replicate({wappfilecpu},4)}

