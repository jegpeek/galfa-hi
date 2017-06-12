;+
; NAME:
;
;  WHSPBLANKS
;
; PURPOSE:
;
; read in an spbalnks file and return whether the spectrum is modified
; CALLING SEQUENCE:
;  
;  whblanks, spblfile, mht, minch, maxch, flag
;
; INPUTS:
;  
;   spblfile - the full path to the file that contains the times, beams
;              channels and fits to modify spectra, less suffix
;   mht - an abbreviated, concatenated mh file of all of the region's data, 
;         cf todarr.pro
;   minch -- the minimum channel we might be interested in
;   maxch -- the maximum channel we might be interested in
;
; OUTPUTS:
;   flag - 1s are bad, 0s are good.
;   
; MODIFICATION HISTORY:
; Initally writted by J.E.G. Peek on June 24, 2011
;-

pro whspblanks, spblfile, mht, minch, maxch, flag


len = (size(mht))[1]
flag = fltarr(len, 7)

if (file_test(spblfile + '.fits')) then begin

spbl = mrdfits(spblfile + '.fits', 1)

sz = size(spbl)
for i=0l, sz[3]-1 do begin
    whb = where((mht.utcstamp eq spbl[i].utc) and ((minch lt spbl[i].fitp[2]) or (maxch gt spbl[i].fitp[1])), ct)
    if (ct ne 0) then flag[whb,spbl[i].beam] = 1.
endfor

endif
end
