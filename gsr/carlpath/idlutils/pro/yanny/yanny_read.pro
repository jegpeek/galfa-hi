;+
; NAME:
;   yanny_read
;
; PURPOSE:
;   Read a Yanny parameter file into an IDL structure.
;
; CALLING SEQUENCE:
;   yanny_read, filename, [ pdata, hdr=, enums=, structs=, $
;    /anonymous, stnames=, /quick, errcode= ]
;
; INPUTS:
;   filename   - Input file name for Yanny parameter file
;
; OPTIONAL INPUTS:
;
; OUTPUT:
;
; OPTIONAL OUTPUTS:
;   pdata      - Array of pointers to all structures read.  The i-th data
;                structure is then referenced with "*pdata[i]".  If you want
;                to pass a single structure (eg, FOOBAR), then pass
;                ptr_new(FOOBAR).
;   hdr        - Header lines in Yanny file, which are usually keyword pairs.
;   enums      - All "typedef enum" structures.
;   structs    - All "typedef struct" structures, which define the form
;                for all the PDATA structures.
;   anonymous  - If set, then all returned structures are anonymous; set this
;                keyword to avoid possible conflicts between named structures
;                that are actually different.
;   stnames    - Names of structures.  If /ANONYMOUS is not set, then this
;                will be equivalent to the IDL name of each structure in PDATA,
;                i.e. tag_names(PDATA[0],/structure_name) for the 1st one.
;                This keyword is useful for when /ANONYMOUS must be set to
;                deal with structures with the same name but different defns.
;   quick      - Quicker read using READF, but fails if continuation lines
;                are present.  However, /QUICK must be used if there are any
;                lines longer than 2047 characters (see bug section below).
;   errcode    - Returns as non-zero if there was an error reading the file.
;
; COMMENTS:
;   Return 0's if the file does not exist.
;
;   Read and write variables that are denoted INT in the Yanny file
;   as IDL-type LONG, and LONG as IDL-type LONG64.  This is because
;   Yanny files assume type INT is a 4-byte integer, whereas in IDL
;   that type is only 2-byte.
;
;   I special-case the replacement of {{}} with "", since it seems
;   that some bonehead used the former to denote blank strings in
;   the idReport files.  Otherwise, any curly-brackets are always ignored
;   (as they should be).
;
; EXAMPLES:
;
; BUGS:
;   The IDL procedure READF will fail if the last non-whitespace character
;   is a backslash.  One can use such backslashes in Yanny files to indicate
;   a continuation of that line onto the next.  For this reason, I wrote
;   yanny_readstring as a replacement, though this will only work if all
;   lines are <= 2047 characters.
;
;   The reading could probably be sped up by setting a format string for
;   each structure to use in the read.
;
;   Not set up yet to deal with multi-dimensional arrays.
;
;   The following does not look for semi-colons within strings,
;   and will incorrectly split that different input lines (at STRSPLIT command).
;
; PROCEDURES CALLED:
;   mrd_struct
;
; INTERNAL SUPPORT ROUTINES:
;   yanny_add_comment
;   yanny_getwords()
;   yanny_strip_brackets()
;   yanny_strip_commas()
;   yanny_readstring
;   yanny_nextline()
;
; REVISION HISTORY:
;   05-Sep-1999  Written by David Schlegel, Princeton.
;-
;------------------------------------------------------------------------------
pro yanny_add_comment, rawline, comments

   if (size(comments,/tname) EQ 'INT') then $
    comments = rawline $
   else $
    comments = [comments, rawline]

   return
end
;------------------------------------------------------------------------------
; Replace left or right curly brackets with spaces.

function yanny_strip_brackets, sline

   sline = repstr(sline, '{{}}', '""')
   sline = repstr(sline, '{', ' ')
   sline = repstr(sline, '}', ' ')

;   i = strpos(sline, '}')
;   while (i NE -1) do begin
;      strput, sline, ' ', i
;      i = strpos(sline, '}')
;   endwhile
;
;   i = strpos(sline, '{')
;   while (i NE -1) do begin
;      strput, sline, ' ', i
;      i = strpos(sline, '{')
;   endwhile

   return, sline
end
;------------------------------------------------------------------------------
; Replace ";" or "," with spaces.  Also get rid of extra whitespace.
; Also get rid of anything after a hash mark.

