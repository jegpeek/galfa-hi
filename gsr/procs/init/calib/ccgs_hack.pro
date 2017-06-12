; This is a code for carl, that allows you to read in a fits, mh and lsfs file

pro ccgs_hack, fitspath, fitsname, mhpath, mhname, lsfspath, lsfsname, outdata, deblip=deblip

stname = strsplit(fitsname, '.', /extract)
name = stname[0] + '.' + stname[1] + '.' + stname[2] + '.'

restore, lsfspath + lsfsname, /ver
restore, getenv('GSRPATH') + 'savfiles/newtemp01032005.sav'
conv_factor = tcal/caldeflnnb

restore, mhpath + mhname
endel = n_elements(mh)-1

ccgs_guts, 'chack', mhpath, name, '/share/galfa/', name, float(stname[3]), fitspath + fitsname, conv_factor, lsfspath, lsfsname, 0, endel, mhall,fnall, reflall, tcal, refl,secs, deblip=deblip

outdata = readfits('/share/galfa/' + name + stname[3]+'.chack.fits', hdr)
spawn, 'rm ' + '/share/galfa/' + name + stname[3]+'.chack.fits'
spawn, 'rm ' + '/share/galfa/' + name + stname[3]+'.chack.sav'


end
