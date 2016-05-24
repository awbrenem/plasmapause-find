;+
; NAME: plasmapause_goldstein_boundary
; SYNTAX:
; PURPOSE: returns Jerry Goldstein's plasmapause boundary for a specific time,
;     as well as the distance from input sc coord to nearest plasmapause and the
;     L and MLT coord of that location. Can plot the plasmapause.
; INPUT: time = '2014-01-06/20:00:00'
;        mlt = 12
;        lshell = 7
;        s = plasmapause_goldstein_boundary(time,mlt,lshell,/plot)
;
;        Required plasmapause files can be found at
;        http://enarc.space.swri.edu/PTP/
;
;
; OUTPUT: Returns a structure with the following values:
;         l, mlt --> all the L and MLT values of the PP for a single time (not
;         returned if more than one time is requested)
;         lpp, mltpp --> L and MLT of the PP position closest to the
;                spacecraft
;         ldiff, mltdiff --> difference b/t Lshell(MLT) of sc and Lshell(MLT)
;                    of nearest PP position. distance_from_pp is
;                    positive if sc is outside of plasmapause.
; KEYWORDS: plot --> create a plot of the PS boundary
;           ps --> create a PS file
;           name --> Name of the output PS file
;
; HISTORY: Written by Aaron W Breneman, 2016
;-


