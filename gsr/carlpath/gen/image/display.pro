;============================================================

function display_getpos, aspect, XSIZE=xsize, YSIZE=ysize, NORESIZE=noresize

compile_opt idl2, hidden

; GET THE CURRENT DEVICE COORDINATES OF THE AXES...
dev_xrange = round(!x.window*!d.x_vsize)
dev_yrange = round(!y.window*!d.y_vsize)

; THE IMAGE WILL BE DISPLAYED WITHIN THESE AXES...
; (MOST DISPLAY ROUTINES PLACE THE AXES *ON TOP* OF THE DISPLAYED IMAGE.
;  I DISAPPROVE OF THIS BEHAVIOR.)
dev_xsize_now = (dev_xrange[1]-1) - (dev_xrange[0]+1) + 1
dev_ysize_now = (dev_yrange[1]-1) - (dev_yrange[0]+1) + 1

; IF THE USER WANTS THE IMAGE RESIZED, THEN SET THE WIDTH AND HEIGHT
; OF THE IMAGE TO THE SPACE BETWEEN THE CURRENTLY ESTABLISHED AXES...
if not keyword_set(NORESIZE) then begin
    xsize = dev_xsize_now
    ysize = dev_ysize_now
endif

; DETERMINE THE NEW IMAGE SIZE BASED ON THE ASPECT RATIO...
aspect_now = double(xsize)/ysize

; IF THE ASPECT HAS BEEN SET TO ZERO, THEN WE FILL THE SPACE
; BETWEEN THE CURRENTLY ESTABLISHED AXES...
if (aspect ne 0) AND (aspect ne aspect_now) then begin

    ; IF THE NEW ASPECT RATIO IS GREATER THAN THE CURRENT ASPECT
    ; RATIO, THEN THE XSIZE IS ANCHORED TO THE CURRENT XSIZE AND THE
    ; YSIZE IS ADJUSTED TO MATCH THE NEW ASPECT RATIO AS NEARLY AS
    ; POSSIBLE...
    if (aspect gt aspect_now) $
      then ysize = round(xsize / aspect) $
      else xsize = round(ysize * aspect)

endif

if keyword_set(VERBOSE) then help, n='*xsize*'
if keyword_set(VERBOSE) then help, n='*ysize*'

; IF EITHER THE NEW HEIGHT OR WIDTH IS LESS THAN 2 PIXELS,
; THEN THE ASPECT RATIO IS RIDICULOUS...
if (xsize lt 2) then $
  message, 'The ASPECT RATIO (width/height) is ridiculously small.'
if (ysize lt 2) then $
  message, 'The ASPECT RATIO (width/height) is ridiculously large.'

;!!!!!!!!!!
; IS THE ASPECT RATIO NOW CORRECT HERE???
if keyword_set(VERBOSE) then help, aspect, double(xsize)/ysize

; CENTER THE IMAGE IN THE WINDOW...
dev_xrange[0] = dev_xrange[0] + 0.5*(dev_xsize_now-xsize)
dev_yrange[0] = dev_yrange[0] + 0.5*(dev_ysize_now-ysize)

return, [dev_xrange[0],$        ; POSITION OF LEFT AXIS
         dev_yrange[0],$        ; POSITION OF BOTTOM AXIS
         dev_xrange[0] + xsize + 1,$ ; POSITION OF RIGHT AXIS
         dev_yrange[0] + ysize + 1]  ; POSITION OF TOP AXIS

end; display_getpos

;============================================================

function display_imgresize, image, nx, ny, xsize, ysize

compile_opt idl2, hidden

;interpolate=1

xfactor = double(nx)/xsize
yfactor = double(ny)/ysize

;stop

if not keyword_set(INTERPOLATE) then begin

    p = [[0.5*(xfactor-1)*(xfactor gt 1),0],[xfactor,0]]
    q = [[0.5*(yfactor-1)*(yfactor gt 1),yfactor],[0,0]]

    return, poly_2d(image,p,q,0,xsize,ysize)

endif

;!!!!!!!!!!!!
; ARE WE SURE THERE'S NOT A XSIZE-1 MISSING ANYWHERE???

xi = xfactor * (dindgen(xsize) + 0.5) - 0.5
yi = yfactor * (dindgen(ysize) + 0.5) - 0.5

;stop
return, interpolate(image, xi, yi, /GRID)

end; display_imgresize

;============================================================

function display_imgscl, image, MIN=mn, MAX=mx, $
                         BOTTOM=btm, TOP=top, NEGATIVE=negative

compile_opt idl2, hidden

