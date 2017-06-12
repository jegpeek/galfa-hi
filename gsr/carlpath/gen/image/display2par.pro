pro display2par, $
                c_img, i_img, $
                xaxis, yaxis, $
                c_title, i_title, $
                PS=ps, GAMMA=gamma, CAPTION=caption, $
                ENCAPSULATED=encapsulated, $
                EPOCH=epoch, $
		style= style, xaxlbl=xaxlbl, yaxlbl=yaxlbl, $
                _REF_EXTRA=_extra, xpage=xpage, ypage=ypage, $
	pseudomod=pseudomod

;+
;NAME:
;display2par -- display intensity/color (2d color image) using pseudocolor table
; KEYWORDS: ENCAPSULATED

;style =1 means put axes on the image; 5 means not.
;xaxlbl and yaxlbl are the x and y axis labels.
;
; !!!!!!
; leave the ps device open!

; !!!!! PROBABLY SMARTER WAY TO DO CONGRID THAN JUST TAKING 541 PIXELS???
; !!!!! WHAT DO WE DO ABOUT VALUES WE REALLY WANT TO IGNORE?
; A COLOR FIELD WITH VALUES FROM -320 TO -200 WILL HAVE A BUNCH
; OF ZEROS WHERE THERE'S NO DATA.  WHAT IF COLOR STRETCHED FROM -10 TO
; +10, THEN TROUBLE CITY.  --> NAN!!!!

; MAKE A COLORBAR AND IMAGE WITH COLOR/INTENSITY
; USE 24 BIT COLOR

; how would figure out what xsize/ysize (before you get here) to feed
; psopen in order to make correct aspect ratio???

; EXAMPLES:
; IDL> psopen, 'color_inensity.ps', /COLOR
; IDL> display2par, vimage, timage, ra, dec, epoch=2002
; IDL> psclose

; assumes rectangular region of sky.  if curvature is important (high
; latitude) then you have to modify this routine.

; CHECK TO MAKE SURE BOTH PARAMETER MAPS HAVE THE SAME SIZE...
;-

csz = size(c_img)
isz = size(i_img)
if (csz[0] ne 2) OR (isz[0] ne 2) $
  then message, 'Images must both be two-dimensional.'
if (total(csz[1:2] - isz[1:2]) ne 0) $
  then message, 'Images must have the same dimensions.'

; IS THE X WINDOW VISUAL 24-BIT... 
depth= 24
if !d.name eq 'X' then begin
device, get_visual_depth=depth
; IF 24-BIT DISPLAY, SET COLOR DECOMPOSITION ON...
if (depth gt 8) then device, decomposed=1
endif

; IF THERE'S A WINDOW OPEN, ERASE THE CONTENTS FIRST!
if (!d.window ge 0) then erase

; DO WE WANT TO USE XWINDOWS OR POSTSCRIPT?
if keyword_set(PS) then begin
    charsize=1.0
    charthick=1.7
endif

; DEFINE THE INDEX TO COLOR MAPPING...
;pseudo, 100, 100, 100, 100, 22.5, .7, colr
pseudo, 100, 100, 100, 100, 22.5, 0.68, colr
loadct, 0, /silent

if keyword_set( pseudomod) then begin
	colr[*,0]= bytscl( colr[*,0], min=100, max=255)
	tvlct, colr
endif

;========================================================================
; THE PRINTABLE AREA ON AN 8.5 X 11 INCH PAGE IS 7.5 X 10 INCHES 
; (19 X 25 CM)... FOR APJ IT'S (18.5 X 24.75)
; IF PRINTING IN A JOURNAL, GIVE ABOUT 2 CM IN Y FOR THE CAPTION!
if keyword_set( xpage) eq 0 then xpage = 18.5 / 2.54 ; inches
if keyword_set( ypage) eq 0 then $
	ypage = (24.75 - 2.0 * keyword_set(CAPTION)) / 2.54 ; inches
aspectpage = xpage / ypage

;================= DEFINE THE REGIONS TO BE PLOTTED ======================

; WHAT IS THE PIXEL SIZE OF THE PLOT?
xplotsizepix = 541
yplotsizepix = 541

; ASSUME RA AND DEC ARE MEASURED IN DEGREES...
; GET THE ASPECT RATIO OF THE IMAGE...
;aspect = (max(ra)-min(ra)) / (max(dec)-min(dec))
;if (aspect ge 1.0) $
;  then yplotsizepix = round(yplotsizepix / aspect) $
;  else xplotsizepix = round(xplotsizepix * aspect)

