; a script to compile the coverage maps needed to make joined cubes,
; as in extract_cubes.pro
restore, getenv('GSRPATH') + 'savfiles/hdr356.00+02.35.sav'
allT = fltarr(45.*480. + 32., 5.*480. + 32.)
tilex =  fltarr(45.*480. + 32., 5.*480. + 32.)
tiley =  fltarr(45.*480. + 32., 5.*480. + 32.)
tilepos = fltarr(45.*480. + 32., 5.*480. + 32.)
temp = findgen(512, 512)
; do edge cases first:

for i=1, 43 do begin
    j = 0
    fn = 'GALFA_HI_RA+DEC_' + string(356 - i*8, f='(I3.3)') + '.00+' + string(2+8*j, f='(I2.2)') + '.35_T.fits'
    if file_exists(fn) then time = readfits(fn, hdr) else time = fltarr(512, 512)
    allT[i*480+16:i*480+495,j*480:j*480+495 ] = time[16:495,0:495]
    tilex[i*480+16:i*480+495,j*480:j*480+495 ] = 44 - i
    tiley[i*480+16:i*480+495,j*480:j*480+495 ] = j
    tilepos[i*480+16:i*480+495,j*480:j*480+495 ] = temp[16:495,0:495]
endfor

for i=1, 43 do begin
    j = 4
    fn = 'GALFA_HI_RA+DEC_' + string(356 - i*8, f='(I3.3)') + '.00+' + string(2+8*j, f='(I2.2)') + '.35_T.fits'
    if file_exists(fn) then time = readfits(fn, hdr) else time = fltarr(512, 512)
    allT[i*480+16:i*480+495,j*480+16:j*480+511 ] = time[16:495,16:511]
    tilex[i*480+16:i*480+495,j*480+16:j*480+511 ] = 44 - i
    tiley[i*480+16:i*480+495,j*480+16:j*480+511 ] = j
    tilepos[i*480+16:i*480+495,j*480+16:j*480+511 ] = temp[16:495,16:511]
endfor


for j=1, 3 do begin
    i = 0
    fn = 'GALFA_HI_RA+DEC_' + string(356 - i*8, f='(I3.3)') + '.00+' + string(2+8*j, f='(I2.2)') + '.35_T.fits'
    if file_exists(fn) then time = readfits(fn, hdr) else time = fltarr(512, 512)
    allT[i*480:i*480+495,j*480+16:j*480+495 ] = time[0:495,16:495]
    tilex[i*480:i*480+495,j*480+16:j*480+495 ] = 44 - i
    tiley[i*480:i*480+495,j*480+16:j*480+495 ] = j
    tilepos[i*480:i*480+495,j*480+16:j*480+495 ] = temp[0:495,16:495]
endfor

for j=1, 3 do begin
    i = 44
    fn = 'GALFA_HI_RA+DEC_' + string(356 - i*8, f='(I3.3)') + '.00+' + string(2+8*j, f='(I2.2)') + '.35_T.fits'
    if file_exists(fn) then time = readfits(fn, hdr) else time = fltarr(512, 512)
    allT[i*480+16:i*480+511,j*480+16:j*480+495 ] = time[16:511,16:495]
    tilex[i*480+16:i*480+511,j*480+16:j*480+495 ] = 44 - i
    tiley[i*480+16:i*480+511,j*480+16:j*480+495 ] = j
    tilepos[i*480+16:i*480+511,j*480+16:j*480+495 ] = temp[16:511,16:495]
endfor

; now corner cases

i=0
j=0
fn = 'GALFA_HI_RA+DEC_' + string(356 - i*8, f='(I3.3)') + '.00+' + string(2+8*j, f='(I2.2)') + '.35_T.fits'
if file_exists(fn) then time = readfits(fn, hdr) else time = fltarr(512, 512)
allT[i*480:i*480+495,j*480:j*480+495] = time[0:495,0:495]
tilex[i*480:i*480+495,j*480:j*480+495] = 44 - i
tiley[i*480:i*480+495,j*480:j*480+495] = j
tilepos[i*480:i*480+495,j*480:j*480+495] = temp[0:495,0:495]


i=0
j=4
fn = 'GALFA_HI_RA+DEC_' + string(356 - i*8, f='(I3.3)') + '.00+' + string(2+8*j, f='(I2.2)') + '.35_T.fits'
if file_exists(fn) then time = readfits(fn, hdr) else time = fltarr(512, 512)
allT[i*480:i*480+495,j*480+16:j*480+511] = time[0:495,16:511]
tilex[i*480:i*480+495,j*480+16:j*480+511] = 44 - i
tiley[i*480:i*480+495,j*480+16:j*480+511] = j
tilepos[i*480:i*480+495,j*480+16:j*480+511] = temp[0:495,16:511]

i=44
j=0
fn = 'GALFA_HI_RA+DEC_' + string(356 - i*8, f='(I3.3)') + '.00+' + string(2+8*j, f='(I2.2)') + '.35_T.fits'
if file_exists(fn) then time = readfits(fn, hdr) else time = fltarr(512, 512)
allT[i*480+16:i*480+511,j*480:j*480+495] = time[16:511,0:495]
tilex[i*480+16:i*480+511,j*480:j*480+495] = 44 - i
tiley[i*480+16:i*480+511,j*480:j*480+495] = j
tilepos[i*480+16:i*480+511,j*480:j*480+495] = temp[16:511,0:495]

i=44
j=4
fn = 'GALFA_HI_RA+DEC_' + string(356 - i*8, f='(I3.3)') + '.00+' + string(2+8*j, f='(I2.2)') + '.35_T.fits'
if file_exists(fn) then time = readfits(fn, hdr) else time = fltarr(512, 512)
allT[i*480+16:i*480+511,j*480+16:j*480+511] = time[16:511,16:511]
tilex[i*480+16:i*480+511,j*480+16:j*480+511] = 44 - i
tiley[i*480+16:i*480+511,j*480+16:j*480+511] = j
tilepos[i*480+16:i*480+511,j*480+16:j*480+511] = temp[16:511,16:511]

for i=1, 43 do begin
    for j=1, 3 do begin
        fn = 'GALFA_HI_RA+DEC_' + string(356 - i*8, f='(I3.3)') + '.00+' + string(2+8*j, f='(I2.2)') + '.35_T.fits'
        if file_exists(fn) then time = readfits(fn, hdr) else time = fltarr(512, 512)
        allT[i*480:i*480+511,j*480:j*480+511 ] = time
        tilex[i*480:i*480+511,j*480:j*480+511 ] = 44 - i
        tiley[i*480:i*480+511,j*480:j*480+511 ] = j
        tilepos[i*480:i*480+511,j*480:j*480+511 ] = findgen(512, 512)
    endfor
endfor

sxaddpar, hdr0, 'NAXIS1', 44.*480. + 32.
sxaddpar, hdr0, 'NAXIS2', 5.*480. + 32.
sxaddpar, hdr0, 'OBJECT', 'TOGS Integration Time Map'
fits_write, 'allT.fits', allT, hdr0
save, tilex, tiley, tilepos, f='tilenames.sav'
end