if (N_elements(mn) eq 0) then mn = min(image,/NAN)
if (N_elements(mx) eq 0) then mx = max(image,/NAN)
if (N_elements(btm) eq 0) then btm = 0L
if (N_elements(top) eq 0) then top = !d.table_size-1L

byte_image = bytscl(image,MIN=mn,MAX=mx,TOP=byte(top-btm),/NAN)

if not keyword_set(NEGATIVE) then return, byte_image + byte(btm)

return, byte(top - byte_image + btm)

end; display_imgscl

;============================================================

pro display, image_in, $
             x, y, $
             MIN=minval, MAX=maxval, $
             ASPECT=aspect, $
             SILENT=silent, $
             NODISPLAY=nodisplay, $
             NOIMAGE=noimage, $
             NORESIZE=noresize, $
             NOSCALE=noscale, $
             BOTTOM=bottom, $
             TOP=top, $
             NEGATIVE=negative, $
             OUT=out, $
             ; PLOT KEYWORDS THAT WE NEED TO MANIPULATE...
             COLOR=color, $
             POSITION=position, $
             DEVICE=device, $
             NORMAL=normal, $
             XSTYLE=xstyle, $
             YSTYLE=ystyle, $
             TITLE=title, $
             SUBTITLE=subtitle, $
             TICKLEN=ticklen, $
             XTICKLEN=xticklen, $
             YTICKLEN=yticklen, $
             ; TV KEYWORDS THAT WE NEED TO MANIPULATE...
             TRUE=true, $
             CHANNEL=channel, $
             ORDER=order, $
             XSIZE=xsize, $
             YSIZE=ysize, $
             ; COLOR_QUAN KEYWORDS THAT WE NEED TO MANIPULATE...
             TRANSLATION=translation, $
             VERBOSE=verbose, $ ; print out some shit for testing...
             ; PLOT, TV, COLOR_QUAN() KEYWORDS PASSED BY REFERENCE...
             _REF_EXTRA = extra

; CLEARLY ASSUMES THAT X AND Y ARE MONOTONICALLY AND LINEARLY
; INCREASING OR DECREASING.  

; WE USE ALL OF THE FOLLOWING EXPLICITLY IN CALLS TO PLOT/TV...
; SO THEY CAN BE OVERRULED BY _REF_EXTRA UNLESS WE DO SOMETHING ABOUT IT!
;
; PLOT
; ======
; XSTYLE 
; YSTYLE
; XRANGE
; YRANGE

; TV
; ====
; XSIZE
; YSIZE

; /NEGATIVE HAS NO EFFECT IS /NOSCALE IS SET.

; DEFAULT UNITS FOR POSITION ARE NORMAL.
; /DATA WILL BE COMPLETELY IGNORED... IT CAN'T BE USED TO SPECIFY
; POSITION ANYWAY, SO NO LOSS.  THE CLIP KEYWORD IS ABSOLUTELY USELESS
; FOR OUR PURPOSES AND IF IT WERE PASSED IN BY REFERENCE, IT WILL BE 
; THOROUGHLY IGNORED...


; PLOT KEYWORDS...
;===========================
; EXPLICITLY SET IN HEADER...
;[, POSITION=[X0, Y0, X1, Y1]]  
;[, COLOR=value] 
;[, /DATA | , /DEVICE | , /NORMAL] 
;[, {X | Y | Z}STYLE=value] 
;
; TEST THESE:
;[, /POLAR] 
;[, /XLOG] ; WHAT DO WE DO HERE?
;[, /YLOG] ; WHAT DO WE DO HERE?
;[, /T3D] 
;[, {X | Y | Z}RANGE=[min, max]] 
;[, ZVALUE=value{0 to 1}]

;!!!!!!!!!!!!!!!!!!!!
; MIN, MAX keywords for imgscl...

