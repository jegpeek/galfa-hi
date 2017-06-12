; make an RSS feed with no items

name='GALFA_DTCHK_RSS.html'

openw, 1, name
printf, 1, '<?xml version="1.0" ?>'
printf, 1, '<rss version="2.0">'
printf, 1, '<channel>'
printf, 1, '</channel>'
printf, 1, '</rss>'

close, 1

end
