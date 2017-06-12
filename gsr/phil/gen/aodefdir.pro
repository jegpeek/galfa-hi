;+
;NAME:
;aodefdir - AO base directory for idl routines.
;
;SYNTAX: defdir=aodefdir(doc=doc,url=url)
;
;ARGS:
;   doc:    if the keyword is set then return the directory for the 
;           html documentation.
;   url:    if the keyword is set then return the url for the 
;           html documentation.
;
;DESCRIPTION:
;   Return the directory where the ao idl routines are stored. At AO it 
;returns '/pkg/rsi/local/libao/phil/'. The addpath() routine will use this
;directory if no pathname is given. This routine makes it easier
;to export the ao idl procedures to other sites.
;
;***************NOTE: WHEN AT ARECIBO, USE THE ARECIBO LINE BELOW
;***************WHEN AT BERKELEY, USE THE BERKELEY LINE BELOW.
;-

function aodefdir,doc=doc,url=url
         if keyword_set(doc) then return,'/home/phil/public_html/'
         if keyword_set(url) then return,'http://www.naic.edu/~phil/'

;return,'/dzd1/heiles/gsr/init/phil/'   ;;;;ARECIBO
;return,'/dzd1/heiles/gsr/phil/'         ;;;;BERKELEY
;;  Oct 15 2006 - K.Douglas
;; use line below because /dzd1 not accessible right now??                                                                                
         if file_exists('/pkg/rsi/local/libao/phil/data/utcToUt1.dat') then return,'/pkg/rsi/local/libao/phil/' else return, getenv("GSRPATH") + "phil/"
end