; USEFUL:
;[, BACKGROUND=color_index]
;[, CHARSIZE=value] 
;[, CHARTHICK=integer] 
;[, FONT=integer] 
;[, /NOERASE] 
;[, SUBTITLE=string] 
;[, TICKLEN=value] 
;[, TITLE=string] 
;[, {X | Y | Z}CHARSIZE=value] 
;[, {X | Y | Z}GRIDSTYLE=integer{0 to 5}] 
;[, {X | Y | Z}MARGIN=[left, right]] 
;[, {X | Y | Z}MINOR=integer] 
;[, {X | Y | Z}THICK=value] 
;[, {X | Y | Z}TICK_GET=variable] 
;[, {X | Y | Z}TICKFORMAT=string] 
;[, {X | Y | Z}TICKINTERVAL= value] 
;[, {X | Y | Z}TICKLAYOUT=scalar] 
;[, {X | Y | Z}TICKLEN=value] 
;[, {X | Y | Z}TICKNAME=string_array] 
;[, {X | Y | Z}TICKS=integer] 
;[, {X | Y | Z}TICKUNITS=string] 
;[, {X | Y | Z}TICKV=array] 
;[, {X | Y | Z}TITLE=string] 
;
; USELESS:
; [, MAX_VALUE=value] [, MIN_VALUE=value] [, NSUM=value] 
; [, /YNOZERO] [, /NODATA] 
; [, CLIP=[X0, Y0, X1, Y1]] [, /NOCLIP] [, LINESTYLE={0 | 1 | 2 | 3 | 4 | 5}] 
; [, PSYM=integer{0 to 10}] [, SYMSIZE=value] [, THICK=value] 


;
; TV KEYWORDS...
;===========================
; DENY USER ACCESS:
;[, XSIZE=value] 
;[, YSIZE=value] 

; EXPLICITLY SET:
;[, CHANNEL=value] 
;[, /ORDER] 
;[, TRUE={1 | 2 | 3}] 
;[, /DATA | , /DEVICE | , /NORMAL] 
;
; TEST:
;[, /WORDS] 
;[, /T3D | Z=value]
;
; USELESS:
;[, /CENTIMETERS | , /INCHES] 

; COLOR_QUAN KEYWORDS...
;===========================
; DENY USER ACCESS:
;[, COLORS=integer{2 to 256}]
;
; USEFUL:
;[, /DITHER] 
;[, ERROR=variable] 
;[, TRANSLATION=vector]
;
; TEST:
;[, CUBE={2 | 3 | 4 | 5 | 6} | , GET_TRANSLATION=variable [, /MAP_ALL]] 

; OPTIONAL OUTPUT KEYWORDS:
; XSIZE = 
; YSIZE = 
; POSITION =

; RESIZING OPTIONS...
;=========================
; RESIZING KEYWORDS: ASPECT, POSITION, NORESIZE
; (1) NO KEYWORDS: DEFAULT IS TO DETERMINE AXIS POSITIONS FROM THE
; DEFAULT FOR THE CURRENT REGION IN THE PLOT WINDOW.  THE ASPECT RATIO
; IS DETERMINED FROM THE INPUT X AND Y VECTORS AND THE AXIS POSITIONS
; ARE ADJUSTED TO CONSERVE THE ASPECT RATIO.  THE IMAGE IS REGRIDDED
; TO FIT WITHIN THE AXES.
; (2) THE ASPECT KEYWORD IS PASSED AND IS NON-ZERO: THE AXES ARE
; DETERMINED AND THE IMAGE IS REGRIDDED AS IN (1), BUT THE ASPECT IS
; ENFORCED TO BE WHAT THE USER REQUESTS VIA THIS KEYWORD.
; (3) THE POSITION KEYWORD IS PASSED: IDENTICAL TO (1) EXECPT THAT THE
; POSITION OF THE AXES ARE INITIALLY ESTABLISHED USING THE VALUES
; PASSED IN VIA THE POSITION KEYWORD.
; (4) POSITION AND ASPECT (NON-ZERO) ARE SENT: ESTABLISHED INITIAL
; AXES POSITIONS VIA THE POSITION KEYWORD, THEN ADJUSTS ONE OF THE
; AXIS SIZES BASED ON THE ASPECT RATIO.
; (5) ASPECT IS PASSED SET TO ZERO: AXIS POSITIONS ARE DETERMINED BY
; DEFAULT IN THE CURRENT REGION OF THE DISPLAY AND THE IMAGE IS
; RESIZED TO FIT WITHIN THESE AXES.
; (6) ASPECT IS PASSED SET TO ZERO AND POSITION KEYWORD SET:  POSITION
; OF AXES IS DETERMINED BY THE POSITION KEYWORD AND THE IMAGE IS
; RESIZED TO FIT WITHIN THESE AXES.
; (7) NORESIZE KEYWORD IS SET: DISPLAYS IMAGE WITHOUT ANY EXPANSION OR
; COMPRESSION; AXES ARE ADJUSTED TO BOUND THE IMAGE.  ASPECT KEYWORD
; IS COMPLETELY IGNORED IS NORESIZE IS SET.  IF POSITION KEYWORD IS
; SENT, ONLY THE LOWER LEFT CORNER IS HONORED.  IMAGE WON'T BE
; DISPLAYED IF IT CAN'T FIT IN THE CURRENT DISPLAY.


