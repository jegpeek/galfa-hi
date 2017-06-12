pro plot_qck, qcks, gdate, pj, freqs

psopen, 'qckplots' + gdate + '.' +pj +'.ps', /helvetica

for d=0,n_elements(qcks)-1 do begin
!p.multi=0.

wh = where((freqs[d, *]) ne 0.)
mm = minmax((freqs[d, *])[wh])

plot, (findgen(600))[wh], (freqs[d, *])[wh], xra=[0, 599], yra=[mm[0]- 0.1*(mm[1]-mm[0])-1d6, mm[1]+ 0.1*(mm[1]-mm[0])+1d6], /xs, /ys, ymargin=[69, 3], xticklen=1d-9, /font, xticks=2, yticks=1, title=gdate+ ' ' +pj +' '+ string(d, f='(I4.4)') +' Rest Freq'

yp1=-0.7
xp1=0.5

for j=0, 1 do begin
    x0 = min(qcks[d].RFFRQ_NB)
    i=0.
    !p.multi=[j, 2, 1]
    plot, qcks[d].RFFRQ_NB, qcks[d].csnb[*,j,i], yra=[-1, 10], /ys, ytickname=replicate(' ', 7), yticklen=1d-9, /nodata, /xs, xticks=2, title=gdate+ ' ' +pj +' '+ string(d, f='(I4.4)') +' Pol' + string(j, f='(I1.1)') + '-NB', /font, /noerase, ymargin=[4, 10]
    for i=0, 6 do begin
        oplot,  qcks[d].RFFRQ_NB,qcks[d].csnb[*,j,i]+i*1.5
        xyouts, x0 -1, i*1.5, string(i, f='(I1.1)'), /font
        xyouts, x0+xp1, i*1.5+yp1, 'NB Cont: '+string( floor(qcks[d].csnbcont[j, i]), f='(I3.3)'), /font

    endfor
   
endfor
xyouts, x0+5, yp1, 'nsec= '+string(qcks[d].countyes, f='(I3.3)'), /font
xyouts, x0+4.2, 9.5, 'rf_frq= '+string(qcks[d].rffrq_nbm1, f='(F7.2)'), /font

yp1=-0.7
xp1=3

for j=0, 1 do begin
    x0 = min(qcks[d].RFFRQ_WB)
    i=0.
    !p.multi=[j, 2, 1]
    
    plot, qcks[d].RFFRQ_WB, qcks[d].cswb[*,j,i], yra=[-1, 10], /ys, ytickname=replicate(' ', 7), yticklen=1d-9, /nodata, /xs, xticks=2, title=gdate+ ' ' +pj +' '+ string(d, f='(I4.4)') +' Pol' + string(j, f='(I1.1)') + '-WB', /font, noerase=j
    for i=0, 6 do begin
        oplot,  qcks[d].RFFRQ_WB,qcks[d].cswb[*,j,i]+i*1.5
        xyouts, x0 -10, i*1.5, string(i, f='(I1.1)'), /font
        xyouts, x0+xp1, i*1.5+yp1, 'NB Cont: '+string( floor(qcks[d].cswbcont[j, i]), f='(I3.3)'), /font

    endfor
   
endfor
xyouts, x0+65, yp1, 'nsec= '+string(qcks[d].countyes, f='(I3.3)'), /font
xyouts, x0+65, 9.5, 'rf_frq= '+string(qcks[d].rffrq_nbm1, f='(F7.2)'), /font

endfor
psclose

end
