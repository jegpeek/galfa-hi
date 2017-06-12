pro doc, name, _REF_EXTRA=_extra
;+
; NAME:
;       doc
;
; PURPOSE:
;       Shorthand for doc_library.
;
; CALLING SEQUENCE:
;       doc, name
;
; INPUTS:
;       Name - A string containing the name of the IDL routine in question. 
;
; KEYWORD PARAMETERS:
;       All keywords accepted by DOC_LIBRARY are also accepted here.
;
; OUTPUTS:
;       None.
;
; NOTES:
;       If a routine is compiled but the directory of the routine is not
;       in !PATH, then in order to get the documentation, you need to specify
;       the DIRECTORY keyword must be set to the directory of the routine.
;
; MODIFICATION HISTORY:
;   26 Feb 2003  Written by Tim Robishaw, Berkeley
;   03 Oct 2005  TR.  Added _REF_EXTRA options.
;-
doc_library, name, _EXTRA=_extra
end; doc
