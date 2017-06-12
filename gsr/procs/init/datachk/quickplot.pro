pro quickplot, qckfile, dely=dely, yscl=yscl

;+
;NAME:
;QUICKPLOT. give it a qckfile, it makes the quickplots.
;
;CALLING SEQUENCE:
;QUICKPLOT, qckfile, dely=dely, yscl=yscl
;
;INPUTS:
;QCKFILE, the path and quickfile name (must include the path)
;
;OPTIONAL INPUTS:
;DELY, the distance between the plotted spectra in K. default 1.5
;YSCL, the plot scale, defalut 5.0
;
;action: plots on the screen
;-

restore, qckfile

plotsimpred_ch, csnb, cswb, csnbcont, cswbcont, rffrq_nb, rffrq_wb, $
        countyes, rffrq_wblsfs, rffrq_nblsfs, rffrq_wbm1, rffrq_nbm1, $
        yscl=yscl, dely=dely

return
end
