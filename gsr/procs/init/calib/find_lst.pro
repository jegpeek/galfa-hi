;+
;
;
;-


pro find_lst, root, name, startlst, endlst, turntime, stel, endel, nums,startn, endn

stel = -1
endel   = -1
i = startn
while (stel eq -1) do begin
    fn = root + name + string(i, format='(I4.4)') + '.mh.sav'
    restore, fn
    secoff =  min(abs((mh.lst_meanstamp-(startlst))*60.*60), x)
    print, secoff
    if (secoff lt 0.5*366./365.) then begin
        nums = i
        stel = x
        print, stel
    endif
    i = i+1
endwhile

while (endel eq -1) do begin
    fn = root + name + string(i, format='(I4.4)') + '.mh.sav'
    restore, fn
    print,  min(abs(mh.lst_meanstamp-endlst)*60.*60)
    ; remember the sidereal second ne the solar second 
    if (min(abs(mh.lst_meanstamp-endlst)*60.*60, x) lt 0.5*366./365) then endel = x else if (i eq endn) then endel = (size(mh))[1]-2 
    nums = [nums,i]
    i = i+1
endwhile

end


    
    
