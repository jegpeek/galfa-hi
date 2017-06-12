;+
; NAME:
;    stg0
;   
;
; PURPOSE:
;   Compiles the input data from a series of stg0 command calls in a batch file. Note that this is a somewhat strange piece of
;   code.  The intent of this code is to use batch files designed to simply run the stg0 reduction and use them to create a 
;   file that can then be accessed by many IDL sessions at once for maximum flexibility and efficiency. To do this, the code is 
;   named 'stg0'. Once it is compiled (i.e. IDL> .r stg0_compiler), when the batch files are run they will, instead of running
;   stg0, run this code (with the same name) that puts all the info together. It's a little confusing, I know.
;
; CATEGORY:
;   Weird, weird codes
;
;
; CALLING SEQUENCE:
;  stg0, year, month, day, proj, region, root, startn, endn, $
;  slst, elst, scan, nomh=nomh, calfile=calfile, fitsdir=fitsdir, $
;  userrxfile=userrxfile, mhdir=mhdir, caldir=caldir, tdf=tdf, odf=odf
;
;
; INPUTS:
;   see stg0.pro
;
;
; OPTIONAL INPUTS:
;   see stg0.pro
;
;
; KEYWORD PARAMETERS:
;   see stg0.pro
;
;
; OPTIONAL OUTPUTS:
;  
;
;
; COMMON BLOCKS:
;
;
;
; SIDE EFFECTS:
;
;
;
; RESTRICTIONS:
;
;
;
; PROCEDURE:
;
;
;
; EXAMPLE:
;
;
;
; MODIFICATION HISTORY:
;  Wednesday, Dec 3, JEG Peek
;-

pro stg0, year, month, day, proj, region, root, startn, endn, slst, elst, scan, nomh=nomh, calfile=calfile, fitsdir=fitsdir, userrxfile=userrxfile, mhdir=mhdir, caldir=caldir, tdf=tdf, odf=odf

if not keyword_set(nomh) then nomh = 0
if not keyword_set(calfile) then calfile = ''
if not keyword_set(fitsdir) then fitsdir = ''
if not keyword_set(userrxfile) then userrxfile = ''
if not keyword_set(mhdir) then mhdir = ''
if not keyword_set(caldir) then caldir = ''
if not keyword_set(tdf) then tdf = 0
if not keyword_set(odf) then odf = 0

fls = file_search('', 'comp_stg0_inps.sav')
if fls[0] eq '' then stg0_inps = replicate({year:0, month:0, day:0, proj:'', region:'', root:'', startn:0, endn:0, slst:0., elst:0., scan:0, nomh:0, calfile:'', fitsdir:'', userrxfile:'', mhdir:'', caldir:'', tdf:0, odf:0, complete:0}, 1)

if fls[0] ne '' then begin 
    restore, fls[0]
    nel = n_elements(stg0_inps)
    stg0_inps_new = replicate({year:0, month:0, day:0, proj:'', region:'', root:'', startn:0, endn:0, slst:0., elst:0., scan:0, nomh:0, calfile:'', fitsdir:'', userrxfile:'', mhdir:'', caldir:'', tdf:0, odf:0, complete:0}, nel+1)
    stg0_inps_new[0:nel-1] = stg0_inps
    stg0_inps = stg0_inps_new
endif

nel = n_elements(stg0_inps)

stg0_inps[nel-1].year = year
stg0_inps[nel-1].month=month
stg0_inps[nel-1].day=day
stg0_inps[nel-1].proj=proj
stg0_inps[nel-1].region=region
stg0_inps[nel-1].root=root
stg0_inps[nel-1].startn=startn
stg0_inps[nel-1].endn=endn
stg0_inps[nel-1].slst=slst
stg0_inps[nel-1].elst=elst
stg0_inps[nel-1].scan=scan
stg0_inps[nel-1].nomh=nomh
stg0_inps[nel-1].calfile=calfile
stg0_inps[nel-1].fitsdir=fitsdir
stg0_inps[nel-1].userrxfile=userrxfile
stg0_inps[nel-1].mhdir=mhdir
stg0_inps[nel-1].caldir=caldir
stg0_inps[nel-1].tdf=tdf
stg0_inps[nel-1].odf=odf

save, stg0_inps, f= 'comp_stg0_inps.sav'

end
