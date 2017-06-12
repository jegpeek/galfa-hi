;+
;NAME:
;gspdr_setup - setup routine for gspdr
;SYNTAX: numPat=gspdr_setup(corfile,scndata,lun,retsl,indForPat,$
;					brdToUse,nfits,
;		    	   mmInfo_arr,hb_arr,beamin_arr,beamout_arr,stkOffsets_chnl_arr,
;					filesavenamemm0, filesavenamemm4,onlymm4=onlymm4,$
;                  tcalxx_board=tcalxx_board,tcalyy_board=tcalyy_board,$
;				    sl=sl,board=board,rcvnam=rcvnam,byChnl=byChnl,
;					sourcename=sourcename,npatterns=npatterns,
;				    dirsave=dirsave,dirplot=dirplot)
;ARGS:
;	scndata: {scndata} observing pattern parameters.

;  mmInfo_arr[nfits]:{mueller_carl} hold results from fits
; beamin_arr[nfits]:{beaminput} input data before fits
;beamout_arr[nfits]:{mmoutput} output from fits
;   filesavenamemm0: string save filename for mm0 1d fits
;   filesavenamemm4: string save filename for mm4 mueller matrix computations
;
;KEYWORDS:
;tcal[2,7]: float if positive then use these value for calxx 

function gspdr_setup,corfile,scndata,lun,retsl,indForPat, brdToUse,$
				   nfits,mmInfo_arr,hb_arr,beamin_arr,beamout_arr,$
				   stkOffsets_chnl_arr,filesavenamemm0,onlymm4=onlymm4,$
				   filesavenamemm4,dirplot=dirplot,dirsave=dirsave,$
                   tcalxx_board=tcalxx_board,tcalyy_board=tcalyy_board,$
				   sl=sl,board=board,rcvnam=rcvnam,$
                   sourcename=sourcename,npatterns=npatterns ,byChnl=byChnl
	norcvr=' '
 	rcvnumAr  = [1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15,16,51,61,$
                 100,  101,  121]
	rcvnamAr = ['327' ,'430' ,'610' ,norcvr,'lbw' ,'lbn' ,'sbw','sbh', $
             'cb' ,norcvr,'xb','sbn' ,norcvr,norcvr,norcvr,'noise' , $
             'lbwifw' ,'lbnifw' ,'430ch' ,'chlb' ,'sb750' ]
;
; 	allocate the stuctures:
;
	hb_arr=replicate({hdr},4,nfits)
	beamin_arr =replicate({beaminput},nfits)
	beamout_arr=replicate({mmoutput},nfits)

;------------------ CAL MATTERS ------------------------------
         
;IF YOU WISH TO DEFINE YOUR OWN CAL TEMPERATURES:
;TO USE CAL VALUES IN THE HEADER, MAKE THESE NEGATIVE
;MAKING THESE POSITIVE MEANS THESE ARE USED INSTEAD.

rcvnum=17               ; rcvr num i use for alfa
caltype=1               ; hcorcal .. but alfa just has the 1 high cal.
freq   =1420.           ; freq
istat=calget1(rcvnum,caltype,freq,calval)

if n_elements(tcal) gt 0 then $
for i=0,n_elements(tcalxx_board) -1 do scndata.tcalxx_board[i] =tcalxx_board[i]

