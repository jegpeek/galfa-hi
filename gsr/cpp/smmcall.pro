pro smmcall, M, N, nrhs, col, row, val, B, C, dbl=dbl, force=force
; All of these terms are similar to those used in sUSMM in SPARSE BLAS
; A is of dimension M x N
; B is of dimension N x nrhs
; C, the output array, is of dimension M x nrhs
; if dbl is set, then call a double precision version
; if force is set to 1, use C++, if force is set to 2 use IDL. Otherwise choose optimal choice, which 
; so far, boils down to whether C has more or less than 5d8 elements (more is C)

if not(keyword_set(force)) then force = (m*nrhs lt 5d8)+1
if force eq 1 then begin
    If (n_elements(C) eq 0) then C = fltarr(M, nrhs)
    nels = n_elements(col)
    ext = (!version.arch eq 'ppc') ? '.dylib' : '.so'
    if keyword_set(double) then s = call_external('smmd'+ext, '_Z4smmiPPc', long(M), long(N), long(nrhs), long(nels), long(col), long(row), double(val), float(B), float(C)) else s = call_external('smm'+ext, '_Z3smmiPPc', long(M), long(N), long(nrhs), long(nels), long(col), long(row), float(val), float(B), float(C))
endif else begin
    mx = max([m, n])
    spmat = sprsin(col,row,val,mx)
    Bbig = fltarr(mx, nrhs)
    Bbig[0:n-1, *]= B
    outs = fltarr(mx, nrhs) 
    for i=0, nrhs-1 do begin
        outs[*, i] = sprsax(spmat,reform(Bbig[*, i], /overwrite))
    endfor
    C = outs[0:M-1, 0:nrhs-1]
endelse

;  print, s

end
