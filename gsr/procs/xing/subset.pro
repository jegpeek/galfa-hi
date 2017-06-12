;+
; Return the indices where A is an element of B. 
;-

function subset, A, B

na = n_elements(A)
nb = n_elements(B)

sorted =  floor(where(rebin(reform(B,1, nb), na, nb) eq rebin(reform(A(sort(A)), na, 1), na, nb))/na)

return, sorted(sort(sort(A)))

end
