;+
; NAME:
;  
;  SCUBE
;
; PURPOSE:
;
;  Make IRIS dust cubes associated to each GALFA survey cube
;    
; CALLING SEQUENCE:
;   sdust, cnx, cny, 
;
; INPUTS:
;   CNX - A number from 0 to 44, selecting which 
;              region in RA to grid
;   CNY - A number from 0 to 4,  selecting which 
;              region in DEC to grid
;
; OPTIONAL INPUTS:
;    NONE.
;
; KEYWORD PARAMETERS:
;   propath -- if set, that path to the irispro directory
;   datapath -- if set, the path to the irisdata directory
;   
; OUTPUTS:
;   NONE
;
; MODIFICATION HISTORY:
;  Written and Commented by J.E.G. Peek on May 9, 2007
;-

pro sdust, cnx, cny, propath=propath, datapath=datapath, hdrpath=hdrpath

if keyword_set(propath) then defsysv, '!IRISPRO', propath else defsysv, '!IRISPRO', '~/Documents/irispro'
defsysv, '!INDEF', 0.

;find the true center positions from the cnx and cny data. cnx is over RA and runs from

cx0 = 4.0 ;degrees
cy0 = 2.35 ;degrees
dcx = 8. ;degrees
dcy = 8. ;degrees

; centers of the final cube of interest
cx = cx0+cnx*dcx
cy = cy0+cny*dcy

caldat,systime(/julian), month ,day, year       
dt = string(year, f='(I4.4)') + '-' + string(month, f='(I2.2)') + '-' + string(day, f='(I2.2)')

;integration time cube

if keyword_set(hdrpath) then restore,  hdrpath + 'dust_hdr.sav' else restore, '/Users/goldston/Documents/batch/GALFA/PIPE/dust_hdr.sav'

sxaddpar, hdr, 'OBJECT', 'GALFA-HI RA+DEC Tile ' + string(cx, f='(I3.3)') + '.00+' +  string(cy, f='(I2.2)') + '.' + string(ceil((cy - floor(cy))*100), f='(I2.2)') + ' Associated Dust Map'
sxaddpar, hdr, 'CRPIX1', 256.5 - (180.0 - cx)/0.01666666
sxaddpar, hdr, 'CRPIX2', 256.5 - cy/0.01666666
sxaddpar, hdr, 'DATE', dt, 'Date data cube was created'
d100name = 'IRIS_RA+DEC_' + string(cx, f='(I3.3)') + '.00+' +  string(cy, f='(I2.2)') + '.' + string(ceil((cy - floor(cy))*100), f='(I2.2)') + '_100.fits'
d060name = 'IRIS_RA+DEC_' + string(cx, f='(I3.3)') + '.00+' +  string(cy, f='(I2.2)') + '.' + string(ceil((cy - floor(cy))*100), f='(I2.2)') + '_060.fits'

if keyword_set(datapath) then defsysv, '!IRISDATA', datapath + '/IRISNOHOLES_B4H0' else defsysv, '!IRISDATA', '~/Documents/IRISNOHOLES_B4H0'
d100 = mosaique_iris(hdr, band=4)
fits_write, d100name, d100, hdr

if keyword_set(datapath) then defsysv, '!IRISDATA', datapath + '/IRISNOHOLES_B3H0' else defsysv, '!IRISDATA', '~/Documents/IRISNOHOLES_B3H0'
d060 = mosaique_iris(hdr, band=3)
fits_write, d060name, d060, hdr

end
