pro makemw, datapath, mwpath, inputfiles, inc0, inc1

;+
;purpose:
;	input a series of galfa fits files and make mw files.
;inputs
;	datapath, mwpath, inputfiles, inc0, inc1
;outputs: 
;	mw, the structure containing mh and the wb spectra
;action:
;	write mw....sav, the mw save file.
;-


FOR INC=INC0, INC1 DO BEGIN
filenm = datapath+ inputfiles[ inc]
print, inc, '  input file is... ', filenm

m1= mrdfits(filenm,1,hdr1)
nspectra= n_elements(m1)/14l
m1 = reform(temporary( m1), 2,7,nspectra)
m1_hdr, m1, mh, /nochdoppler

;stop

;if (inc eq inc0) then mwb_hdr, mh, m1

;mwb= mwb_hdr( mh, m1)
;if (inc eq inc0) then mwb= { mh : mh[0] , g_wide : fltarr( 512, 2, 7) }
;mw= replicate( mwb, 600, 7)

print, mh[uniq( mh.obsmode, sort( mh.obsmode))].obsmode

mw= mwb_hdr( mh, m1)

save, mw, file= mwpath+ 'mw' + inputfiles[ inc]

ENDFOR


end
