pro stg0, year, month, day, proj, region, root, slst, elst, scan, fd, v25, nomh=nomh, calfile=calfile, fitsdir=fitsdir, mhdir=mhdir, caldir=caldir, tdf=tdf, odf=odf, deblip=deblip
;+

;+
; Name:
;   stg0 
; PURPOSE:
;   To run the stage 0 reduction of an single day's scan. This includes:
;      * Putting the data into temperature-calibrated form
;      * Removing bandpass effects and ripples in the spectra
;      * Removing single frequency RFI
;      * Finding positions for all integrations
;      * Frequency corrections to LSR
;
; CALLING SEQUENCE:
;   stg0, year, month, day, proj, region, root, startn, endn, slst, $
;         elst, scan, nomh=nomh, calfile=calfile, $
;         fitsdir=fitsdir, userrxfile=userrxfile, mhdir=mhdir, $
;         caldir=caldir, tdf=tdf, odf=odf
; INPUTS:
;   YEAR - The year, as an integer (e.g. 2005, not '2005')
;   MONTH - The month, as an integer (e.g. 6, not 'June')
;   DAY - The day as an integer (e.g. 27 )
;   PROJ - The Arecibo project code (e.g. 'a2050')
;   REGION - The name of the region as entererd into BW_fm (e.g. 'lwa')
;   ROOT - The main direcotry in which the project directory
;             resides (e.g. '/dzd4/heiles/gsrdata/' )
;   STARTN - The fits file number at which to start looking for data.
;            Typically this number is 0.
;   ENDN - The last file # in which to look and generate mh files. Usually
;          the last numbered fits file for the project that exists 
;          for that day. 
;   SLST - The LST at which the observations started. If this is a BW scan, the number can be gotten
;          from the output of BW_fm (e.g. lwa_slst[3, 0], or 1.1785302). Otherwise, choose
;          an LST just before the observation starts, AFTER any calibration (SFS) has been done,
;          and the telescope is no longer dwelling on a single spot. 
;   ELST - The LST at which the observations were concluded. If you are reducing BW data, this number
;          is also availible as an output from BW_fm (e.g. lwa_elst[3], or 2.3341234). It is a good
;          idea to set this to an LST before the telescope has changed observing modes.
;   SCAN - The scan number. In a BW observation, if the object is lwa_03_01, the scan number is 3.
;          This is arbitary - you can put any day's observation in any scan if you choose.
;          It is not crucial to set this to any particular number, other than that further stages of 
;          reduction will only function if a group of scan numbers has been assigned starting at 0
;          and ending at N-1, where N is number of scans. One convinient system is to use scan numbers
;          starting at 0 for the first day of observation and increasing by one for each following day.
;  FD - The directory in which fits files are searched, instead of the usual locale.
;  v25     - Only enter an eleventh variable here if you wish to use the old (v2.5) version
;            of the code, with endn, startn and fitsdir as a keyword. In this version a few
;            variables are permuted, so that previous bathc files can still run correctly. 
;            All varibles are the same except: 
;                slst -> startn
;                elst -> endn
;                scan -> slst
;                fd -> elst
;                v25 -> scan
;            Sorry this is so craptacularly kludgy, but it was all I could figure out.
; KEYWORDS PARAMETERS
;  NOMH - Run the reduction without generating the mh files. Use only if mh files
;         have already been generated.
;  MH
;  CALFILE - The name of the calibration file to use. If this keyword is set, the 
;            program will not generate an LSFS file out of the data. This is useful
;            if the LSFS cal file has already been generated or you wish to use an 
;            LSFS cal file not generated by the data set. (e.g. 'lsfs.20050528.A2011.0000.sav')
;  FITSDIR - a depricated keyword for a previous version of the software. If set, along with
;            v25, will be used as the directory for the software
;  CALDIR - if set, is the directory in which lsfs files are searched, instead of the usual locale.
;  MHDIR - if set, is the directory in which mh files are searched, instead of the usual locale.
;  TDF -- use the older two-digit formatting
;  ODF -- Old Data Format. Save in the GSR 2.1 and prior compatible 
;                 format if this flag is set.
;   deblip -- if set, remove blips, a la a2124 2008/2009
; OUTPUTS:
;   NONE (reduced data, calibration files, mh files)
;
; MODIFICATION HISTORY:
;   Initial Documentation Wednesday, June 29, 2005
;   Modified to include v1.2 Heiles codes, October 21, 2005
;   Got rid of cyc_time, Jan 08, 2006
;   Added caldir and mhdir, by popular (kevin's) request, Jan 27 2006
;   Added FFN, by popular (kevin's) request, Jan 27 2006
;   Got rid of this FFN, LFN nonsense, and wrapped it into endn and startn., Jan 30, 2006
;   Modified for S1H compatability, July 12, 2006, Goldston Peek
;   Added ODF, July 2006, Goldston Peek
;   Ditched stops, renamed some stuff, Nov 2006
;   Made fitsdir a variable, removed userrxfile, Peek May, 30, 2009
;   hacked in the v25 variable, lord have mercy, Peek May 31, 2009
;   Joshua E. Goldston, goldston@astro.berkeley.edu
;-
if keyword_set(tdf) then scnfmt = '(I2.2)' else scnfmt = '(I3.3)' 
if (not keyword_set(mhdir)) then mhdir = root + '/' + proj + '/mh/'
if (not keyword_set(caldir)) then caldir =  root + '/' + proj + '/' + region + '/lsfs/'

if n_elements(v25) ne 0 then begin
    
    endn = elst
    elst = fd
    fd = fitsdir
    startn = slst
    slst = scan
    scan = v25
endif

name = 'galfa.' + string(year, format='(I4.4)')+ string(month, format='(I2.2)')+ string(day, format='(I2.2)')+'.'+proj+'.'

fns = file_search(fd, name +'*.fits')
nf = n_elements(fns)
fn = strarr(nf)

for i=0, nf-1 do begin
    fn[i] = (reverse(strsplit(fns[i], '/', /extract)))[0]
endfor

if n_elements(v25) eq 0 then begin
    startn = (reverse(strsplit(fn[0], '.', /extract)))[1]
    endn = (reverse(strsplit(fn[nf-1], '.', /extract)))[1]
endif else begin
    fn = name + string(findgen(endn-startn+1)+startn, format='(I4.4)') + '.fits'
endelse 

if (not keyword_set(nomh)) then  mh_wrap, datadir, 'null', mhdir, namearray=fn

writdir = root + '/' + proj + '/' +  region + '/' + region +'_'+ string(scan, format=scnfmt) + '/'

if (not(keyword_set(calfile))) then begin

    lsfs_wrap, fd, mhdir, 'null', caldir, savefilename=calfiles, namearray=fn
    calfile=calfiles[0]
endif

lastfile = mhdir + name +  string(endn, format='(I4.4)') + '.mh.sav'
;if (keyword_set(ffn)) then 
;firstfile = mhdir + name +  string(startn, format='(I4.4)') + '.mh.sav'

calcor_gs, region, mhdir, name, fd, name, writdir, slst, elst, calfile, caldir, startn, endn, odf=odf, deblip=deblip
;+

if n_elements(v25) ne 0 then begin
    ; put everything back where it was
    v25 = scan
    scan = slst
    slst = startn
    fitsdir = fd
    fd = elst
    elst = endn
endif

end