; CREATE A LITTLE EXTRA SPACE AROUND THE IMAGE FOR PLOT LABELS...
yblank       = 20  ; BLANK SPACE BETWEEN COLORBAR AND IMAGE
ywedge       = 80  ; HEIGHT OF COLORBAR
yextrabottom = 50  ; BLANK SPACE AT BOTTOM
yextratop    = 50  ; BLANK SPACE AT TOP
xextraleft   = 80  ; BLANK SPACE AT LEFT
xextraright  = 50  ; BLANK SPACE AT RIGHT

; WINDOW SIZE IN PIXELS; INCLUDE MARGINS...
wxsize = xextraleft + xplotsizepix + xextraright
wysize = yextrabottom + yplotsizepix + yblank + ywedge + yextratop

; DEFINE THE PLOT SIZE IN **NORMAL** COORDINATES...
xplotsize = xplotsizepix/float(wxsize)
yplotsize = yplotsizepix/float(wysize)

; DEFINE THE **NORMAL** COORDINATES OF THE TV WINDOW...
ytvbottom = float(yextrabottom)/float(wysize)
ytvtop    = ytvbottom + yplotsize
xtvleft   = float(xextraleft)/float(wxsize)
xtvright  = xtvleft + xplotsize

; DEFINE THE **NORMAL** COORDINATES OF THE BAR WINDOW...
ybarsize   = float(ywedge)/float(wysize)
ybarbottom = float(yextrabottom + yplotsizepix + yblank)/float(wysize)
ybartop    = ybarbottom + ybarsize

;=========================================================================

; DEFINE THE INTENSITY ...
; INTIMG = A 541 BY 541 ARRAY, ARBITRARY UNITS AND RANGE 
; IT DEFINES THE INTENSITY
intimg = congrid(i_img, xplotsizepix, yplotsizepix)

; DEFINE THE VELOCITY/CHANNEL CONVERSION...
; DEFINE A VELOCITY FOR EACH PIXEL IN THE IMAGE.
; COLORIMG1 = A 541 BY 541 ARRAY WITH ARBITRARY UNITS AND RANGE.
; IT DEFINES THE COLOR
colorimg = congrid(c_img, xplotsizepix, yplotsizepix)

; MIN AND MAX INTENSITIES TO DISPLAY...
; INTMIN IS BLACK, INTMAX IS MAX INTENSITY, INTGAMMA IS THE GAMMA.
; THE DISPLAYED INTENSITY IS...
; DISPLAYED INTENSITY = ((INTIMG-INTMIN)/(INTMAX-INTMIN))^INTGAMMA
intmin = min(intimg, max=intmax, /NAN)

; SELECT GAMMA...
if not keyword_set(GAMMA) then gamma = 0.8

;!!!!!!!!!!!
; DO WE WANT TO HAVE FIX FOR CONVERTING FROM SCREEN TO PRINTER...
; GAMMA = GAMMA * PRINTGAMMA
; -> THIS WOULD BE HARD SINCE DIDDLE WOULD SCREW THINGS UP, NO?

; THESE PARAMETERS DEFINE THE MIN AND MAX VEL OF THE COLOR RANGE.
; COLORMIN CORRESPONDS TO ONE COLOR EXTREME
; COLORMAX CORRESPONDS TO THE OTHER COLOR EXTREME.
colormin = min(c_img[where(c_img ne 0)], max=colormax, /NAN) 

; TELL US ABOUT RANGE...
message, string(intmin, intmax,$
                format='("Intensity Range : [ ",F8.2,",",F8.2," ]")')+$
         string(gamma,format='(", Gamma : ",f10.5)'), /INFO
message, string(colormin, colormax,$
                format='("    Color Range : [ ",F8.2,",",F8.2," ]")'), /INFO

; DEFINE THE COLOR PART OF THE COLORBAR...
colorbar = (colormin + $
            double(colormax-colormin) * $
            dindgen(xplotsizepix)/(xplotsizepix-1)) $
           # (dblarr(ywedge)+1)

; SCALE THE COLOR PART OF THE COLORBAR FROM 0 TO 255.
colorbar = bytscl(reverse(colorbar,1), MIN=colormin, MAX=colormax)