; Gleaned a lot of useful ideas over the years from the code of the
; following folks: Fen Tamanaha (DISPLAY.PRO), Liam Gumley
; (IMDISP.PRO), and David Fanning (TVIMAGE.PRO).


;On_Error, 2


; /NORESIZE COULD WORK WITH SCALABLE PIXELS; BUT THE IMAGE WOULD BE
; USELESSLY SMALL.  YOU'RE BETTER OFF DETERMINING THE ASPECT RATIO OF
; THE IMAGE XSIZE/YSIZE AND FORCING IT VIA THE ASPECT KEYWORD...

; IF DISPLAYING A TRUECOLOR IMAGE IN POSTSCRIPT, BE SURE TO LOADCT, 0
; (UNLESS YOU NEED A DIFFERENT COLOR PALETTE) BEFORE USING DISPLAY AND
; BE SURE TO USE DISPLAY PRIOR TO MESSING WITH THE COLOR TABLE, SAY TO
; LOAD LINE PLOT COLORS INTO THE COLOR TABLE...  THE SAME PROCESS FOR
; DISPLAYING A TRUECOLOR IMAGE IN THE TRUECOLOR VISUAL CLASS.
; HOWEVER, IF YOU'RE RUNNING THE DIRECTCOLOR VISUAL CLASS, THEN THE
; DYNAMIC COLOR TABLE WILL CAUSE PROBLEMS IF TRYING TO USE THIS
; ROUTINE WITH COLOR DECOMPOSITION TURNED OFF (TO TRY TO MIMIC RESULTS
; OBTAINED USING THE PSEUDOCOLOR VISUAL CLASS.)  IF YOU'RE RUNNING
; DIRECTCOLOR, YOU SHOULD BY ALL MEANS TAKE ADVANTAGE OF COLOR
; DECOMPOSITION, BUT IF FOR SOME REASON YOU INSIST THAT THIS ROUTINE
; WORK WITH COLOR DECOMPOSITION TURNED OFF, THEN YOU'LL NEED TO HACK
; THE CODE SO THAT COLOR_QUAN IS RUN IN THIS CASE


;!!!!!!!!!!!!!!!!
; WHAT IF TOP <= BOTTOM???


;!!!!!!!!!!!!!!!
; ALSO WANT TO REMOVE X/YRANGE KEYWORDS AS WELL, RIGHT!?
; BUT USER MAY WANT THE XRANGE AND YRANGE VALUES PASSED BACK!!!
; HOWZABOUT X/YSTYLE???

;!!!!!!!!!!!
; WARNING IF NORESIZE AND POSITION KEYWORDS ARE SET...

;!!!!!!!!!!!
; WARNING IF POSITION AND (ASPECT NE 0) KEYWORDS ARE SET...

;!!!!!!!!!!!!!!!!!
; WILL EVERYTHING BE COOL IF SOMEONE SETS THE VARIOUS !P,!X,!Y VARS?
; LIKE !P.TICKLEN, !X.TICKLEN...

;!!!!!!!!!!!!!!!!!
; ASPECT RATIO HAS BECOME RIDICULOUS ONCE CHARACTERS START OVERLAPPING!

; DETERMINE THE IDL RELEASE...
release = float(!version.release)

if (release lt 5.1) then $
  message, 'DISPLAY.PRO is not supported for IDL versions before 5.1.'

; GET THE DIMENSIONS OF THE INPUT IMAGE...
sz = size(image_in)
ndims = sz[0]
if (ndims eq 0) then $
  message, 'IMAGE is undefined.'

if (ndims lt 2) OR (ndims gt 3) then $
  message, 'IMAGE must have 2 (or 3, if TRUECOLOR) dimensions.'
dims = sz[1:ndims]

image = image_in

