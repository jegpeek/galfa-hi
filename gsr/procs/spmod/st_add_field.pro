
function st_add_field, in_struct, in_field_name, in_field_blank, in_field_fill=in_field_fill, remove=remove, swap=swap

;+
;
; ST_ADD_FIELD: Function that adds a given field to a pre-existing
; structure or structure array.
;
; Call Sequence:
; Result = ST_ADD_FIELD(IN_STRUCT, IN_FIELD_NAME, IN_FIELD_BLANK 
;                       [, IN_FIELD_FILL=Value] [, /REMOVE] [, /SWAP])
;
; Input:
; IN_STRUCT - Structure to be modified.
; IN_FIELD_NAME - String containing name of field to be added.
; IN_FIELD_BLANK - Empty element to be added to new field in a single
;                 structure element.
;
; Keywords:
; IN_FIELD_FILL - Quantity to be inserted in new field (e.g. ' ', 0d).
;                 If IN_STRUCT is an array and IN_FIELD_FILL is a
;                 scalar, the field will be filled with a replication
;                 of that element.
; REMOVE - Set to remove a structure field instead of add one.
; SWAP - Set to change the nature of an existing field.
;
;
; Output:
; Structure of form IN_STRUCT but with additional field.
;
; Notes:
; Add named structure capability?
;
; Katie Peek / March 2006
;            / March 2008: Added /remove keyword.
;            / Nov 2008: Added /swap keyword.
;
;-

; Give syntax.
if (n_elements(in_struct) eq 0) then begin
  print,' ST_ADD_FIELD syntax: '
  print,' result = st_add_field(in_struct, in_field_name, in_field_blank '
  print,'          [, in_field_fill=value] [, /remove] [, /swap]) '
  st_out = ' '
  goto, theend
endif

; Protect input.
st_in = in_struct
out_struct = 0.
in_struct = 0.


; Verify that input is indeed a structure.
sz = size(st_in,/type)
if (sz ne 8) then begin
  message,'Input is not a structure.  Exiting.'
endif

; Set keyword stuff.
if ~keyword_set(remove) then remove=0
if ~keyword_set(swap) then swap=0

; Grab tag names.
tags = strlowcase(tag_names(st_in))   ; Forcing TAGS to be lowcase.
ntags = n_tags(st_in)
if (~swap and ~remove and $
     (where(tags eq strlowcase(in_field_name)))[0] ne -1) then begin
  print,'ST_ADD_FIELD: in_field_name already exists. Swapping in new value.'
  swap=1
endif

; Assess structure size.
n = n_elements(st_in)
stsz = size(st_in,/dim)

; Assess new element size.
m = n_elements(in_field_blank)

; Pull out template.
template = st_in[0]

; Create new template: 
;   if /remove: sans IN_FIELD_NAME
;   if /swap: with new character of IN_FIELD_NAME
;   else: with IN_FIELD_NAME added to end.
idxswp = -1 ; No swapping unless turned on inside /swap section below.
if (remove or swap) then begin   ; A field-by-field loop will be necessary.
  if (remove) then begin         ; Identify field to remove.
    idxrem = where(tags eq strlowcase(in_field_name))
    if (idxrem[0] eq -1) then begin
      message,'Structure tag name '+in_field_name+" doesn't exist."
    endif
    tags = elrem(tags,idxrem)    ; Make new tags array.
  endif 
  if (swap) then begin           ; Ideintify field to swap.
    idxswp = (where(tags eq strlowcase(in_field_name)))[0]
    if (idxswp eq -1) then begin
      message,'Structure tag name '+in_field_name+" doesn't exist."       
    endif
  endif
  ntags = n_elements(tags)       ; Number of tags to loop over.
  for i=0,ntags-1 do begin
    j = where(strlowcase(tag_names(template)) eq tags[i])
    if (i eq idxswp) then begin
      fieldfill = in_field_blank   ; New field to swap in.
    endif else begin
      fieldfill = template.(j)     ; Old field, no swapping.
    endelse
    if (n_elements(newtemp) eq 0) then begin       ; New template,
      newtemp = create_struct(tags[i], fieldfill)  ;  if necessary.
    endif else begin
      newtemp = create_struct(newtemp, tags[i], fieldfill)
    endelse
  endfor
endif else begin     ; If no /rem or /swap, just add new field to end.
  newtemp = create_struct(template, in_field_name, in_field_blank)
endelse

; Create new structure.
st_out = replicate(newtemp,stsz)

; Fill new structure with old stuff.
for i=0,ntags-1 do begin
  if (i eq idxswp) then continue         ; Skip if the /swap tag.
  j = where(strlowcase(tag_names(st_in)) eq tags[i])
  st_out.(i) = st_in.(j)
endfor

; In non-/rem case, fill new field as appropriate.
if ~remove then begin
  if swap then i=idxswp else i=ntags
  case n_elements(in_field_fill) of
         ; Leave blank
    0: st_out.(i) = st_out.(i)       ; Leave blank.
         ; Array fills all new structure elements.
    n*m: st_out.(i) = in_field_fill
         ; Different value fills different structure elements.
    n: st_out.(i) = transpose(rebin(in_field_fill,n,m))
         ; Same array fills each structure element.
    m: st_out.(i) = rebin(in_field_fill,m,n)
         ; IN_FIELD_FILL doesn't match array size.
    else: begin
      print,'IN_FIELD_FILL keyword does not match new structure tag.'
      print,'st_out.'+in_field_name+' dimensions: ',str(size(st_out.(i),/dim)) 
      stop
    end
 endcase
endif

theend:  ; Skip to here in an exit sequence.

return,st_out
end
