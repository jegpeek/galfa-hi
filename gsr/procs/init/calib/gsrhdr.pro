; returns simple header plus file name to write data to file

function gsrhdr, outdata, sfn

hdr=strarr(10)

hdr[0]='SIMPLE  =                    T /image conforms to FITS standard                 '
hdr[1]='BITPIX  =                  -32 /bits per data value                             '
hdr[2]='NAXIS   =                    4 /number of axes                                  '
hdr[3]='NAXIS1  =                 8192 /                                                '
hdr[4]='NAXIS2  =                    2 /                                                '
hdr[5]='NAXIS3  =                    7 /                                                '
hdr[6]='NAXIS4  =                 '+string((size(outdata))[4], format='(I4.2)')+' /                                                '
hdr[7]='EXTEND  =                    T /file may contain extensions                     '
hdr[8]='ASFN =' +  string(sfn, format='(A48)') + ' /associated GSR file name'
hdr[9]='END                                                                             '

return, hdr
end
