; BETA VERSION -- 20051205

;   region    -- the name given to this set of reductions
;   rootmh   -- where the mh file lives : '/share/goldston/Oct04/'
;   namemh   -- the core name for the mh file : 'galfa.20041029.a1943.'
;   root     -- where the galspect fits file is : '/share/galfa/'
;   name     -- the core name of for the galspect file (usually identical to namemh): 'galfa.20041029.a1943.'
;   rootout  -- the output directory
;   calfile  -- the appropriate SFS calibration file to use
;   calpath  -- the path of said calibration file
;   num      -- the number of the fits file (5 -> 0005)
;   userrxfile -- the name and full path to any badrx file 
;                 beyond the standard file.
;   odf      -- if set use the old data format (.sav).
pro onefile, region, rootmh, namemh, root, name, rootout, calfile, calpath, num, userrxfile=userrxfile, odf=odf

date = (strsplit(namemh, '.', /extract))[1]
; from the begining of 2005 to june 2005 two cables were swapped.
; All LSFS files and mh files are generated naively, and all data
; should be switched back after this step in calcor_GS
if ((double(date) gt 20050000d) and (double(date) lt 20050600d)) or ((double(date) ge 20050711d) and (double(date) le 20050719d))  then swap05 = 1. else swap05 = 0.

filename = root + name + string(num, format='(I4.4)') + '.fits'

restore, calpath + calfile, /ver
restore, getenv('GSRPATH') + 'savfiles/newtemp01032005.sav'
conv_factor = tcal/caldeflnnb

ccgs_guts, region, rootmh, namemh,rootout,name, num, filename, conv_factor, calpath, calfile, (-1), (-1), mhall, fnall, reflall, tcal, rxgood, refl, secs, swap05=swap05, userrxfile=userrxfile, odf=odf

end

