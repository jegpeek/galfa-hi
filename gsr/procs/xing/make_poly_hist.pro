pro make_plot_hist, xh, yh, xp, yp

dxo = (xh[1]-xh[0])/2.
nel = n_elements(xh)
xlxr = reform(transpose([[xh-dxo], [xh+dxo]]), nel*2.)
ylyr =  reform(transpose([[yh], [yh]]), nel*2.)

xp = [xh[0]-dxo, xlxr, xh[nel-1]+dxo, xh[0]-dxo]
yp = [0, ylyr, 0, 0]

end
