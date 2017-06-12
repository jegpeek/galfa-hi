;+
;NAME:
;cataloginp - input a pointing catalog
;SYNTAX: nsrc=cataloginp(file,format,retdata,comment=comment)
;ARGS:
;	file	 :string	filename of catatlog
;	format   :int       format for catalog:
;						1: srcname hh mm ss dd mm ss
;						2: srcname hhmmss ddmmss
;   retdata[]:{srccat}  return data here
;                       in retdata.
;KEYWORDS:
;   comment  : string   comment characters for catatlog.def:#
;DESCRIPTION:
;   Read in all of the source names and positions catalog specified by
;file
;The returned srccat array will contain:
;help,retdat,/st
;** Structure CATENTRY, 6 tags, length=52:
;   NAME            STRING 	   ''			source name
;   RA              FLOAT     Array[3]      hh mm ss.ss 
;   DEC             FLOAT     Array[3]      dd mm dd.dd	 (alway positive)
;   DECSGN          INT              0      +/- 1 sign of declination
;   RAH             DOUBLE           0.0	ra in hours (includes sign)
;   DECD            DOUBLE           0.0    dec in hours (includes sign)
;   EOL             STRING                  string dec to end of line
;-
;28jun01 - fixed so aliases worked..
function cataloginp,file,format,retdat,comment=comment

    on_ioerror,doneio
	maxentries=2000L
	if n_elements(comment) eq 0 then begin
		comment=';#'
	endif
	if (format lt 1 ) or (format gt 2) then begin
		printf,-2,'illegal format requested:',format
		return,0
	endif
	c='['+comment+']*'
    openr,lun,file,/get_lun,error=err
	if err ne 0 then begin
		printf,-2,'could not open file:'+file
		printf,-2,!err_string
		return,0
	endif
    inpline=''
    retdat=replicate({catentry},maxentries)
    i=0L
	rec=0L
    while  1 do begin
        readf,lun,inpline
		rec=rec+1
		if strmatch(strmid(inpline,0,1),c) eq 0 then begin
			strlen=strlen(inpline)
			tok   =strsplit(inpline,/extract)
			tokInd=strsplit(inpline,len=len)
			ntok=n_elements(tok)
			retdat[i].name=tok[0]
			retdat[i].decsgn=1
			eol=''
			case format of
				1 : begin
						if strmid(tok[4],0,1) eq '-' then begin
							retdat[i].decsgn=-1
							tok[4]=strmid(tok[4],1)
						endif
						retdat[i].ra  =tok[1:3]
						retdat[i].dec =tok[4:6]
;
;					    position end last token
;
						tokend=tokInd[6] + len[6]
						if strlen gt tokend then eol=strmid(inpline,tokend)
					end
				2 : begin
						sixtyunp,tok[1],junk,temp
						retdat[i].ra=temp
						sixtyunp,tok[2],junk,temp
						retdat[i].decsgn=junk
						retdat[i].dec=temp
						tokend=tokInd[2] + len[2]
						if strlen gt tokend then eol=strmid(inpline,tokend)
					end
			endcase
			retdat[i].eol=eol
			retdat[i].raH =retdat[i].ra[0]+retdat[i].ra[1]/60.D + $
					      retdat[i].ra[2]/3600.D
			retdat[i].decD=retdat[i].dec[0]+retdat[i].dec[1]/60.D + $
					      retdat[i].dec[2]/3600.D
	    i=i+1		
		endif
		if i ge maxentries then begin
			printf,-2,'hit max allowed number of entries:' + string(maxentries)
			goto,doneio 
		endif
	endwhile

doneio: 
    free_lun,lun
    if i ne maxentries then begin
		if i gt 0 then begin
			retdat=retdat[0:i-1]
		endif else begin
			retdat=''
		endelse
	endif
;
    return,i
end
