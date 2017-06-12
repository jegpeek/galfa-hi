pro dcs_wrap, indata, indop, incrval1, centerfreq, outdata

len = (size(indata))[4]
outdata = fltarr(8192, 2,7,len)

for i=0,1 do begin
    for j=0, 6 do begin
        for k=0, len-1 do begin
            dop_cor_spect, indata[*, i, j, k], indop[j,k], centerfreq, incrval1[k], outspec, freqs
            outdata[*,i,j,k] = outspec
        endfor
    endfor
endfor

end
