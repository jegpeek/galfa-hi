;------------------------------------------------------------------------------
;ldcolph - load color table for line drawing
; 0 - blk
; 1 - white
; 2 - red
; 3 - green
; 4 - blue
; 5 - rg
; 6 - rb
;
pro ldcolph,pscol=pscol,maxlen=maxlen
	common colph,decomposedph,colph
;
;  decomposedph: 0 --> pseudo color loaded
;              1 --> true color loaded.
;
	maxind=255
    if keyword_set(maxlen) then maxind=maxlen-1
    lmaxlen=maxind+1
    black=[0,0,0]
    r   =[1.,0,0]
    g   =[0,1.,0]
    b   =[0,0,1.]
    w   = (r+g+b)
    rg  =((r+g))
    rb  =((r+b))
    gb  =((g+b))
    coltbl=fltarr(lmaxlen,3)
    loccol=fltarr(11,3)
    if keyword_set(pscol) then begin
        col0   =black
        forgrnd=black
    endif else begin 
        col0 =black
        forgrnd=w
    endelse
    loccol[0,*]=col0
    loccol[1,*]=forgrnd

    loccol[2,*]=r
;    loccol[3,*]=g*.88+.12*b
    loccol[3,*]=g
    loccol[4,*]=b
    loccol[5,*]=rg
       if keyword_set(pscol) then loccol[5,*]=r*.8 + .2*g +.7*b
;      if keyword_set(pscol) then loccol[5,*]=r*.8 + .2*g +.3*b
;      if keyword_set(pscol) then loccol[5,*]=r*.7 + .5*g +.3*b
;      if keyword_set(pscol) then loccol[5,*]=r*.6 + .5*g +.3*b
    loccol[6,*]=rb
    if keyword_set(pscol) then $
    	loccol[6,*]=r*.8 + .2*g +.3*b
    if keyword_set(pscol) then loccol[7,*]=gb*.85 + b*.1 $
    else loccol[7,*]=gb
     loccol[8,*]=r*.5  + gb*.8
     loccol[9,*]=rg*.8   + .5*b + .2*r
     loccol[10,*]=rb*.7  + .5*g + .3*b
    coltbl[0:(maxind<10),*]=loccol[0:(maxind<10),*]
    if maxind gt 10 then begin
        coltbl[11:*,0]=forgrnd[0]
        coltbl[11:*,1]=forgrnd[1]
        coltbl[11:*,2]=forgrnd[2]
    endif

    coltbl=fix(coltbl*255.)
	if not keyword_set(pscol) then begin
		device,get_decomposed=decomposedph
	endif else begin
		decomposedh=0
	endelse
	if n_elements(colph) eq 0 then colph=ulonarr(256)
	if (decomposedph eq 1) and (not keyword_set(pscol)) then begin
	   colph[0:maxind]=coltbl[*,0]+coltbl[*,1]*256UL+coltbl[*,2]*256UL*256UL
    endif else begin
	   colph[0:maxind]=lindgen(maxind+1)
       tvlct,coltbl[*,0],coltbl[*,1],coltbl[*,2]
    endelse
    return
end
