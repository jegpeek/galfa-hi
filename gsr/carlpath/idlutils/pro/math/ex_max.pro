;+
; NAME:
;   ex_max
; PURPOSE:
;   expectation-maximization iterative multi-gaussian fit to data
; INPUTS:
;   weight      [N] array of data-point weights
;   point       [d,N] array of data points - N vectors of dimension d
;   amp         [M] array of gaussian amplitudes
;   mean        [d,M] array of gaussian mean vectors
;   var         [d,d,M] array of gaussian variance matrices
; OPTIONAL INPUTS:
;   maxiterate  maximum number of iterations; default to 1000
;   qa          name for QA plot PostScript file
; OUTPUTS:
;   amp         updated amplitudes
;   mean        updated means
;   var         updated variances
; OPTIONAL OUTPUTS:
;   entropy     final entropy, relative to one-gaussian case
;   probability [N,M] array of probabilities of point i in gaussian j
; BUGS:
;   Entropy calculation could be wrong; see in-code comments.
;   Stopping condition is hard-wired.
; DEPENDENCIES:
;   idlutils
; REVISION HISTORY:
;   2001-Aug-06  written by Blanton and Hogg (NYU)
;   2001-Oct-02  added data-point weights - Hogg
;-
pro ex_max, weight,point,amp,mean,var,maxiterate=maxiterate,qa=qa, $
  entropy=entropy,probability=probability

; set defaults
  if NOT keyword_set(maxiterate) then maxiterate= 1000

; check dimensions
  ndata= n_elements(weight)                    ; N
  ngauss= n_elements(amp)                      ; M
  dimen= n_elements(point)/n_elements(weight)  ; d
  splog, ndata,' data points,',dimen,' dimensions,',ngauss,' gaussians'

; cram inputs into correct format
  point= reform(double(point),dimen,ndata)
  amp= reform(double(amp),ngauss)
  mean= reform(double(mean),dimen,ngauss)
  var= reform(double(var),dimen,dimen,ngauss)

; compute entropy normalization -- ie, entropy for one-gaussian case
  amp1= total(weight)
  mean1= total(weight##(dblarr(dimen)+1D)*point,2)/amp1
  var1= 0d
  for i=0L,ndata-1 do begin
    delta= point[*,i]-mean1
    var1= var1+weight[i]*delta#delta
  endfor
  var1= var1/amp1
  invvar= invert(var1,/double)
  if dimen GT 1 then $
    normamp= amp1*sqrt(determ(invvar))/(2.0*!PI)^(dimen/2) $
  else $
    normamp= amp1*sqrt(invvar)/(2.0*!PI)^(dimen/2)
  probability1= dblarr(ndata)
  for i=0L,ndata-1 do begin
    delta= point[*,i]-mean1
    probability1[i]= normamp*exp(-0.5*delta#invvar#delta)
  endfor
; Hogg is not sure about the following formula:
  entropy1= total(weight*alog(probability1/amp1))/alog(2D)

; allocate space for probabilities and updated parameters
  probability= reform(dblarr(ndata*ngauss),ndata,ngauss)
  newamp= amp
  newmean= mean
  newvar= var

; begin iteration loop
  iteration= 0L
  lastplot= 0L
  repeat begin
    iteration= iteration+1

; compute (un-normalized) probabilities
    for j=0L,ngauss-1 do begin
      invvar= invert(var[*,*,j],/double)
      if dimen GT 1 then $
        normamp= amp[j]*sqrt(determ(invvar))/(2.0*!PI)^(dimen/2) $
      else $
        normamp= amp[j]*sqrt(invvar)/(2.0*!PI)^(dimen/2)
      for i=0L,ndata-1 do begin
        delta= point[*,i]-mean[*,j]
        probability[i,j]= normamp*exp(-0.5*delta#invvar#delta)
      endfor
    endfor

; compute entropy using un-normalized probabilities
; Hogg is unsure of the following formula:
    entropy= total(weight*alog(total(probability,2)/total(amp)))/ $
      alog(2D) - entropy1
    splog, iteration,': entropy S =',entropy,' bits'

; normalize probabilities
    probability= probability/(total(probability,2)#(dblarr(ngauss)+1))

; compute new quantities
    newamp= total(weight#(dblarr(ngauss)+1D)*probability,1)
    newmean= point#(weight#(dblarr(ngauss)+1D)*probability)/ $
      (newamp##(dblarr(dimen)+1.0))
    for j=0L,ngauss-1 do begin
      tmp= 0.0D
      for i=0L,ndata-1 do begin
        delta= point[*,i]-newmean[*,j]
        tmp= tmp+weight[i]*probability[i,j]*delta#delta
      endfor
      newvar[*,*,j]= tmp/newamp[j]
    endfor

; update
    splog, iteration,newamp
    damp= newamp-amp
    amp= newamp
    mean= newmean
    var= newvar

; check stopping condition -- no amplitude changes by more than one point
    stopflag= 0B
    if (max(abs(damp)) LT 1D-7 AND iteration GT 1) OR $
       (iteration GE maxiterate) then stopflag= 1B

; plot
    if keyword_set(qa) AND stopflag then begin
      ex_max_plot, weight,point,amp,mean,var,qa
    endif

; stop
  endrep until stopflag
  if keyword_set(qa) AND dimen GT 1 then device, /close
  return
end

