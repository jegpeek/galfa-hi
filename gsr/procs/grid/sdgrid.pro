
pro sdgrid_c_do_sparse_mult, ngrid, ndata, nchannels, $
                             sprs_data, data, cube, $
                             imsizex, imsizey, crange, stokes, $
                             DOUBLE=double
compile_opt idl2, hidden
; THIS ROUTINE IS SIMPLY A WRAPPER FOR JOSH GOLDSTON'S C++ PROGRAMS
; THAT UTILIZE THE NIST_SPBLAS SPARSE MATRIX LIBRARY, WHICH, UNLIKE
; IDL, CAN HANDLE RECTANGULAR SPARSE MATRICES.

; DETERMINE THE SHARED/DYNAMIC LIBRARY EXTENSION FOR THIS SYSTEM...
ext = (!version.arch eq 'ppc') ? '.dylib' : '.so'

libfile = 'smm'+(keyword_set(DOUBLE) ? 'd' : '')+ext

; CHECK FOR THE SDGRID_DIR ENVIRONMENT VARIABLE...
libpath = getenv('SDGRID_DIR')
if (strlen(libpath) eq 0) then begin
   ; LOOK FOR THE SDGRID C++ SHARED OBJECT FILE IN THE IDL !PATH AND THE
   ; CURRENT DIRECTORY...
   file = file_which('smm'+ext, /INCLUDE_CURRENT_DIR)
   if (strlen(file) gt 0) $
      then setenv, 'SDGRID_DIR='+file_dirname(file) $
      else message, libfile+' can''t be found. Possible solutions: '+$
                    'first find the directory where '+libfile+' resides; '+$
                    'next, try (a) starting IDL in this directory; (b) '+$
                    'setting the environment variable SDGRID_DIR to this '+$
                    'directory, (c) adding this directory environment '+$
                    'variable IDL_PATH.  If none of these works, '+$
                    'make sure '+libfile+' was compiled without any errors.'
endif

; RUN THE C++ CODE FOR EACH POLARIZATION...
for stk = 0, stokes-1 do begin

   ; INITIALIZE THE OUTPUT DATA CUBE...
   C = keyword_set(DOUBLE) ? $
       dblarr(ngrid,nchannels) : $
       fltarr(ngrid,nchannels)

   ; CALL THE C++ WRAPPER...
   io = keyword_set(DOUBLE) $
      ? call_external(getenv('SDGRID_DIR')+'/smmd'+ext, '_Z4smmdiPPc', $
                      long(ngrid), long(ndata), long(nchannels), $
                      N_elements(sprs_data), $
                      long(sprs_data.row), $
                      long(sprs_data.col), $
                      double(sprs_data.weight), $
                      double(data[*,crange[0]:crange[1],stk]), $
                      double(C), $
                      /B_VALUE) $
      : call_external(getenv('SDGRID_DIR')+'/smm'+ext, '_Z3smmiPPc', $
                      long(ngrid), long(ndata), long(nchannels), $
                      N_elements(sprs_data), $
                      long(sprs_data.row), $
                      long(sprs_data.col), $
                      float(sprs_data.weight), $
                      float(data[*,crange[0]:crange[1],stk]), $
                      float(C), $
                      /B_VALUE)

   ; ADD THIS TO THE FINAL CUBE...
   cube[0,0,0,stk] = reform(C,imsizex,imsizey,nchannels)

endfor
end; sdgrid_c_do_sparse_mult

function sdgrid_idl_get_sparse, sprs_data, imsizex, imsizey, ngrid, ndata, $
                                DOUBLE=double
compile_opt idl2, hidden
; THIS IS THE "OLD WAY" OF USING IDL'S PROPRIETARY SPARSE MATRIX
; ROUTINES (WHICH ARE JUST THE NUMERICAL RECIPES ALGORITHMS).  THESE
; REQUIRE SQUARE SPARSE MATRICES AND ARE HORRIBLE...
; IDL HAS A SENSELESS REQUIREMENT THAT THE SPARSE MATRIX BE SQUARE, SO WE
; NEED TO SET THE SIZE OF THE MATRIX TO THE LARGER OF THE NUMBER OF GRID
; POINTS OR THE NUMBER OF DATA...
sparse_matrix = sprsin([sprs_data.col], $
                       [sprs_data.row], $
                       [sprs_data.weight], $
                       ngrid>ndata, $
                       DOUBLE=keyword_set(DOUBLE))
return, sparse_matrix
end; sdgrid_idl_get_sparse

pro sdgrid_idl_do_sparse_mult, data, sparse_matrix, cube, stokes, $
                               ngrid, nmax, crange, nchannels, verb, $
                               DOUBLE=double
compile_opt idl2, hidden

; GO THROUGH EACH STOKES PARAMETER...
for stk = 0, stokes-1 do $
; GO THROUGH EACH VELOCITY CHANNEL...
for i = crange[0], crange[1] do begin
   ; BECAUSE THE SPARSE MATRIX IS SQUARE, IF THERE ARE MORE GRID POINTS
   ; THAN DATA POINTS, THE DATA VECTOR WILL NEED TO BE THE SIZE OF THE
   ; TOTAL NUMBER OF GRID POINTS WHERE THE REMAINDER OF THE VECTOR IS
   ; BUFFERED WITH ZEROS...
   data_vector = keyword_set(DOUBLE) ? dblarr(nmax) : fltarr(nmax)
   data_vector[0] = data[*,i,stk]
   ; DO SPARSE MATRIX MULTIPLICATION...
   sprs_product = sprsax(sparse_matrix, temporary(data_vector), $
                         DOUBLE=keyword_set(DOUBLE))
   if (nmax gt ngrid) then $
      sprs_product = sprs_product[0:ngrid-1]
   gi = i - crange[0]
   cube[0,0,gi,stk] = cube[*,*,gi,stk] + temporary(sprs_product)
   if ((verb and 4b) ne 0) then $
      print, 100*float(stk*nchannels+gi)/(stokes*nchannels-1), $
             format='($,"Progress: ",I4,"%",%"\R")'
endfor
end; sdgrid_idl_do_sparse_mult

; THESE CONVOLUTION FUNCTIONS ARE LIFTED FROM THE AIPS FORTRAN CODE AND THE
; PARAMETERS ARE BEST ESTIMATES AS EXPLAINED IN CHAPTER 10 OF THE AIPS
; COOKBOOK AND LISTED IN THE TABLE OF MANGUM, EMERSON, & GREISEN

;!!!!!!!!!!!!!!!!!!!
; PHIL USES WIDTH, WHICH IS EQUIV TO FWHM/3 BELOW
; WELL, CLOSE, DEFAULT IS FWHM/2.35842, SO HIS FUNCTIONS ARE NOT QUITE
; EQUIVALENT TO AOGRIDZALFA AND AIPS...

function sdgrid_pillbox, diff, fwhm
compile_opt idl2, hidden
return, replicate(1.0,N_elements(diff))
end; sdgrid_pillbox

function sdgrid_sinc, diff, fwhm
compile_opt idl2, hidden
parm2=1.14*fwhm/3. ; in arcmin
;parm2=1.14*fwhm ; in arcmin
x=diff/parm2     ; in radians
mask = x eq 0.0
return, mask + sin(!dpi*x)/(!dpi*x + mask) ; pure sinc
end; sdgrid_sinc

function sdgrid_gauss, diff, fwhm
compile_opt idl2, hidden
minvalue = (machar(DOUBLE=(size(diff,/TYPE) eq 5))).minexp
;arg = 2.7725887*(diff/fwhm)^2  ; gaussian
arg = 5.5451774*(diff/fwhm)^2  ; exponential, like AIPS/AOGRIDZILLA
mask = -arg/alog(2) gt minvalue
return, mask * exp(-mask*arg)
end; sdgrid_gauss

