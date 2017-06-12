pro lsfs_shell, mhpath, datapath, inputfiles, savepath, $
	seq=seq, name=name, savefilename=savefilename, $
	quiet=quiet, skiprec=skiprec

;+
;purpose: act as a shell to run lsfs calib software and write out
;results in save files.
;QUIET means no plots or iterations output from carl9's lsfs nonlinear fit.
;format of lsfs output filename:
;	lsfs.20050713.1121254525.a2004.0000.sav
;	     yearmoda.utcstamp.prjct.filenr.
;
;the utcstamp was added on 16 jul 2005
;-

skipwb= 0
 
;READ FIRST MH FILE IN GROUP TO FIND STARTING UTCSTAMP...
mhfile= strmid( $
  inputfiles[ 0], 0, strpos( inputfiles[ 0], 'fits', /reverse_search)) $
        + 'mh.sav'
restore, mhpath+ mhfile
indx= where( strpos( mh.obsmode, 'SMARTF') ne -1, count)
utcstamp= mh[ indx[ 0]].utcstamp

res= strsplit( inputfiles[ 0], '.', /extract)
;savefilename= 'lsfs.'+ res[1] + '.' + res[2] + '.' + res[3] + '.sav'
savefilename= 'lsfs.'+ res[1] + '.' + $
	string( utcstamp, format='(i10.10)') + '.' + $
	res[2] + '.' + res[3] + '.sav'
 
;I WANATED TO USE ONLY THE FIRST FILE AND TEST FOR WHEN SMARTF STOPPED,
;BUT SMARTF IS STICKY AND THIS GIVES TOO MUCH DATA...
;firstfile= 'galfa.20041105.a1943.0000.fits'
;lsfs, path, firstfile, $
 
yesnonb= 3
 
lsfs, datapath, inputfiles, $
        ggwb, rf4wb, rfwb, fnewwb, multwb, problemwb, $
        ggnb, rf4nb, rfnb, fnewnb, multnb, problemnb, $
        bbfrq_nb, bbgain_dft_nb, rffrq_wb, rffrq_nb, $
        yesnowb=yesnowb, yesnonb=yesnonb, skipwb=skipwb, seq=seq, $
	error=error, quiet=quiet, skiprec=skiprec
 
if error ne 0 then return

;USE FOR TESTING:
;save,   ggwb, rf4wb, rfwb, fnewwb, multwb, problemwb, $
;        ggnb, rf4nb, rfnb, fnewnb, multnb, problemnb, $
;        bbfrq_nb, bbgain_dft_nb, $
;        rffrq_wb, rffrq_nb, $
;	file= 'ggnb.sav'
;
;stop

ggnb_recon, rffrq_wb, rffrq_nb, bbgain_dft_nb, ggwb, ggnb, $
        ggnb_7679, ggnb_coeffs, ggnb_sigcoeffs, ggnb_problem
 
if keyword_set( name) ne 1 then name=''

save,   ggwb, rf4wb, rfwb, fnewwb, multwb, problemwb, $
        ggnb, rf4nb, rfnb, fnewnb, multnb, problemnb, $
        bbfrq_nb, bbgain_dft_nb, rffrq_wb, rffrq_nb, $
        ggnb_7679, ggnb_coeffs, ggnb_sigcoeffs, ggnb_problem, $
        file= savepath+ name+ savefilename

indxwb= where( problemwb ne 0, countwb)
indxnb= where( problemnb ne 0, countnb)

if countwb ne 0 then begin
print, ' '
print, '********PROBLEMS IN WB LSFS FITS: NR PROBLEMS = ', countwb, ' **********'
endif

if countnb ne 0 then begin
print, ' '
print, '********PROBLEMS IN NB LSFS FITS: NR PROBLEMS = ', countnb, ' **********'
endif

indxggnb= where( ggnb_problem ne 0, countggnb)
if countnb ne 0 then begin
print, ' '
print, '********PROBLEMS IN GGNB POLYFIT: NR PROBLEMS = ', countggnb, ' **********'
endif


print, 'saving data in file ', savepath + name + savefilename


return
end
