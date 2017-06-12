pro datachk_w, fitspath, lsfspath, fitsfile, lsfsfile, qckpath

;+
;NAME:
;DATACHK_W -- input a list of fits, lsfs files and plot, save the file's avg spectra
;
;CALLING SEQUENCE:
;datachk_w, fitspath, lsfspath, fitsfile, lsfsfile, qckpath
;
;INPUTS
;FITSPATH, the path to the fits files
;LSFSPATH, the path to the fits files
;FITSFILE, the fits file to process
;LSFSFILE, the lsfs file to use for calibration of this fits file
;QCKPATH, where to write the avg spectra. if blank or not set, no file write
;ACTION:
;	plots avg spectra and writes the associated qck files if so specified.
;-

simpred_ch, fitspath, lsfspath, fitsfile, lsfsfile, qckpath

plotsimpred_ch, csnb, cswb, csnbcont, cswbcont, rffrq_nb, rffrq_wb, countyes

return
end
