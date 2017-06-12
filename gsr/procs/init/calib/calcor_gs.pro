pro calcor_gs, region, rootmh, namemh, root, name, rootout, startlst, endlst, calfile, calpath, startn, endn, stops=stops, odf=odf, deblip=deblip
;+
; NAME:
;   CALCOR_GS
; PURPOSE:
;   The do the first stage reduction for basketweave
;   (BW) collected data. Requires that there be mh headers 
;   generated, as in m1_hdr.pro. This program works on a single 
;   night's worth of data, within a single BW command scan.
;
; CALLING SEQUENCE:
;   calcor_GS, rname, rootmh, namemh, root, name, startlst, endlst, calfiles
;
; INPUTS:
;   region    -- the name given to this set of reductions
;   rootmh   -- where the mh files live : '/share/goldston/Oct04/'
;   namemh   -- a typical name for the mh files : 'galfa.20041029.a1943.'
;   root     -- where the galspect files are : '/share/galfa/'
;   name     -- the name of for a the galspect files : 'galfa.20041029.a1943.'
;   rootout  -- the output directory
;   startlst -- the time at which the BW was commanded to start
;   endlst   -- the time at which the BW expected to end
;   calfile  -- the appropriate SFS calibration file to use
;   calpath  -- the path of said calibration file
;   startn        -- If the observation was ended early, use this
;                     parameter to make everthing work nice-nice.
;   endn          -- If the observation starts with any file other than 0000, use this
;                     parameter to make everthing work nice-nice.
; KEYWORD PARAMETERS:
;   stops         -- engineering mode.
;   odf -- Old Data Format. Save in the GSR 2.1 and prior compatible 
;                 format if this flag is set.
;   deblip -- if set, remove blips, a la a2124 2008/2009
; OUTPUTS:
;   NONE (corrected spectral files)
; MODIFICATION HISTORY
;   Got rid of userrxfile, Peek, June 1, 2009
;-

versiondate = '20090601'

date = (strsplit(namemh, '.', /extract))[1]
; from the begining of 2005 to june 2005 two cables were swapped.
; All LSFS files and mh files are generated naively, and all data
; should be switched back after this step in calcor_GS
if ((double(date) gt 20050000d) and (double(date) lt 20050600d)) or ((double(date) ge 20050711d) and (double(date) le 20050719d))  then swap05 = 1. else swap05 = 0.

; This finds the starting and element of the starting and ending files of a scan
; as given in LST.
find_lst, rootmh, namemh, startlst, endlst, 25., stel,endel, nums, startn, endn

; Filenames for the original data
filenames = root + name + string(nums, format='(I4.4)') + '.fits'

; convert to K
restore, calpath + calfile, /ver
restore, getenv('GSRPATH') + 'savfiles/newtemp01032005.sav'
conv_factor = tcal/caldeflnnb

; Size of the narrowband, in bins
nbsz = 7679.

; for the sake of the refl thing, we resort our order
shufi = findgen(n_elements(filenames))
nsecs =  fltarr(n_elements(filenames))
msecs = nsecs
if n_elements(shufi) gt 1. then shufi = [reverse(shufi[0:(n_elements(shufi)-1)/2]), shufi[(n_elements(shufi)-1)/2+1: *]]

for q=0, n_elements(filenames)-1 do begin
    i=shufi[q]
    if (i eq 0) then stel_i = stel else stel_i = -1
    if (i eq (n_elements(filenames)-1)) then endel_i = endel else endel_i = -1
    ccgs_guts, region, rootmh, namemh,rootout,name, nums[i], filenames[i], conv_factor, calpath, calfile, stel_i, endel_i, mhall, fnall, reflall, tcal, refl, secs, swap05=swap05, odf=odf, deblip=deblip
    nsecs[i] = secs
    msecs[q] = secs
endfor


fn = fnall
mh = mhall
refl=reflall
filepos = fltarr(total(nsecs))
;alright, lets re-order these aggregates
for q=0, n_elements(filenames)-1 do begin
    i = shufi[q]
    fn[total(nsecs[0:i])-nsecs[i]:total(nsecs[0:i])-1] = fnall[total(msecs[0:q])-msecs[q]:total(msecs[0:q])-1]
    mh[total(nsecs[0:i])-nsecs[i]:total(nsecs[0:i])-1] = mhall[total(msecs[0:q])-msecs[q]:total(msecs[0:q])-1]
    refl[*,*,i] = reflall[*,*,q]
    filepos[total(nsecs[0:q]) - nsecs[q]:total(nsecs[0:q])-1] = findgen(nsecs[q])
Endfor

save, mh, fn, refl, tcal, conv_factor, stel, endel, versiondate, filepos, filename=rootout + name +'hdrs.'+region+'.sav'
end
