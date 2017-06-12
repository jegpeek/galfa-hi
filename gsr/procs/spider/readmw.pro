;pro readmw, datapath, mwpath, inputfiles, inc0, inc1

;+
;purpose:
;	read the mw files and concatenate into a single structure called mx
;inputs
;	datapath, mwpath, inputfiles, inc0, inc1
;outputs: 
;	mw, the structure containing mh and the wb spectra
;action:
;	write mw....sav, the mw save file.
;-

nfiles= long( inc1-inc0+1)
zro= 0l

FOR INC=INC0, INC1 DO BEGIN
filenm = mwpath+ inputfiles[ inc]
print, inc, '  input file is... ', filenm
restore, filenm

if (inc eq inc0) then mx= replicate( mw[0], 600l* nfiles)

mx[ zro: zro+n_elements( mw)-1]= mw
zro= zro+ n_elements( mw)

ENDFOR

mx= temporary( mx[0: zro-1l])

;INTERPOLATE OVER CHNL 256...
mx.g_wide[ 256,*,*]= 0.5* (mx.g_wide[ 255,*,*]+ mx.g_wide[ 257,*,*])

end
