pro xmatrixgen, indx0a, indxtot, xmatrix

;generate xmatrix.


;THIS VERSION MAKES THE NR OF DATA EQNS 1 LARGER THAN THE NR OF 
;FREQ CHNLS, ALLOWING ONE TO SET THE SUM OF RF POWERS EQUAL TO ZERO.

sz= size( indx0a)
n736= sz[ 1]
nfsw= sz[ 2]
ndata= nfsw* n736

xmatrix= fltarr( n736+ indxtot, ndata+ 1l)

FOR NF= 0l,nfsw-1l DO BEGIN
FOR NR= 0l,n736-1l DO BEGIN
xmatrix[ nr, nf*n736+ nr]= 1.
ENDFOR
ENDFOR

;FILL RF PORTION OF MATRIX...
FOR NF= 0l,nfsw-1l DO BEGIN
FOR NR= 0l,n736-1l DO BEGIN
xmatrix[ n736+ indx0a[ nr, nf], nf*n736+ nr]= 1.
ENDFOR
ENDFOR

xmatrix[ n736:*, ndata]= 1.

end
