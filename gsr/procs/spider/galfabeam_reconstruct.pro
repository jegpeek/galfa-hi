pro galfabeam_reconstruct, feed, beamprops, delaz, delza, $
	totalbeam, mainbeam, sidelobe, $
	path=path, nterms=nterms, noreform=noreform,$
	noconvol=noconvol, rotangle=rotangle

;+
;PURPOSE: evaluate the alfa beam properties for a particular feed (the
;combination of both polarizations) at a 2d array of delaz, delzal
;
;INPUTS
;	FEED: 0 to 6
;
;	BEAMPROPS: the structure containing the beam properties.  This
;is obtained from a file and is automatically read in the first time the
;proc is called.  It has a default location which can be changed with the
;optional input parameter PATH
;
;	DELAZ, the vector of az offsets from beam center in arcmin
;
;	DELZA, the vector of za offsets from beam center in arcmin
;NOTE: obviously, DELAZ and DELZA must be identical in length!
;
;OPTIONAL inputs:
;	PATH, the location of the file contianing BEAMPROPS. default
;		is getenv('GSRPROCDATAPATH') 
;	NTERMS, the nr of sidelobe Fourier terms to include 
;	NOREFORM, you usually want this: don't reform output to a 60 by 60 grid
;	NOCONVOL, if NOT set, it returns the convolution of the beam ;pattern. If it IS set, it reeturns the actual beam pattern on the sky.
;these differ by a reflection about the origin (equivalent to a rotation
;by 180 deg).
;
;	ROTANGLE, the ALFA array rotation angle. Default is zero.
;
;************************ CAUTION ********************************
;
;       As of 20 dec 2004 ROTANGLE has not been tested.
;
;
;       Moreover, its effects are recommended, not measured.  See GALFA 
;technical memo 2004-01.
;
;*****************************************************************
;
;OUTPUTS:
;	TOTALBEAM; the 2-d array of beam responses evaluated at [delaz,
;delza].  They are normalized so that the on-axis resonse is unity. 
;TOTALBEAM= MAINBEAM+ SIDELOBE
;
;	MAINBEAM, the main beam contribution (the 2d Gaussian)
;
;	SIDELOBE, the sidelobe contribution. 
;-

if keyword_set( nterms) eq 0 then nterms=8

;pathdefault= '/dzd1/heiles/gsr1/spider/'
pathdefault= getenv('GALFAPATH') 

;GO GET THE BEAMPROPS STRUCTURE IF IT ISN'T DEFINED..
IF N_ELEMENTS( BEAMPROPS) EQ 0 THEN BEGIN
	if keyword_set( path) eq 0 then path= pathdefault
	restore, path+ '/savfiles/beamprops.sav'  ;;;, /ver
ENDIF

;SPLIT INPUTDELAZZA INTO TWO VECTORS TO SATISFY DEMANDS OF EXISTING SOFTWARE...

mainbeam_eval_newcal, delaz, delza, beamprops[ feed].b2dfit, mainbeam
mainbeam= mainbeam/beamprops[ feed].b2dfit[2,0]

gsrsidelobe_eval, nterms, $
     beamprops[ feed].fhgt, beamprops[ feed].fcen, beamprops[ feed].fhpbw, $
	delaz, delza, sidelobe, $
	noreform=noreform, noconvol=noconvol, rotangle=rotangle
sidelobe= sidelobe/beamprops[ feed].b2dfit[2,0]

totalbeam= mainbeam+ sidelobe

return
end
