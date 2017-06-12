pro lsfs_wrap, fitspath, mhpath, fitsfilelist, lsfspath, $
	noquiet=noquiet, namearray=namearray, savefilename=savefilename, $
	nrbegin=nrbegin

;+
;NAME:
;lsfs_wrap -- wrapper to make lsfs files from a list of fits files.
;
;CALLING SEQUENCE
;lsfs_wrap, fitspath, mhpath, fitsfilelist, lsfspath
;
;INPUTS
;FITSPATH, the path to the fits files, which are read
;MHPATH,  the path to the mh files, which are read
;FITSFILELIST, the list of fits files to process. THERE MUST BE
;	AN MH FILE FOR EACH FITS FILE!
;LSFSPATH, the path to the lsfs files, which are written.

;OPTIONAL INPUTS
;NOQUIET -- set to produce plots and stuff about the fit.
;NAMEARRAY. if you give this an array of filenames, it won't read fitsfilelist
;NRBEGIN -- day nr to begin processsing (in case a previous run was interrupted)
;-

if keyword_set( nrbegin) then nrb=nrbegin else nrb=0

if n_elements( namearray) eq 0 then $          
        readcol, fitsfilelist, fitsfiles, format='a' $           
else fitsfiles= namearray

;BREAK THE LIST UP INTO DAYS...
multiday_select, fitsfiles, nr0, nr1

;LOOP THROUGH EACH DAY...
FOR NR=NRB, N_ELEMENTS( NR0)-1 DO BEGIN
print, 'BEGINNING NR = ', nr, '  ', fitsfiles[ nr0[ nr]]
namearray= fitsfiles[ nr0[ nr]: nr1[ nr]]

;DETERMINE WHICH OF THESE FILES CONTAIN SMARTF DATA...
find_smartf, mhpath, namearray, smartf

IF TOTAL( SMARTF) EQ 0 THEN BEGIN
        print, '********* there are no lsfs in this group. skipping ********'
        GOTO, SKIPTHISGROUP
ENDIF

;FIND THE GROUPINGS OF SMARTF DATA FOR THIS PARTICULAR DAY...
smartf_groups, smartf, smf

quiet=1
if keyword_set( noquiet) then quiet=0
;LOOP THROUGH THE GROUPS OF THIS PARTICULAR DAY...
FOR NRSG=0, (SIZE( SMF))[2]-1 DO BEGIN
indx= smf[0,NRSG]  + indgen( smf[1,NRSG]-smf[0,NRSG] + 1)
print, 'NRSG = ', NRSG, '   indx= ', indx
;stop
lsfs_shell, mhpath, fitspath, namearray[ indx], lsfspath, $
	quiet=quiet, savefilename=savefilename
ENDFOR

SKIPTHISGROUP:

ENDFOR

end