function yanny_strip_commas, rawline

   sline = rawline

   i = strpos(sline, '#')
   if (i EQ 0) then sline = '' $
    else if (i GE 0) then sline = strmid(sline, 0, i-1)

   i = strpos(sline, ',')
   while (i NE -1) do begin
      strput, sline, ' ', i
      i = strpos(sline, ',')
   endwhile

   i = strpos(sline, ';')
   while (i NE -1) do begin
      strput, sline, ' ', i
      i = strpos(sline, ';')
   endwhile

   sline = strtrim(strcompress(sline),2)

   return, sline
end
;------------------------------------------------------------------------------
; Procedure to read the next line from a file into a string, but work even
; if the last non-whitespace character is a backslash (READF will fail on
; that).  Note that the line cannot be more than 2047 characters long.

pro yanny_readstring, ilun, sline

   common yanny_linenumber, lastlinenum ; Only for debugging

   sarray = strarr(2047)
   readf, ilun, sarray, format='(2047a1)'

   sline79='                                                                              '
   sline19='                   '
   sline = sline79+sline79+sline79+sline79+sline79+sline79+sline79+sline79 $
    +sline79+sline79+sline79+sline79+sline79+sline79+sline79+sline79+sline79 $
    +sline79+sline79+sline79+sline79+sline79+sline79+sline79+sline79+sline79 $
    +sline19

;   sline = string(' ', format='(a2047)') ; This format cannot be larger
                                          ; than 255 characters.

;   for i=0, 2047-1 do strput, sline, sarray[i], i

   ; The following is faster than the above since IDL loops are so slow.
   indx = where(sarray NE ' ', ct)
   lastchar = indx[(ct-1) > 0]
   for i=0, lastchar do strput, sline, sarray[i], i

   lastlinenum = lastlinenum + 1
end
;------------------------------------------------------------------------------
; Read the next line from the input file, appending several lines if there
; are continuation characters (backslashes) at the end of lines.

