function sixtystr, decimals_global
; converts decimal hours to AO input format: hhmmsss or ddmmsss
;
; apparently IDL uses global variables!
; copy calling value to local parameter to ensure it is unchanged outside
decimals_local = decimals_global
;
; convert to 1-element array; not sure why
decimals_local = [decimals_local]
; deal with < 0
whltz = fltarr(n_elements(decimals_local))
wh = where(decimals_local lt 0., ct)
if ct ne 0. then whltz(wh) = 1.
decimals_local = abs(decimals_local)
str = strarr(  (size(decimals_local))[1: (size(decimals_local))[0] ])

for i = 0, n_elements(decimals_local)-1 do begin
    if whltz[i] then pref = '-' else pref = ''
    x = sixty(decimals_local(i))
    str[i] = pref + string(x[0], format='(I2.2)') +string(x[1], format='(I2.2)') +string(x[2], format='(I2.2)') + '.' + string(round(x[2]*10.) mod 10, format='(I1.1)' )
endfor
if (n_elements(decimals_local) eq 1) then str = reform(str)

return, str

end


pro BW_fm, sourcename, RA, dec, wait_time, dra, ddec, late, out_exp=out_exp, out_cat=out_cat, end_time=end_time, start_lsts=start_lsts, end_lsts=end_lsts, gear=gear, file=file, days_done=days_done, redst=redst, fitswhen=fitswhen, ifloname=ifloname, restfreq=restfreq, azwagha=azwagha, sfsradec=sfsradec, fixedaz=fixedaz

