;+
; NAME:
;   spheregroup
;
; PURPOSE:
;   Perform friends-of-friends grouping given ra/dec type coords 
;
; CALLING SEQUENCE:
;   ingroup = spheregroup( ra, dec, linklength, [chunksize=], $
;     [multgroup=], [firstgroup=], [nextgroup=] )
;
; INPUTS:
;   ra         - ra coordinates in degrees (N-dimensional array)
;   dec        - dec coordinates in degrees (N-dimensional array)
;   linklength - linking length for groups (degrees)
;
; OPTIONAL INPUTS:
;   chunksize  - the algorithm breaks the sphere up into a bunch of
;                regions with a characteristic size chunksize
;                (degrees). By default this is max(1.,4*linklength)
;
; OUTPUTS:
;   ingroup    - group number of each object (N-dimensional array)
;
; OPTIONAL INPUT/OUTPUTS:
;   multgroup  - multiplicity of each group (N-dimensional array; must
;                allocate before input)
;   firstgroup - first member of each group (N-dimensional array; must
;                allocate before input)
;   nextgroup  - index of next member of group for each object
;                (N-dimensional array; must allocate before input) 
;
; COMMENTS:
;   The code breaks the survey region into chunks which overlap by
;   about linklength. Friends-of-friends is run on each chunk
;   separately. Finally, the bookkeeping is done to combine the
;   results (i.e. joining groups across chunk boundaries). This should
;   scale as area*density^2, 
;
;   It is important that chunksize is >=4.*linklength, and this is
;   enforced.
;
;   firstgroup and nextgroup form a primitive "linked list", which 
;   can be used to step through a particular group, as in the example 
;   below.
;
; EXAMPLES:
;   Group a set of points on a scale of 55'', then step through
;   members of the third group:
;
;   > mult=lonarr(n_elements(ra))
;   > ingroup=spheregroup(ra,dec,.0152778,multgroup=mult, $
;   > firstgroup=first, nextgroup=next)
;   > indx=firstgroup[2]
;   > for i = 0, multgroup[2] do begin & $
;   > print,ra[indx],dec[indx] & $
;   > indx=nextgroup[indx]  & $
;   > end
;
;   Of course, you could just "print,ra[where(ingroup eq 2)]", but I
;   wanted to demostrate how the linked list worked.
;
; BUGS:
;   Behavior at poles not well tested.
;
; PROCEDURES CALLED:
;   Dynamic link to spheregroup.c
;
; REVISION HISTORY:
;   19-Jul-2001  Written by Mike Blanton, Fermiland
;-
;------------------------------------------------------------------------------
function spheregroup, ra, dec, linklength, chunksize=chunksize, multgroup=multgroup, firstgroup=firstgroup, nextgroup=nextgroup

   ; Need at least 3 parameters
   if (N_params() LT 3) then begin
      print, 'Syntax - ingroup = spheregroup( ra, dec, linklength, [chunksize=], $'
      print, ' [multgroup=], [firstgroup=], [nextgroup=] )' 
      return, -1 
  endif

   if (NOT keyword_set(chunksize)) then begin
       chunksize=max([4.*linklength,1.])
   end else begin
       if (chunksize lt 4.*linklength) then begin
           chunksize=4.*linklength
           print,'chunksize changed to ',chunksize
       endif
   endelse 

   npoints = N_elements(ra)
   if (npoints le 0) then begin
       print, 'Need array with > 0 elements'
       return, -1
   endif

   if (linklength le 0) then begin
       print, 'Need linklength > 0'
       return, -1
   endif
   
   if (keyword_set(multgroup) and n_elements(multgroup) lt npoints) then begin
       print, 'Please allocate enough memory for multgroup'
       return, -1
   endif

   if (keyword_set(firstgroup) and n_elements(firstgroup) lt npoints) then begin
       print, 'Please allocate enough memory for firstgroup'
       return, -1
   endif

   if (keyword_set(nextgroup) and n_elements(nextgroup) lt npoints) then begin
       print, 'Please allocate enough memory for nextgroup'
       return, -1
   endif

   ; Allocate memory for the ingroups array
   ingroup=lonarr(npoints)

   ; Call grouping software
   soname = filepath('libspheregroup.so', $
    root_dir=getenv('IDLUTILS_DIR'), subdirectory='lib')
   retval = call_external(soname, 'spheregroup', long(npoints), double(ra), $
                          double(dec), double(linklength), double(chunksize), $
                          ingroup)
   
   ; If desired, make multiplicity, etc.
   if (keyword_set(multgroup)) then begin
       for i = 0l, npoints-1l do multgroup[ingroup[i]]=multgroup[ingroup[i]]+1l
   endif
   if (keyword_set(firstgroup) or keyword_set(nextgroup)) then begin
       firstgroup=-1l+firstgroup-firstgroup
       nextgroup=firstgroup
       for i = npoints-1l, 0l, -1l do begin 
           nextgroup[i]=firstgroup[ingroup[i]]
           firstgroup[ingroup[i]]=i
       end
   endif
   
   return, ingroup
end
;------------------------------------------------------------------------------