; ARE WE DEALING WITH A TRUECOLOR IMAGE...
truecolor = (ndims eq 3)
if truecolor then begin

    ; HAVE WE PASSED THE TRUE KEYWORD...
    if (N_elements(TRUE) eq 0) then begin
        ; OVER WHICH DIMENSION IS THE IMAGE INTERLEAVED...
        dim3 = where(dims eq 3,ndim3)
        ; IS THIS REALLY A TRUECOLOR IMAGE...
        if (ndim3 eq 0) then message, 'This is not a truecolor image.'
        ; HAS USER PASSED AN AMBIGUOUSLY CONSTRUCTED IMAGE...
        if (ndim3 gt 1) then $
          message, 'Unclear how IMAGE is interleaved; use TRUE keyword.'
    endif else begin
        case 1 of
            ; DOES TRUE HAVE MORE THAN ONE ELEMENT...
            (N_elements(TRUE) gt 1) : $
              message, 'TRUE must be a scalar or 1 element array.'
            ; WAS CHANNEL PASSED IN AS AN ARRAY...
            (N_elements(CHANNEL) gt 1) : $
              message, 'CHANNEL must be a scalar or 1 element array.'
            ; IS TRUE IN THE ALLOWED RANGE...
            (true[0] lt 1) OR (true[0] gt 3) : $
              message, 'Value of TRUE keyword is out of allowed range.'
            else : begin
                dim3 = true-1
                ; IS IMAGE REALLY INTERLEAVED OVER THIS DIMENSION...
                if (dims[dim3] ne 3) then $
                  message, 'Color is not interleaved over dimension '$
                  +strtrim(true,2)
            end
        endcase
    endelse

    ; IF THE IMAGE IS NOT IMAGE-INTERLEAVED, THEN TRANSPOSE IT SO THAT
    ; IT IS...
    if (dim3[0] ne 2) then begin
        imdim = where([0,1,2] ne dim3[0])
        image = transpose(image,[imdim,dim3])
        dims  = sz[[imdim,dim3]+1]
    endif
endif

; MAKE SURE IMAGE, X, AND Y SIZES ARE COMPATIBLE...
nx = N_elements(x)
ny = N_elements(y)
if (nx eq 0) $
  then x = lindgen(dims[0]) $
  else if (nx ne dims[0]) $
         then message, 'IMAGE and X array dimensions are incompatible.'
if (ny eq 0) $
  then y = lindgen(dims[1]) $
  else if (ny ne dims[1]) $
         then message, 'IMAGE and Y array dimensions are incompatible.'

; GET THE NUMBER OF COLUMNS AND ROWS IN THE IMAGE...
nx = dims[0]
ny = dims[1]

; SET DEFAULTS FOR KEYWORDS...
if (N_elements(XSTYLE) eq 0) then xstyle = 1
if (N_elements(YSTYLE) eq 0) then ystyle = 1
if (N_elements(BOTTOM) eq 0) then bottom = 0B
if (N_elements(TOP) eq 0) then top = !d.table_size-1
if (N_elements(MINVAL) eq 0) then minval = min(image,/NAN)
if (N_elements(MAXVAL) eq 0) then maxval = max(image,/NAN)
if (N_elements(POSITION) gt 0) then begin
    ; ERROR CHECK POSITION KEYWORD...
    case 1 of
        (N_elements(position) ne 4) : $
          message, 'Keyword array parameter POSITION must have 4 elements.'
        (position[0] ge position[2]) : $
          message, 'Normalized POSITION[0] must be less than POSITION[2].'
        (position[1] ge position[3]) : $
          message, 'Normalized POSITION[1] must be less than POSITION[3].'
        (position[0] lt 0) OR (position[1] lt 0) : $
          message, 'Normalized POSITION[0:1] must be >= 0.'
        else: begin
            ; IF /DEVICE IS SET THEN TRANSFORM POSITION TO NORMAL
            ; COORDINATES, OTHERWISE MAKE SURE POSITION IS FLOATING...
            position = keyword_set(DEVICE) $
                       ? position/float(([!d.x_vsize,!d.y_vsize])[[0,1,0,1]]) $
                       : float(position)
            if (position[2] gt 1.0) OR (position[3] gt 1.0) then $
              message, 'Normalized POSITION[2:3] must be less than 1.'
        end
    endcase

    ; BECAUSE IDL IS RETARDED, IT ALLOWS YOU TO PLACE THE LAST COLUMN
    ; OR ROW ONE PIXEL OFF OF THE DISPLAY, AT A NORMALIZED POSITION OF
    ; 1.0.  SINCE IT CALCULATES THE NORMALIZED COORDINATES AS
    ; PIXEL/!D.X_VSIZE, THEN THE LAST PIXEL IS LOCATED AT
    ; (!D.X_VSIZE-1)/!D.X_VSIZE, WHICH IS ALWAYS < 1.0. WE DON'T WANT
    ; AN AXIS OFF THE DISPLAY...
    position[2] = position[2] < float(!d.x_vsize-1)/!d.x_vsize
    position[3] = position[3] < float(!d.y_vsize-1)/!d.y_vsize
endif

;!!!!!!!!!!!!!!!!
; WHAT IF NO X/Y SENT IN, BUT XRANGE AND YRANGE ARE SENT IN???
;delx = abs(xrange[1] - xrange[0])
;dely = abs(yrange[1] - yrange[0])

