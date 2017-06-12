pro lsfs_shell, datapath, inputfiles, savepath, seq=seq, name=name

;+
;purpose: act as a shell to run lsfs calib software and write out
;results in save files.

skipwb= 0
 
res= strsplit( inputfiles[ 0], '.', /extract)
savefilename= 'lsfs.'+ res[1] + '.' + res[2] + '.' + res[3] + '.sav'
 
;I WANATED TO USE ONLY THE FIRST FILE AND TEST FOR WHEN SMARTF STOPPED,
;BUT SMARTF IS STICKY AND THIS GIVES TOO MUCH DATA...
;firstfile= 'galfa.20041105.a1943.0000.fits'
;lsfs, path, firstfile, $
 
yesnonb= 3
 
lsfs, datapath, inputfiles, $
        ggwb, rf4wb, rfwb, fnewwb, multwb, problemwb, $
        ggnb, rf4nb, rfnb, fnewnb, multnb, problemnb, $
        bbfrq_nb, bbgain_dft_nb, $
        yesnowb=yesnowb, yesnonb=yesnonb, skipwb=skipwb, seq=seq
 
ggnb_recon, bbfrq_nb, bbgain_dft_nb, ggnb, ggnb_7679
 
if keyword_set( name) ne 1 then name=''

save,   ggwb, rf4wb, rfwb, fnewwb, multwb, problemwb, $
        ggnb, rf4nb, rfnb, fnewnb, multnb, problemnb, $
        bbfrq_nb, bbgain_dft_nb, ggnb_7679, $
        file= savepath+ name+ savefilename

indxwb= where( problemwb ne 0, countwb)
indxnb= where( problemnb ne 0, countnb)

if countwb ne 0 then begin
print, ' '
print, '********PROBLEMS IN WB FITS: NR PROBLEMS = ', countwb, ' **********'
endif

if countnb ne 0 then begin
print, ' '
print, '********PROBLEMS IN NB FITS: NR PROBLEMS = ', countnb, ' **********'
endif

print, 'saving data in file ', savepath + name + savefilename


return
end
