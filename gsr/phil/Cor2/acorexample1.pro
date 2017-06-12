;+
;NAME:
;acorexample1 - Examples using correlator routines.
;
;   Starting idl.
;   - To use the correlator routines you need to tell idl where to
;     look to get these procedures. You can do it manually each
;     time you run idl, or you can put it in an idl startup file.
;     Manually:
;       idl
;       @phil
;       @corinit
;     Using a idl setup file:
;       Suppose your home directory is ~jones.
;       create the file ~jones/.idlstartup
;       add the line        
;          @phil
;       to this file.
;       In your .cshrc file (if you run csh) add the line
;           setenv IDL_STARTUP ~/.idlstartup
;       You can then run idl with :
;           idl
;           @corinit 
;       You can also put any other commands in the startup
;       file that you want to be executed each time you 
;       start idl. My startup file contains:
;           !EDIT_INPUT=500
;           @phil
;       Note: if you are running the idl routines at a different site, 
;             replace @phil with the directory at your site.
;       
;0. MISC..
;   - to access a procedures documentation:
;     doc_library,'corplot'   .. complete documentation on routine.
;     or http://www.naic.edu/~phil .. cordoc ...
;   - ctrl-c:             
;     if you ctrl-c out of a routine, you may have to type retall to get
;     back to the main level (i'm stilll debugging some routines and they
;     don't all do it automatically).
;   - positining:
;     rew,lun                    .. rewind file 
;     print,posscan(lun,scan,rec).. position to scan and record
;   - generic routines:
;     idl routines that are not correlator specific are documented under
;     idl generic routines.
;
;1. ATTACH A FILE:  
;   openr,lun,'/share/olcor/corfile.22aug00.x101.1',/get_lun
;   free_lun,lun                 .. when you are done with the file
;
;2. LIST CONTENTS OF A FILE:
;   corlist,lun             .. this will rewind before listing.
;   corlist,lun,scan=scan   .. start listing at scan specified
;
;3. POSITION IN THE FILE:
;   scan=20100012   
;   rec = 1
;   print,posscan(lun,scan,rec)
;   Some routines also allow you to position to the scan with the
;   scan= keyword in the call (eg corget).
;
;4. INPUT A RECORD AND PLOT IT.
;   print,corget(lun,b)             .. the next record
;   print,corget(lun,b,scan=scan)   .. position to scan then get a rec.
;   corplot,b                       .. plot all the sbc.
;   or..
;   cornext,lun,b                   .. corget then corplot
;   use hor,h1,h2 .. ver,v1,v2 to ajust horizontal and vertical scales.
;
;5. INPUT AN ENTIRE SCAN AND PLOT IT.
;   print,corinpscan(lun,b)         .. input next scan, all records
;   corplot,b                       .. plot all sbc, all recs
;   corplot,b,off=.2                .. plot all sbc, all recs, strip plot with
;                                      .2 between recs.
;   corplot,b,m=1,off=.2            .. plot sbc 1, all recs, strip plot with
;                                      .2 between recs.
;
;   print,corinpscan(lun,b,/sum)    .. input next scan, return only average.
;   corplot,b                       .. plot summary rec only all sbc
;
;   print,corinpscan(lun,b,brecs,/sum,scan=scan)
;                                   .. position to scan, return average
;                                      rec (b) and individual recs (brecs).
;   corplot,b,m=1,pol=1             .. plot summary rec,sbc 1 , polA
;   corplot,b,m=2,pol=1,/over       .. overplot sbc2 same window (set hor
;                                      scale to include whole freq range).
;   corplot,brecs,/vel,m=4          .. plot sbc 4 vs vel, no offsets 
;
;6. PROCESS POSITION SWITCH WITH CAL RECORD FOLLOWING:
;   scan=20100034                   .. assume on position scan  
;   print,corposonoff(lun,b,t,cals,/sclcal,scan=scan).. input, scale to Kelvins
;   corplot,b                       .. plot (on/off-1) all sbc
;   help,t,/st                      .. print out t structure
;   print,t.src                     .. print src strength K pola,b each sbc
;   print,t.on                      .. print on  strength K pola,b each sbc
;   print,t.off                     .. print off strength K pola,b each sbc
;   help,cals,/st                   .. print out cals structure
;   print,cals.calval               .. print out cal values pola,b each sbc
;
;   print,corposonoff(lun,b,t,cals,bon,boff,/sclcal,scan=scan)
;                                   .. input,scale to Kelvins, also return
;                                      individual records bon,boff
;7. INTENSITY CALIBRATE STOKES DATA:
;   assume the src scan is 210200238 and is followed by a cal on off:
;   print,corstokes(lun,bsrc,bcal,scan=210200238,/han)
;
;8. accumulate, average data.
;       The routine coraccum() will accumulate data. It will sum records of a
;   scan or different scans. You can accumulate as many scans as you
;   want. The number of accumulations is kept in the b.b1.accum variable. 
;   If you call corplot with the accumulated variable, it will compute the 
;   average before plotting. 
;       The routine coravg() will average data. It will average an entire
;   scan, the output of coraccum, and/or it will average polarizations.
;   Suppose you have two on off position switches on the same source:
;
;   print,corposonoff(lun,b,t,cals,bon,boff,/sclcal,scan=scan)
;   coraccum,b,baccum,/new
;   corplot,baccum                  .. plot the first one
;   print,corposonoff(lun,b,t,cals,bon,boff,/sclcal)
;   coraccum,b,baccum               .. accumulate the second
;   corplot,baccum                  .. plot the average of the two.
;   bavg=coravg(baccum,/pol)        .. compute the average of accum
;                                      then average the polarizations.
;
;9. MAKE AN IMAGE OF INDIVIDUAL RECORDS.
;   input and make an image of a scan. assume you have already opened the
;   file.
;   scan=20100038L
;   image=corimgdisp(b,scan=scan,lun=lun) 
;   xloadct                         .. manipulate the color table
;
;10.Hardcopy
;   When idl makes a plot it sends it to only 1 device. The default is
;   the screen. To send the plot to a postscript file you need to
;   tell idl, and then make the plot. The output will then go only to
;   the file. The default filename is idl.ps
;   eg.
;    print,corget(lun,b)            .. get some data
;    corplot,b                      .. goes to the screen
;    ps                             .. switch to send to ps file
;    corplot,b                      .. outputs to file idl.ps
;    hardcopy                       .. flushes the buffer
;    x                              .. switch output to screen (xwindows).
;   
;   To make a color postscript file use:
;       pscol                       
;   ps and pscol can be passed a filename to send the output to a 
;   different file. The /fullpage option will plot on the entire page
;   rather than the top half:
;       ps,junk.ps,/fullpage       .. send to junk.ps, plot on full page
;       pscol,/fullpage            .. send to idl.ps, plot on full page.
;   Possible hardcopy problems:
;   - If the color poscript does not appear when you run ghostview, you
;     may need to reload the color table before plotting..
;       ldcolph  or ldcolph,/pscol
;   - If you send a color plot to a black and white printer, the solid lines
;     may look shaded.
;
;11. Plot total power vs za for all scans with more than 1 record.
;   You can read in all of the total power info from a file and then plot
;   the total power versus za for all scans with more than 1 record. This
;   can be used to verify that position switch (on,off) data is ok. The
;   curves for the on's and offs should have the same curvature.
;
;       nrecs=corpwrfile('/share/olcor/corfile',pwr)
;       corplttpza,pwr,horza=[10.,15.],/printscan
;
;   This will plot the data between 10 and 15 degrees za.  To make a
;   full page color hardcopy:
;       pscol,/fulllpage
;       corplttpza,pwr,ver1=[.7,1.8],/printscan
;       hardcopy
;       x
;   This plots all the data with the vertical scale for the upper plot set
;   to .7,1.8 . The data will be in the file idl.ps. You can look at it with
;       gv idl.ps   outside of idl.
;-
