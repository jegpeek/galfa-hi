pro radarbad, mhpath, mhfilelist, juldanrange=juldayrange, $
	noprint=noprint, nodoc=nodoc, noplot=noplot, $
	writesave=writesave, readsave=readsave, $
	mxx=mxx, mxindxrange=mxindxrange

;+
;NAME:
;RADARBAD -- input mh files, look at the bad-radar diagnostic
;
;CALLING SEQUENCE:
;radarbad, mhpath, mhfilelist, juldanrange=juldayrange, $
;        noprint=noprint, nodoc=nodoc, noplot=noplot, $
;        writesave=writesave, readsave=readsave, $
;        mxx=mxx, mxindxrange=mxindxrange
;INPUTS
;MHPATH, the path to the mh files
;MHFILELIST, a list of the mh files. this should be in a file located
;	in the directory inm which you are running IDL
;
;OPTIONAL INPUTS:
;JULDAYRANGE[2]: restrict processing to this range of julian day offsets
;MXINDXRANGE[2]: restrict processing to this range of indx nrs. 
;	overrides juldayrange
;NOPRINT: suppress the printed listing of diagnostics
;NODOC: suppress printed documentation
;NOPLOT; suppress the plot
;WRITESAVE: write a save file containing all the mh and mx structures.
;	useful for huge lists to save time on subsequent reruns.
;	set writesave equal to the filename you want it saved.
;READSAVE: read the above save file and don't read the mhfilelist.
;MXX: you can give it a previoiusly defined mxx array and it will
;	not read mxx from input files.
;
;OUTPUTS: note
;
;ACTION: produces plots and a printout.
;-

getmxx, mhpath, mhfilelist, mxx, writesave=writesave, readsave=readsave

MXRADARLOOK:
mxradarlook, mxx, juldayrange, mxindxrange

print, 'TYPE q TO QUIT; ANY OTHER KEY REPEATS'
res= get_kbrd( 1)
if res eq 'q' then return
GOTO, MXRADARLOOK

return
end
