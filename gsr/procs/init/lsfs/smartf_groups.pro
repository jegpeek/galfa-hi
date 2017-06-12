pro smartf_groups, smartf, smartf_groups

;+
;SMARTF_GROUPS: define groups of smartf files.
;
;PURPOSE: FIND_SMARTF returns a vector of length the number of mh files
;tested for containing SMARTF. This routine converts this vector to
;groups. For example, if SMARTF returns [1,1,0,1,0,1], indicating that
;the first 2 and the last file contain SMARTF records, this routine
;returns the beginning and ending indices of the SMARTF records, which in
;this case is a 2 X 3 element matrix equal to...
;       0       1
;       3       3
;       6       6
;
;INPUT: the SMARTF vector from FIND_SMARTF
;
;OUTPUT: the groups matrix, as defined above.
;-

;first: how many groups:

indxend= -1
indxbeg= -1

;find beginnings (0 to 1 transition)
indxend = where( smartf eq 1 and shift( smartf,-1) eq 0, countend)
ndxend= indxend

;find endings (1 to 0 transition)
indxbeg= where( smartf eq 1 and shift( smartf,1) eq 0, countbeg)
ndxbeg= indxbeg

if (countend eq 0) and (countbeg eq 0) and (smartf[ 0] eq 1) then begin
	smartf_groups= intarr( 2,1)
	smartf_groups[ 0,0]= 0
	smartf_groups[ 1,0]= n_elements( smartf) -1
	smartf_groups= reform(smartf_groups,2,1)
	return
endif

;stop

;print, 'beg', indxbeg
;stop, 'end', indxend

if indxend[0] lt indxbeg[0] then ndxbeg = [0, indxbeg]

if countend ne 0 then begin
if indxend[countend-1] lt indxbeg[ countbeg-1] then $
	ndxend= [indxend, n_elements( smartf)-1]
endif

;print, smartf

;print, 'beg', ndxbeg        
;print, 'end', ndxend

smartf_groups= intarr( 2, n_elements(ndxbeg))

for nd= 0, n_elements( ndxbeg)-1 do  $
	smartf_groups[*,nd]= [ndxbeg[nd], ndxend[ nd]]

;print, smartf_groups

smartf_groups= reform( smartf_groups, 2, n_elements(smartf_groups)/2)

return
end
