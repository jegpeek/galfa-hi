pro fix_T, filename

time = readfits(filename, hdr)

sxaddpar, hdr, 'CRVAL1', 180.0
sxaddpar, hdr, 'CRVAL2', 0.0

writefits, filename, time, hdr

end
