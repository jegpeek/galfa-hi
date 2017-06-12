function rootswap, strings, oldroot, newroot
outstrings = strings
for i=0l, long(n_elements(strings))-1 do begin
    outstrings[i] = newroot + strmid(strings[i], strlen(oldroot))
endfor
return, outstrings
end
