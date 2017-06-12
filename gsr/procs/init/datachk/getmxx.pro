pro getmxx, mhpath, mhfilelist, mxx, $
	writesave=writesave, readsave=readsave, nosort=nosort, mhh=mhh

;+
;NAME:
;GETMXX -- get the time-sorted mxx structure array a list of fits files
;
;
;PURPOSE: get the time-sorted mxx structure array, whether from original
;files, or saved disk, from a list of fits files. the fits file names are
;converted to mh files names and the mh files are used to make mxx array.
;optionally, mhh, the array of mh files, can be returned. 
;
;CALLING SEQUENCE:
;GETMXX, mhpath, mhfilelist, mxx, $
;        writesave=writesave, readsave=readsave, nosort=nosort, mhh=mhh
;
;INPUTS
;MHPATH, the path to the mh files
;MHFILELIST, name of a file containing thelist of the mh files. 
;this file located in the directory in which you are running IDL
;
;OPTIONAL INPUTS:
;MXX: you can give it a previoiusly defined mxx array and it will
;       not read mxx from input files. ***it WILL timesort it unless
;	/nosort is set
;WRITESAVE: write a save file containing all the mh and mx structures.
;       useful for huge lists to save time on subsequent reruns.
;       set writesave equal to the filename you want it saved.
;READSAVE: read the above save file and don't read the mhfilelist.
;NOSORT: don't time sort the mxx array.
;
;OUTPUT: 	
;MXX, the TIME-SORTED mxx array of mx structures
;
;OPTIONAL OUTPUT:
;MHH, the TIME-SORTED mhh array of mx structures
;-

IF KEYWORD_SET( MXX) THEN BEGIN
	if keyword_set( nosort) eq 0 then mxx= mxx[ sort( mxx.julstamp)]
	return
ENDIF

IF KEYWORD_SET( READSAVE) THEN BEGIN
	restore, readsave
	if keyword_set( nosort) eq 0 then mxx= mxx[ sort( mxx.julstamp)]
	return
ENDIF

readcol, mhfilelist, mhfiles, format='a' ;, /silent

restore, mhpath+ mhfiles[0]

mxx= replicate( mx, n_elements( mhfiles))
mhh= replicate( mh[0], 600*n_elements( mhfiles))

;stop

mhndx=0
FOR NR=0, N_ELEMENTS( MHFILES)-1 DO BEGIN  
restore, mhpath+ mhfiles[ nr]  
mxx[ nr]= mx 
mhh[ mhndx:mhndx+n_elements( mh)-1]= mh
mhndx= mhndx+ n_elements( mh)
loop_bar, nr, n_elements( mhfiles)-1  
ENDFOR

mhh= mhh[ 0:mhndx-1]
if keyword_set( nosort) eq 0 then mxx= mxx[ sort( mxx.julstamp)]

if keyword_set( writesave) then save, mxx, file=writesave

return
end
