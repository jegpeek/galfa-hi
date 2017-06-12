pro opixwin, oldwin

oldwin = !d.window
window, /free, /pixmap, XS=!d.x_size, YS=!d.y_size
winnum = !d.window

end
