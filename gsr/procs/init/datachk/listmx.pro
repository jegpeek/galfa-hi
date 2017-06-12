pro listmx, mx, filenm, label=label

if keyword_set( label) then begin
print, '   problems for 14 rx, 7 beams             |<------------------------------radar periods------------------------------------>||<-------------------radar amplitudes---------------------->|
print, ' 0 1 | 2 3 | 4 5 | 6 7 | 8 9  10 11 12 13    0    1', $
'  |   2    3  |   4    5  |   6    7  |   8    9  |  10   11  |  12   13',$
'  || 0  1  |  2  3  |  4  5  |  6  7  |  8  9  | 10 11  | 12 13'
print, ' '
return
endif

print, mx.rxbadwb, mx.rxbadnb, format='(7(i2,i2," |"), "           |           |           |           |           |           |         ", "  ||       |        |        |        |        |        |      ")'
print, mx.feedbadwb, filenm, format='(2x,7(i1,"  |  "), a)'
print, mx.feedbadnb, format='(2x,7(i1,"  |  "), "         |           |           |           |           |           |         ", "  ||       |        |        |        |        |        |      ")'

;print, mx.rxbadwb, mx.rxbadnb, format='(7(i2,i2," |"))'
;print, mx.feedbadwb, filenm, format='(2x,7(i1,"  |  "), a)'
;print, mx.feedbadnb, format='(2x,7(i1,"  |  "))'

rd= mx.rxradarwb
print, rd[0,*], rd[1,*], $
  format='(42x,6(2f5.1, " |"), 2f5.1, " ||", 6(2f3.0, " | "), 2f3.0)'

return
end
