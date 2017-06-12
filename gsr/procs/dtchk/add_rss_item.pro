pro add_rss_item, file, title, description, links, linknames
; read in the file
readcol, file, filecont, format='A', deli='^M'
nel = n_elements(filecont)
; truncate the end of the file to get rid of /channel and /rss
get_lun, unit
openw, unit, file
for i=0, nel-3 do begin
    printf, unit, filecont[i]
endfor
;title

printf, unit, '<item>'
printf, unit, '<title>'+title+'</title>'

;description
printf, unit, '<description>'+description

;links

nl = n_elements(links)
for i=0, nl -1 do printf, unit, '<a href=' + links[i] + '>' + linknames[i] +'</a>'
printf, unit, '</description>'
printf, unit, '</item>'
printf, unit, '</channel>'
printf, unit, '</rss>'
close, unit
end
