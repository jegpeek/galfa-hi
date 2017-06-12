pro dop_cor_spect, inspec, dopvel, centerfreq, crval1, outspec, freqs
;+
; NAME:
;   DOP_COR_SPECT
; PURPOSE:
;  To convert an un-doppler corrected spectrum that comes out of the 
;  galspect machine (typically 7679 elements) into a doppler corrected spectrum,
;  with 8192 elements. 
;
; CALLING SEQUENCE:
;   dop_cor_spect, inspec, dopvel, outspec
;
; INPUTS:
;   INSPEC     -- The input spectrum
;   DOPVEL     -- The velocity of the telescope wrt the source (i.e.
;                 positive if the telescope is receeding from the
;                 source, v = dx/dt)
;   CENTERFREQ -- The desired rest frequency of the center of the 
;                 spectrum in hz, typically 1420405750 Hz 
;   CRVAL1     -- The earth-frame frequency the center bin is recording
;                 in Hz
;
; KEYWORD PARAMETERS:
;   NONE
;
; OUTPUTS:
;   OUTSPEC -- The corrected spectrum, in LSR.
;   FREQS   -- The x axis, i.e. bin centers for each frequency in
;              the corrected spectrum.
;
; MODIFICATION HISTORY:
;
;       Written Sat Oct 30
;       12:04:26 2004, Josh Goldston, goldston@astro.berkeley.edu
;
;-
 
hzperchn = 100.d/14d/8192d*1d6
c = 2.99792458d5
freqshift = centerfreq*(sqrt((1.+dopvel/c)/(1.-dopvel/c))-1.)-centerfreq+crval1
Chnshift = freqshift/hzperchn 
outspec = interpolate( inspec, findgen(8192)-4096+n_elements(inspec)/2.-chnshift, missing=0)
freqs = (findgen(8192)-4095.5)*hzperchn+centerfreq
end