;+
; Name:
;   BW_fm 
; PURPOSE:
;   Create all inputs neccessary to run Basketweave observing from the 
;   command line interface on CIMA at Arecibo with ALFA and the 
;   GALSPECT spectrometer.
;
; CALLING SEQUENCE:
;   BW_fm, sourcename, RA, dec, wait_time, dra, ddec, late, out_exp=out_exp, $
;   out_cat=out_cat, end_time=end_time, start_lsts=start_lsts, end_lsts=end_lsts, $
;   gear=gear, file=file, days_done=days_done, redst=redst, fitswhen=fitswhen, $
;   ifloname=ifloname, restfreq=restfreq, azwagha=azwagha, sfsradec=sfsradec, fixedaz=fixedaz
;
; INPUTS:
;   SOURCENAME - An arbitrary name for the region, e.g. 'blw'  
;   RA - The center of the region you wish to observe in RA (decimal hours, 
;        e.g. 22.85
;   DEC - The center of the region you wish to observe in dec (decimal 
;         degrees e.g. 3.85
;   WAIT_TIME - The requested time for turning around in seconds.
;         13 seconds seems to be the best time to choose for meridian nodding.
;	  15 seconds may be required for AZ wagging however!
;   DRA - The size of the region you wish to observe in RA (decimal hours, 
;        e.g. 1.85
;   DDEC - The size of the region you wish to observe in dec (decimal 
;        degrees e.g. 3.85
;   LATE - The number of places you wish to compute a late start time.
;          These are useful if your observations get screwed up and you
;          wish to do part of a day's worth of scans. A typical number here
;          would be 3.
;
; KEYWORD PARAMETERS:
;   GEAR - The style, in terms of dec attack angle, to scan the sky. There
;          are 6 different viable styles (gears) to use, ranging from 1 to 6.
;          6 is the default, and fastest, gear. If we take a Nyquist pixel to 
;          be 1.8 arcminutes on a side then:
;              GEAR     Integration time per Nyquist pixel   ALFA angle
;                6                   2.4                         0
;                5                   4.1                        30
;                4                   8.3                        30
;                3                   9.6                         0
;                2                   12.0                        0
;                1                   12.4                       30
;  
;   FILE - If this keyowrd is set, BW_fm writes 3 files for use
;          as inputs to CIMA at AO. NB: In older versions BW_fm 
;          used to write many files, now it just writes 3. 
;
;   DAYS_DONE - If this keyword set, then BW_fm will only produce files for
;               days that are not listed in the DAYS_DONE variable. It will 
;               also not list scans for days that are done in the late-starting
;               commands in the files.
;
;   REDST - If set, is a structure that the data reduction software can use to 
;           find start times, end times and cycle times.
;
;   FITSWHEN - Loops per WAPP fits file. Default is -1. This is mostly
;              irrelevant to GALSPECT operation, but keeps the WAPPS happy.
;
;   IFLONAME - the name of the iflo.gui file to load. default is
;              'galfa_only_iflo.conf'
;   
;   RESTFREQ - The rest frequency to use - default is 1420.405750 MHz.
;   
;   SFSRADEC - If you wish to give a position to do the sfs calibration other than 
;              the starting point of 00_00, enter it here in [ra, dec], decimal format
;
;    OUT_EXP - Set this to a variable that will contain the expressions 
;              that can be entered into the the command file. Use OUT_EXP[N,M] 
;              for day N, delay M
;    OUT_CAT - Set this to a variable that will contain the the catalog of all 
;              starting places for all scans. 
;    END_TIME - Set this to a variable that will contain the time in hhmmss.s 
;               form that the scan ends
;    START_LSTS - Set this to a variable that will contain the start times for 
;                 all the possible starting positons, in decimal LST (e.g. 21.7312)
;    END_LSTS - Set this to a variable that will contain the end times for each day in decimal LST
;    FIXEDAZ - Set this to implement fixed az scanning, rather than fixed 
;              HA scanning.
;    AZWAGHA - if it's set, do observations at az near 90/270, wagging in azimuth,
;              rather than nodding in za, and use the azwagha as the hour angle to observe,
;              in hours.
;
; MODIFICATION HISTORY:
;   Initial Documentation Wednesday, May 11, 2004, 1:43 PM PDT
;   Revision to include FILE keyword. June 15, 2005
;   Revision to update CIMA syntax, and deal with some "mod 24" issues.  June 17, 2005
;   Revison to deal with "mod 24" issues in CIMA fail-safe codes, added 'notes' to file. June 27, 2005
;   Revision to deal with Extended CIMA. July 5, 2005
;   Revision to fix doppler correction frame - HELIO -> TOPO. July, 2005
;   Revision to fix doppler for only LSFS. July 21, 2005
;   Revision to include redst, to go along with stg0_st in /gsr v1.1. July 27, 2005
;   Revision to include loops and restfreq Sept 1, 2005
;   Revisions to switch to evolved + got rid of many outputs &c March 23rd 2006.
;   Revision to include fixed azimuth scanning June 1 2006
;   Revision to switch to final azza implementation July 12 2006
;   Revision to fix negative dec nonsense.
;   Revision to add hourangle ne 0. October, 24 2006
;   Revision to fix elongation factor June, 11 2007
;   Revisions to deal with New CIMA April 13-25, 2007
;   Joshua E. Goldston, goldston@astro.berkeley.edu
;-

; make sure these input parameters are integers (CIMA requires for wait_time)
wait_time = long (round (wait_time))
late      = long (round (late))

; measured elongation factor as of october 22 2004 - 1.1162
; measured elongation factor as of June 11 2007 - 1.167. Not yet
; sure how the previous number was wrong...

elon=1.167
if (keyword_set(azwagha)) then elon=1/elon
; fmw is the 'fat marker width' - the width of all the beams together
; with appropriate spacing. neld is the non elongated 
; lateral distance - as measured in  carl's memo alfa_bm1
neld = 329.1
fmw = neld*sin(atan(sqrt(3)/2.))/2.*7/60.
if (not keyword_set(gear)) then begin 
    angle = atan(3.*sqrt(3)*elon)*180./!pi 
    RAwid = fmw/sin(atan(3.*sqrt(3)*elon))
 end else case gear of
    1: begin
        angle = atan(1./(3.*sqrt(3))*elon)*180./!pi
        RAwid = fmw/sin(atan(1./(3.*sqrt(3))*elon))
    end
    2: begin
        angle = atan(sqrt(3)/5.*elon)*180./!pi
        RAwid = fmw/sin(atan(sqrt(3)/5.*elon))
    end
    3: begin
        angle = atan(sqrt(3)/2.*elon)*180./!pi
        RAwid = fmw/sin(atan(sqrt(3)/2.*elon))
    end
    4: begin
        angle = atan(2./sqrt(3)*elon)*180./!pi
        RAwid = fmw/sin( atan(2./sqrt(3)*elon))
    end
    5: begin
        angle = atan(5./sqrt(3)*elon)*180./!pi
        RAwid = fmw/sin(atan(5./sqrt(3)*elon))
    end
    6: begin
        angle = atan(3.*sqrt(3)*elon)*180./!pi
        RAwid = fmw/sin(atan(3.*sqrt(3)*elon))
    end
endcase
 
; a general location for the bottom of the scan region, to calculate speeds.
; NOT an exact locationof the bottom of the box, as in lowdec
botdec = dec - ddec/2

;arcminutes per second at given dec, that the sky scrolls by
ampersec = 0.25*cos(botdec*!pi/180.)

; wait time in seconds
;ddec is in degrees
N = ceil( ((1./tan(angle*!pi/180.))*ddec*60*2.+2*wait_time*ampersec )/RAwid )
print, 'number of days =', N

;new dec range, given integer N
ddec = (N*RAwid-2*wait_time*ampersec)/(60*2.*(1./tan(angle*!pi/180.)) )
print, 'ddec=', ddec

; Bottom corner of dec

lowdec = dec - ddec/2.

; The starting ras need to start at the beginning of the scan, minus
; twice the wait time minus the upscan time, in hours.

start_ras = (24 +ra-dra/2.-( 2.*wait_time/3600.+ddec*(1./tan(angle*!pi/180.))*(1./ampersec)*60./3600.) +dindgen(N)*RAwid/ampersec/3600.) mod 24
if not keyword_set(azwagha) then azwagha = 0.
lsts_start = (24 +ra-dra/2.+azwagha-( 2.*wait_time/3600.+ddec*(1./tan(angle*!pi/180.))*(1./ampersec)*60./3600.) +dindgen(N)*RAwid/ampersec/3600. ) mod 24

;print, dra, N, RAwid, cos(botdec*!pi/180), (dra)/(N*RAwid/cos(botdec*!pi/180)/60./15.)
n_reps = ceil((dra)/(N*RAwid/cos(botdec*!pi/180)/60./15.))
print, 'n_reps=', n_reps, '  late=', late
if (late gt n_reps) then begin
  print, 'late > n_reps; reduced to n_reps.'
  late = n_reps
endif

sweep_time = round(ddec/(tan(angle*!pi/180.)*cos(botdec*!pi/180)*0.25/60.))

AO_start_ras = strarr(N, late)
AO_start_lsts = strarr(N, late)
AO_cutoff_ras = strarr(N, late)
; how much time before start time as a buffer?
buffer_time= 20.
start_lsts = strarr(N, late)
end_time = sixtystr((sweep_time+wait_time)*2*n_reps/60./60.+start_ras)
end_lsts = (24 + (sweep_time+wait_time)*2*n_reps/60./60.+start_ras) mod 24

; contruct the expression for the observing_from_file protocol.
out_exp = strarr(N, late)
out_cat = strarr(N, late)

lpf = ' 4' 
lpf = '-1' 
if (keyword_set(fitswhen)) then lpf =  ' ' + strcompress(string(fix(fitswhen)), /remove_all) 

for i=0, N-1 do begin
    for j=0, late-1 do begin
        AO_start_ras[i,j] = sixtystr((24 + start_ras[i] + j*2.*(sweep_time+wait_time)/60./60.) mod 24)
        AO_cutoff_ras[i,j] = sixtystr((24 + lsts_start[i] + j*2.*(sweep_time+wait_time)/60./60.-buffer_time/60./60.) mod 24)
        AO_start_lsts[i,j] = sixtystr((24 + lsts_start[i] + j*2.*(sweep_time+wait_time)/60./60.) mod 24)
        start_lsts[i,j] = (24 + start_ras[i] + j*2.*(sweep_time+wait_time)/60./60.) mod 24
        name =  sourcename + '_' + string(i, format='(I2.2)')+ '_' + string(j, format='(I2.2)')
        if keyword_set(fixedaz) then out_exp[i, j] = 'BASKETWEAVE' + ' dec=' + sixtystr(lowdec) + ' lst=' + ao_start_ras[i,j]+' loops=' + strcompress(n_reps-j, /remove_all) else out_exp[i, j] = 'BASKETWEAVE' + ' ra=' +ao_start_ras[i,j]+ ' dec=' + sixtystr(lowdec) + ' lst=' + ao_start_lsts[i,j]+' loops=' + strcompress(n_reps-j, /remove_all)
        out_cat[i,j] = name + ' ' + ao_start_ras[i,j] + ' ' + sixtystr(lowdec) + ' j 0. HELIO VOPT'
    endfor
endfor

if keyword_set(sfsradec) then begin
    sfsra = sixtystr(sfsradec[0])
    sfsdec = sixtystr(sfsradec[1])
endif else begin
    sfsra = ao_start_ras[0,0]
    sfsdec = sixtystr(lowdec)
endelse

;lsfs_cat = sourcename + '_sfs ' + sfsra + ' ' + sfsdec + ' j 0. TOPO VOPT'
;
;change to horizontal coordinates to keep telescope on starting meridian:
;
aodec = 18.34350
if (azwagha eq 0) then begin
  ; meridian nodding scan
  if (lowdec gt aodec) then begin
    ; north of zenith
    sfsaz = 180.0
    sfsza = lowdec - aodec
  endif else begin
    ; south of zenith
    sfsaz = 360.0
    sfsza = aodec - lowdec
  endelse
endif else begin
  ; off-meridian AZ wagging scan
  ; kludge: go near lamdba center DEC, not starting DEC
  if (azwagha lt 0) then begin
    ; east of meridian (LST < RA)
    sfsaz = 270.0
    sfsza = abs (azwagha * 15.0)
  endif else begin
    ; west of meridian (LST > RA)
    sfsaz = 90.0
    sfsza = abs (azwagha * 15.0)
  endelse
endelse
lsfs_cat = sourcename + '_sfs ' + string(sfsaz,format='(F8.4)') + ' ' + string(sfsza,format='(F7.4)') + ' h 0. TOPO VOPT'


redst = {sourcename:sourcename, end_lsts:end_lsts, start_lsts:start_lsts, sweep_time:sweep_time}

if (keyword_set(file)) then begin

free_lun, 1

if not(keyword_set(gear)) then alfarotator = '0.' else if ( (gear eq 6.) or (gear eq 3.) or (gear eq 2.)) then alfarotator = '0.' else  alfarotator = '30.'

if (keyword_set(days_done)) then begin
    days_not_done = findgen(N) 
    for j = 0, n_elements(days_done) -1 do days_not_done = days_not_done(where(days_not_done ne days_done[j]))
endif
if (not(keyword_set(days_done))) then days_not_done = findgen(N)

endloop = 0
if (not keyword_set(restfreq)) then restfreq = 1420.405750
sfsfreqs = string( 25+restfreq+[-22.5d, -8.5d, -7.5d, -4.5d, 1.5d, 3.5d, 8.5d]*100.d/512.d, format='(D13.8)')
sfsfreqsstring = sfsfreqs[0] + ' ' + sfsfreqs[1] + ' '+ sfsfreqs[2] + ' ' + sfsfreqs[3] + ' ' + sfsfreqs[4] + ' ' + sfsfreqs[5] + ' ' + sfsfreqs[6] + ' '

;while (endloop eq 0)  do begin
    i = days_not_done[0]
                                ; pt1 file
    filenamept1 = sourcename + '_day_' + string(i,format='(I2.2)') + '_pt1.cmd'

    openw, 1, filenamept1
    ;printf, 1, 'LOAD galfa_only_iflo.conf'
    if (keyword_set(ifloname)) then  printf, 1, 'LOAD ' + ifloname else printf, 1, 'LOAD pulsar_mode_with_wapps_test3.conf'
    printf, 1, 'ALFAANGLE ' + alfarotator 
    printf, 1, 'CATALOG ' + sourcename + '_sources.list'
    printf, 1, 'SEEK ' + sourcename + '_sfs'
    printf, 1, 'ADJUSTPOWER'
    close, 1
    
                                ;pt2 file
    filenamept2 = sourcename + '_day_' + string(i,format='(I2.2)') + '_pt2.cmd'

    openw, 1, filenamept2
    printf, 1, 'TRACKCURPOS'
    printf, 1, 'SMARTFREQ freqs={' + sfsfreqsstring + '} secs=10 loops=2 caltype=hcorcal newfile=0 adjpwr=never'
    ;if (keyword_set(ifloname)) then  printf, 1, 'LOAD ' + ifloname else printf, 1, 'LOAD pulsar_mode_with_wapps_test3.conf'
    if keyword_set(fixedaz) then printf, 1, 'SETUP basketweave secs=' + strcompress(sweep_time, /remove_all) + ' declen=' + strcompress(string(ddec,  format='(F6.3)'), /remove_all) + ' turnsecs=' + strcompress(wait_time, /remove_all) else printf, 1, 'SETUP basketweave rarate=15 secs=' + strcompress(sweep_time, /remove_all) + ' declen=' + strcompress(string(ddec,  format='(F6.3)'), /remove_all) + ' turnsecs=' + strcompress(wait_time, /remove_all)
     printf, 1, 'SETUP basketweave cals=1 calwhen=twice calsecs=3'
    if keyword_set(fixedaz) then printf, 1, 'SETUP basketweave mode=azza caltype=hcorcal dop=never newfile=' + lpf + ' adjpwr=never' else printf, 1, 'SETUP basketweave mode=traditional caltype=hcorcal dop=never newfile=' + lpf + ' adjpwr=never'

    if keyword_set(azwagha) then  printf, 1,'TRACKSKYANGLE skyangle = '+ alfarotator + ' limithit1 = wrap_60 limithit2 = keep'

    for j = 0, late-1 do begin
        for q = 0, n_elements(days_not_done)-1 do begin
            k = days_not_done[q]

; Simpler codes for 'evolved' CIMA

; Notes

            printf, 1, '#'
            printf, 1, '# DAY = ' + string(k, format='(I2.2)') + ' , LAMBDA = ' + string(j, format='(I2.2)')
            
; Pointing:
            printf, 1, 'IF lst < '+ AO_cutoff_ras[k,j] + ' THEN SEEK ' + sourcename + '_' + string(k, format='(I2.2)') + '_' +  string(j, format='(I2.2)')

; Basksetweave:
            printf, 1,  'IF lst < '+ AO_cutoff_ras[k,j] + ' THEN ' + out_exp[k, j]


        endfor
    endfor

    if keyword_set(azwagha) then  printf, 1,'STOPSKYANGLE'

    close, 1

;    if (n_elements(days_not_done) eq 1) then endloop = 1 else days_not_done = days_not_done[1:*]
    
;endwhile

; catalog file
filenamecat = sourcename + '_sources.list'
openw, 1, filenamecat
printf, 1, lsfs_cat
for j = 0, n_elements(out_cat)-1 do begin
    printf, 1, out_cat[j]
endfor
close, 1

endif
;stop

end

