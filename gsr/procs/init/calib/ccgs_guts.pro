pro ccgs_guts, region, rootmh, namemh, rootout, name, num, filename, conv_factor, calpath, calfile, stel, endel, mhall,fnall, reflall, tcal, refl,secs, swap05=swap05, odf=odf, deblip=deblip
;+
; NAME:
;   CCGS_GUTS
; PURPOSE:
;   The do the _guts_ of the first stage reduction for basketweave
;   (BW) collected data. Requires that there be mh headers 
;   generated, as in m1_hdr.pro. This program works on a single 
;   night's worth of data, and a single file within that.
;
; CALLING SEQUENCE:
;  ccgs_guts, region, rootmh, namemh, rootout, $
;  name, num, filename, conv_factor, calpath, calfile, $
;  stel, endel, mhall,fnall, tcal, swap05=swap05
;
; INPUTS:
;   region   -- the name given to this set of reductions
;   rootmh   -- where the mh files live : '/share/goldston/Oct04/'
;   namemh   -- a typical name for the mh files : 'galfa.20041029.a1943.'
;   rootout  -- where the galspect files go : '/share/galfa/A2011/fits'
;   name     -- the name of for a the galspect files : 'galfa.20041029.a1943.'
;   num      -- time-ordered number of the fits file, e.g. 5 (0005)
;   filename -- full name of the fits file including full path.
;   conv_factor -- the number by which to multiply 
;                 the data to get temperature calibrated data
;   calpath -- the path of the calibration file
;   calfile  -- the appropriate SFS calibration file to use
;   stel -- the first element of the file that we wish to reduce
;   endel -- the last element of the file that we wish to reduce
;   tcal  -- The assumed cal temperatures
; KEYWORD PARAMETERS:
;   swap05  -- Set if beam 4 pol 0 and beam 6 pol 0 are swapped. 
;   odf -- Old Data Format. Save in the GSR 2.1 and prior compatible 
;                 format if this flag is set.
;   deblip -- if set, remove blips, a la a2124 2008/2009
; OUTPUTS:
;   mhall -- The output amalgamated mh structure
;   fnall -- The output amalgamted filenames list
;   secs -- number of seconds in the file
; HISTORY:
;  Inital documentation, October 2005 - goldston
;  Tweaked documentation, December 12 2005
;  Added ODF, July 2006
;  Added "despike.pro" for removing RFIs, December 08 2008 - Min-Young Lee
;  Got rid of rx stuff, June 1, 2009 JEG Peek
;-

versiondate = '20090709'

; Size of the narrowband, in bins
nbsz = 7679.
; if starting element is unspecified, use 0.
if (stel eq (-1)) then stel =0.
; read in m1 files
m1 = mrdfits(filename, 1, hdr1)
; length of the m1 array (600, typically)
len = (size(m1))[1]/14l
m1 = temporary(m1[0:len*14l-1])
; if ending element is unspecified, use len -1
if (endel eq (-1)) then endel = len -1
; apply the bandpass corrections from the LSFS file
m1polycorr, calpath, calfile, m1, data, swb_c, pnb_uc, pwb_uc, /alsodocal
;trucate the data
data= data[*,*,*,stel:endel]
secs = (size(data))[4]
; swap the beams
if keyword_set(swap05) then begin
   temp = data[*, 0, 4, *]
   data[*, 0, 4, *] = data[*, 0, 6, *]
   data[*, 0, 6, *] = temp
   temp = swb_c[*, 0, 4, *]
   swb_c[*, 0, 4, *] = swb_c[*, 0, 6, *]
   swb_c[*, 0, 6, *] = temp
   temp = pnb_uc[0, 4, *]
   pnb_uc[0, 4, *] = pnb_uc[ 0, 6, *]
   pnb_uc[0, 6, *] = temp
   temp = pwb_uc[0, 4, *]
   pwb_uc[0, 4, *] = pwb_uc[0, 6, *]
   pwb_uc[0, 6, *] = temp
endif
data = data*rebin(reform(conv_factor, 1, 2, 7, 1), nbsz, 2, 7, secs)

deflect, data, refl=refl
restore, rootmh+namemh+string(num, format='(I4.4)') + '.mh.sav'
if (mh[0].object eq 'DATAMISS') then dataver = 0. else if (mh[0].obs_name eq 'DATAMISS') then dataver = 1. else dataver = 2.
mh = mh[stel:endel]
smh = (size(mh))[1]


; does the removal of single-channel RFI
sm_data_out = dblarr(7679, secs)
if secs gt 10 then begin
for k = 0, 1 do begin
 for j = 0, 6 do begin
   sm_data = smooth(reform(data[*, k, j, *]), [1, 10], /edge_truncate) 
   data_slice = reform(data[*, k, j, *]) 
   for i = 0, secs-1 do begin
     despike, sm_data[*, i], out
     sm_data_out[*, i] = out 
   endfor
   rfi = sm_data - sm_data_out
   despiked_data = data_slice - rfi 
   data[*, k, j, *] = despiked_data
 endfor
endfor
endif

; gets rid of the strange 'blips' seen in a2124 data
if keyword_set(deblip) then begin
    ; to deal with dt slightly great than 12 seconds, we do this twice.
    deblipper, data
    deblipper, data
endif

; into VLSR
dcs_wrap, data, mh.vlsr, mh.crval1, 1420405750d,  outdata
fn = rootout + name + string(num, format='(I4.4)')+'.'+region+'.sav'
fns = strarr(smh)
fns[*] = fn
if n_elements(mhall) eq 0 then mhall = mh else mhall = [mhall, mh]
if n_elements(fnall) eq 0 then fnall = fns else fnall = [fnall, fns]
if n_elements(reflall) eq 0 then reflall = refl else reflall = [[[reflall]], [[refl]]]

if (not (keyword_set(swap05))) then swap05 = 0.
if keyword_set(odf) then begin
   save, outdata, swb_c, pwb_uc, pnb_uc, mh, conv_factor, versiondate, tcal, swap05, refl, filename=rootout + name + string(num, format='(I4.4)')+'.'+region+'.sav'
endif else begin
   save, swb_c, pwb_uc, pnb_uc, mh, conv_factor, versiondate, tcal, swap05, refl, filename=rootout + name + string(num, format='(I4.4)')+'.'+region+'.sav'
   hdr = gsrhdr( outdata,  name + string(num, format='(I4.4)')+'.'+region+'.sav')
   writefits, rootout + name + string(num, format='(I4.4)')+'.'+region+'.fits', outdata, hdr
endelse
end
