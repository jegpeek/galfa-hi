;
; generic structures..
;
; added 05jul02
;
@hdrStd.h
@hdrPnt.h
@hdrIfLo.h
@hdrDop.h
@hdrProc.h
;
; scanlist structure created by getsl. used for randmon access to
; 20jan02 added fileindex..
; 08dec02 added julday
; files
a={ sl,                     $
    scan      :         0L, $; scannumber this entry
    bytepos   :         0L,$; byte pos start of this scan
    fileindex :         0L, $; lets you point to a filename array
    stat      :         0B ,$; not used yet..
    rcvnum    :         0B ,$; receiver number 1-16
    numfrq    :         0B ,$; number of freq,cor boards used this scan
    rectype   :         0B ,$;1-calon,2-caloff,3-posOn,4-posOff
    numrecs   :         0L ,$; number of groups(records in scan)
    freq      :   fltarr(4),$;topocentric freqMhz center each subband
	julday    :         0.D,$; julian day start of scan
    srcname   :         ' ',$;source name (max 12 long)
    procname  :         ' '};procedure name used.
;
; 	when creating scanlists of multiple files
;
a={slInd , $
        path    : '' , $; pathname
        file    : '' , $; filename
		size    : 0UL, $; bytes in file
		tapenum : 0UL, $; non zero --> not on disc
        i1      : 0L , $; first index into large sl array
        i2      : 0L  } ; last index into large sl array

;   flux structure .. fluxsrc()
;   x=log10(freqMhz)
;   y=log10(S[ju])
;   y= a[0]+a[1]*x + a[2]*exp(-x)
;
;  25nov04 .. added ra,dec positions..
;
a={fluxdata,$
    name    : ' '   ,$; source name
    code    :  0    ,$; code 1-good,2-bad,3-from flux.ca
    coef    :  fltarr(3),$;
    rms     :  0.   ,$; rms of fit to data
	raHB    :  0.D  ,$; ra in hours    B1950
	decDB   :  0.D  ,$; dec in degrees B1950
	posCoord:  0    ,$; 0- no coord, valid pos coord.
    notes   : ' '   }

a={catentry,$
    name    : ' '   ,$; source name
	ra      : fltarr(3),$; hh mm ss
	dec     : fltarr(3),$; dd mm ss, always positive
	decsgn  :  0    ,$; sign of dec 1 or -1
	raH     :  0.d  ,$; ra  in hours
	decD    :  0.d  ,$; dec in deg (signed value)
	eol     :  ' '  } ; end of dec to end of line string
;
;
;fitazzainit - initialize to use fitazza() routine.
;SYNTAX: @fitazzainit
;ARGS:   none
;DESCRIPTION:
;   Initialize to use the fitazza() routine. This must be called once
;before using fitazza(). It defines the {fitazza} structure.
;SEE ALSO
;fitazza
; 
a={azzafit, $
            numCoef:        10L    ,$; for fit
            fittype:         1     ,$; 1-def,2-about za10,3-chebyshev 3rd order
            freq   :         0.    ,$; Mhz
             coef  :       dblarr(10),$;coef.
         sigmaCoef :       dblarr(10),$; sigmas on each coef.
             covar :       dblarr(10,10),$; covariance matrix
            chisq  :         0.D   ,$; of fit
           sigma   :         0.D   ,$; of fit - data
           zaSet   :        14.    ,$; za cutoff for higher order,or pivot
            rfNum  :         0     ,$; rcv num
             pol   :         ' '   ,$; 'a', 'b','i' stokes I
            type   :         ' '   ,$;gain,sefd,tsys,etc..
           title   :         ' '   ,$; for any plots top
           ytitle  :         ' '   ,$; for any plots left
           date    :         ' '   } ; fit run


