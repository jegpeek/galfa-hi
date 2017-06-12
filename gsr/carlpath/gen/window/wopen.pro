function wopen
;+
;NAME:
;WOPEN -- return list of all open windows
;     
; PURPOSE:
;       Quick way to find all open windows
;     
; CALLING SEQUENCE:
;       result= wopen()
;     
; INPUTS:
;       NONE
;     
; RETURNS: VECTOR OF OPEN WINDOWS
;
; RESTRICTIONS:
;       The current device must be X Windows.
;
; MODIFICATION HISTORY:
;       Written CARL, who finally got fed up 
;-

; ARE YOU USING X WINDOWS DEVICE...
if (!d.name ne 'X') then begin
  message, 'DEVICE not set to X Windows.', /INFO
  return, -1
endif

; FIND THE OPEN WINDOWS...
device, window_state=openwindows
openwindows = where(openwindows,Nopen)

return, openwindows

end

