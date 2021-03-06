common colors, r_orig, g_orig, b_orig, r_curr, g_curr, b_curr
common plotcolors, black, red, green, blue, cyan, magenta, yellow, white, grey 

print, 'STARTUP FILE IS /dzd1/heiles/gsr/start.idl_vermi.pro'

;------------------------THE USUAL PATHS---------------------------

;MAKE SURE WE COMPILE OUR OWN VERSIONS OF ADDPATH AND WHICH...
!path= expand_path( getenv( 'CARLPATH') + 'idl/gen/path/') + ':' + !path
.run addpath
.run which

;ADD IDL NATIVE UTILITIES...
addpath, getenv('IDL_DIR') + '/lib/utilities'

;THE FOLLOWING PROVIDES A SOME WAVELET FUNCTIONS THAT DO NOT SEEM
;	TO EXIST IN IDL6.2...
addpath, '/apps1/idl_6.0/lib/wavelet/source/


;---------------------DO ARECIBO SETUP STUFF-------------------------
addpath, getenv( 'PHILPATH') + 'gen/pnt'
addpath, getenv( 'PHILPATH') + 'data/pnt/'
addpath, getenv( 'PHILPATH') + 'gen'
.run aodefdir
@corinit1

addpath, getenv( 'GSRPATH') + 'procs/', /expand, /all_dirs

addpath, getenv( 'CARLPATH')+ 'idl/CodeIDL' 
addpath, getenv( 'CARLPATH') + 'idl/goddard' 
addpath, getenv( 'CARLPATH')+ 'idl/idlutils', /expand 
addpath, getenv( 'CARLPATH')+ 'idl/gen', /expand 

;OBSERVATORY COORDINATES...
;@/home/heiles/pro/carls/aostart.idl
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
 
; EXPLAIN THE X WINDOWS VISUAL CLASSES...
print, 'X WINDOWS VISUAL CLASSES:', format='(%"\N",A)'
print, '<g> : GrayScale 8-bit.'
print, '<p> : PseudoColor 8-bit, only available color indices allocated.'
print, '<2> : PseudoColor 8-bit, all 256 color indices allocated.'
print, '<t> : TrueColor 24-bit, a static color display.'
print, '<d> : DirectColor 24-bit, a dynamic color display.'
print, '<s> : System-restricted color display is selected.'
print, '<n> : Dont set any visual class.', format='(A,%"\N")'
 
; SET THE X WINDOWS VISUAL CLASS...
repeat begin &$
   print, format = $
'($,"<g>ray, <p>seudo, pseudo<2>56, <t>rue, <d>irect, <n>othing, or <s>ystem: ")' &$
   mode = strlowcase(get_kbrd(1)) & print &$
   case (mode) of &$
     'g' : device, Gray_Scale=8,    retain=2 &$     ; GRAYSCALE
     'p' : device, Pseudo_Color=8,  retain=2 &$     ; PSEUDOCOLOR
     '2' : device, Pseudo_Color=8,  retain=2 &$     ; PSEUDOCOLOR 256
     't' : device, True_Color=24,   retain=2 &$     ; TRUECOLOR
     'd' : device, Direct_Color=24, retain=2 &$     ; DIRECTCOLOR
     'n' : print, 'no visual class selected' &$
     'q' : exit &$
    else : if (mode ne 's') then print, 'Try again! (<q> to quit!)' &$
   endcase &$
endrep until (strpos('gp2tdns',mode) ne -1)

print, 'using undocumented device call for direct color on my linux machine'
device, /install_colormap
 
; GET IDL COLOR INFORMATION AND SET UP SYSTEM VARIABLES WITH BASIC
; PLOT COLOR NAMES...
setcolors, /SYSTEM_VARIABLES, PSEUDO256=(mode eq '2')
 
;stop
                                                                                
;GENERATE OUR FAVORITE CURSOR...
if (mode ne 'n') then device, cursor_standard=46
                                                                                
;----THE FOLLOWING SECTION DOES CARL'S COLOR SCHEME FOR BACKWARDS COMPATIBILITY-----
nrbits=0
if ( mode ne 'n') then nrbits=1
@start_plotcolors.idl
defsysv, '!grey', !gray                                                                                
red=!red
green=!green
blue=!blue
yellow=!yellow
magenta=!magenta
white=!white
black=!black
grey=!grey
gray=!gray
tvlct, r_orig, g_orig, b_orig, /get
tvlct, r_curr, g_curr, b_curr, /get
                                                                                
;if ( mode ne 'n') then plotcolors
if ( mode ne 'n') then window, 0, xsize=760, ysize=450, retain=2
if ( mode ne 'n') then window, 1, xsize=760, ysize=450, retain=2
                                                                                
delvar, mode
                                                                                
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

print, 'to use color table: device, dec=0'


print, 'STARTUP FILE IS /dzd1/heiles/gsr/start.idl_vermi.pro'