; WHAT ARE SEPARATIONS IN X AND Y UNITS BETWEEN PIXELS...
delx = abs(x[1] - x[0])
dely = abs(y[1] - y[0])

; COMPUTE THE ASPECT RATIO...
case 1 of
    ; IF /NORESIZE IS SET, FORCE ASPECT TO ZERO...
    keyword_set(NORESIZE) : aspect = 0d0
    ; DOES ASPECT HAVE MORE THAN ONE ELEMENT...
    (N_elements(ASPECT) gt 1) : $
      message, 'ASPECT keyword must be a scalar or 1 element array.'
    ; HAS THE USER PASSED A NEGATIVE ASPECT RATIO...
    (N_elements(ASPECT) eq 1) : $
      if (aspect lt 0) then message, 'ASPECT keyword must be non-negative.'

;!!!!!!!!!!!!!!
; WHAT IF IMAGE IS BEING SHRUNK????

    ; THE ASPECT RATIO IS *DEFINED* AS WIDTH/HEIGHT...
    else: aspect = (double(max(x))-double(min(x))+delx) $
      / (double(max(y))-double(min(y))+dely)
endcase

; DOES THE DEVICE SUPPORT WINDOWS...
windows  = (!d.flags AND 256) ne 0
; DOES THE DEVICE HAVE SCALABLE PIXELS...
scalable = (!d.flags AND 1) ne 0

; A WINDOW NEEDS TO HAVE BEEN CREATED TO ESTABLISH THE VISUAL TYPE...
if windows AND (!d.window lt 0) then begin
  window, /FREE, /PIXMAP
  wdelete, !d.window
endif

; USE A DUMMY PLOT TO ESTABLISH THE POSITION OF THE PLOT DATA WINDOW,
; I.E., THE PLOT END POINTS... DON'T WORRY, PASSING NODATA=0 BY
; REFERENCE DOES NOT OVERRIDE OUR SETTING /NODATA BELOW...
if not keyword_set(POSITION) $
  then plot, [0], /NODATA, XSTYLE=4, YSTYLE=4, _EXTRA=extra $
  else plot, [0], /NODATA, XSTYLE=4, YSTYLE=4, POSITION=position, _EXTRA=extra

; DO WE NOT WANT TO RESIZE...
if (not scalable) AND keyword_set(NORESIZE) then begin

    ; CALCULATE THE MINIMUM NUMBER OF PIXELS THE DISPLAY MUST CONTAIN
    ; IN ORDER TO DISPLAY THIS IMAGE...
    xwin = nx + round(!d.x_vsize*!x.window[0]) $
           + round(!d.x_vsize*(1-!x.window[1])-1)
    ywin = ny + round(!d.y_vsize*!y.window[0]) $
           + round(!d.y_vsize*(1-!y.window[1])-1)

    ; IF DISPLAY IS TOO SMALL, TELL USER HOW BIG THE DISPLAY MUST BE...
    if (xwin gt !d.x_vsize) OR (ywin gt !d.y_vsize) then $
      message, string('IMAGE will not fit in window. Either allow IMAGE'$
                      +' to be compressed (omit /NORESIZE keyword) or'$
                      +' create a window with the following dimensions:',$
                      'XSIZE = '+strtrim(xwin,2),$
                      'YSIZE = '+strtrim(ywin,2),$
                      FORMAT='(2(A,%"\N"),A)')

    ; SET THE XSIZE AND YSIZE TO THE NUMBER OF PIXELS IN THE IMAGE...
    ysize = ny
    xsize = nx
endif 

; GET THE POSITION OF THE COORDINATE AXES IN DEVICE COORDINATES...
; RETURN THE WIDTH AND HEIGHT OF THE IMAGE AS KEYWORDS...
dev_pos = display_getpos(aspect,XSIZE=xsize,YSIZE=ysize,NORESIZE=keyword_set(NORESIZE))

; DETERMINE WHAT THE VALUES OF X AND Y SHOULD BE AT THE AXIS ENDPOINTS...
xfactor = double(nx) / xsize
yfactor = double(ny) / ysize
x_per_pixel = delx * xfactor ; = 1./(!x.s[1]*!d.x_vsize)
y_per_pixel = dely * yfactor ; = 1./(!y.s[1]*!d.y_vsize)
xrange = interpol(x,dindgen(nx),xfactor*([0,xsize-1]+0.5)-0.5) $
         + x_per_pixel*[-1,1]
