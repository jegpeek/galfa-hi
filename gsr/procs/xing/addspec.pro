;+
; NAME:
;   addspec
;
;
; PURPOSE:
;   To add the spectral template to the xarr structures
;
;
; CALLING SEQUENCE:
;  addspec, xarr
;
;
; INPUTS:
;  xarr - The xarr structure without the spectral templates. This 
;         format is more disk conservative.
;
; MODIFICATION HISTORY:
;   Inital documentation, November 17th, 2006
;   JEG Peek
;   moved the xdec and xra! JEGP, March 5 2008 (old bug!!)
;   goldston@astro.berkeley.edu
;-

pro addspec, xarr

n = n_elements(xarr)

xarr2 = replicate({scan1:0, beam1:0, time1:0l, pos1bef:0., pos1aft:0., fn1bef:'null', fn1aft:'null', W1:0., vlsr1:0., spect1:fltarr(8192), scan2:0, beam2:0, time2:0l, pos2bef:0., pos2aft:0.,fn2bef:'null', fn2aft:'null', W2:0., vlsr2:0.,spect2:fltarr(8192), XRA:0., Xdec:0., ZPTR:0., GAINR:0.}, n)

xarr2.scan1=xarr.scan1
xarr2.beam1=xarr.beam1
xarr2.time1=xarr.time1
xarr2.pos1bef=xarr.pos1bef
xarr2.pos1aft=xarr.pos1aft
xarr2.fn1bef=xarr.fn1bef
xarr2.fn1aft=xarr.fn1aft
xarr2.W1=xarr.W1
xarr2.vlsr1=xarr.vlsr1
xarr2.scan2=xarr.scan2
xarr2.beam2=xarr.beam2
xarr2.time2=xarr.time2
xarr2.pos2bef=xarr.pos2bef
xarr2.pos2aft=xarr.pos2aft
xarr2.fn2bef=xarr.fn2bef
xarr2.fn2aft=xarr.fn2aft
xarr2.W2=xarr.W2
xarr2.vlsr2=xarr.vlsr2
xarr2.xra=xarr.xra
xarr2.xdec=xarr.xdec



xarr = xarr2

end
