function elrem,array,index,dim

;+
;
; ELREM:
; A function that removes an element or several elements from a vector.
;
; Call Sequence:
; Result = ELREM(ARRAY, INDEX [, DIM])
;
; Inputs:
; ARRAY - The one-dimensional vector to be modified.
; INDEX - The index or array of indices to be removed.  Setting equal
;         to -1 returns the original array.
; DIM - Optional input.  Specify dimension to remove (1 or 2: follows 
;         dimension convention of TOTAL).
;
; Returns:
; ARRAY, sans elements specified by INDEX.
;
; N.B.
; Can currently handle 1- and 2-dimensional arrays only.
;
; Katie Peek / Feb 2007
; Mar 2007: Added 2-D capabilities.
; Jul 2008: Added -1 INDEX capability.
;
;-

; Syntactical check.
if (n_elements(array) eq 0) then begin
  print,' '
  print,' Syntax: Result = ELREM(ARRAY, INDEX [, DIM]) '
  return,''
endif

; Return ARRAY unchanged if INDEX is -1.
if (index[0] eq -1) then return,array

; Check stats of the inputs.
ndim = n_elements(size(array,/dim))
if (ndim ne 1) then begin
  if (n_elements(dim) eq 0) then message,'ELREM: Please specify a dimension.'
endif else dim=0

; Determine number of elements in ARRAY.
case dim of
  0: n = n_elements(array)
  1: n = n_elements(array[*,0])
  2: n = n_elements(array[0,*])
  else: message,'ELREM: DIM specification not supported.'
endcase

; Create array of indices of length N.
idx = indgen(n)

; Select out indices to keep.
idx[index] = -1
idx_keep = where(idx ne -1)

; Create new array.
case dim of
  0: arr_keep = array[idx_keep]
  1: arr_keep = array[idx_keep,*]
  2: arr_keep = array[*,idx_keep]
  else: message,'DIM: Invalid INDEX specification.'
endcase

; Return new array to user.
return,arr_keep
end