yrange = interpol(y,dindgen(ny),yfactor*([0,ysize-1]+0.5)-0.5) $
         + y_per_pixel*[-1,1]

if keyword_set(verbose) then help, x_per_pixel, y_per_pixel

;!!!!!!!!
; PROBABLY AN EASY WAY TO JUST GET ENDPOINT VALUES HERE...
; USING VALUE_LOCATE AND INTERPOL() CODE...
; DETERMINE THE ENDPOINTS OF THE AXES...
;xi = double(nx)/xsize*(dindgen(xsize) + 0.5) - 0.5
;yi = double(ny)/ysize*(dindgen(ysize) + 0.5) - 0.5
;xnew = interpol(x,dindgen(nx),xi)
;ynew = interpol(y,dindgen(ny),yi)
;xrange = (xnew)[[0,xsize-1]]; + x_per_pixel*[-1,1]
;yrange = (ynew)[[0,ysize-1]]; + y_per_pixel*[-1,1]
;xfoo = image[*,0]
;stop

; IF /NODISPLAY IS SET THEN WE DON'T WANT TO TV THE IMAGE OR DRAW THE
; AXES, WE SIMPLY WANT TO ESTABLISH THE CORRECT AXIS POSITIONS...
if keyword_set(NOIMAGE) OR keyword_set(NODISPLAY) then begin
;;;!!!!!!!!!!
    ; be more clever about this?
    if arg_present(OUT) then image_unscaled = image
    goto, plotaxes
endif
;stop

; RESIZE THE IMAGE...
if (not scalable) AND (not keyword_set(NORESIZE)) $
;   AND (not ((nx eq xsize) AND (ny eq ysize))) $
    then begin
    if not keyword_set(SILENT) then message, "Resizing image...", /INFO
    image = (not truecolor) $
            ? display_imgresize(image, nx, ny, xsize, ysize) $
            : [[[display_imgresize(image[*,*,0],nx,ny,xsize,ysize)]], $
               [[display_imgresize(image[*,*,1],nx,ny,xsize,ysize)]], $
               [[display_imgresize(image[*,*,2],nx,ny,xsize,ysize)]]]
endif

; SAVE A COPY OF THE RESIZED BUT UNSCALED IMAGE FOR PASSING OUT...
if arg_present(OUT) then image_unscaled = image

; DO WE WANT TO BYTE SCALE THE IMAGE...
if not keyword_set(NOSCALE) then begin
    if not keyword_set(SILENT) then message, "Scaling image...", /INFO

    neg = keyword_set(NEGATIVE)
    image = (not truecolor) $
            ? display_imgscl(image,MIN=minval,MAX=maxval,$
                               BOTTOM=bottom,TOP=top,NEG=neg) $
            ; FOR A TRUECOLOR IMAGE, WE WANT TO SCALE EACH COLOR PLANE
            ; FROM 0B TO 255B...
            : [[[display_imgscl(image[*,*,0],BOTTOM=0B,TOP=255B,NEG=neg)]],$
               [[display_imgscl(image[*,*,1],BOTTOM=0B,TOP=255B,NEG=neg)]],$
               [[display_imgscl(image[*,*,2],BOTTOM=0B,TOP=255B,NEG=neg)]]]

endif

if windows then begin

    ; WHAT IS THE DEPTH OF THE VISUAL CLASS...
    device, GET_VISUAL_DEPTH=depth;, GET_VISUAL_NAME=visual

    ; IF WE HAVE A TRUECOLOR IMAGE AND WE'RE ON A 24-BIT DISPLAY,
    ; THEN MAKE SURE DECOMPOSED COLOR IS TURNED ON...
    if (depth gt 8) AND truecolor then begin
          if (release ge 5.2) $
            then device, GET_DECOMPOSED=decomposed_in $
            else decomposed_in=0
        device, DECOMPOSED=1
    endif

endif else depth = 8



; ARE WE TRYING TO DISPLAY A TRUECOLOR IMAGE ON A PSEUDOCOLOR DISPLAY...
if truecolor AND (depth le 8) AND (!d.name ne 'PS') then begin

    ; IF CHANNEL KEYWORD IS SET, THEN BLANK OUT THE OTHER
    ; CHANNELS...
    if (N_elements(CHANNEL) gt 0) then begin
        if (channel lt 0) OR (channel gt 3) $
          then message, 'Value of CHANNEL is out of allowed range.'
        if (channel ne 0) then begin
            blank = where([1,2,3] ne channel)
            image[*,*,blank] = 0B
        endif
    endif

    ; FIND (TOP-BOTTOM+1) COLORS THAT ACCURATELY REPRESENT THE ORIGINAL 
    ; COLOR DISTRIBUTION...
    if not keyword_set(SILENT) then $
      message, 'Color quantizing TrueColor image...', /INFO
    image = color_quan(image, 3, r, g, b, COLORS=(top-bottom+1), $
                       TRANSLATION=translation, _EXTRA=extra) $
            + byte(bottom)

    ; LOAD THE COLOR PALETTE...
    if (N_elements(TRANSLATION) eq 0) then tvlct, r, g, b, bottom
    truecolor = 0B

