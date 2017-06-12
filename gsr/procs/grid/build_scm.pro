;+
; NAME:
;  BUILD_SCM
;
;
; PURPOSE:
;  To make a file for scaubemultiproc to access
;
;
; CALLING SEQUENCE:
;  build_scm, cnxs, cnys, file
;
;
; INPUTS:
;  cnxs = array of positions to build cubes, from 0 to 44
;  cnys = array of positions to build cubes, from 0 to 4
;  file = the file name into which to save said input
;
; MODIFICATION HISTORY:
;  Written and documented by Josh Peek, January 16, 2009
;-

pro build_scm, cnxs, cnys, file

nel = n_elements(cnxs)
scm = replicate({cnx:0, cny:0, complete:0}, nel)
scm.cnx = reform(floor(cnxs), nel)
scm.cny = reform(floor(cnys), nel)
scm.complete = 0

save, scm, f=file

end
