;+
;NAME:
;corinit - initialize to use the idl correlator routines.
;SYNTAX: @corinit   
;DESCRIPTION:
;   call this routine before using any of the correlator idl routines.
;It sets up the path for the idl correlator directory and defines the
;necessary structures.
;-


;@geninit


@hdrCor.h
@hdrMueller.h
addpath,'df'
addpath,'/dzd1/heiles/gsr/init/phil/Cor2

; @procfileinit
.compile corhquery
.compile corblauto
; 05jul02 moved to geninit
;.compile dophquery
;.compile pnthquery
;.compile iflohquery
addpath,'/dzd1/heiles/gsr/init/phil/Cor2/cormap'
;.compile corgethdr
;.compile corget
;.compile corwaitgrp
;.compile corlist
;.compile corfrq
;.compile corpwr
;.compile corhan
;.compile corplot
;.compile cornext
;.compile corloopinit
;.compile corloop
;.compile corwaitgrp
;.compile cormon
forward_function corget,chkcalonoff,corallocstr,coravgint,corcalonoff,$
        corcalonoffm,corfrq,corgethdr,corgetm,corimg,corinpscan,$
        cormedian,corposonoff,corposonoffm,corpwr,corpwrfile,corrms,$
        mmget ,cormapsclk,corhgainget,corhstate,cordfbp