function plasmapause_goldstein_boundary,$
  time,$
  mlt_i,$
  lshell_i,$
  plot=plotpp,$
  ps=ps,$
  name=name,$
  path=path



  if ~keyword_set(name) then name = 'pshere_plot.ps'

  time = time_string(time_double(time))

  extension = 'ppa'
  if ~keyword_set(path) then $
  path = '/Users/aaronbreneman/Desktop/code/Aaron/datafiles/goldstein_pp_files/'



  if ~keyword_set(mlt_i) then mlt_i = 0.
  if ~keyword_set(lshell_i) then lshell_i = 5.


  year0 = strmid(time,0,4) + '-01-01'

  doy = 1 + floor(time_double(time)/86400 - time_double(year0)/86400)
  doyS = strarr(n_elements(doy))

  for i=0L,n_elements(doy)-1 do begin
    if doy[i] lt 10 then doyS[i] = '00'+strtrim(doy[i],2)
    if doy[i] ge 10 and doy[i] lt 100 then doyS[i] = '0'+strtrim(doy[i],2)
    if doy[i] ge 100 then doyS[i] = strtrim(doy[i],2)
  endfor

  datetime = strmid(time,0,4) + doyS + strmid(time,11,2) + strmid(time,14,2)



  files = FILE_SEARCH(path+'*.'+extension)

  for i=0L,n_elements(files)-1 do files[i] = strmid(files[i],14,/reverse_offset)
  files = double(strmid(files,0,11))

  file_to_load = ''

  ;;------------------------------------------------------------------------------
  ;; Load each appropriate file and find the MLT and Lshell values
  ;;------------------------------------------------------------------------------


  ;lfinal = fltarr(n_elements(datetime))
  ;mltfinal = lfinal
  lpp = fltarr(n_elements(datetime))
  mltpp = lpp
  ldiff = lpp
  mltdiff = lpp

  for n=0L,n_elements(datetime)-1 do begin


    ;;find correct file to load
    goo = where(double(datetime[n]) le files)
    file_to_load2 = path + string(files[goo[0]],format='(i11)') + '.' + extension

    ;;load a new file if required
    if file_to_load2 ne file_to_load then begin

      file_to_load = file_to_load2

      openr,1,file_to_load
      junk = ''
      readf,1,junk
      vals = ''

      while not eof(1) do begin
        readf,1,junk
        vals = [vals,junk]
      endwhile

      close,1
      free_lun,1



      ;;Remove last 11 lines in file
      vals = vals[1:n_elements(vals)-11]
      l = fltarr(n_elements(vals))
      phi = l


      for i=0,n_elements(vals)-1 do begin
        tmp = strsplit(vals[i],' ',/extract)
        l[i] = tmp[0]
        phi[i] = tmp[1]
      endfor


      ;;in "wrapped" values of 360
      deg = (phi + !pi)/!dtor

      ;;unwrap the degree values
      nwrap = floor(min(deg)/360.)
      deg2 = deg - nwrap*360.

      ;;--------------------------------------------------
      ;; ;;Compare wrapped and unwrapped values to make sure I've done
      ;; ;;unwrapping correctly
      ;; x2 = abs(l)*cos(mlt*!dtor)
      ;; y2 = abs(l)*sin(mlt*!dtor)
      ;; r2 = sqrt(x^2 + y^2)

      ;; x = abs(l)*cos(deg2*!dtor)
      ;; y = abs(l)*sin(deg2*!dtor)
      ;; r = sqrt(x^2 + y^2)

      ;; ;;Test showing that the unwrapping was done correctly
      ;; ;; print,x-x2
      ;;--------------------------------------------------



      ;;Change to MLT values
      mlt = deg2 * (24./360.)
      goo = where(mlt ge 24)
      if goo[0] ne -1 then mlt[goo] = mlt[goo] - 24.


    endif ;;loading new file

    ;;Find L and MLT value of plasmapause closest to the input region
    diffv = abs(mlt - mlt_i[n])

    ;;--------------------------------------------------
    ;;plot values
    ;; !p.multi = [0,0,2]
    ;; plot,24.*indgen(n_elements(mlt))/(n_elements(mlt)-1),mlt
    ;; oplot,[0,24],[mlt_i,mlt_i]
    ;; plot,24.*indgen(n_elements(mlt))/(n_elements(mlt)-1),diffv
    ;;--------------------------------------------------

    ;array location of plasmapause with same MLT as sc
    minv = min(diffv,loc)

    lpp[n] = l[loc]
    mltpp[n] = mlt[loc]




    if keyword_set(lshell_i) then ldiff[n] = lshell_i[n] - lpp[n] else ldiff[n] = !values.f_nan
    mltdiff[n] = mlt_i[n] - mltpp[n]


  endfor


  if keyword_set(plotpp) then begin

    if keyword_set(ps) then popen,'~/Desktop/'+name

    rad=findgen(101)
    rad=rad*2*!pi/100.0
    lval=findgen(7)
    lval=lval+3.0
    lshell1x=1.0*cos(rad)
    lshell1y=1.0*sin(rad)
    lshell3x=lval[0]*cos(rad)
    lshell3y=lval[0]*sin(rad)
    lshell5x=lval[2]*cos(rad)
    lshell5y=lval[2]*sin(rad)
    lshell7x=lval[4]*cos(rad)
    lshell7y=lval[4]*sin(rad)
    lshell9x=lval[6]*cos(rad)
    lshell9y=lval[6]*sin(rad)
    !x.margin=[5,5]
    !y.margin=[5,5]

    xr = [-12, 12]
    yr = [-12, 12]

    if !d.name eq 'X' then window,1, xsize = 600, ysize = 600
    plot, lshell3x, lshell3y, $
    xrange=xr, yrange=yr,$
    ;           XSTYLE=4, YSTYLE=4, $
    title=''+$
    " UT (L vs MLT Kp=1)!Cfrom plasmapause_goldstein_boundary.pro",$
    position=aspect(1.)

    x2 = abs(l)*cos(mlt*360./24. *!dtor)
    y2 = abs(l)*sin(mlt*360./24. *!dtor)

    polyfill,x2,y2,color=160,clip=[xr[0],yr[0],xr[1],yr[1]],noclip=0


    ;NOT WORKING....maybe b/c of position=aspect(1)??
    ;     AXIS,0,0,XAX=0,/DATA
    ;     AXIS,0,0,0,YAX=0,/DATA

    ;     xax = axis('X',location=0,tickinterval=1)

    oplot, lshell1x, lshell1y
    oplot, lshell5x, lshell5y
    oplot, lshell7x, lshell7y
    oplot, lshell9x, lshell9y

    ;;Earth
    rvals = replicate(1,360)
    thetavals = indgen(360)*!dtor
    xearth = rvals*cos(thetavals)
    yearth = rvals*sin(thetavals)
    good = where(xearth ge 0.)
    polyfill,xearth[good],yearth[good]


    xyouts, -10.5, -0.60, '12:00', /data
    xyouts, 9.75, -0.60, '0:00', /data
    xyouts, -7, -0.6, '7', /data
    xyouts, -3, -0.6, '3',/data
    xyouts, 7, -0.6, '7', /data
    xyouts, 3, -0.6,'3', /data


    ;;plot the payload position
    xp = abs(lshell_i)*cos(mlt_i*360./24. *!dtor)
    yp = abs(lshell_i)*sin(mlt_i*360./24. *!dtor)
    for q=0,n_elements(xp)-1 do oplot,[xp[q],xp[q]],[yp[q],yp[q]],$
    psym=q+4,symsize=2

    if keyword_set(ps) then pclose

  endif





  if n_elements(mlt_i) eq 1 then $
  return,{$
    lval_all:l,$
    mlt_all:mlt,$
    l_nearest:lpp,$
    mlt_nearest:mltpp,$
    distance_from_pp:ldiff,$
    mlt_offset:mltdiff} $
  else return,{$
    l_nearest:lpp,$
    mlt_nearest:mltpp,$
    distance_from_pp:ldiff,$
    mlt_offset:mltdiff}


end
