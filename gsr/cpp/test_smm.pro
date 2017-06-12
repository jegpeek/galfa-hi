pro test_smm, m, n, nrhs, nels, rat
st1 = systime(/sec)
rands = floor(randomu(seed, nels)*n*m)
nuniq = n_elements( uniq(rands, sort(rands)))
while (nuniq lt nels) do begin
uniqs = uniq(rands, sort(rands))

rands = [rands(uniqs),floor(randomu(seed, nels-n_elements(uniqs))*n*m)]
nuniq = n_elements( uniq(rands, sort(rands)))
endwhile
row = rands mod n ; N
col = floor(rands/n) ; M
val = randomu(seed, nels)
;A = fltarr(m, n)
nels = long(nels)
;for i=0l, nels-1 do A[col[i], row[i]] = val[i]
B = randomu(seed,n, nrhs)
st2 = systime(/sec)
smmcall, M, N, nrhs, col, row, val, B, C
st3 = systime(/sec)
mx = max([m, n])
spmat = sprsin(col,row,val,mx)
Bbig = fltarr(mx, nrhs)
Bbig[0:n-1, *]= B
outs = fltarr(mx, nrhs) 
st4= systime(/sec)
for i=0, nrhs-1 do begin
    outs[*, i] = sprsax(spmat,reform(Bbig[*, i], /overwrite))
endfor
st5 = systime(/sec)

;print, 'C'
;print, C
;print, 'A#B'
;print, A#B
;print, 'A#B- C'
;print, A#B-C
print, 'setup time = ', st2-st1
print, 'compute time c++ = ', st3-st2
print, 'compute time IDL = ', st5-st4
rat =  (st3-st2)/(st5-st4)
print, 'ratio C++/IDL = ',  (st3-st2)/(st5-st4)
;stop

; On my G4
; IDL> test_smm, 6e4, 600.*7, 8192., 600.*7*15.
; Setup time =        3.3670781
; compute time =        576.82697
; On vermi
;IDL> test_smm, 6e4, 600.*7, 8192., 600.*7*15.
;% Compiled module: TEST_SMM.
;% Compiled module: SMMCALL.
;           0
;setup time =        1.0855460
;compute time =        153.20774


end
