;+
;NAME:
;yymmddtojulday - convert yymmdd to julian day
;
;SYNTAX: julday=yymmddtojulday(yymmdd)
;ARGS:
;      yymmdd: long    to convert
;RETURNS:
;      julday: double  julian day
;
;DESCRIPTION:
;   Convert from yymmdd to julian day.
;-
function yymmddtojulday,yymmdd

	yr=yymmdd/10000L
	case 1 of 
	 (yr lt 50) :yr=yr+2000
	 (yr ge 50) and (yr lt 100): yr=yr+1900
	 else : yr=yr
	endcase
	mm=yymmdd/100 mod 100
	dd=yymmdd mod 100
	return,julday(mm,dd,yr,0,0,0)
end

