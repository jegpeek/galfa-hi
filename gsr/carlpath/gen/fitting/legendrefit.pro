pro legendrefit, xdata, ydata, degree, $
	coeffs, sigcoeffs, yfit, sigma, nr3bad, ncov, cov, $
	residbad=residbad, goodindx=goodindx, problem=problem
;+
;NAME:
;LEGENDREFIT -- legendre fit using standard least squares
;
;IMPORTANT NOTES: 
;	(1) GODDARD'S FLEGENDRE IS MUCH FASTER THAN IDL'S LEGENDRE!
;	(2) TO EVALUATE: YFIT= POLYLEG( XDATA, COEFFS)
;       (3) PAY ATTENTION TO DOUBLE PRECISION FOR HARD PROBLEMS!!!
;       (4) THE XDATA MUST LIE BETWEEN 0 AND 1. WHAT'S MORE...
;       (5) IF POINTS ARE UNIFORMLY SPACED, TO OBTAIN MAX ORTHOGONALITY:
;               (A) YOU HAVE nrt POINTS
;               (B) THESE nrt POINTS SPAN A TOTAL RANGE range
;               (C) THEN THE INTERVAL BETWEEN POINTS IS delta= range/(nrt-1)
;               (D) MAKE THE INPUT X VALUES BE...
;
;                       X = (2*findgen(nrt) - (nrt-1))/nrt
;
;                   which corresponds to half a bin away from the (-1,1) ends.
;                   suppose the original nrt uniformly-spaced values have values f=frt.
;                   then an alternative set of equation (good for arbitrary f) is
;
;                       frtspan= max( frt)- min( frt)
;                       dfrtspan= frtspan/( nrt-1)
;                       sfrtspan= max( frt)+ min( frt)
;                       x = (2.*frt - sfrtspan)/(frtspan+ dfrtspan)
;       OR              x = (2.*f - sfrtspan)/(frtspan+ dfrtspan)
;
;TIME:
;       (1) LEGENDRE FIT IS ABOUT 20% SLOWER THAN POLYNOMIAL FIT.
;       (2) FOR BOTH, SVD VERSION IS ABOUT 3 TIMES SLOWER THAN ORDINARY VERSION.
;
;PURPOSE:
;    like a polynomial fit but uses legendre functions, which are 
;orthogonal over the interval (-1,1). the input data must be 
;within this range.
;
;CALLING SEQUENCE:
;    LEGENDREFIT, xdata, ydata, degree, coeffs, sigcoeffs, yfit, $
;	sigma, nr3bad, cov
;
;INPUTS:
;     xdata: the x-axis data points. 
;     ydata: the y-axis data points.
;     degree: the degree of the legendre fit. e.g. linear fit has degree=1.
;KEYWORDS:
;     residbad: if set, excludes points those residuals exceed residbad*sigma
;	goodindx: the array of indices actually used in the fit.
;	problem: nonzero if there was a problem with the fit.
;OUTPUTS:
;     coeffs: array of coefficients.
;     sigcoeffs: me's of the coefficients.
;     yfit: the fitted points evaluated at datax.
;     sigma: the sigma (mean error) of the data points.
;     nr3sig: the nr of datapoints lying more than 3 sigma away from the fit.
;     ncov: the normalized covariance matrix.
;     cov: the covariance matrix.
;
;HISTORY;
;-

problem=0
x = double(xdata)
t = double(ydata)
ndata = n_elements(x)
goodindxx= lindgen( ndata)
niter= 0l
nr3bad = 0l

ITERATE:
;s = dblarr(degree+1, ndata, /nozero)
;for ndeg = 0, degree do s[ndeg,*] = legendre( x, ndeg)
s= transpose( flegendre( x, degree+1))

;stop

ss = transpose(s) ## s
st = transpose(s) ## transpose(t)
ssi = invert(ss)
a = ssi ## st
bt = s ## a
resid = t - bt
yfit = reform( bt)
sigsq = total(resid^2)/(ndata-degree-1.)
sigarray = sigsq * ssi[indgen(degree+1)*(degree+2)]
sigcoeffs = sqrt( abs(sigarray))
coeffs = reform( a)
sigma = sqrt(sigsq)
if keyword_set( residbad) then $
	badindx = where( abs(resid) gt residbad*sigma, nr3bad)
;stop

if ( (keyword_set( residbad)) and (nr3bad ne 0) ) then begin
goodindx = where( abs(resid) le residbad*sigma, nr3good)
IF NR3GOOD LE DEGREE+1 THEN BEGIN
	problem=-2
	goto, problemgood
ENDIF
x= x[goodindx]
t= t[goodindx]
goodindxx= goodindxx[ goodindx]
ndata= nr3good
niter= niter+ 1l
goto, iterate
endif

PROBLEMGOOD: ; go here if there aren't enough good points left.

;stop

;TEST FOR NEG SQRTS...
indxsqrt = where( sigarray lt 0., countbad)
if (countbad ne 0) then begin
	print, countbad, ' negative sqrts in sigarray!'
	sigarray[indxsqrt] = -sigarray[indxsqrt]
	problem=-3
endif

cov=ssi

;DERIVE THE NORMALIZED COVARIANCE ARRAY...
doug = ssi[indgen(degree+1)*(degree+2)]
doug = doug#doug
ncov = ssi/sqrt(doug)

;yfit= fltarr( n_elements( xdata))
;for ndeg=0, degree do yfit= yfit+ coeffs[ ndeg]*legendre( xdata, ndeg)
yfit= polyleg( x, coeffs)

goodindx= goodindxx

return
end
