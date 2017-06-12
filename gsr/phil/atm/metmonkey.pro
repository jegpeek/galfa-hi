;
function metmonkey,lun,numLoc,fbase,useCh,singleStep
;
;   istat:
;   1 - continue
;   2 - newfile,nextfile,  or rewind current file
;   3 - exit
;    

    ant=(useCh)?'ch':'dome'
    retstat=1

    print,'Cmd CurVal   function'
    lab=string(format=$
    '(" a ",a4,"      antenna ch, dome")',ant)
    print,lab
    lab=string(format=$
    '(" f  ",i3,"      move to new fileNum")',numLoc)
    print,lab
    print,' l           list all files'
    print,' n           next file (or quit if 1 file)'
    print,' q           to quit'
    print,' r           rewind current file'
;    print,lab
    lab=string(format=$
    '(" s  ",i3,"      single step 0,1")',singleStep)
    print,lab
    print,' otherkey    continue'
    inpstr=''
    read,inpstr
    toks=strsplit(inpstr,' ,',/extract)
    cmd=toks[0]

    case cmd of
;
;   new antenna
;
    'a': begin
         if n_elements(toks) ne 2 then begin
            print,'Enter a  ch/dome'
         endif else begin
            ch=strlowcase(strmid(toks[1],0,1))
            case ch of
                'd': useCh=0
                'c': useCh=1
               else: print,'enter a  ch or dome'
            endcase
         endelse
         end
;
;   new file num 
;
    'f': begin
         if n_elements(toks) ne 2 then begin
            print,'Enter f  fileNum..'
         endif else begin
            numLoc=long(toks[1])
            retStat=2
         endelse
         end
;
;       list filenums
;
    'l': begin
            fileSpec=fbase + '.*'
            a=findfile(filespec,count=count)
            if count gt 1 then print,a[0:count-1]
            if count gt 0 then begin
                istat=file_exists(a[count-1],size=size)
                lab=string(format='(a," size:",i10)',a[count-1],size)
                print,lab
            endif else begin
                print,'no files match:',fbase
            endelse
          end
    'n': begin
            numLoc=numLoc+1
            retStat=2
         end
    'q': begin
            retstat=3
         end
    'r': begin
            retStat=2
         end
;
;    	single step
;
    's': begin
         if n_elements(toks) ne 2 then begin
            print,'Enter s  0,1.. to turn single step off,on'
         endif else begin
            singleStep=(long(toks[1]) eq 0) ? 0 : 1
         endelse
         end
    else: begin
          end
    endcase
done:
    print,''
    return,retstat
end
