pro add_notes_GALFA_RSS, proj, date

RSSfile = '~goldston/public_html/GALFA_DTCHK_RSS.html'
;RSSfile = '~goldston/GALFA_DTCHK_RSS.html'
readcol, RSSfile, filecont, format='A', deli='^M'
nel = n_elements(filecont)
title = proj + ': ' + string(date, f='(I8.8)')

wh = where(filecont eq '<title>' + title +'</title>', ct)
if ct eq 1 then begin 
    get_lun, unit
    openw, unit, RSSfile
    for i=0, wh[0]+2 do begin
        printf, unit, filecont[i]
    endfor
    note = ''
    print, 'Please enter your note now.'
    read, note
    printf, unit, 'NOTES: '+note
    for i=wh[0]+3, nel-3 do begin
        printf, unit, filecont[i]
    endfor
    printf, unit, '</description>'
    printf, unit, '</item>'
    printf, unit, '</channel>'
    printf, unit, '</rss>'
    close, unit
endif else begin
    print, 'Project and date does not match one and only one scan - cannot annotate'
endelse

end

