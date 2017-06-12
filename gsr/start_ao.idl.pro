
print, 'STARTUP FILE IS ' + getenv('GALFAPATH') + ' start_ao.idl.pro'

;stop

;---------------------DO ARECIBO SETUP STUFF-------------------------

;PHIL'S ARECIBO ROUTINES (NOTE: THE '+' GETS ALL SUBDIRS IN TREE)
!path= expand_path( '+' + getenv( 'PHILTOP'), /all_dirs) + ':' + !path
;stop
;.run aodefdir
print, 'aodefdir is excluded'
@corinit1

;AT THIS POINT PHIL'S ADDPATH IS DOMINANT. 
;COMPILE OUR OWN VERSION OF ADDPATH TO REPLACE PHIL'S...
addpath, getenv( 'CARLPATH') + 'gen/path'
.run addpath

;GALFA ARCHIVE ROUTINES
addpath, getenv('TREETOP') + 'archive'
;Kevin changed this from archive.pro to galfaarchive.pro
.run galfaarchive.pro

;GALFA PLANNING CODES
addpath, getenv('TREETOP') + 'planningcodes'
.run plotobserved.pro
.run BW_fm

;GET IDLUTILS ROUTINES...
addpath, getenv( 'GSRPATH')+ 'carlpath/idlutils' 

;10aug2006: JOSH/CARL DETERMINED THAT IT'S OK TO USE 
;	THE NEW, INSTEAD OF OLD, GODDARD ROUTINES
;;GET OLD GODDARD ROUTINES SO OUR LST CALCS ARE CORRECT 
;addpath, getenv( 'GSRPATH')+ 'carlpath/goddard' 

;GET THE SUITE OF CARL'S PROCS...
addpath, getenv( 'GSRPATH')+ 'carlpath/gen', /expand

;GET ENTIRE GSR PROCS PATH
addpath, getenv( 'GSRPATH')+ 'procs', /expand

;GET NEW (CURRENT) GODDARD ROUTINES
addpath, getenv( 'GSRPATH')+ 'goddard', /expand

;GET C++ code in path
addpath, getenv( 'GSRPATH')+ 'cpp', /expand


;OBSERVATORY COORDINATES...
common anglestuff, obslong, obslat, cosobslat, sinobslat
obslong = ten(66,45,10.8)
obslat = ten(18,21,14.2)
cosobslat = cos(!dtor*obslat)
sinobslat = sin(!dtor*obslat)

;-------------------DI\O STABDARD IDL SETUP STUFF----------------------


; WE'RE GOING TO SET THE PLOT DEVICE TO X WINDOWS...
set_plot, 'X'
                                                                                
; SET THE NUMBER OF LINES YOU WANT IDL TO SAVE FOR UP-ARROW CALLBACK...
!EDIT_INPUT=200

; COMPILE COLOR TABLE ROUTINES...
.compile setcolors, stretch
 
; Find out all you want about X Windows Visual Classes by looking in the
; online help under: X Windows Device Visuals
 
;; EXPLAIN THE X WINDOWS VISUAL CLASSES...
;print, 'X WINDOWS VISUAL CLASSES:', format='(%"\N",A)'
;print, '<g> : GrayScale 8-bit.'
;print, '<p> : PseudoColor 8-bit, only available color indices allocated.'
;print, '<2> : PseudoColor 8-bit, all 256 color indices allocated.'
;print, '<t> : TrueColor 24-bit, a static color display.'
;print, '<d> : DirectColor 24-bit, a dynamic color display.'
;print, '<s> : System-restricted color display is selected.'
;print, '<n> : Dont set any visual class.', format='(A,%"\N")'
 
; SET THE X WINDOWS VISUAL CLASS...
;repeat begin &$
;   print, format = $
;'($,"<g>ray, <p>seudo, pseudo<2>56, <t>rue, <d>irect, <n>othing, or <s>ystem: ")' &$
;   mode = strlowcase(get_kbrd(1)) & print &$
mode= 't'
;   case (mode) of &$
;     'g' : device, Gray_Scale=8,    retain=2 &$     ; GRAYSCALE
;     'p' : device, Pseudo_Color=8,  retain=2 &$     ; PSEUDOCOLOR
;     '2' : device, Pseudo_Color=8,  retain=2 &$     ; PSEUDOCOLOR 256
;     't' : device, True_Color=24,   retain=2 &$     ; TRUECOLOR
device, True_Color=24,   retain=2 &$     ; TRUECOLOR
;     'd' : device, Direct_Color=24, retain=2 &$     ; DIRECTCOLOR
;     'n' : print, 'no visual class selected' &$
;     'q' : exit &$
;    else : if (mode ne 's') then print, 'Try again! (<q> to quit!)' &$
;   endcase &$
;endrep until (strpos('gp2tdns',mode) ne -1)
 
; GET IDL COLOR INFORMATION AND SET UP SYSTEM VARIABLES WITH BASIC
; PLOT COLOR NAMES...
setcolors, /SYSTEM_VARIABLES, PSEUDO256=(mode eq '2')
 
;stop
                                                                                
;GENERATE OUR FAVORITE CURSOR...
device, cursor_standard=46
                                                                                
;plotcolors
;if ( mode ne 'n') then window, 0, xsize=300, ysize=225, retain=2
;if ( mode ne 'n') then window, 1, xsize=300, ysize=225, retain=2
                                                                                
delvar, mode
wdelete, 0                                                                                
; BELOW I'M REDEFINING SOME KEY COMBINATIONS...
; GET RID OF THE PRINT LINES IF THE OUTPUT BUGS YOU...
; OR GET RID OF THE DEFINITIONS IF YOU'RE NOT GOING TO USE THEM...
                                                                                
; REDEFINE SOME KEYS...
define_key, /control, '^F', /forward_word
print, 'Redefining CTRL-F : Move cursor forward one word'
define_key, /control, '^B', /back_word
print, 'Redefining CTRL-B : Move cursor backward one word'
define_key, /control, '^K', /delete_eol
print, 'Redefining CTRL-K : Delete to end of line'
define_key, /control, '^U', /delete_line
print, 'Redefining CTRL-U : Delete to beginning of line'
define_key, /control, '^D', /delete_current
print, 'Redefining CTRL-D : Delete current character under cursor'
define_key, /control, '^W', /delete_current
print, 'Redefining CTRL-W : Delete word to left of cursor', format='(A,%"\N")'

print, 'STARTUP FILE IS ' + getenv('GALFAPATH') + ' start_ao.idl.pro'
print, ''
print, ''
