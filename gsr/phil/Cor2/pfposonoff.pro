;+
;NAME:
;pfposonoff - process all position switch  onoffs in a file
;SYNTAX: npairs=pfposonoff(filename,bf,tf,calsf,han=han,median=median,
;                          scan=scan,dir=dir,sl=sl,maxrecs=maxrecs,
;                          scltsys=scltsys,sclJy=sclJy, 
;                          rcv=rcv,sav=sav,fsav=fsav,rsl=rsl,$
;					       badIndAr=badIndAr,nbadindar=nbadindar)
;ARGS  :
;       filename: string  .. file to process
;
;KEYWORDS:
;       han        : if set then hanning smooth the data
;	 median		   : if set then use median rather mean when averaging a scan.
;       scan       : long    if set then start at this scan number
;       dir[]      : string  search for filename in these directories.
;                            in this case filename should not have a path.
;       sl[]       : {slist} Scan list to use when searching file. This
;                            saves having to scan the file. Use this to speed
;                            processing if you have already scanned the file (
;                            see the Rsl keyword).
;      maxrecs     : long    The maximum number of recs to allow in a scan
;                            the default is 300.
;       scljy      : if set then scale to kelvins using the cals and then
;                    use the gain curve to return the spectra in janskies.
;                    The default is to return the spectra in kelvins.
;       scltsys    : if set then scale to tsys rather than using the cals
;                    to scale to kelvins (the default).
;      rcv         : int     If supplied then only process reciver number rcv.
;                    (1-327,2-430,3-610,5-lbw,6-lbn,7-sbw,8-sbh,9-cb,11=xb,
;                     12-sbn)
;      sav         :         if keyword set then save the processed data
;                            to ddmmyy.projid.N.sav . The keyword fsav
;                            will let you switch this to a different save file.
;      fsav        : string  name for save file. Only used if /sav is set.
;                            file will be forced to end in .sav
;RETURNS:
;            npairs:  int number of complete on/offs processed
;                     -1 if illegal filename
;                     -1 if scan option but scan not in file
;       bf[npairs] : {corget}.. return (on/off-1) average for each pair
;                            scaled to: kelvins,janskies, or Tsys units.
;       tf[npairs] : {temps} .. array of temp structures (see corposonoff).
;calsf[nbrds,npairs]: {cal}  .. array of cal structures  (see corposonoff).
;        Rsl[nscans]: {sl}   .. return scan list that was used.
;        nBadIndAr  : int    .. number of scans not used because different type.
;                               the indices into sl[] are returned in badindar.
;badIndAr[nBadIndAr]: int    .. hold indices into sl[] of on/off position
;                               switch data that were not processed 
;                               because they had a different data structure.
;                               The number of elements should be in nbadindar
;
;DESCRIPTION:
;   pfposonoff will process all of the on/off pairs it finds in filename.
;The keyword dir[] will search for this file in all of the directories in dir.
;
;   The routine will first scan the file and create a scan list array (see
;getsl()). If you have already scanned the file, then using the sl=sl keyword
;lets you pass in the scan list array and save the time to scan the file 
;(the scanlist array used is returned in the rsl=rls keyword).
;
;   If an incomplete on/off pair is found, it will skip forward and continue
;searching. The processing can be limited to a subset of the entire file by :
; 1.  scan= keyword. Start processing on this scan.
; 2.  rcv=N keyword. Only process data from receiver number N.
;
;   The processed on/off-1 spectra will be returned in a array bf[npairs] of
;{corget) structures. For this to work, all of the position switch data must
;meet the following criteria:
; 1. All scans use the same number of boards.
; 2. For a single board (say board n) 
;    a. All scans should have the same number of polarizations.
;    b. all scans should have the same number of lags.
;    (It is ok if different boards have  different number of polarizations or
;    lags).
;The keywords nbadIndAr and badIndAr will return the number and indices
;into rsl[] of the patterns not included because the data type differed 
;from the first one found.
;
;   By default the units for the returned data is Kelvins. Setting
;the keyword scljy will return the spectra in janskies (as long as there is
;a gain curve for this receiver). Setting the keyword sclTsys will return 
;the spectra in units of Tsys.
;
;   The /sav keyword will store the processed data in an idl save file. The
;default name is ddmmmyy.projid.n.sav where ddmmmyy.projid.n are taken
;from the correlator datafile name. You can change the savefile name
;with the fsav= keyword (it still must end in .sav). The variable names
;stored in the file will be:
;
;   bf[npairs], tf[npairs], calsf[4,npairs] .. same as the returned data.
;   savefile         :string  The name of the save file used.
;   srcnamesf[npairs]:string  An array holding the source names
;
;The save file lets you recall this data into a later session of idl using
;restore:
;   restore,'02may02.x101.1.sav'
;
;You can also use corsavbysrc() to recall a set of these save files
;and create arrays  of processed data by src.
;
;SEE ALSO: corposonoff, corsavbysrc 
;-
;19sep02 switched to use corfindpat(), added rcv keyword
;20sep02 added dir option,
;21sep02 added rsl keyword to return scan list
;        put in buf check so we don't process files that are different.
;14jul04 check if was data
function    pfposonoff,filename,bf,tf,calsf,maxrecs=maxrecs,sl=sl,han=han,$
            dir=dir,scan=scan,scltsys=scltsys,scljy=scljy,rcv=rcv,$
            sav=sav,fsav=fsav,rsl=rsl,badIndAr=badIndAr,nbadindar=nbadindar,$
			median=median
