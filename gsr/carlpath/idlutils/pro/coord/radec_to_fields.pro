;+
; NAME:
;   radec_to_fields
; PURPOSE:
; CALLING SEQUENCE:
; INPUTS:
; OUTPUTS:
; BUGS:
;   Currently undocumented; allFields.fit file hacked in
;   0/360 not properly done 
; REVISION HISTORY:
;   2002-Feb-21  written by Blanton (NYU)
;-
pro radec_to_fields,ra,dec,objectlist,fieldlist,includereruns=includereruns,allfieldfile=allfieldfile 
                    

; Input field list and make it uniq
if(NOT keyword_set(allfieldfile)) then $
  allfieldfile='/data/sdss/fields/allFields.fits'
allfields=mrdfits(allfieldfile,1)
fieldindx=allfields.run*1000l*8l*10000l + $
          allfields.camcol*10000l*1000l + $
          allfields.field*1000l + $
          allfields.rerun
sortfields=sort(fieldindx)
if(n_elements(includereruns) gt 0) then begin
  fieldindx2=allfields.run*1000l*8l*10000l + $
            allfields.camcol*10000l*1000l + $
            allfields.field*1000l + $
            allfields.rerun
endif else begin
  fieldindx2=allfields.run*1000l*8l*10000l + $
             allfields.camcol*10000l*1000l + $
             allfields.field*1000l 
endelse
uniqfields=uniq(fieldindx2[sortfields])
allfields=allfields[sortfields[uniqfields]]

; Find positions of the fields 
mufield=allfields.mu
nufield=allfields.nu
atbound2,nufield,mufield
mufieldcenters=0.5*(allfields.mu[1]+allfields.mu[0])
nufieldcenters=0.5*(allfields.nu[1]+allfields.nu[0])
atbound2,nufieldcenters,mufieldcenters
munu_to_radec,mufieldcenters,nufieldcenters,allfields.stripe,rafields,decfields

; Find "close" fields (within 0.18 degrees)
spherematch,ra,dec,rafields,decfields,0.3,objects,fields,distance,maxmatch=0l
sortbyobject=sort(objects)
objects=objects[sortbyobject]
fields=fields[sortbyobject]
distance=distance[sortbyobject]
uniqobjects=uniq(objects)

; Now check the positions in detail based on mu nu
radec_to_munu,ra[objects],dec[objects],muobj,nuobj,stripeobj, $
  setstripe=allfields[fields].stripe
infield=where(muobj ge mufield[0,fields] and $
              muobj lt mufield[1,fields] and $
              nuobj ge nufield[0,fields] and $
              nuobj lt nufield[1,fields],ninfield)
if(ninfield eq 0) then return

; Return the field list
objectlist=objects[infield]
fieldlist=allfields[fields[infield]]

end
