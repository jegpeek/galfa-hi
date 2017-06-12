; find any places where the data is bad rxed in both beams and blank it

pro double_blank, badrxfile, blanksfile

restore, badrxfile
nel = n_elements(badrx)

for i=0, nel-2 do begin
    wh = where((badrx[i+1:*].utcstart le badrx[i].utcend) and (badrx[i+1:*].utcend ge badrx[i].utcstart) and (badrx[i+1:*].badbeam eq badrx[i].badbeam) and (badrx[i+1:*].badpol ne badrx[i].badpol), ct)
    if ct ne 0 then begin
        for j=0, ct-1 do begin
            print, 'doublerx : blanking...'
            edblanks, blanksfile, max([(badrx[i+1:*])[wh[j]].utcstart, badrx[i].utcstart]), min([(badrx[i+1:*])[wh[j]].utcend, badrx[i].utcend]), badrx[i].badbeam
        endfor
    endif
endfor

end 
