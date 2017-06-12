;+
; NAME:
;   SCUBEMULTIPROC
; 
;
; PURPOSE:
;   A wrapper for scube that allows many computers to make survey cubes simultaneously
;
;
; CALLING SEQUENCE:
;      scubemultiproc, root, region, proj, multifile, rs=rs, _REF_EXTRA=_extra, tdf=tdf, $
;      spname=spname, badrxfile=badrxfile, xingname=xingname, odf=odf, blankfile=blankfile, $
;      arcminperpixel=arcminperpixel, norm=norm, pts=pts,  cpp=cpp, madecubes=madecubes, 
;      noslice=noslice, strad=strad
; INPUTS:
;   Same as scube, except instead of cnx and cny we have multifile, which
;   contains the information as to which files have been processed.
;
;
; OPTIONAL INPUTS:
;   same as scube
;
;
; KEYWORD PARAMETERS:
;  same as scube
;
;
; OUTPUTS:
;   same as scube
;
;
; MODIFICATION HISTORY:
;   Written and documented by Josh Peek, Friday, Jan 16th
;-

pro scubemultiproc, root, region, proj, multifile, rs=rs, _REF_EXTRA=_extra, tdf=tdf, spname=spname, badrxfile=badrxfile, xingname=xingname, odf=odf, blankfile=blankfile, arcminperpixel=arcminperpixel, norm=norm, pts=pts,  cpp=cpp, madecubes=madecubes, noslice=noslice, strad=strad

ct =1
while ct ne 0 do begin
restore, multifile

wh = where(scm.complete eq 0, ct)

;random seems too dangerous...
;ch = wh[n_elements(wh)*randomu(seed)]
ch=wh[0]
scm[complete].ch = 1.

save, scm, f=multifile

scube,root, region, proj, scm[ch].cnx, scm[ch].cny, rs=rs, _REF_EXTRA=_extra, tdf=tdf, spname=spname, badrxfile=badrxfile, xingname=xingname, odf=odf, blankfile=blankfile, arcminperpixel=arcminperpixel, norm=norm, pts=pts,  cpp=cpp, madecubes=madecubes, noslice=noslice, strad=strad



endwhile

end