function sdgrid_bessel, diff, fwhm
compile_opt idl2, hidden
; AIPS BESSJ1() = IDL BESELJ(,1)
parm2=1.55*fwhm/3.
parm3=2.52*fwhm/3. 
minvalue = (machar(DOUBLE=(size(diff,/TYPE) eq 5))).minexp
xb = diff/parm2
xg = (diff/parm3)^2
maskb = xb eq 0.0
maskg = -xg/alog(2) gt minvalue
;return, 2d0 * (maskb*0.5 + beselj(!dpi*xb, 1, /DOUBLE) / $
return, 2d0 * (maskb*0.5 + beselj(!dpi*xb, 1) / $
               (!dpi*xb + maskb)) * $
        maskg * exp(-maskg*xg)
end; sdgrid_bessel

pro sdgrid, data, $
            lon, lat, $
            ;lon0, lat0, $
            fwhm, $
            cube, $
            CRVAL=crval, $
            IMSIZE=imsize, $
            GRIDLON=gridlon, GRIDLAT=gridlat, $
            ARCMINPERPIXEL=arcMinPerPixel, $
            FIELDCEN=fieldCen, $
            IMCEN=imcen, $
            PROJECTION=projection, $
            GRIDFUNCTION=gridfunc, $
            MAXRADARCMIN=maxRadArcmin, $
            STOKES=stokes, $
            SQUARE=square, $
            CRANGE=crange, $
            MINWEIGHT=minweight, $
            WCUTOFF=wcutoff, $
            NONORMALIZE=nonormalize, $
            NODATA=nodata, $
            WEIGHT=weight, $
            DOUBLE=double, $
            VERBOSE=verbose, $
            SPARSEIN=sparsein, $
            SPARSEOUT=sparseout, $
            _REF_EXTRA=_extra, $
            ; ONLY FOR TESTING...
            ;OFFSET=offset, $
            PLOTWATCH=plotwatch, $    ; WATCH THE SUPPORT CELLS
            NWMAP=nwmap, $            ; MAP OF # OF WEIGHTS
            MINDISTMAP=mindistmap,$   ; MAP OF MINIMUM DIST FROM GRIDPOINT
            CPP=cpp,$                   ; TEST OUT C++ CODE...
			QUIET=quiet
;+
; NAME:
;       SDGRID
;
; PURPOSE:
;       Grids single-dish radio telescope data.
;
; DESCRIPTION:
;       A regularly-gridded data cube is produced from an input array of
;       single-dish radio telescope data (Arecibo 300m, GBT 100m, Kitt Peak
;       12m).  It is often the case that single-dish data are not taken on
;       a regular grid.  The method is to take data at non-regular
;       positions, project them onto a plane using one of the many standard
;       FITS projections specified by Calabretta & Greisen (2002, A&A, 395,
;       1077), convolve them with a user-specified convolution function and
;       resample the results on a regular grid.  Selecting the correct
;       keyword inputs can be a challenge; read the documentation carefully
;       (especially the KEYWORDS, EXAMPLES and NOTES sections) to get an
;       understanding of how this routine can be used in various ways.
;
; CALLING SEQUENCE:
;       SDGRID, data, lon, lat, lon0, lat0, fwhm, cube [, 
;               IMSIZE=[imsizex,imsizey] ] [, STOKES=scalar] [, 
;               CRANGE=[cmin,cmax] ]  [,
;               ARCMINPERPIXEL=scalar] [,
;               GRIDLON=variable, GRIDLAT=variable] [, MINWEIGHT=scalar] [,
;               PROJECTION=string] [, NODATA=scalar] [,
;               /SQUARE] [, /NONORMALIZE] [,
;               WEIGHT=variable] [, SPARSEIN=variable] [,
;               SPARSEOUT=variable] [, 
;               /DOUBLE]  [, VERBOSE=scalar]
;
; INPUTS:
;       data - data to be gridded.  This is an array of temperatures or
;              flux densities and can have either one, two, or three
;              dimensions.  It is up to the user to make sure that the
;              order of the dimensions is [POSITION, SPECTRUM,
;              POLARIZATION].  For a very detailed explanation, see the
;              NOTES section below.
;       lon - the corresponding longitude for each position in the DATA
;             array, measured in DEGREES.  This is a vector and must have
;             the same number of elements as the first dimension of the
;             DATA input array.
;       lat - the corresponding latitude for each position in the DATA
;             array, measured in DEGREES.  This is a vector and must have
;             the same number of elements as the first dimension of the
;             DATA input array.
;       lon0 - the central longitude of the projection in degrees, a
;              scalar.  It is assumed that this is the center of the grid
;              unless the IMCEN keyword is set.
;       lat0 - the central latitude of the projection in degrees, a scalar.
;              It is assumed that this is the center of the grid unless the
;              IMCEN keyword is set.
;       fwhm - the full width at half maximum (FWHM) of the telescope in
;              arcminutes, a scalar.
;
; KEYWORD PARAMETERS:
;       IMSIZE - a two-element vector containing the number of pixels in
;                the final grid, the first value being the number in the
;                horizontal direction and the second being the number in
;                the vertical direction.

;       ACRMINPERPIXEL = the distance between pixels in the horizontal and
;                        vertical direction for the output grid.  This is
;                        given in arcminutes and must be a scalar.  The
;                        default value is FWHM/4.  

;       GRIDLON = if the ARCMINPERPIXEL keyword is set, the longitude
;                 values of the output grid will be returned in DEGREES.
;                 This will be a vector of size IMSIZE[0].  The horizontal
;                 grid positions can be passed into SDGRID via this
;                 keyword, but if this is done, the user *must not* set the
;                 ARCMINPERPIXEL keyword.  There will also be no need to
;                 set the IMSIZE keyword as the grid size will be
;                 determined via the GRIDLON and GRIDLAT keywords. 
;                 Obviously, if GRIDLON is used to input the horizontal
;                 grid values, GRIDLAT must also be specified.

;       GRIDLAT = if the ARCMINPERPIXEL keyword is set, the latitude values
;                 of the output grid will be returned in DEGREES.  This
;                 will be a vector of size IMSIZE[1].  The vertical grid
;                 positions can be passed into SDGRID via this keyword, but
;                 if this is done, the user *must not* set the
;                 ARCMINPERPIXEL keyword.  There will also be no need to
;                 set the IMSIZE keyword as the grid size will be
;                 determined via the GRIDLON and GRIDLAT keywords. 
;                 Obviously, if GRIDLAT is used to input the vertical grid
;                 values, GRIDLON must also be specified.

;       PROJECTION = a three-letter FITS code for map projection. See
;                    Calabretta & Greisen 2002, A&A, 395, 1077 for details
;                    about each projection. The projection is done by the
;                    Goddard routine WCSSPH2XY.PRO. The deafult value is
;                    DEF, which is equivalent to CAR.  Possible values are:
;
; FITS  Name                       Comments
; code
; ----  -----------------------    -----------------------------------
;  DEF  Default = Cartesian
;  AZP  Zenithal perspective       PV2_1 required
;  TAN  Gnomic                     AZP w/ mu = 0
;  SIN  Orthographic               PV2_1,PV2_2 optional
;  NCP  Noth Celestial Pole        PV2_2 = cot(dec)
;  STG  Stereographic              AZP w/ mu = 1
;  ARC  Zenithal Equidistant
;  ZPN  Zenithal polynomial        PV2_0, PV2_1....PV2_20 possible
;  ZEA  Zenithal equal area
;  AIR  Airy                       PV2_1 required
;  CYP  Cylindrical perspective    PV2_1 and PV2_2 required
;  CAR  Cartesian
;  MER  Mercator
;  CEA  Cylindrical equal area     PV2_1 required
;  COP  Conical perspective        PV2_1 and PV2_2 required
;  COD  Conical equidistant        PV2_1 and PV2_2 required
;  COE  Conical equal area         PV2_1 and PV2_2 required
;  COO  Conical orthomorphic       PV2_1 and PV2_2 required
;  BON  Bonne's equal area         PV2_1 required
;  PCO  Polyconic
;  SFL  Sanson-Flamsteed
;  PAR  Parabolic
;  AIT  Hammer-Aitoff
;  MOL  Mollweide
;  CSC  Cobe Quadrilateralized     convergence of inverse is poor
;       Spherical Cube
;  QSC  Quadrilateralized 
;       Spherical Cube
;  TSC  Tangential Spherical Cube
;  SZP  Slant Zenithal Projection   PV2_1,PV2_2, PV2_3 optional

;       GRIDFUNCTION = this keyword is set to a scalar string specifying
;                      the name of the convolution function that the data
;                      around each grid point will be convolved with.  The
;                      current options are:
;                      'tophat'  : a tophat function
;                      'gauss'   : a Gaussian
;                      'sinc'    : a sin(x)/x pattern
;                      'bessel'  : a first-order Bessel function times a
;                                  Gaussian
;                       AIPS also has a SINC*GAUSS and Spherical Wave
;                       functions.  Also, it strongly seems like AIPS and
;                       the AOGRIDZILLA code were using exponentials and
;                       calling them Gaussians.  The effect of this is that
;                       the effective FHWM of the final gridded data is
;                       narrower than one would be lead to believe.  The
;                       convolving functions (should) match those of the
;                       AIPS/AOGRIDZILLA variety.  This needs to be
;                       thoroughly checked and some thought needs to go
;                       into their improvement.

;       MAXRADARCMIN = the maximum radius around each grid point for which
;                      data will be allowed to contribute, a scalar
;                      quantity measured in arcminutes.  If not set, the
;                      default value is the FWHM.  If set too small, very
;                      few data points will contribute to each grid point
;                      and the final map will be missing information.  If
;                      set too large, the total number of contributions to
;                      all the grid points will be extrememly large and
;                      will slow down the sparse matrix storage and
;                      algebra.  This can be avoided by setting the
;                      MINWEIGHT keyword appropriately.

;       IMCEN = a two-element vector specifying the longitude and latitude
;               of the center of the current grid.  Both the longitude and
;               latitude must be specified in degrees.  This keyword is
;               provided in the case that the user needs to stitch multiple
;               grids together; here the input lon0 and lat0 values will be
;               the projection center and IMCEN will specify the
;               coordinates of the center of the current grid.  See EXAMPLE
;               section to see how this might be used. 

;       /DOUBLE - if set, then perform all computations and return all
;                 values in double precision.

;       CRANGE = a two-element vector that specificies the channel range to
;                consider in the spectral dimension.  The obvious
;                considerations for this keyword are that (a) there needs
;                to be a spectral dimension in the DATA array, (b) the
;                values must be greater than or equal to 0 and less than
;                the number of spectral channels, (c) CRANGE[0] must be
;                less than or equal to CRANGE[1].

;       MINWEIGHT = the minimum weight that will be considered. If not set,
;                   the default value is 0.001.

;       STOKES = the number of Stokes parameters (I/Q/U/V), polarizations
;                (X/Y, L/R), or polarization products (XX/YY/XY/YX,
;                /LL/RR/LR/RL) that the input data array contains.  Sane
;                values for this keyword are 1-4.  If not set, it is
;                assumed to be 1 unless the DATA array is 3-dimensional, in
;                which case the number of polarizations is the number of
;                elements in the 3d dimension.

;       NODATA = set this to the value that will be assigned to positions
;                in the final grid that contain no data.  The default value
;                is IEEE Not-a-Number.  If the /NONORMALIZE keyword is set,
;                the empty grid positions retain a value of zero and this
;                keyword is not used.

;       WEIGHT = set this keyword to a named variable that will receive a
;                2-dimensional array of total convolved weights for each
;                final grid point.  The array will be of single-precision
;                floats unless the /DOUBLE keyword is set, in which case it
;                will be double-precision.  If the SPARSEIN keyword is set,
;                the WEIGHT keyword must be set to an array of weights
;                passed out of SDGRID via this keyword in a previous call
;                to SDGRID (see SPAREIN for more details).

;       /SQUARE - if set, the region around each grid point in which data
;                 will be searched for will be a square with a side of
;                 length 2*maxRadArcmin.  If not set, the default is to use
;                 a circular region around each grid point of radius
;                 maxRadArcmin.

;       SPARSEOUT = set this keyword to a named variable that will receive
;                   an array of structures storing the row, column and
;                   weight for each element in the sparse matrix used to
;                   compute the final gridded data set.  This can then be
;                   passed into SDGRID again via the SPARSEIN keyword. The
;                   only scenario in which this is useful is if multiple
;                   calls to SDGRID are made using the same final grid
;                   positions and the same input data positions; really,
;                   the only feasible examples are these: (a) the user
;                   decides to grid multiple polarizations from the same
;                   data set separately; (b) the user decides to grid
;                   separate ranges of velocity/wavelength/frequency
;                   separately (perhaps there are two ranges of channels
;                   with interesting spectral lines and a whole lot of
;                   nothing in between); (c) the user grids a spectral cube
;                   and then wants to grid continuum data taken at the very
;                   same positions (perhaps zero-level offsets to the
;                   spectal line cube).  An error will occur if the user
;                   specifies both SPARSEOUT and SPARSEIN.

;       SPARSEIN = set this keyword to an array of structures containing
;                  the sparse matrix information passed out of SDGRID via
;                  the SPARSEOUT keyword.  See SPARSEOUT for a description
;                  of when this might be useful. An error will occur if the
;                  user specifies both SPARSEIN and SPARSEOUT.  It is also
;                  mandatory to pass in the the total convolved weights for
;                  each gridpoint via the WEIGHT keyword (this will have
;                  been passed out via the WEIGHT keyword in the original
;                  call to SDGRID).

;       /NONORMALIZE - if this keyword is set, the output cube is not
;                      normalized by the sum of the weights.  If this
;                      keyword is set, the user needs to pass out the
;                      weight array via the WEIGHT keyword in order to
;                      properly normalize the data later.

;       VERBOSE = this keyword controls the degree of verbiage that the
;                 routine reports back to the user.  It is set bitwise. 1:
;                 basic information, 2: progress reports, 4: time updates,
;                 8: values of useful variables are displayed; 16: memory
;                 usage is reported along the way.  To show memory, time
;                 updates and basic info we set the keyword to (16+4+1)=21.
;                 For maximum information, set to 31.  For silent
;                 operation, set to 0.

;       WCUTOFF = TBD
;
; OUTPUTS:
;       cube - the gridded data set, an array of single-precision floats,
;              unless the /DOUBLE keyword is set, in which case the results
;              are double-precision floats.  The number of dimensions in
;              the output cube will be equivalent to that of the input DATA
;              array with the caveat that any degenerate dimensions will be
;              removed.  I.e., the DATA array may be 3-dimensional, but if
;              CRANGE were set to [1024,1024] then the output cube will
;              have only one element in the 2nd dimension.  This output
;              cube will be returned as a 2-dimensional array.  For more
;              examples, see the EXAMPLES and NOTES sections below.
;
; COMMON BLOCKS:
;       None.
;
; SIDE EFFECTS:
;       Possibilities:

;       (1) User can run out of memory if requested grid size is too large
;           or input data set is too large.
;       (2) If a really large grid or data set is passed in, IDL will call
;           the NIST BLAS Sparse Matrix C++ library.  If the user hasn't
;           compiled this (correctly) for the current system, the code will
;           crash.
;       (3) The user might specify a projection that requires extra
;           keywords to be passed to WCSSPH2XY.  If the keywords are not
;           sent into SDGRID, WCSSPH2XY will crash.  See documentation for
;           WCSSPH2XY if thinking about using complicated projections.
;
; RESTRICTIONS:
;       The input DATA variable must be 1-3 dimensional and must have its
;       dimensions arranged in the following order:
;       [POSITION, SPECTRUM, POLARIZATION]
;       See NOTES below for more details.
;
;       This code relies on C++ code when the input data or the output grid
;       become extremely large (how large? Josh?).
;
; PROCEDURE:
;
;
;
; EXAMPLE:
;

; Right now the stuff below is just baloney... there are no useful examples
; here yet.
;

; IN EXAMPLES, CAN TALK ABOUT PRE-PROCESSING THE INPUT DATA...
; THE INPUT DATA CAN BE OF NUMEROUS DIMENSIONS:
;NDIM NPOL  POSN  VELO  DESCRIPTION
; 1    1    POS    1    CONTINUUM MAP, ONE POLN
; 2    1    POS    1         "
; 2    1    POS/T  1         "
; 2    1    X/Y    1         "
; 2  1/2/4  POS    1    CONTINUUM MAP, MULTIPLE POLNS
; 2    1    POS    >1   SPECTRAL CUBE, ONE POLN
; 3    1    X/Y    >1        "
; 3    1    X/Y/T  1    MULTIPLE CONTINUUM MAPS, 1 POLN
; 3    1    POS/T  >1   MULTIPLE SPECTRAL CUBES, 1 POLN
; 3  1/2/4  POS    >1   SPECTRAL CUBE, MULTIPLE POLNS
; 3  1/2/4  X/Y    1    CONTINUUM MAP, MULTIPLE POLNS
; 4    1    X/Y/T  >1   MULTIPLE SPECTRAL CUBES, 1 POLN
; 4  1/2/4  POS/T  >1   MULTIPLE SPECTRAL CUBES, MULTIPLE POLNS
; 4  1/2/4  X/Y/T  1    MULTIPLE CONTINUUM MAPS, MULTIPLE POLNS
; 5  1/2/4  X/Y/T  >1   MULTIPLE SPECTRAL CUBES, MULTIPLE POLNS

; AS A COMPLEX EXAMPLE, LET'S SAY THERE ARE THREE CUBES OF THE
; FOLLOWING DIMENSIONS:
; CUBE1 => [2,33,33,2048]
; CUBE2 => [2,20,10,2048]
; CUBE3 => [2,40,54,2048]
; WE CAN COMBINE THESE CUBES TO PASS INTO THIS ROUTINE IN THE FOLLOWING
; WAY...
; DATA = [[reform(cube1,[2,33l*33l,2048])],$
;           [reform(cube2,[2,20l*10l,2048])],$
;           [reform(cube3,[2,40l*54l,2048])]]
; IDL> HELP, DATA
; DATA          FLOAT     = Array[2, 3449, 2048]


; If you have an array that stores the velocity for your spectra and you
; know the range of velocities that you are interested in, you can find the
; corresponding channels using TABINV:
; tabinv, velocity, [v1,v2], crange, /FAST
;
; NOTES:
;       In order to make this routine indpendent of telescope, the user
;       must pass in a data set that is divorced from each
;       observatory's data structure.  Therefore, the data that will
;       be passed into SDGRID are simply the following:
;       (A) A DATA array that is simply an array of temperature or flux
;           density values.  This array can be of 1-3 dimensions.  The
;           dimensions must be ordered in a very specific way:
;           (1) Dimension 1 must correspond to the position of the
;               telescope (or you may think of this dimenstion as
;               corresponding to time since you might have mapped the same
;               exact positions on three consecutive nights; in this case
;               each element in the first dimension may not be unique in
;               position, but it is in time).  As a complex example, let's
;               consider the ALFA multifeed system on Arecibo.  There are 7
;               feeds producing data for each integration.  The telescope
;               is changing position with time.  For a pointed map of 20
;               longitude positions and 10 latitude positions, the total
;               number of spectra produced (for one polarization) is 20 x
;               10 x 7 = 1400.  Therefore the first dimension of the DATA
;               array would be of length 1400.  ASIDE: the IDL function
;               REFORM() is useful for assembling the input DATA array (see
;               the EXAMPLE section).
;           (2) Dimension 2 must correspond to a spectrum (measured in
;               wavelength, velocity, or frequency; it doesn't matter.)  In
;               the case of a continuum map, there is only one spectral
;               channel, so the user is allowed to pass in a DATA array of:
;               (a) 3 dimensions with size [NPOSITIONS,1,NSTOKES]
;               (b) 2 dimensions with size [NPOSITIONS,NSTOKES], but in
;                   this case, the STOKES keyword *must* be specified.
;               (c) 1 dimension with size [NPOSITIONS]
;           (3) Dimension 3 must correspond to polarization.  Depending on
;               backend, a telescope might produce two polarizations (X/Y
;               or L/R), four auto- and cross-correlated polarizations
;               (XX/XY*/YX*/YY; LL/LR*/RL*/RR), or four calibrated Stokes
;               parameters (I/Q/U/V).  Therefore, the user can pass in as
;               many polarization data as necessary, or only grid a single
;               polarization.
;       (B) A LONGITUDE array that contains the longitude values for each
;           position in the DATA array.  The input must be an array with a
;           length matching that of the first dimension of the DATA array.
;           The longitudes must also be measured in degrees.  There is no
;           restriction on which coordinate system the data are measured in
;           or gridded to, so the longitude value can be Right Ascension,
;           Galactic longitude, Azimuth, etc.
;       (C) A LATITUDE array that contains the latitude values for each
;           position in the DATA array.  The input must be an array with a
;           length matching that of the first dimension of the DATA array.
;           The longitudes must also be measured in degrees.  The
;           longitudes can be either Declination or Galactic latitude.
;           There is no restriction on which coordinate system the data are
;           measured in or gridded to, so the latitude value can be
;           Declination, Galactic latitude, Elevation, Zenith Angle, etc.
;
;       No averaging of polarizations will be done in SDGRID.  This should
;       be done either before or after by the user, properly weighting each
;       polarization.
;
;       SDGRID assumes the spectral axis of each spectrum is identical.
;
;       There are two scenarios for which we have designed SDGRID to be
;       called repeatedly:
;
;       (1) The user might have huge data sets with multiple polarizations
;       that she wants to grid separately to save some memory, or perhaps
;       there are multiple nights of data each with the same exact number
;       of integrations and measured at the same positions on the sky; in
;       these particular situations the user might wish to run sdgrid
;       multiple times but avoid calculating the sparse matrix and weight
;       matrix since they will be identical. In this case the user would
;       need to pass in both the sparse matrix and the weight array.
;       Another case where this might be useful is if the user has
;       ridiculously high spectral resolution and would like to grid
;       subsets of the total channel range independently.
;
;       (2) The user might have multiple sets of data that she wants to be
;       mapped to the same grid.  In this case each data set is very
;       different; perhaps the data are too large to have them all in
;       memory at once.  In this case SDGRID could be run many times with
;       the same input parameters, but the sparse matrix and weight matrix
;       will be different for each data set.  In this case we would not
;       want to normalize the final cube, so we would set the /NONORMALIZE
;       keyword.  After each call to SDGRID, the output cube would be added
;       to the cumulative cube and the weight matrix would be added to the
;       cumulative weight matrix.  After the final call to SDGRID, the user
;       could then normalize the cube on her own.

;       Until looked into, there is a whole load of baggage associated with
;       using bizarro projections when calling WCSSPH2XY.  That routine
;       will let you know when it's not receiving the proper keywords
;       for a particular projection.  These keywords can be passed via the
;       _REF_EXTRA mechanism.  That is, if you need to set the LATPOLE
;       keyword, just send it to SDGRID and it will get passed in, no
;       problem.  What needs to be done though, someday, is to set up
;       default extra keywords for each projection that needs them, and
;       have them passed on.  Or maybe not.  Maybe we should assume that if
;       someone wants a bizarro projection, they should have a copy of the
;       Calabretta and Greisen paper in front of them and therefore know
;       which keywords are necessary.
;
;       This routine began as a way to make a faster, more flexible version
;       of the Arecibo gridding software suite that was written by Snezana
;       Stanimirovic, Phil Perillat and Josh Goldston.  It also
;       incorporates features of the SDGRD AIPS task (see chapter 10 of the
;       AIPS cookbook).
;
; PROCEDURES CALLED:
;       WCSSPH2XY, WCS_ROTATE, DELVARX
;
; TO-DO LIST:
;       * Implement C++ code
;         * explain makefile
;         * warn about using same .so files on different OSes
;       * Max difference btwn IDL/C++ is 1E-15 (DOUBLE); 1E-17 (SINGLE)
;       * Is it faster?
;       * Write up examples:
;         * standard, easy case
;         * HUGE grid; break it up.
;         * HUGE data; loop through it.
;       * Finish documentation.
;       * How do we handle the obscure map projections that need
;         extra keywords to be passed into WCSSPH2XY.PRO?
;       * What do gridlon and gridlat MEAN for whacky (or any) projection?
;       * Apply the WCUTOFF keyword??
;       * User might want to pass in their own convolution function.
;       * Determine effective FWHM for standard convolution functions.
;       * What is proper way to deal with jy/beam correction?
;       * Way to determine if parts of map are undersampled.
;       * When ready for prime time, uncomment delvarx'es and on_error.
;       * Need to distribute correct copy of WCSSPH2XY with this code!
;       * Are there IDL version dependencies? For certain.  What are they?
;         * FILE_DIRNAME -> introduced 6.0
;         * BESELJ(/DOUBLE) -> 5.6
;         * FILE_WHICH -> 5.4
;           * Getting rid of /DOUBLE keyword for BESELJ, this runs
;             fine on IDL v5.4 without using C++ code.
;
; MODIFICATION HISTORY:
;	Written by Tim Robishaw, Berkeley  28 Jul 2006
;	TR 02 Aug 2006 Incorporated Josh Goldston's wrappers for the
;	NIST SPARSE_BLAS C++ library.
;       TR 04 Aug 2006 Added kludge for Cartesion projection until we
;       figure out what's wrong with WCSSPH2XY.
;       TR 29 Aug 2006 Added square brackets around column, row and
;       weight arrays in call to SPRSIN() guarding against weird but
;       encountered case of one value being gridded.  Also fixed
;       calculation of IMCEN.
;       As this is a work in progress, please send any changes to:
;       robishaw@astro.berkeley.edu
;       Addded wrap solution, JEGP, August 25, 2010
;       Dealt with single element y, line 1023, JEGP, Nov 15, 2011
;       Added quiet keyword, JEGP, July 29, 2014.
;-

; WHEN IT'S READY FOR PRIME TIME, WE CAN GO BACK TO CALLING ROUTINE...
;on_error, 2

; RESOLVE GODDARD ROUTINES...
resolve_routine, ['wcssph2xy','wcs_rotate','delvarx'], /NO_RECOMPILE

; MAKE SURE WE'RE BEING PASSED A DATA ARRAY OF SANE DIMENSIONS...
sz = size(data)
if (sz[1] eq 0) then message, 'DATA array is not defined!'
ndims = sz[0]
if (ndims gt 3) then message, 'DATA array must be 1, 2 or 3 dimensions.'
ndata = sz[1]

; IF USER HAS PASSED IN CUBE, WHICH IS AN OUTPUT ARRAY, BLAST IT TO SAVE
; MEMORY...
if (N_elements(CUBE) gt 0) then delvarx, cube

; MAKE SURE SPARSEIN AND SPARSEOUT AREN'T BOTH PRESENT...
if keyword_set(SPARSEIN) and keyword_set(SPARSEOUT) then $
   message, 'Set only one of the keywords SPARSEIN or SPARSEOUT, not both.'

; IF THE USER DOESN'T ASK FOR INFORMATION, THEN DON'T PROVIDE ANY...
verb = (N_elements(VERBOSE) eq 0) ? 0b : byte(verbose)

; IF THE USER HASN'T SPECIFIED THE NUMBER OF STOKES PARAMETERS, THEN
; FIRST CHECK THE SIZE OF THE INPUT DATA, THEN ASSUME ONLY ONE POLARIZATION
; IS BEING DEALT WITH...
if (N_elements(STOKES) eq 0) then stokes = (ndims eq 3) ? sz[3] : 1

; DO WE HAVE A CONTINUUM MAP...
nchan = ((ndims eq 1) OR ((stokes gt 1) AND (ndims eq 2))) ? 1 : sz[2]

; REFORM DATA IF USER PASSES IN 2-D MULTI-STOKES CONTINUUM IMAGE...
if (stokes gt 1) AND (ndims eq 2) then $ 
   data = reform(data, sz[1], 1, sz[2], /OVERWRITE)

; ERROR CHECK ON WEIRD CRANGE INPUTS... THERE'S TOO MUCH WORK TO BE
; DONE TO LET SOME STUPID VALUES OF CRANGE CRASH THE PROGRAM AT THE VERY
; END...
if (N_elements(CRANGE) gt 0) then begin
   if (crange[0] lt 0) OR (crange[1] lt 0) OR $
      (crange[0] ge nchan) OR (crange[1] ge nchan) $
      then message, 'Values of CRANGE must be in range [0,'+$
                    strtrim(nchan-1,2)+'].'
   if (crange[1] lt crange[0]) $
      then message, 'CRANGE[0] must be <= CRANGE[1].'
endif else crange = [0,nchan-1]

; HOW MANY CHANNELS WILL WE END UP CONSIDERING...
nchannels = crange[1] - crange[0] + 1

; HAS THE USER PASSED IN A PREDEFINED GRID...
grid_in = (N_elements(GRIDLON) gt 0) OR (N_elements(GRIDLAT) gt 0) $
          AND (N_elements(ARCMINPERPIXEL) eq 0)
if grid_in then begin
   ; ERROR CHECK TO MAKE SURE USER HASN'T SUPPLIED OTHER KEYWORDS
   ; LIKE LONCEN, LATCEN, IMSIZEX, IMSIZEY
   imsize = [N_elements(gridlon), N_elements(gridlat)]

   ; MAKE SURE THE USER SUPPLIES BOTH THE GRID LON AND LAT...
   if (imsize[0] eq 0) or (imsize[1] eq 0) then $
      message, 'Both GRIDLON and GRIDLAT must be set.'

   if (imsize[0] eq 1) or (imsize[1] eq 1) then $
      message, 'GRIDLON and GRIDLAT must be arrays in this context.'

   ;!!!!!!!!!!!!!!!!!!!!!!
   ; IS GRIDLON RUNNING RIGHT TO LEFT AS IT SHOULD BE...

   ;!!!!!!!!!!!!!!!!!!!!!!!
   ; WHAT IF LON CROSSES 0/360...

   arcminperpixel = median(abs(gridlat-shift(gridlat,+1))) * 60d0

endif

; HOW MANY POINTS ARE IN THE GRID...
imsizex = imsize[0]
imsizey = imsize[1]

; HOW MANY TOTAL POINTS ARE IN THE GRID...
ngrid = ulong(imsizex)*ulong(imsizey)

; WHICH IS THE BIGGER, THE TOTAL NUMBER OF GRID POINTS OR THE TOTAL NUMBER
; OF DATA POINTS...
nmax = ngrid > ndata

; SET THE MISSING DATA VALUE TO IEEE NAN...
if (N_elements(NODATA) eq 0) $
   then nodata = keyword_set(DOUBLE) ? !values.d_nan : !values.f_nan

; LET'S PERUSE WHAT THE USER HAS PASSED IN...
if ((verb and 8b) ne 0) then begin
   help, ndata, ngrid, nmax
   help, stokes, nchan, nchannels
   help, imsizex, imsizey
   help, crval
   ;help, lon0, lat0
   help, fwhm
   help, nodata
endif

; IF THE USER HAS PASSED IN A SPARSE MATRIX THEN ERROR CHECK THE INPUTS...
if (N_elements(sparsein) gt 0) then begin

   ; WHEN PASSING IN A SPARSE MATRIX, THE USER NEEDS TO PASS IN WEIGHT...
   if (N_elements(weight) eq 0) then $
      message, 'When passing in a sparse matrix via SPARSEIN, the '+$
               'matrix of weights must also be passed in via the '+$
               'WEIGHT keyword.'

   ; MAKE SURE THE WEIGHT ARRAY HAS THE CORRECT DIMENSIONS...
   if not array_equal(size(weight,/DIMENSIONS), imsize) then $
      message, 'WEIGHT array does not have the same dimensions as IMSIZE. '+$
               'Have you passed in the correct sparse data?'

   ; THE ONLY SANITY CHECK WE HAVE AVAILABLE FOR THE INPUT SPARSE DATA IS
   ; TO MAKE SURE THAT NONE OF THE ROWS OR COLUMNS EXCEED THE LARGER OF THE
   ; TOTAL NUMBER OF GRID POINTS OR DATA POINTS...
   if (max(sparsein.row) > max(sparsein.col) gt nmax) then $
      message, 'Something is wrong with SPARSEIN; the maximum column or '+$
               'row number is larger than the total number of grid '+$
               'or the total number of data points.'

   ; JUST GO TO THE END OF THIS ROUTINE...
   goto, make_cube

endif

; SET THE MINIMUM WEIGHT WE WISH TO CONSIDER...
if (N_elements(MINWEIGHT) eq 0) then minweight = 1d-3

; LET'S NOT PLOT THE PROCESS UNLESS THE USER ASKS FOR IT...
if (N_elements(PLOTWATCH) eq 0) then plotwatch = 0

; WHAT IS THE INITIAL MEMORY STATE...
if ((verb and 16b) ne 0) then help, /MEMORY

; INITIALIZE SOME VARIABLES...
weight = replicate(keyword_set(DOUBLE) ? 0d0 : 0.0, imsizex, imsizey)
nwmap = ulonarr(imsizex,imsizey)
mindistmap = keyword_set(DOUBLE) $
             ? dblarr(imsizex,imsizey) $
             : fltarr(imsizex,imsizey)

if ((verb and 16b) ne 0) then help, /MEMORY

; CENTER OF THE FINAL GRID IN PIXELS...
imrefx = (imsizex-1)/2.
imrefy = (imsizey-1)/2.

;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; FOR PROJECTIONS WITH LATPOLE, LIKE CAR, MAKE LATPOLE AN EXPLICIT KEYWORD
; AND SET TO DEFAULT VALUE OF +90 IF NOT PASSED IN???
; OR LEAVE AS SO??

; WHICH COORDINATE PROJECTION DID WE REQUEST...
pv2 = 0.0
if (N_elements(PROJECTION) eq 0) then projection = 'DEF'
case strupcase(projection) of 
   'DEF' : map_type= 0
   'AZP' : map_type= 1
   'TAN' : map_type= 2
   'SIN' : map_type= 3
   'NCP' : begin
      map_type = 3
      pv2 = [0.0,cos(!dpi/180d0*lat0)/sin(!dpi/180d0*lat0)]
   end
   'STG' : map_type= 4
   'ARC' : map_type= 5
   'ZPN' : map_type= 6
   'ZEA' : map_type= 7
   'AIR' : map_type= 8
   'CYP' : map_type= 9
   'CAR' : map_type=10
   'MER' : map_type=11
   'CEA' : map_type=12
   'COP' : map_type=13
   'COD' : map_type=14
   'COE' : map_type=15
   'COO' : map_type=16
   'BON' : map_type=17
   'PCO' : map_type=18
   'SFL' : map_type=19
   'PAR' : map_type=20
   'AIT' : map_type=21
   'MOL' : map_type=22
   'CSC' : map_type=23
   'QSC' : map_type=24
   'TSC' : map_type=25
   'SZP' : map_type=26
   else : message, 'Projection '+strtrim(projection,2)+' not known. '+$
   'See Documentation for WCSSPH2XY.PRO and Calabretta and Greisen '+$
   '2002, A&A, 395, 1077 for more details.'
endcase

; USE KLUDGE FOR CARTESIAN PROJECTION FOR NOW...

;CRVAL = [lon0,lat0]
;CRVAL = get_crval_for_pole([0,30],150,[0,0])

;LONGPOLE=  0
;LATPOLE = 90

;crval = [mean(lon),mean(lat)]

;crval = [90,45]
;imcen = [0,90]

; DETERMINE DISTANCE OF DATA FROM CENTER OF MAP IN 
; COORDINATE PROJECTION...
wcssph2xy, lon, lat, x, y, map_type, $
           CRVAL=crval, LONGPOLE=longpole, LATPOLE=latpole, $
           PV2=pv2, _EXTRA=_extra

;print, 'CRVAL = ', crval

; IS THE CENTER OF OUR IMAGE DIFFERENT THEN THE CENTER OF OUR PROJECTION...
if (N_elements(FIELDCEN) eq 2) then begin
   wcssph2xy, fieldcen[0], fieldcen[1], x0, y0, map_type, $
              CRVAL=crval, LONGPOLE=longpole, LATPOLE=latpole, $
              PV2=pv2, _EXTRA=_extra

   x = x - x0
   y = y - y0

endif

;!!!!!!!!!!!!!!!!!
; THIS ISN'T REALLY BEING USED BY ANYTHING RIGHT NOW...
smoothWidthArcmin = fwhm

; DETERMINE THE MAXIMUM RADIUS IN ARCMIN AROUND WHICH DATA WILL BE
; CONSIDERED FOR EACH GRID POINT...
if not keyword_set(maxRadArcmin) then maxRadArcmin = smoothWidthArcmin

; WHAT IS THE GRID SPACING IN ARCMIN...
if not keyword_set(arcminPerPixel) then arcminPerPixel = fwhm/4.

; GET THE CELL SIZE FOR THE MAXIMUM AREA AROUND EACH GRID POINT IN
; FRACTIONAL PIXELS...
maxRadPix = double(maxRadArcmin/arcminPerPixel)

; LET'S PERUSE THE RELEVANT GRIDDING PARAMETERS...
if ((verb and 8b) ne 0) then begin
   help, smoothwidtharcmin
   help, maxradarcmin
   help, maxradpix
   help, arcminperpixel
   help, minweight
   help, square
   help, projection, gridfunc
endif

; WHICH GRIDDING KERNEL DID WE REQUEST...
case STRUPCASE(gridfunc) of 
   'SINC' : begin
        fnameg = 'sdgrid_sinc'
        parm2  = 1.14*fwhm/3.      
   end
   'GAUSS' : begin
        fnameg = 'sdgrid_gauss'
        ; WHAT THE HELL WAS THIS BEING USED FOR?
        parm2  = fwhm/3.
   end
   'BESSEL' : begin
        fnameg = 'sdgrid_bessel'
        parm2  = 1.55*fwhm/3.
   end
   else : message, 'Gridding function '+gridfunc+' not recognized.'
endcase

nweights = 0ul

if ((verb and 16b) ne 0) then help, /MEMORY

;!!!!!!!!!!!!!
;!! TESTING
; DID WE SET IMCEN...
if (N_elements(imcen) gt 0) then begin
   if (N_elements(imcen) ne 2) then $
      message, 'IMCEN keyword must be a 2-element vector.'

   x = x + (crval[0] - imcen[0])
   y = y + (crval[1] - imcen[1])

   ;x = x + (lon0 - imcen[0])
   ;y = y + (lat0 - imcen[1])

endif
;stop

; DETERMINE X AND Y IN FRACTIONAL PIXELS...
x = imrefx - x*60./arcMinPerPixel
y = imrefy + y*60./arcMinPerPixel

;stop

; new fix to wrap problem, aug 25, 2010; JEGP
whover =where(x ge 180*60.*arcminperpixel+imrefx, ct)
if ct gt 0 then x[whover] = x[whover]-360*60.*arcminperpixel

whover = where(x lt (-1)*180*60.*arcminperpixel+imrefx, ct)
if ct gt 0 then x[whover]= x[whover]+360*60.*arcminperpixel


; PLOT THE DATA POSITIONS AND THE GRID POSITIONS...
if (plotwatch gt 0) then begin
   color = [!red,!green,!cyan,!yellow,!blue,!magenta,!orange,!gray]
   xg = indgen(imsizex)
   yg = indgen(imsizey)
   plot, [x,xg], [y,yg], /ISO, ys=19, xs=19, /NODATA
   oplot, x, y, PS=3
   oplot, xg # (intarr(imsizey)+1), yg ## (intarr(imsizex)+1), ps=3, co=!blue
endif

;stop

; DEFINE THE GRID STRUCTURE...
grid_struct = {weight:keyword_set(DOUBLE) ? 0d0 : 0.0, row:0ul, col:0ul}

;profiler, /reset, /clear
;profiler, /system
if ((verb and 1b) ne 0) then  message, 'Calculating weights...', /INFO
t1 = systime(1)
; GO THROUGH EACH ROW OF THE GRID...
for j = 0ul, imsizey-1ul do begin

   ; in case y is 1 element long?
   y = [y]
   ; USE HISTOGRAM TO FIND ALL DATA THAT IN THIS ROW OF THE GRID...
   useless = histogram(y, BINSIZE=2*maxRadPix, $
                       MIN=(j-maxRadPix), NBINS=1, $
                       REVERSE=ry)

   if (Ry[0] eq Ry[1]) then continue
   yindx = ulong(Ry[Ry[0] : Ry[1]-1])
   xbin = x[yindx]
   ybin = y[yindx]

   ; GO THROUGH EACH COLUMN OF THE GRID...
   for i = 0ul, imsizex-1ul do begin

      ; REPORT OUR PROGRESS...
      if ((verb and 2b) ne 0) then $
         print, 100*float(float(imsizex)*j+i)/(float(imsizex)*imsizey-1), $
                format='($,"Progress: ",I4,"%",%"\R")'

      ; IF THE USER HAS SET THE /SQUARE KEYWORD, THEN CONSIDER ALL THE DATA
      ; IN A SQUARE REGION AROUND THIS GRID POINT; OTHERWISE, DEFAULT IS TO
      ; CONSIDER DATA AROUND A CIRCULAR AREA...
      if keyword_set(SQUARE) $
         then useless = histogram(xbin, BINSIZE=2*maxRadPix, $
                                  MIN=(i-maxRadPix), NBINS=1, $
                                  REVERSE=rx) $
         else useless = histogram((xbin-i)^2+(ybin-j)^2, $
                                  BINSIZE=maxRadPix^2, $
                                  NBINS=1, REVERSE=rx)

      if (Rx[0] eq Rx[1]) then continue
      box_indx = Rx[Rx[0] : Rx[1]-1]
      xbox = xbin[box_indx]
      ybox = ybin[box_indx]
      if (plotwatch gt 0) then oplot, xbox, ybox, ps=3, co=color[(i+j) mod 8]

      ; DETERMINE DISTANCE, IN ARCMIN, FROM THIS GRID POINT TO
      ; THE DATA IN THIS BOX...
      distFromGridToData = sqrt((temporary(xbox)-i)^2 + $
                                (temporary(ybox)-j)^2) $
                           * arcminPerPixel

      ;!!!!!!!!!!!!!!!!!!!
      ; USER MIGHT WANT TO PROVIDE THEIR OWN CONVOLUTION FUNCTION...
      ; SO WE SHOULD CONSIDER PASSING IN X,Y,X0,Y0,FWHM...
      ; WHAT ELSE?

      ; GET THE WEIGHT AT THIS PIXEL...
      weights = call_function(fnameg,distFromGridToData,fwhm)

      ; IF WEIGHT IS BELOW MINIMUM THRESHOLD, DON'T EVEN BOTHER STORING WEIGHT...
      goodindx = where(weights gt minWeight, ngood)

      ; IF THERE ARE NO NON-NEGLIGIBLE WEIGHTS, THEN SPLIT...
      if (ngood eq 0) then continue

      ; ADD WEIGHT AT THIS PIXEL TO NORMALIZATION ARRAY...
      weight[i,j] = total(weights[goodindx],/DOUBLE)
      nwmap[i,j] = ngood
      mindistmap[i,j] = min(distfromgridtodata[goodindx])

      ;continue ; FOR TESTING, SKIP MAKING THE LINKED LIST

      ; CREATE ARRAY OF STRUCTURES CONTAINING THE WEIGHTS AND THE
      ; CORRESPONDING ROW AND COLUMN IN THE FINAL SPARSE MATRIX...
      item = replicate(grid_struct,ngood)
      item.weight = weights[goodindx]
      ; THE ROW IS THE 1-DIMENSIONAL POSITION IN THE GRID...
      item.row = i + j*imsizex
      ; THE COLUMN WILL BE THE 1-DIMENSIONAL POSITION OF THE DATA...
      item.col = yindx[box_indx[goodindx]]

      ; APPEND SPARSE MATRIX STRUCTURES TO LINKED LIST...
      if (nweights eq 0) then begin
         llist = ptr_new({previous:ptr_new(), $
                          item:ptr_new(item, /NO_COPY), $
                          next:ptr_new()})
         head = llist  ; COPY A POINTER TO THE HEAD OF THE LIST
      endif else begin
         (*llist).next = ptr_new({previous:llist, $
                                  item:ptr_new(item, /NO_COPY), $
                                  next:ptr_new()})
         llist = (*llist).next
      endelse

      ; KEEP TRACK OF THE NUMBER OF WEIGHTS ABOVE THE THRESHOLD...
      nweights = nweights + ngood

   endfor
endfor
if ((verb and 4b) ne 0) then $
   message, 'Time = '+strtrim(systime(1)-t1,2)+' seconds.', /INFO
; FREE UP SOME MEMORY...
;delvarx, x, y, xbin, ybin, box_indx
;profiler, /report

;stop

; HOW MANY WEIGHTS DID WE ACCUMULATE...
if ((verb and 8b) ne 0) then help, nweights

; DID WE MISS THE TARGET ALTOGETHER...
if (nweights eq 0) then begin
   ; COMPLAIN ABOUT IT...
   if not keyword_set(quiet) then begin
      message, 'There were no data near any of these grid points. '+$
            'Possible causes include: (a) the central position of the '+$
            'grid is way off (be sure longitude is in DEGREES); (b) '+$
            'MAXRADARCMIN has been set to far too small a value; (c) '+$
            'MINWEIGHT has been set to too high a value.', /INFO
	endif
   ; SEND BACK AN EMPTY GRID FILLED WITH THE NODATA VALUE...
   cube = replicate(nodata, imsizex, imsizey, nchannels, stokes)

   ; SPLIT...
   return
endif

if ((verb and 16b) ne 0) then help, /MEMORY
if ((verb and 1b) ne 0) then message, 'Dumping linked list...', /INFO
t1 = systime(1)
; CREATE SPARSE WEIGHTING ARRAY...
sprs_data = replicate(grid_struct, nweights)
i = 0
llist = head
while ptr_valid(llist) do begin
   current = (*llist)
   item = *current.item
   sprs_data[i] = item
   i = i + N_elements(item)
   next = current.next
   ; FREE THE PREVIOUS POINTER...
   ptr_free, current.previous
   ; FREE THE POINTER TO THE DATA...
   ptr_free, current.item
   if ptr_valid(next) $
      then llist = temporary(next) $
      else ptr_free, temporary(llist)
   ; THIS MAKES THIS LOOP MANY TIMES LONGER!!!
   if ((verb and 2b) ne 0) then $
      print, 100*float(i)/(float(nweights)-1), $
             format='($,"Progress: ",I4,"%",%"\R")'
endwhile
if ((verb and 2b) ne 0) then $
   message, 'Time = '+strtrim(systime(1)-t1,2)+' seconds.', /INFO
;delvarx, head, current, next
if ((verb and 16b) ne 0) then help, /MEMORY

make_cube:

; IS THERE A PROBLEM...
if (total(weight ne 0.0) eq 0.0) then $
   message, 'WEIGHT array has no non-zero elements!  Check input parameters.', /INFO

; CALCULATE THE WEIGHT CUTOFF...
; LOOKS LIKE THIS SHOULD BE APPLIED TO FINAL CONVOLVED WEIGHTS!!!
;if (N_elements(WCUTOFF) eq 0) then wcutoff = 0.05
;threshold = wcutoff*max(val.weight)

; ALLOCATE FINAL CUBE...
cube = keyword_set(DOUBLE) $
       ? dblarr(imsizex, imsizey, nchannels, stokes) $
       : fltarr(imsizex, imsizey, nchannels, stokes)

;!!!!!!!!!!!!!!!!!!!!!
; UNTIL WE HAVE SOME RESULTS ON WHEN TO USE THE C++ LIBRARY, WE WILL ONLY
; INVOKE IT IF THE USER SETS THE /CPP KEYWORD...
if not keyword_set(CPP) then begin

   ; WE WILL USE IDL TO DO SPARSE ALGEBRA...
   if ((verb and 1b) ne 0) then $
      message, 'Using IDL to do sparse linear algebra...', /info

   if ((verb and 1b) ne 0) then message, 'Making sparse matrix...', /info
   t1 = systime(1)
   ;stop
   sparse_matrix = sdgrid_idl_get_sparse((N_elements(SPARSEIN) eq 0) $
                                         ? sprs_data : sparsein, $
                                         imsizex, imsizey, $
                                         ngrid, ndata, $
                                         DOUBLE=keyword_set(double))
   if ((verb and 4b) ne 0) then $
      message, 'Time = '+strtrim(systime(1)-t1,2)+' seconds.', /INFO
   if ((verb and 16b) ne 0) then help, /MEMORY

   ; HANDLE SPARSE DATA APPROPRIATELY...
   if not arg_present(sparsein) and arg_present(SPARSEOUT) $
      then sparseout = temporary(sprs_data)
   if not arg_present(sparsein) and not arg_present(SPARSEOUT) $
      then delvarx, sprs_data

   ;profiler, /clear, /reset
   ;profiler, /system
   if ((verb and 1b) ne 0) then message, 'Weighting Data...', /INFO
   t1 = systime(1)
   sdgrid_idl_do_sparse_mult, data, sparse_matrix, cube, stokes, $
                              ngrid, nmax, crange, nchannels, $
                              verb, DOUBLE=keyword_set(double)
   if ((verb and 4b) ne 0) then $
      message, 'Time = '+strtrim(systime(1)-t1,2)+' seconds.', /INFO
   delvarx, sparse_matrix

   ;profiler, /report

endif else begin

   ; WE WILL USE C++ CODE TO DO SPARSE ALGEBRA...
   if ((verb and 1b) ne 0) then $
      message, 'Using C++ to do sparse linear algebra...', /info

   if ((verb and 1b) ne 0) then message, 'Weighting Data...', /INFO
   t1 = systime(1)
   sdgrid_c_do_sparse_mult, ngrid, ndata, nchannels,$
                            (N_elements(SPARSEIN) eq 0) $
                            ? sprs_data : sparsein, $
                            data, cube,$
                            imsizex, imsizey, crange, stokes, $
                            DOUBLE=keyword_set(DOUBLE)
   if ((verb and 4b) ne 0) then $
      message, 'Time = '+strtrim(systime(1)-t1,2)+' seconds.', /INFO

endelse

;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; SET SOME KIND OF THRESHOLD...
;if (N_elements(WCUTOFF) eq 0) then wcutoff = 0.05
;wcutoff=0.2
;threshold = wcutoff*max(weight,/NAN)

; aips
; maxcwt -> maximum convolved weight
; rwt -> fractional cutoff level
; xnlim = abs(rwt) * maxcwt

if ((verb and 16b) ne 0) then help, /MEMORY
t1 = systime(1)

; IF USER PASSED IN 2-D MULTI-STOKES CONTINUUM IMAGE, RETURN DATA TO INPUT
; DIMENSIONS...
if (stokes gt 1) AND (ndims eq 2) then $ 
   data = reform(data, sz[1:2], /OVERWRITE)

; WHERE ARE THE VALID WEIGHTS AND THE EMPTY WEIGHTS...
inv_indx = where(weight ne 0.0, ninv, $
                 COMPLEMENT=blank_indx, NCOMPLEMENT=nblank)
;inv_indx = where(abs(weight) gt threshold,ninv)
;if (ninv eq 0) then $
;   message, 'All weights are zero. Check input parameters or lower MAXCWT.'

; NORMALIZE EACH DATA POINT...
if not keyword_set(NONORMALIZE) then begin
   if ((verb and 1b) ne 0) then message, 'Normalizing Data...', /INFO
   inv_weight = replicate(keyword_set(DOUBLE) ? 0d0 : 0.0, imsizex, imsizey)
   inv_weight[inv_indx] = 1d0 / weight[inv_indx]
   for stk = 0, stokes-1 do $
      for i = 0l, nchannels-1l do $
         cube[0,0,i,stk] = cube[*,*,i,stk] * inv_weight

if ((verb and 4b) ne 0) then $
   message, 'Time = '+strtrim(systime(1)-t1,2)+' seconds.', /INFO
if ((verb and 16b) ne 0) then help, /MEMORY

; IF THE NODATA KEYWORD IS SET THEN FILL THE EMPTY PIXELS OF THE FINAL CUBE
; WITH THE NODAT VALUE...
if (nblank gt 0) AND (nodata ne 0.0) then $
   for stk = 0, stokes-1 do $
      for i = 0l, nchannels-1l do $
         cube[blank_indx mod imsizex, blank_indx/imsizex,$
              replicate(i,nblank), replicate(stk,nblank)] = nodata
endif

;delvarx, inv_indx, blank_indx

; GET RID OF VELOCITY DIMENSION IF MULTI-POLARIZATION CONTINUUM MAP...
cube = reform(cube,/OVERWRITE)

; IF THE SPARSEIN KEYWORD WAS SET, SPLIT...
if (N_elements(SPARSEIN) gt 0) then return

; HOW MANY SPECTRA WERE ADDED TO THE GRID...
if ((verb and 1b) ne 0) then $
   message, strtrim(nweights,2)+' spectra gridded successfully.', /INFO

; ONLY PASS OUT GRIDLON AND GRIDLAT IF THEY WERE NOT PASSED IN AS INPUTS...
if not grid_in then begin
   gridlon = crval[0] + (dindgen(imsizex) - imrefx) * arcminPerPixel/60d0
   gridlon = reverse(gridlon)
   gridlat = crval[1] + (dindgen(imsizey) - imrefy) * arcminPerPixel/60d0
   if not keyword_set(DOUBLE) then begin
      gridlon = float(gridlon)
      gridlat = float(gridlat)
   endif
endif

;stop
return

; PHIL'S JANSKY PER BEAM CORRECTION IS...
;scalebm = (fwhm^2 + smoothWidth^2)/(fwhm^2)
;weight = weight/scalebm

end; sdgrid