endif

; PUT THE IMAGE ON THE TV...
tv, image, dev_pos[0]+1, dev_pos[1]+1, /DEVICE, $
    XSIZE=xsize, YSIZE=ysize, $
    ORDER=keyword_set(ORDER), $
    TRUE=truecolor*3, CHANNEL=channel, $
    _EXTRA=extra

; IF WE HAVE A 24-BIT VISUAL CLASS, RETURN THE COLOR DECOMPOSITION
; BACK TO ITS ORIGINAL STATE...
if windows AND (depth gt 8) then device, DECOMPOSED=decomposed_in

;!!!!!!!
; IF THE USER HAS SUPPLIED BOTH THE XTICKLEN AND YTICKLEN KEYWORDS
; THEN WE ASSUME THE USER WANTS TO EXPLICITLY SET THE LENGTHS...
xticklset = N_elements(XTICKLEN) gt 0
yticklset = N_elements(YTICKLEN) gt 0
if not (xticklset AND yticklset) then begin

;; IF THE X/YTICKLEN KEYWORD IS SET, IF NONZERO, OVERRIDES THE GLOBAL TICK LENGTH
;; SPECIFIED IN !P.TICKLEN, AND/OR THE TICKLEN KEYWORD PARAMETER,
;; WHICH IS EXPRESSED IN TERMS OF THE WINDOW SIZE.

    tick_aspect = double(dev_pos[2]-dev_pos[0]) / (dev_pos[3]-dev_pos[1])

    case 1 of
        xticklset : yticklen = xticklen / tick_aspect
        yticklset : xticklen = yticklen * tick_aspect
        else : begin
            xticklen = (N_elements(TICKLEN) eq 0) ? 0.02 : ticklen
            yticklen = (N_elements(TICKLEN) eq 0) ? 0.02 : ticklen
            if (tick_aspect gt 1.0) $
              then xticklen = yticklen * tick_aspect $
              else yticklen = xticklen / tick_aspect
        end
    endcase

endif

; PLOT THE AXES...
; EVEN IF PASSED IN BY REFERENCE, /NOERASE AND /NODATA TAKE PRECEDENCE
; BELOW...
plotaxes:
if keyword_set(ORDER) then yrange = yrange[[1,0]]
plot, [0], /NOERASE, /NODATA, $
      XSTYLE=(xstyle OR 1 OR 4*keyword_set(NODISPLAY)), $
      YSTYLE=(ystyle OR 1 OR 4*keyword_set(NODISPLAY)), $
      XRANGE=xrange, YRANGE=yrange, $
      TICKLEN=ticklen, XTICKLEN=xticklen, YTICKLEN=yticklen, $
      TITLE=title, SUBTITLE=subtitle, $
      /DEVICE, POSITION=dev_pos, $
      COLOR=color, $
      _EXTRA=extra

;!!!!!!!!!!!!
; THIS CHOKES HARD IF NODISPLAY/NOIMAGE ARE SET!!!!

; PASS OUT A STRUCTURE FULL OF RESULTS THAT MIGHT BE USED LATER...
if arg_present(OUT) $
  then out = {image:image, $    ; RESIZED AND SCALED IMAGE THAT IS DISPLAYED
              ; IF /NOSCALE IS SET, THEN image AND image_unscaled
              ; WILL BE IDENTICAL...
              image_unscaled:image_unscaled, $ ; UNSCALED IMAGE
              xsize:xsize, $    ; THE WIDTH (IN DEVICE UNITS) OF IMAGE
              ysize:ysize, $    ; THE HEIGHT (IN DEVICE UNITS) OF IMAGE
              aspect:double(xsize/ysize), $ ; ASPECT RATIO OF IMAGE
              xrange:xrange, $  ; XRANGE OF AXIS
              yrange:yrange, $  ; YRANGE OF AXIS
              ; THE NORMALIZED POSITION OF THE AXES...
              position:double(dev_pos)/([!d.x_vsize,!d.y_vsize])[[0,1,0,1]]}

end; display