; TAKE CARE OF PLOTTING DEVICE DEFINITIONS...
if keyword_set(PS) then begin

    ; DETERMINE THE CORRECT PLOT SIZE...
    aspectimg = float(wxsize) / float(wysize)
    if (aspectimg ge aspectpage) then begin
        xsize = xpage
        ysize = xpage / aspectimg
    endif else begin
        ysize = ypage
        xsize = ypage * aspectimg
    endelse

    ; SET UP THE OFFSETS...
    ; !!! SHOULDN'T MATTER IF ENCAPSULATED, NO???
    xoffset = (8.5-xsize)*0.5 * (keyword_set(EPS) eq 0)
    yoffset = (11.-ysize)*0.5 * (keyword_set(EPS) eq 0)

    ; SET UP THE POSTSCRIPT DEVICE...
    !p.font = 0
    set_plot, 'PS', /copy, /interpolate 
    device, file=fileout, $
            /PORTRAIT, BITS_PER_PIXEL=8, /COLOR, /INCHES, $
            YSIZE=ysize, XSIZE=xsize, $
            XOFFSET=xoffset, YOFFSET=yoffset, $
            /TIMES, /BOLD, /ISOLATIN1, _EXTRA = _extra

endif else window, 13, ysize=wysize, xsize=wxsize

if (Depth le 8) $
  then white = !d.table_size-1 $
  else white = !p.color*(keyword_set(PS) eq 0) + !p.background*keyword_set(PS)

;======================================================

;================= REALIZE THE COLORBAR ===============

; DEFINE THE TITLES FOR THE GRAPHS...
if !p.font eq 0 then begin
    sum   = '!M'+string(229B)+'!X'
    delta = '!M'+string(68B)+'!X'
endif else begin
    sum   = '!7R!X'
    delta = '!7D!X'
endelse

thick = 1.0 + 2.0 * keyword_set(PS)

; DEFINE THE INTENSITY PART OF THE COLORBAR...
intbar = (intmin + $
          double(intmax-intmin) * $
          dindgen(ywedge)/(ywedge-1)) $
         ## (dblarr(xplotsizepix)+1)

; THE FOLLOWING IS 'SCHEME2'
intbar = ((intbar-intmin)/(intmax-intmin))^gamma
redbar = intbar*colr[colorbar,0]
grnbar = intbar*colr[colorbar,1]
blubar = intbar*colr[colorbar,2]
redbar = bytscl(redbar, MIN=min(redbar), MAX=max(redbar))
grnbar = bytscl(grnbar, MIN=min(grnbar), MAX=max(grnbar))
blubar = bytscl(blubar, MIN=min(blubar), MAX=max(blubar))

; DISPLAY THE COLORBAR...
if (Depth gt 8) then begin

    tv, [[[redbar]], [[grnbar]], [[blubar]]], $
      xtvleft, ybarbottom, ysize=ybarsize, xsize=xplotsize, $
      /normal, true=3

endif else begin

    ; QUANTIZES TRUECOLOR IMAGE FOR DISPLAY ON PSEUDO DEVICE... 
    pseudoimg = color_quan([[[redbar]], [[grnbar]], [[blubar]]], $
                           3, r, g, b, GET_TRANSLATION=true2pseudo, $
                           /MAP_ALL, COLORS=255)

    ; STRETCH THE COLOR TABLE SO THAT THE TOP INDEX CAN BE THE COLOR WHITE!
    low = 0
    nc = !d.table_size
    high = nc-2
    slope = float(nc-1)/(high-low) ;Scale to range of 0 : nc-1
    intercept = -slope*low
    p = long(findgen(nc)*slope+intercept) ;subscripts to select
    tvlct, r[p], g[p], b[p]
    tvlct, 255, 255, 255, !d.table_size-1

    tv, pseudoimg, xtvleft, ybarbottom, $
      ysize=ybarsize, xsize=xplotsize, /normal

endelse

; CREATE THE COLORBAR PLOT AREA.
plot, [colormin, intmin], /noerase, /nodata, $
      xstyle=5, ystyle=5, $
      yrange=[intmin,intmax], xrange=[colormin, colormax],  $
      position=[xtvleft, ybarbottom, xtvright, ybartop], /normal

; DISPLAY THE X AXIS ON THE TOP OF THE BAR.
axis, xaxis=1, xstyle=1, xrange=[colormin, colormax], $
      xticks=4, xminor=2, xticklen=1, xthick=thick, $
      charsize=charsize, charthick=charthick

