;+
; NAME:
;  stg0_multiproc
;
;
; PURPOSE:
;  To run stg0 on mulitple machines simultaneously.
;
;
; CATEGORY:
;
;
;
; CALLING SEQUENCE:
;  stg0_multiproc
;
;
; INPUTS:
;
;
;
; OPTIONAL INPUTS:
;
;
;
; KEYWORD PARAMETERS:
;
;
;
; OUTPUTS:
;
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
;  JEG Peek: Dec 3 2008
;  JEG Pekk: Added Eric's locking code, May 17, 2009
;-
pro stg0_multiproc
ct =1
while ct ne 0 do begin
; ERIC'S LOCKING RESTORE CODE:                
                repeat begin
                    got_lock=get_lock_file('stg0.lock')
                endrep until got_lock eq 1
                restore, 'comp_stg0_inps.sav'
                dummy_var=free_lock_file('stg0.lock')
; END ERIC'S LOCKING RESTORE CODE
wh = where(stg0_inps.complete eq 0, ct)

;random seems too dangerous...
;ch = wh[n_elements(wh)*randomu(seed)]
ch=wh[0]
stg0_inps[ch].complete = 1.



; ERIC'S LOCKING SAVE CODE:  
                repeat begin
                    got_lock=get_lock_file('stg0.lock')
                endrep until got_lock eq 1
                save, stg0_inps, f='comp_stg0_inps.sav'
                dummy_var=free_lock_file('stg0.lock')
; END ERIC'S LOCKING SAVE CODE
  


stg0, stg0_inps[ch].year, stg0_inps[ch].month, stg0_inps[ch].day, stg0_inps[ch].proj, stg0_inps[ch].region, stg0_inps[ch].root, stg0_inps[ch].startn, stg0_inps[ch].endn, stg0_inps[ch].slst, stg0_inps[ch].elst, stg0_inps[ch].scan, nomh=stg0_inps[ch].nomh, calfile=stg0_inps[ch].calfile, fitsdir=stg0_inps[ch].fitsdir, userrxfile=stg0_inps[ch].userrxfile, mhdir=stg0_inps[ch].mhdir, caldir=stg0_inps[ch].caldir, tdf=stg0_inps[ch].tdf, odf=stg0_inps[ch].odf

endwhile

end
