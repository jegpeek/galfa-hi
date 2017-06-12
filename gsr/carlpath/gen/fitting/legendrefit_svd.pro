pro legendrefit_svd, xdata, ydata, degree, $
	coeffs, sigcoeffs, yfit, sigma, nr3bad, ncov, cov, $
	residbad=residbad, goodindx=goodindx, problem=problem
;+
;NAME:
;LEGENDREFIT_SVD -- legendre fit using standard least squares
;
;IMPORTANT NOTES:
;       (1) GODDARD'S FLEGENDRE IS MUCH FASTER THAN IDL'S LEGENDRE!
;       (2) TO EVALUATE: YFIT= POLYLEG( XDATA, COEFFS)
;	(3) PAY ATTENTION TO DOUBLE PRECISION FOR HARD PROBLEMS!!!
;	(4) THE XDATA MUST LIE BETWEEN 0 AND 1. WHAT'S MORE...
;	(5) IF POINTS ARE UNIFORMLY SPACED, TO OBTAIN MAX ORTHOGONALITY:
;		(A) YOU HAVE nrt POINTS
;		(B) THESE nrt POINTS SPAN A TOTAL RANGE range
;		(C) THEN THE INTERVAL BETWEEN POINTS IS delta= range/(nrt-1)
;		(D) MAKE THE INPUT X VALUES BE...
;
;			X = (2*findgen(nrt) - (nrt-1))/nrt
;
;		    which corresponds to half a bin away from the (-1,1) ends.
;		    suppose the original nrt uniformly-spaced values have values f=frt.
;		    then an alternative set of equation (good for arbitrary f) is
;
;			frtspan= max( frt)- min( frt)
;			dfrtspan= frtspan/( nrt-1)
;			sfrtspan= max( frt)+ min( frt)
;			x = (2.*frt - sfrtspan)/(frtspan+ dfrtspan)
;	OR		x = (2.*f - sfrtspan)/(frtspan+ dfrtspan)
;
;TIME: 
;	(1) LEGENDRE FIT IS ABOUT 20% SLOWER THAN POLYNOMIAL FIT.
;	(2) FOR BOTH, SVD VERSION IS ABOUT 3 TIMES SLOWER THAN ORDINARY VERSION.
;
;PURPOSE:
;    like a SVD polynomial fit but uses legendre functions, which are 
;orthogonal over the interval (-1,1). the input data must be 
;within this range.
;
;CALLING SEQUENCE:
;    LEGENDREYFIT_SVD, xdata, ydata, degree, coeffs, sigcoeffs, yfit, $
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

s= transpose( flegendre( x, degree+1))

;if (keyword_set( wgt_inv) eq 0) then begin
;        U=0.
;        V=0.
;        wgts=0.
;endif
                                                                                
lsfit_svd, s, t, U, V, $
        wgts, a, vara, siga, ncov, sigsq, ybar=yfit, cov=cov ;;;;, wgt_inv=wgt_inv
                                                                                
;DEAL WITH HUGE WGTS USING THE AUTO KEYWORD...
IF KEYWORD_SET(AUTO) THEN BEGIN
if ( auto eq 1.) then auto= 1.e-12
indxw= where( wgts/max( wgts) lt 1e-12, count)
wgt_inv= 1./wgts
if count ne 0 then wgt_inv[ indxw]= 0.
lsfit_svd, s, t, U, V, $
        wgts, a, vara, siga, ncov, sigsq, ybar=yfit, cov=cov, wgt_inv=wgt_inv
ENDIF
                                                                                
coeffs = reform( a)
sigcoeffs= siga
sigma = sqrt(sigsq)

resid = t - yfit

if keyword_set( residbad) then $
        badindx = where( abs(resid) gt residbad*sigma, nr3bad)
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
indxsqrt = where( vara lt 0., countbad)
if (countbad ne 0) then begin
	print, countbad, ' negative sqrts in vara!'
	vara[indxsqrt] = -vara[indxsqrt]
	problem=-3
endif

;DERIVE THE NORMALIZED COVARIANCE ARRAY...
doug = cov[indgen(degree+1)*(degree+2)]
doug = doug#doug
ncov = cov/sqrt(doug)

ybar= polyleg( x, coeffs)
;sss= transpose( flegendre( x, degree+1))
;ytrytry= transpose( flegendre( xda, degree+1)) ## coeffs

;stop

goodindx= goodindxx

return
end