; XYOUTS THE X-AXIS TITLE... TOO STUFFY WHEN AXIS PLACES IT!
titlepos = 2*float(!d.y_ch_size)/!d.y_size
xyouts, xtvleft+0.5*xplotsize-0.05, ybartop+titlepos, c_title, $
        /normal, charsize=charsize, charthick=charthick

; PLOT THE Y AXIS ON THE LEFT OF THE BAR.
axis, yaxis=0, ystyle=1, yrange=[intmin, intmax], $
      yticks=2, yminor=2, yticklen=1, ythick=thick, $
      ytitle=i_title, charsize=charsize, charthick=charthick

; OVERPLOT THE BOUNDARY TO SHARPEN CORNERS...
corners = [0,0,0,1,1,1,1,0,0,0,0,1]
for i = 0, 4 do $
  plots, [!x.window[corners[2*i]], !x.window[corners[2*(i+1)]]], $
         [!y.window[corners[2*i+1]], !y.window[corners[2*(i+1)+1]]], $
         /NORMAL, THICK=thick

;======================================================

;================== REALIZE THE IMAGE =================

; SCALE THE COLOR PART OF THE IMAGE FROM 0 TO 255.
colordenom = float(colormax-colormin)
colorimg1 = (0. > ( float( colormax-colorimg)/colordenom)) < 1.0
colorimg = byte( (0. > (255.*colorimg1)) < 255.5)

;shiftcol = (colormax-colorimg)
;colorimg = bytscl(shiftcol, MIN=0, MAX=max(shiftcol))

; THE FOLLOWING IS 'SCHEME2'
intimg = ((intimg-intmin)/(intmax-intmin))^gamma
redimg = byte( (0 > (intimg*colr[colorimg, 0])) < 255)
grnimg = byte( (0 > (intimg*colr[colorimg, 1])) < 255)
bluimg = byte( (0 > (intimg*colr[colorimg, 2])) < 255)

;stop

; DISPLAY THE IMAGE INTERLEAVED DATA CUBE...
if (Depth gt 8) then begin

    tv, [[[redimg]], [[grnimg]], [[bluimg]]], $
      xtvleft, ytvbottom, ysize=yplotsize, xsize=xplotsize, $
      /normal, true=3

endif else begin

    ; IF THE DISPLAY IS NOT 24-BIT...
    pseudoimg = color_quan([[[redimg]], [[grnimg]], [[bluimg]]], $
                           3, r, g, b, TRANSLATION=true2pseudo, $
                           /DITHER, COLORS=255)

    tv, pseudoimg, xtvleft, ytvbottom, $
      ysize=yplotsize, xsize=xplotsize, /normal

endelse

; X(Y)STYLE=5 SUPPRESSES THE AXIS AND FORCES THE EXACT RANGE.
if keyword_set( style) eq 0 then style= 5
if keyword_set( xaxlbl) eq 0 then xaxlbl= ''
if keyword_set( yaxlbl) eq 0 then yaxlbl= ''

plot, xaxis, yaxis, xstyle=style, ystyle=style, $
	xtit= xaxlbl, ytit= yaxlbl, $
      xrange=[max(xaxis),min(xaxis)], $
      yrange=[min(yaxis),max(yaxis)], $
      position=[xtvleft, ytvbottom, xtvright, ytvtop], /normal, $
      /noerase, /nodata

; OVERPLOT THE BOUNDARY TO SHARPEN CORNERS...
corners = [0,0,0,1,1,1,1,0,0,0,0,1]
for i = 0, 4 do $
  plots, [!x.window[corners[2*i]], !x.window[corners[2*(i+1)]]], $
         [!y.window[corners[2*i+1]], !y.window[corners[2*(i+1)+1]]], $
         /NORMAL, THICK=thick

if keyword_set(PS) then begin
;	psclose
	!p.font = -1
endif

end; display2par

;=======================================================================

; psopen, colorimg.ps
; display2par, vimage, timage, $
; 'v!DLSR!N [km s!E-1!N]', 'H!7a!X Intensity [Rayleigh]'
; ra_dec_axes, position=position
; !p.font=-1
; psclose

;datatitle1= sum+'!E !N!XT'+delta+'v [K km s!E-1!N]'
;datatitle2='v!DLSR!N [km s!E-1!N]'



