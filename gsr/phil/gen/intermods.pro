
function intermods,f1,f2,minfreq,maxfreq,maxorder,out,nf1,nf2
;
    maxcount=10000L
    out =fltarr(maxcount)
    nf1=fltarr(maxcount)
    nf2=fltarr(maxcount)
    f1l=(findgen(maxorder)+1)*f1
    f2l=(findgen(maxorder)+1)*f2
    last=0
;
; if just one freq, print out the harmonics and return
;
    if f2 le 0 then begin
        ind=where((f1l ge minfreq) and (f1l le maxfreq),count)
        if count gt 0 then begin
            last=count
            out[0:count-1]=f1l[ind]
            nf1=ind+1
            nf2=ind+1
        endif
        goto,done
    endif
;
; loop through to max order
;   take f1 - shift f2  +/-
;
    for i=0,maxorder-1 do begin
        if i gt 0 then begin
            a=abs(f1l-shift(f2l,i))
            b=abs(f1l+shift(f2l,i))
            c=abs(f2l-shift(f1l,i))
            d=abs(f2l+shift(f1l,i))
            a[0:i-1]=-1
            b[0:i-1]=-1
            c[0:i-1]=-1
            d[0:i-1]=-1
        endif else begin
            a=abs(f1l-f2l)
            b=abs(f1l+f2l)
            c=abs(f1l-f2l)
            d=abs(f1l+f2l)
        endelse
;       print,a
        inda=where((a ge minfreq) and (a le maxfreq),counta)
        indb=where((b ge minfreq) and (b le maxfreq),countb)
        indc=where((c ge minfreq) and (c le maxfreq),countc)
        indd=where((d ge minfreq) and (d le maxfreq),countd)
        if counta gt 0 then begin
            out[last:last+counta-1]  = a[inda]
            nf1[last:last+counta-1]  =   inda + 1 
            nf2[last:last+counta-1]  =   (inda + 1)-i
            if ((last + counta) ge maxcount) then goto,done
            last=last+counta
        endif
        if countb gt 0 then begin
            out[last:last+countb-1]  =   b[indb]
            nf1[last:last+countb-1]  =   indb + 1 
            nf2[last:last+countb-1]  =   (indb + 1)-i
            if ((last + countb) ge maxcount) then goto,done
            last=last+countb
        endif
        if countc gt 0 then begin
            out[last:last+countc-1]  =   c[indc]
            nf1[last:last+countc-1]  =   (indc + 1 )-i ; we took f2-f1 so switch
            nf2[last:last+countc-1]  =   (indc + 1 )
            if ((last + countc) ge maxcount) then goto,done
            last=last+countc
        endif
        if countd gt 0 then begin
            out[last:last+countd-1]  =   d[indd]
            nf1[last:last+countd-1]  =   (indd + 1 )-i 
            nf2[last:last+countd-1]  =   (indd + 1 )
            if ((last + countd) ge maxcount) then goto,done
            last=last+countd
        endif
    endfor
done:
    if last gt 0 then begin
        out =out[0:last-1]
        nf1=nf1[0:last-1]
        nf2=nf2[0:last-1]
    endif else begin
        out=''
    endelse

    return,last
end
