function gromask, mask, shrink=shrink

if keyword_set(shrink) then return, floor((mask+shift(mask, 1,0)+shift(mask, 1,1)+shift(mask, 1,-1)+shift(mask, 0,1)+shift(mask, 0,-1)+shift(mask, -1,-1)+shift(mask, -1,0)+shift(mask, -1,1))/9.)
return, ceil((mask+shift(mask, 1,0)+shift(mask, 1,1)+shift(mask, 1,-1)+shift(mask, 0,1)+shift(mask, 0,-1)+shift(mask, -1,-1)+shift(mask, -1,0)+shift(mask, -1,1))/9.)

end
