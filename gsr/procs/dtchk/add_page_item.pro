pro add_page_item, file, title, description, links, linknames
; read in the file
readcol, file, filecont, format='A', deli='^M'
nel = n_elements(filecont)
; truncate the end of the file to get rid of /channel and /rss
get_lun, unit
openw, unit, file

printf, unit, '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">'
printf, unit, '<HTML>'
printf, unit, ' <HEAD>'
printf, unit, '  <TITLE>QCK file data</TITLE>'
printf, unit, ' </HEAD>'
printf, unit, ' <BODY>'
printf, unit, '<H1>QCK file data</H1>'
printf, unit, '<PRE>'
printf, unit, '<HR>'


;links
nl = n_elements(links)
lnx = ''
for i=0, nl -1 do lnx = lnx + '<a href=' + links[i] + '>' + linknames[i] +'</a>'
printf, unit, '<b>' + title +'</b> '+ description + ' ' + lnx
printf, unit, '<HR>'
for i=9, nel-1 do begin
    printf, unit, filecont[i]
endfor
;title

close, unit
end
