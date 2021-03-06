;+
;NAME:
;x111init - initialize idl to process x111 data.
;SYNTAX: @x111init
;ARGS:   none 
;DESCRIPION:
;   Initialize to process x111 data. This is interference monitoring
;data taken on the telescope. The routine calls @corinit, adds the
;Cor2/x111 path and defines the {x111imghdr} structure.
;SEE ALSO:
;x111imgdisp (x111 software documentation).
;-
; to process files worth of data
;
@corinit
addpath,'Cor2/x111'
a={x111imghdr,$
        dir : ' '   ,$; directory where the files are
       name : ' '   ,$;for variables  img is 'img'+name, hdr is hdr+namE
        cfr : 0.    ,$; cfr Mhz 
        bw  : 0.    ,$; bandwidth Mhz
        nx  : 0     ,$; number of x pixels
        ny  : 0     ,$; number of y pixels
      fltnst: 0     ,$; x pixel start for flattening (cnt from 0)
     fltnnum: 0     } ; number of x pixels to use for flattening
loadct,0
