
function dirty_spectrum, t, signal
; Given a time and signal, return a dirty spectrum
;
; CALLING SEQUENCE: ds = dirty_spectrum(t, s)
;
; INPUTS:
;  t => x-value at which input sig is sampled
;  signal => amplitude of input sig
;
; RETURN VALUE: structure of frequency and signal of dirty spectrum
;     spec_freq : frequencies at which dirty spectrum is sampled.
;     spec : signal of dirty spectrum
;     beam_freq : frequencies at which dirty beam is sampled.
;     beam : signal of dirty beam
;  


nn = n_elements(t)

t_sample = t[1] - t[0]
nu_sample = 1.D/t_sample
f_max = .5D*nu_sample

T_max = max(t) - min(t) ;; maximum time seperation


delta_nu = .5D/ T_max ;; delta nu for dirty spectrum
                      ;; Note that this value is half of typical delta nu
                      ;; which means we are oversampling.
                      ;; And amplitude of resulting dirty spectrum
                      ;; nned to be corrected.


J = ceil(f_max / delta_nu) + 1 ;; nr of channels in resulting dirty spectra.


;; f_j1 : frequencies at which DIRTY SPECTRUM will be sampled.

; f_j1 = (dindgen(2*J + 1) - J)*delta_nu ;; jjlee's old version
; f_j1 = (dindgen(J) - J/2)*2.D*delta_nu ;; carl's new version
;                                           (This is correct when delta_nu
;                                           and J is half of current value)

f_j1 = (dindgen(2*J+1) - J)*delta_nu ;; jj's revised one

dft, t, signal, f_j1, spec

;; f_j2 : frequencies at which DIRTY BEAM will be sampled.
f_j2 = (dindgen(4*J+1) - 2*J)*delta_nu


s = dblarr(n_elements(signal))+1.
dft, t, s, f_j2, beam

beam = beam / max(abs(beam)) ;; normalizing beam such that ;
;				its peak amplitude is 1.

return, CREATE_STRUCT('spec_freq', f_j1, 'spec', $
	spec*T_max*delta_nu, 'beam_freq', f_j2, 'beam', beam*T_max*delta_nu)

;; T_max*delta_nu is mulitplied to make sure "ift(ft) = 1"
;; It is because we are using too much data points.

          end


