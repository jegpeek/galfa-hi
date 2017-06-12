;-----------------------------------------------------------------------
;+
; NAME:
;   djs_lockfile
;
; PURPOSE:
;   Test if a file is already "locked", and lock it if not.
;
; CALLING SEQUENCE:
;   res = djs_lockfile( filename, [lun= ] )
;
; INPUT:
;   filename:   File name
;
; OPTIONAL INPUTS:
;   lun:        If this argument exists, then open FILENAME for read/write
;               access and return the pointer (LUN number) for that file.
;               Do this only if we are able to lock the file.
;
; OUTPUTS:
;   res:        Return 0 if file already locked, or 1 if not in which case
;               we would have just locked it.
;
; COMMENTS:
;   We use a lock file, which has a single byte written to it, to indicate
;   that FILENAME should be locked (as determined by any subsequent calls
;   to this routine).  Unlock files with DJS_UNLOCKFILE.
;
; BUGS:
;
; PROCEDURES CALLED:
;
; REVISION HISTORY:
;   30-Apr-2000  Written by D. Schlegel, APO
;-
;-----------------------------------------------------------------------
function djs_lockfile, filename, lun=lun

   lockfile = filename + '.lock'

   openw, olun, lockfile, /append, /get_lun
   if ((fstat(olun)).size EQ 0) then begin
      writeu, olun, 1B
      flush, olun ; Flush output immediately
      res = 1
      if (arg_present(lun)) then begin
         openw, lun, filename, /get_lun
      endif
   endif else begin
      res = 0
   endelse

   close, olun ; This will flush output to this file
   free_lun, olun

   return, res
end
;-----------------------------------------------------------------------