;
;     on_error,0
    on_error,1
    if not keyword_set(maxrecs) then maxrecs=0
    if n_elements(scltsys) eq 0 then scltsys=0
    if n_elements(scljy) eq 0 then scljy=0
    if not keyword_set(rcv) then rcv=0
    lun=-1
    nbadindar=0
	useFits=(strmid(filename,4,5,/rev) eq '.fits')
    if file_exists(filename,fullname,dir=dir) then begin
		if useFits then begin
			fitsOpen=wasopen(fullname,lun)
			if fitsOpen eq 0 then begin
            	print,'pfposonoff error opening file:',fullname
            	numfound=-1
            	goto,done
			endif
		endif else begin
        	openr,lun,fullname,/get_lun,error=err
        	if err ne 0 then begin
            	print,'pfposonoff open error:',!err_string
            	numfound=-1
            	goto,done
        	endif
		endelse
    endif else begin
            print,'pfposonoff file not found:',fullname
            numfound=-1
            goto,done
    endelse
    sclcal=keyword_set(scltsys) eq 0
    if not keyword_set(sl) then begin
        print,'scanning file:',fullname
        sl=getsl(lun)
    endif 
;
;       if start at scan, throw out all scans before this
;
    if n_elements(scan) gt 0 then begin
        ind=where(sl.scan eq scan,count)
        if count eq 0 then begin
            print,'cannot position to scan:',scan
            numfound=-1
            goto,done
        endif
        sl=sl[ind[0]:*]
    endif
    rsl=sl
;
; find all of the poson,off with cals
;
    numfound=corfindpat(sl,indar,pattype=1,rcv=rcv)
    if numfound eq 0 then goto ,done
    numsto=0                ; number we've stored
    numbadind=0
    badIndar=indar
    for i=0,numfound-1 do begin
        istat=corposonoff(lun,b,t,cals,sclcal=sclcal,scljy=scljy,han=han,$
                scan=sl[indar[i]].scan,sl=sl,maxrecs=maxrecs,median=median)
        if istat eq 1 then begin
            actualrecs=sl[indar[i]].numrecs
            if ((maxrecs eq 0) and (actualrecs gt 300)) or $
                ((maxrecs ne 0) and (actualrecs gt maxrecs)) then begin
            lab=string(format=$
    '("Warning..scan:",i9," has ",i4," recs. Need to use maxrecs= keyword")',$
                sl[indar[i]].scan,sl[indar[i]].numrecs)
            message,/info,lab
            endif

            if (numsto eq 0 ) then begin
                bf=corallocstr(b,numfound)
                tf=replicate(t,numfound)
                calsf=replicate({corcal},(size(cals))[1],numfound)
            endif else begin
                istat=corchkstr(bf[0],b)
            endelse
            if istat eq 1 then begin
                corstostr,b,numsto,bf
                tf[numsto]=t
                calsf[*,numsto]=cals
                numsto=numsto+1
                lab=string(format='( "process scan:",i9," ",a)',$
                b.b1.h.std.scannumber,$ 
                    string(b.b1.h.proc.srcname))
                badIndAr[i]=-1              ; its ok
            endif else begin
                lab=string(format=$
                '( "skip    scan:",i9," ",a," different data format")',$
                b.b1.h.std.scannumber,string(b.b1.h.proc.srcname))
            endelse
            print,lab
        endif
    endfor
done:
	if useFits then begin
		if fitsOpen then wasclose,lun
	endif else begin
    	if lun gt 0 then free_lun,lun
	endelse
    if numfound le 0 then begin
        bf=''
        calsf=''
        tf=''
    endif else begin
        if (numfound ne numsto) then begin 
            bf=bf[0:numsto-1] 
            tf=tf[0:numsto-1] 
            calsf=calsf[*,0:numsto-1] 
            numfound=numsto
        endif
    endelse
    if keyword_set(sav) and (numfound gt 0) then begin
        if n_elements(fsav) gt 0 then begin
;
;       make sure it ends in .sav . This way they can't overwrite a datafile
;
            suf=''
            if strmid(fsav,3,4,/reverse_offset) ne '.sav' then suf='.sav'
            fsavl=fsav+suf
        endif else begin
            fsavl=fullname
            i=strpos(fsavl,'/',/reverse_search)
            if i ne -1 then fsavl=strmid(fsavl,i+1) 
            if strmid(fsavl,4,5,/reverse_offset) eq '.fits' then begin
				fsavl=strmid(fsavl,5,19)+'.sav'
			endif  else begin
            	fsavl=strmid(fsavl,8)  + '.sav'
			endelse
        endelse
        srcnamesf=string(bf.b1.h.proc.srcname)
        print,'save data to file:',fsavl
        save,bf,tf,calsf,srcnamesf,file=fsavl
    endif
;
;   return all of the indices that didn't match
;
	if numfound gt 0 then begin
		ind=where(badIndAr ne -1,count)
	endif else begin
		count=0
	endelse
    if count gt 0 then begin
        badIndAr=badIndAr[ind]
        nBadIndAr=count
    endif else begin
        badindar=-1
        nbadindar=0
    endelse
    return,numfound
end
