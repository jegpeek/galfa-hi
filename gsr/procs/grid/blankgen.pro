;+
; NAME:
;  BLANKGEN
;
;
; PURPOSE:
;  Look at the todarr positions and truncate the data in needed.
;
;
; CALLING SEQUENCE:
;  blankgen, root, region, proj
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
;  documented Feb 7 2007 JEG Peek
;-


pro blankgen, root, region, proj, blankfile

path = root + proj + '/' + region + '/'
restore, path + 'todarr.sav';, /ver

;read an old blankfile or make a blank parameter
fileorig = file_search( path, blankfile)
if fileorig eq path + blankfile then restore, fileorig else blank = [0l,0l,0l]

ndays = n_elements(uniq(mht.day, sort(mht.day) ))

for i=0, ndays-1 do begin

    plot, mht[where(mht.day eq i)].ra_halfsec[0], mht[where(mht.day eq i)].dec_halfsec[0], /ynozero

    print, 'Early cut? (L=no, R = yes)'

    cursor, x, y, /up
    if !mouse.button eq 1 then early = 0. else early = 1.
    
    while early eq 1 do begin
        print, 'choose early cut location'
        cursor, x, y, /up
        mn = min( (mht[where(mht.day eq i)].ra_halfsec[0]-x)^2*15^2. + (mht[where(mht.day eq i)].dec_halfsec[0]-y)^2, pos)
        plots, (mht[where(mht.day eq i)].ra_halfsec[0])[pos], (mht[where(mht.day eq i)].dec_halfsec[0])[pos], psym=1
        print, 'is this ok (L=no, R = yes)?'
        cursor, x, y, /up
        if !mouse.button eq 4 then begin
            early = 0. 
            for j=0, 6 do blank = [[blank], [min(mht[where(mht.day eq i)].utcstamp)-1l, (mht[where(mht.day eq i)].utcstamp)[pos], j]]
        endif else begin
            early = 1.
            plot, mht[where(mht.day eq i)].ra_halfsec[0], mht[where(mht.day eq i)].dec_halfsec[0], /ynozero
            
        endelse
    endwhile

    print, 'Late cut? (L=no, R = yes)'

    cursor, x, y, /up
    if !mouse.button eq 1 then late = 0. else late = 1.
    
    while late eq 1 do begin
        print, 'choose late cut location'
        cursor, x, y, /up
        mn = min( (mht[where(mht.day eq i)].ra_halfsec[0]-x)^2*15^2. + (mht[where(mht.day eq i)].dec_halfsec[0]-y)^2, pos)
        plots, (mht[where(mht.day eq i)].ra_halfsec[0])[pos], (mht[where(mht.day eq i)].dec_halfsec[0])[pos], psym=1
        print, 'is this ok (L=no, R = yes)?'
        cursor, x, y, /up
        if !mouse.button eq 4 then begin
            late = 0. 
            for j=0, 6 do blank = [[blank], [(mht[where(mht.day eq i)].utcstamp)[pos],  max(mht[where(mht.day eq i)].utcstamp)+1l, j]]
        endif else begin
            late = 1.
            plot, mht[where(mht.day eq i)].ra_halfsec[0], mht[where(mht.day eq i)].dec_halfsec[0], /ynozero
        endelse
    endwhile

endfor

save, blank, f=path + blankfile

end
    
