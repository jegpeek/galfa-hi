;+
; NAME:
;  
;  FLIPYA
;
; PURPOSE:
;
;  Josh is an idiot.
;    
; MEMORABLE QUOTE:
;
;    Cop: What are you saying? 
;    Fenster: I said he'll flip you. 
;    Cop: He'll what? 
;    Fenster: Flip you. Flip ya for real. 
;
; MODIFICATION HISTORY:
;  Written by J.E.G. Peek on May 11, 2007
;-

pro flipya, root, region, proj, cnx, cny, rs=rs

;find the true center positions from the cnx and cny data. cnx is over RA and runs from

starttime=systime(/sec)

cx0 = 4.0 ;degrees
cy0 = 2.35 ;degrees
dcx = 8. ;degrees
dcy = 8. ;degrees

; centers of the final cube of interest
cx = cx0+cnx*dcx
cy = cy0+cny*dcy

; centers of the subcubes

scx0 = cx - 128./60.
scx1 = cx + 128./60.

scy0 = cy - 128./60. 
scy1 = cy + 128./60.

if not(keyword_set(savepath)) then savepath = root + proj + '/' + region + '/'

;Narrow
Nname = 'GALFA_HI_RA+DEC_' + string(cx, f='(I3.3)') + '.00+' +  string(cy, f='(I2.2)') + '.' + string(ceil((cy - floor(cy))*100), f='(I2.2)') + '_N.fits'

Wname = 'GALFA_HI_RA+DEC_' + string(cx, f='(I3.3)') + '.00+' +  string(cy, f='(I2.2)') + '.' + string(ceil((cy - floor(cy))*100), f='(I2.2)') + '_W.fits'

Sname = strarr(512)
cd, 'GALFA_HI_RA+DEC_' + string(cx, f='(I3.3)') + '.00+' +  string(cy, f='(I2.2)') + '.' + string(ceil((cy - floor(cy))*100), f='(I2.2)')

for i=0, 511 do begin
    loop_bar, i, 511
    Sname[i] = 'GALFA_HI_RA+DEC_' + string(cx, f='(I3.3)') + '.00+' +  string(cy, f='(I2.2)') + '.' + string(ceil((cy - floor(cy))*100), f='(I2.2)') + '_' +  string(i+1, f='(I3.3)') +'.fits'
endfor
cd, '..'

ns = 0.

;read and write Narrow cube
Narrow = readfits(Nname, hdrN, /noscale, /silent)
Narrow = reverse(temporary(Narrow), 3)
fits_write, Nname, Narrow, hdrN
Narrow =0.

;Wide
Wide = readfits(Wname, hdrW, /noscale, /silent)
Wide = reverse(temporary(Wide), 3)
fits_write, Wname, Wide, hdrW
Wide = 0

;Slices
; Read and Write RA-VEL Slices

cd, 'GALFA_HI_RA+DEC_' + string(cx, f='(I3.3)') + '.00+' +  string(cy, f='(I2.2)') + '.' + string(ceil((cy - floor(cy))*100), f='(I2.2)')

for i = 0, 511 do begin
    Slice = readfits(Sname[i], hdrS, /noscale, /silent)
    Slice = reverse(temporary(Slice), 2)
    fits_write, Sname[i], slice, hdrS
endfor
cd, '..'

print, 'time elapsed:' + string((systime(/sec)-starttime)/3600., f ='(G6.4)') + ' hours'


end
