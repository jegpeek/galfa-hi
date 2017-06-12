pro polyfit_median, xdata, ydata, degree, $
	coeffs, sigcoeffs, yfit, sigma, ncov

;+
;NAME:
;   POLYFIT_MEDIAN -- perform a least-abs-dev (median) polynomial fit
;
;PURPOSE:
;    Polynomial MEDIAN fits.
;
;CALLING SEQUENCE:
;    POLYFIT_MEDIAN, xdata, ydata, degree, $
;	coeffs, sigcoeffs, yfit, sigma, ncov
;
;INPUTS:
;     XDATA: the x-axis data points. 
;     YDATA: the y-axis data points.
;     DEGREE: the degree of the polynomial. e.g. linear fit has degree=1.
;
;OUTPUTS:
;     COEFFS: array of coefficients.
;     SIGCOEFFS: me's of the coefficients. SEE NOTE BELOW
;     YFIT: the fitted points evaluated at datax.
;     SIGMA: the sigma (mean error) of the data points. SEE NOTE BELOW
;     NCOV: the normalized covariance matrix.
;
;NOTE ON SIGMA AND SIGCOEFFS:
;	SIGMA and SIGCOEFFS are calculated as if we were doing a least
;squares fit.  this is appropriate for Gaussian statistics, but not for
;others, so this is relatively meaningless. For example, a single large
;discrepant point will contribute a lot to sigma, and to sigcoeffs, but
;because this is a median fit it is ignored.
;
;-

x = double(xdata)
tt = double(ydata)
ndata = n_elements(x)
ncoeffs= long( degree+ 1.5)
niter= 0

;FIRST TIME AROUND, DO A CONVENTIONAL LS FIT...
wgt= 1.0d0 + dblarr( ndata)
w = wgt
ws = dblarr(degree+1, ndata, /nozero)
wmin= 1.

ITERATE:

wmin_before= wmin
for ndeg = 0, degree do ws[ndeg,*] = wgt* (x^ndeg)
wt= wgt* tt

wss = transpose(ws) ## ws
wst = transpose(ws) ## transpose(wt)
wssi = invert(wss)
a = wssi ## wst

;BELOW, THE PREFIX 'W' MEANS WEIGHTED. FOR EXAMPLE,
;WBT IS PREDICTED YDATA WITH WEIGHT; BT IS WITHOUT WEIGHT...
wbt = ws ## a
bt= wbt/wgt

wresid = wt - wbt
resid = wresid/wgt
wyfit = reform( wbt)
yfit = wyfit/wgt

w= abs( resid) > 1e-10
wgt = 1./ sqrt( w)

niter= niter+1
wmin= min( w)

indx= where( resid gt 0, count)
indxhalf = 0
if ( abs( count - ndata/2) gt 1) then indxhalf=1
;print, niter, count, wmin
;result= get_kbrd(1)
;if (result ne 'q') then goto, iterate

;print, niter, count, wmin, count, indxhalf
;print, wmin-wmin_before
IF ( (NITER LT 200) AND $
	((ABS( WMIN) GT 1E-6) or (indxhalf eq 1)) AND $
	( abs( wmin - wmin_before) gt 1e-6) ) THEN GOTO, ITERATE
;print, niter, count, wmin, count, indxhalf
;print, niter, count, wmin
;print, wss ## wssi

;DERIVE THE NORMALIZED COVARIANCE ARRAY...
doug = wssi[indgen(degree+1)*(degree+2)]
doug = doug#doug
ncov = wssi/sqrt(doug)

;CALCULATE ERRORS ASSUMING GAUSSIAN PDF, USING STANDARD LS FIT TECHNIQUE...
variance= total( resid^2)/ (ndata-degree-1.)
sigsqarray1 = variance * wssi[indgen(degree+1)*(degree+2)]

sigma= sqrt( variance)
sigcoeffs = sqrt( abs(sigsqarray1))
coeffs = reform( a)

return
end
