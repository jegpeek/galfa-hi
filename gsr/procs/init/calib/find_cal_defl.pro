;+
; rootmh -- the directory the mh files live in
; namemh -- the name of the files up 'til the 4 digit number.
; endel -- the last element to use in the last file
; stel -- the first element to use in the first file
; sys_on_cal -- the output for each beam and and each pol
; cyc_time -- the half-period of an observation i.e. the 
;             slew-across-dec-once time plus the turn time (13s)
; conv_factor -- the factor by which to multiply the current spectrum
;                to get a corrected spectrum.  Output.
; single -- if single is set, do only calibration on the first cal
; tcal  -- the cal temps used
;-

pro find_cal_defl, rootmh, namemh, stel, endel, nums, cyc_time, conv_factor, mht, caloncent, nocals, tcal, single=single

newstel = stel-25

nfls = n_elements(nums)
fn = rootmh + namemh + string(nums[0], format='(I4.4)') + '.mh.sav'
restore, fn
print, fn
mht = mh[stel:*]
for i= nums[1], nums[nfls-2] do begin
    fn = rootmh + namemh + string(i, format='(I4.4)') + '.mh.sav'
    restore, fn
    print, fn
    mht = [mht, mh]
endfor
fn = rootmh + namemh + string(i, format='(I4.4)') + '.mh.sav'
restore, fn
print, fn
mh = mh[0:endel]
mht = [mht, mh]


caln = floor( (size(mht))[1]/cyc_time)
caloncent = fltarr(caln)
calsecs = 5
smmht =  smooth(mht.pwr_nb[0,0],calsecs)
for i = 0, caln-1 do begin
    mx = max( smmht[i*cyc_time:i*cyc_time+24], x)
    caloncent[i]=x+i*cyc_time
endfor

caloffcent = caloncent+6

if ( not keyword_set(single)) then begin
; take the cal to be on both before and after the peak by one second
c_on = (mht[caloncent-1].pwr_nb +  mht[caloncent].pwr_nb +  mht[caloncent+1].pwr_nb)/3.
c_off = (mht[caloffcent-1].pwr_nb +  mht[caloffcent].pwr_nb +  mht[caloffcent+1].pwr_nb)/3 
; the typical equation we employ is T_sys/Cal = (CalOff)/(CalOn-CalOff)
sys_on_cal = (c_off)/(c_on-c_off)
; We now calculate the mean of this value in a somewhat sophisticated way, by
; tossing out any crap outliers. Here we make an array in which to put said mean
soc_mean = fltarr(2,7)
; These are the mean off values for places we don't get a bad answer
c_off_mean = fltarr(2,7)
for i=0,1 do begin
    for j=0, 6 do begin
        ; Establish this beam+pol values for sys_on_cal for each measurement
        socij = sys_on_cal[i,j,*]
        ; Establish this beam+pol values for CalOff for each measurement
        coij = c_off[i,j,*]
        ; Find the mean of sys_on_ca
        mn = mean(socij)
        ; Likewise the standard deviation
        sd = stddev(socij)
        ; Now only average reasonable ratios
        soc_mean[i,j] = mean(socij(where( (socij gt mn -3*sd) and (socij lt mn + 3*sd) )))
        ; And take the mean of the CalOffs the same way
        c_off_mean[i,j] = mean(coij(where( (socij gt mn -3*sd) and (socij lt mn + 3*sd) )))
        ; Here is a sanity check to see that we are not 
        ; tossing too many data points
        print, string(i, format='(I2.2)') + ' ' + string(j, format='(I2.2)'), + ' '+ string( n_elements(where(( (socij lt mn -3*sd) or (socij gt mn + 3*sd) ))),  format='(I2.2)')
    endfor
endfor
endif


if (keyword_set(single)) then begin
; Here mean is used to mean 'only' :)
c_on_mean = total(mht[caloncent[0]-1:caloncent[0]+1].pwr_nb, 3)/3.
c_off_mean = total(mht[caloffcent[0]-1:caloffcent[0]+1].pwr_nb, 3)/3.
soc_mean = (c_off_mean)/(c_on_mean-c_off_mean)

endif

; I have changed the cal values to a new set of values as determined
; by  Josh and carl, by comparing beam to beam and with LDS. This used
; the fact that the beam efficiency in the region inspected was 0.9,
; so that the calibration process now requires an extra factor of
; 1/0.9 to get to LDS values.

;restore, '/dzd4/heiles/gsrdata/caltemp/ALFA_tcal_1420.sav'

restore, getenv('GSRPATH') + 'savfiles/newtemp01032005.sav'

;restore, '/dzd4/heiles/gsrdata/caltemp/newtemp01032005.sav'

tsys_mean=soc_mean*tcal

conv_factor = tsys_mean/c_off_mean

; Lets find all the places w/o cals

sz = (size(mht.pwr_nb[0,0]))[1]
nocals = fltarr(sz)+1.
for c=-5, 5 do begin
    nocals[caloncent+c] = 0.
endfor

end
