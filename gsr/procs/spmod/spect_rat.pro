pro spect_rat, sp1, sp2, f, a, b, sig_a_b, xaxis, conrem=conrem, nozero=nozero

std1 = stddev(sp1[where(sp1 ne 0.)])
std2 = stddev(sp2[where(sp2 ne 0.)])

; where the fit isn't too off of 1.
wh = where( (sp1 ne 0.) and (sp2 ne 0.) and ((sp1 lt f*std1) and (sp2 lt f*std2) or ((sp2/sp1 gt 0.5) and (sp2/sp1 lt 2.0))))
          ;  sqrt((sp1/std1)^2+(sp2/std2)^2) gt 3.5
A1=0.
A2=0.
B1=0.
B2=0.
                                ; to get rid of continuum in each line
if (keyword_set(conrem)) then begin
    wh1 = where( (sp1 ne 0.) and (abs(xaxis) gt 512))
    wh2 = where( (sp2 ne 0.) and (abs(xaxis) gt 512))
    fitexy, xaxis[wh1], sp1[wh1], A1, B1, X_SIG=1. , Y_SIG=1.
    fitexy, xaxis[wh2], sp2[wh2], A2, B2, X_SIG=1. , Y_SIG=1.
endif
s1 = sp1[wh] - (A1 + B1*xaxis)[wh]
s2 = sp2[wh] - (A2 + B2*xaxis)[wh]

;avoid blanking everything
wh = where(sqrt((s1/std1)^2+(s2/std2)^2) gt 3.5, ct)

if ct ne 0 then begin
	s1(where(sqrt((s1/std1)^2+(s2/std2)^2) lt 3.5)) = 0.
	s2(where(sqrt((s1/std1)^2+(s2/std2)^2) lt 3.5)) = 0.
endif


if (keyword_set(nozero)) then begin
    s11 =s1
    s22 =s2
    s1 = s1(where(s22+s11 ne 0))
    s2 = s2(where(s22+s11 ne 0))
endif

FITEXY, s2, s1, A, B, X_SIG=1. , Y_SIG=1., sig_a_b

end