function yanny_nextline, ilun

   common yanny_lastline, lastline

   ; If we had already parsed the last line read into several lines (by
   ; semi-colon separation), then return the next of those.
   if (keyword_set(lastline)) then begin
      sline = lastline[0]
      nlast = n_elements(lastline)
      if (nlast EQ 1) then lastline = '' $
       else lastline = lastline[1:nlast-1]
      return, sline
   endif

   sline = ''
   yanny_readstring, ilun, sline
   sline = strtrim(sline) ; Remove only trailing whitespace
   nchar = strlen(sline)
   while (strmid(sline, nchar-1) EQ '\') do begin
      strput, sline, ' ', nchar-1 ; Replace the '\' with a space
      yanny_readstring, ilun, stemp
      stemp = strtrim(stemp) ; Remove only trailing whitespace
      sline = sline + stemp
      nchar = strlen(sline)
   endwhile

   ; Now parse this line into several lines by semi-colon separation,
   ; but then add the semi-colon back to each of those lines.
   ; NOTE: The following does not look for semi-colons within strings,
   ; and will incorrectly split that different input lines!!!???
   ; lastline = strsplit(sline, ';', /extract, escape='\')

   ; Attempt with a 5.2 hack

   lastline = str_sep(strcompress(sline), ';')
   nonblank = where(lastline NE '')
   if nonblank[0] NE -1 then lastline = lastline[nonblank]
   nlast = n_elements(lastline)
   lastchar = strtrim(sline)
   lastchar = strmid(lastchar, strlen(lastchar)-1, 1)

   if (lastchar EQ ';') then lastline[nlast-1] = lastline[nlast-1] + ';'
   if (nlast GT 1) then lastline[0:nlast-2] = lastline[0:nlast-2] + ';'

   sline = lastline[0]
   if (nlast EQ 1) then lastline = '' $
    else lastline = lastline[1:nlast-1]

   return, sline
end
;------------------------------------------------------------------------------
; Append another pointer NEWPTR to the array of pointers PDATA.
; Also add its name to PNAME.

pro add_pointer, stname, newptr, pcount, pname, pdata, pnumel

   if (pcount EQ 0) then begin
      pname = stname
      pdata = newptr
      pnumel = 0L
   endif else begin
      pname = [pname, stname]
      pdata = [pdata, newptr]
      pnumel = [pnumel, 0L]
   endelse

   pcount = pcount + 1

   return
end
;-----------------------------------------------------------------------------
; Split SLINE into words.  First, any phrase that appears between double-
; quotes is designated one word (and the quotes are dropped).  Then, white-
; space is used to split the line into words.

function yanny_getwords, sline

   words = ''
   stemp = strtrim(sline,2)

   while (keyword_set(stemp)) do begin
      slen = strlen(stemp)
      if (strmid(stemp,0,1) EQ '"') then begin
         ; Found double-quote, so extract that string (w/out the quotes)
         if (slen EQ 1) then begin
            words = [words, '']
            i2 = slen-1
            stemp = ''
         endif else begin
            i2 = strpos(stemp, '"', 1)
            if (i2 NE -1) then begin
               words = [words, strmid(stemp, 1, i2-1)]
            endif else begin
               i2 = slen-1
               words = [words, strmid(stemp, 1, i2)]
            endelse
         endelse
      endif else begin
         i2 = strpos(stemp, '"', 1)
         if (i2 EQ -1) then i2 = slen-1 $
          else i2 = i2-1

         ; Divide into words based upon spaces
         words = [words, $
          str_sep( strcompress(strtrim(strmid(stemp,0,i2+1),2)),' ') ]
      endelse
      if (i2 LT slen-1) then $
       stemp = strtrim( strmid(stemp, i2+1, slen-i2+1), 2) $
      else $
       stemp = ''
   endwhile

   nword = N_elements(words)
   if (nword GT 1) then words = words[1:nword-1]

   return, words
end
;------------------------------------------------------------------------------
pro yanny_read, filename, pdata, hdr=hdr, enums=enums, structs=structs, $
 anonymous=anonymous, stnames=stnames, quick=quick, errcode=errcode

   common yanny_linenumber, lastlinenum ; Only for debugging
   lastlinenum = 0

   if (N_params() LT 1) then begin
      print, 'Syntax - yanny_read, filename, [ pdata, hdr=, enums=, structs=, $
      print, ' /anonymous, stnames=, /quick, errcode= ]'
      return
   endif

   tname = ['char', 'short', 'int', 'long', 'float', 'double']
   ; Read and write variables that are denoted INT in the Yanny file
   ; as IDL-type LONG, and LONG as IDL-type LONG64.  This is because
   ; Yanny files assume type INT is a 4-byte integer, whereas in IDL
   ; that type is only 2-byte.
;   tvals = ['""'  , '0'    , '0'  , '0L'  , '0.0'  , '0.0D'  ]
;   tarrs = ['strarr(' , $
;            'intarr(' , $
;            'intarr(' , $
;            'lonarr(' , $
;            'fltarr(' , $
;            'dblarr(' ]
   tvals = ['""'  , '0'    , '0L'  , '0LL'  , '0.0'  , '0.0D'  ]
   tarrs = ['strarr(' , $
            'intarr(' , $
            'lonarr(' , $
            'lon64arr(' , $
            'fltarr(' , $
            'dblarr(' ]

   hdr = 0
   enums = 0
   structs = 0
   errcode = 0
   stnames = 0

   ; List of all possible structures
   pcount = 0       ; Count of structure types defined
   pname = 0        ; Name of each structure
   pdata = 0        ; Pointer to each structure
   pnumel = 0       ; Number of elements in each structure

   get_lun, ilun
   openr, ilun, filename, error=err
   if (err NE 0) then begin
      close, ilun
      free_lun, ilun
      return
   endif

   rawline = ''

   while (NOT eof(ilun)) do begin

      qdone = 0

      ; Read the next line
      if (keyword_set(quick)) then readf, ilun, rawline $
       else rawline = yanny_nextline(ilun)

      sline = yanny_strip_commas(rawline)
      words = yanny_getwords(sline) ; Divide into words and strings

      nword = N_elements(words)

      if (nword GE 2) then begin

         ; LOOK FOR "typedef enum" lines and add to structs
         if (words[0] EQ 'typedef' AND words[1] EQ 'enum') then begin

            while (strmid(sline,0,1) NE '}') do begin
               yanny_add_comment, rawline, enums
               if (keyword_set(quick)) then readf, ilun, rawline $
                else rawline = yanny_nextline(ilun)
               sline = yanny_strip_commas(rawline)
            endwhile

            yanny_add_comment, rawline, enums

            qdone = 1 ; This last line is still part of the enum string

         ; LOOK FOR STRUCTURES TO BUILD with "typedef struct"
         endif else if (words[0] EQ 'typedef' AND words[1] EQ 'struct') $
          then begin

            ntag = 0
            yanny_add_comment, rawline, structs
            if (keyword_set(quick)) then readf, ilun, rawline $
             else rawline = yanny_nextline(ilun)
            sline = yanny_strip_commas(rawline)

            while (strmid(sline,0,1) NE '}') do begin
               sline = strcompress(sline)
               ww = yanny_getwords(sline)

               if (N_elements(ww) GE 2) then begin
                  i = where(ww[0] EQ tname, ct)
                  i = i[0]

                  ; If the type is "char", then remove the string length
                  ; from the defintion, since IDL does not need a string
                  ; length.  For example, change "char foo[20]" to "char foo",
                  ; or change "char foo[10][20]" to "char foo[10]".
                  if (i EQ 0) then begin
                     j1 = rstrpos(ww[1], '[')
                     if (j1 NE -1) then ww[1] = strmid(ww[1], 0, j1)
                  endif

                  ; Force an unknown type to be a "char"
                  if (i[0] EQ -1) then i = 0

                  ; Test to see if this should be an array
                  ; (Only 1-dimensional arrays supported here.)
                  j1 = strpos(ww[1], '[')
                  if (j1 NE -1) then begin
                     addname = strmid(ww[1], 0, j1)
                     j2 = strpos(ww[1], ']')
                     addval = tarrs[i] + strmid(ww[1], j1+1, j2-j1-1) + ')'
                  endif else begin
                     addname = ww[1]
                     addval = tvals[i]
                  endelse

                  if (ntag EQ 0) then begin
                     names = addname
                     values = addval
                  endif else begin
                     names = [names, addname]
                     values = [values, addval]
                  endelse

                  ntag = ntag + 1
               endif

               yanny_add_comment, rawline, structs
               if (keyword_set(quick)) then readf, ilun, rawline $
                else rawline = yanny_nextline(ilun)
               sline = yanny_strip_commas(rawline)
            endwhile

            yanny_add_comment, rawline, structs

            ; Now for the structure name - get from the last line read
            ; Force this to uppercase
            stname1 = strupcase( strtrim(strmid(sline,1), 2) )
            if (NOT keyword_set(stnames)) then stnames = stname1 $
             else stnames = [stnames, stname1]

            ; Create the actual structure
            if (keyword_set(anonymous)) then structyp='' $
             else structyp = stname1
            add_pointer, stname1, $
             ptr_new( mrd_struct(names, values, 1, structyp=structyp) ), $
             pcount, pname, pdata, pnumel

            qdone = 1 ; This last line is still part of the structure def'n

         ; LOOK FOR A STRUCTURE ELEMENT
         ; Only look if some structures already defined
         ; Note that the structure names should be forced to uppercase
         ; such that they are not case-sensitive.
         endif else if (pcount GT 0) then begin
            ; If PDATA is not to be returned, then we need to read this
            ; file no further.
            if (NOT arg_present(pdata)) then begin
               close, ilun
               free_lun, ilun
               return
            endif

            idat = where(strupcase(words[0]) EQ pname[0:pcount-1], ct)
            if (ct EQ 1) then begin
               idat = idat[0]
               ; Add an element to the idat-th structure
               ; Note that if this is the first element encountered,
               ; then we already have an empty element defined.
               if (pnumel[idat] GT 0) then $
                *pdata[idat] = [*pdata[idat], (*pdata[idat])[0]]

               ; Split this text line into words
               sline = strcompress( yanny_strip_brackets(sline) )
               ww = yanny_getwords(sline)

               i = 1 ; Counter for which word we're currently reading
                     ; Skip the 0-th word since it's the structure name.

               ; Now fill in this structure from the line of text
               ntag = N_tags( *pdata[idat] )
               for itag=0, ntag-1 do begin
                  ; This tag could be an array - see how big it is
                  sz = N_elements( (*pdata[idat])[0].(itag) )

                  ; Error-checking code below
                  if (i+sz GT n_elements(ww)) then begin
                     splog, 'Last line number read: ', lastlinenum
                     splog, 'Last line read: "' + rawline + '"'
                     splog, 'ABORT: Invalid Yanny file ' + filename $
                      + ' at line number ' $
                      + strtrim(string(lastlinenum),2) + ' !!'
                     close, ilun
                     free_lun, ilun
                     yanny_free, pdata
                     errcode = -1L
                     return
                  endif

                  for j=0, sz-1 do begin
                     (*pdata[idat])[pnumel[idat]].(itag)[j] = ww[i]
                     i = i + 1
                  endfor
               endfor

               pnumel[idat] = pnumel[idat] + 1
            endif
            qdone = 1 ; This last line was a structure element
         endif

      endif

      if (qdone EQ 0) then $
       yanny_add_comment, rawline, hdr

   endwhile

   close, ilun
   free_lun, ilun

   return
end
;------------------------------------------------------------------------------
