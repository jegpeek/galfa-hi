; a code to display buttons which the user can use to select an output

pro plb, name, x, y, dx, dy, clr, th, filled=filled, cs=cs

if keyword_set(filled) then  polyfill, [x-dx, x+dx, x+dx, x-dx, x-dx], [y-dy, y-dy, y+dy, y+dy, y-dy], thick=th, color=clr else plots, [x-dx, x+dx, x+dx, x-dx, x-dx], [y-dy, y-dy, y+dy, y+dy, y-dy], thick=th, color=clr 

xyouts, x, y, name, alignment=0.5, charsize=cs, charthick=th

end


function buttons, bnames, win=win, asp=asp, title=title

nb = n_elements(bnames)
; make the window
if keyword_set(win) then wset, win
; setup the frame coordinates
if not (keyword_set(asp)) then asp = 1.

; button layout
nx = ceil(sqrt(nb*asp))
ny = ceil(sqrt(nb/asp))

;button position

xpos = rebin(reform((findgen(nx)+1), nx, 1), nx, ny)
ypos = rebin(reform(reverse(findgen(ny)+1), 1, ny), nx, ny)

opixwin, ow
plot, fltarr(2), xra=[0, nx+1], yra=[0, ny+1], /nodata, xs=5, ys=5, xmargin=[0, 0], ymargin=[0,0]
if keyword_set(title) then xyouts, 0.5, 0.95, title, charthick=2, align=0.5, /normal, charsize=2

dx = 0.3
dy = 0.3
; plot the buttons

for i=0, nb-1 do plb, bnames[i], xpos[i], ypos[i], dx, dy, 200, 4, cs = 2
cpixwin, ow, pw, x1, y1, p1
spixwin, pw

!mouse.button=3.
ct=0.
while ((!mouse.button ne 1) or (ct lt 1)) do begin
    cursor, xx, yy, /change
    spixwin, pw
    inside = (abs(xx-xpos) lt dx)*(abs(yy-ypos) lt dy)
    wh = where(inside[0:nb-1] eq 1, ct)
    if ct ne 0 then plb, bnames[wh], xpos[wh], ypos[wh], dx, dy, 200, 4, cs = 2, /filled
endwhile

; define regions for buttons

return, wh[0]
end
