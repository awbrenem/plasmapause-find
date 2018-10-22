;+
; NAME: get_distance_from_plasmapause_goldstein_boundary
; SYNTAX:
; PURPOSE: returns distance from input sc coord to nearest Goldstein plasmapause location, and the
;     L and MLT coord of that location. 
;     (for plotting the plasmapause see plot_plasmapause_goldstein_boundary.pro)
; INPUT: time = '2014-01-06/20:00:00'
;        mlt = 12
;        lshell = 7
;        s = get_distance_from_plasmapause_goldstein_boundary(time,mlt,lshell)
;
;        Required plasmapause files can be found at
;        http://enarc.space.swri.edu/PTP/
;        An example of one of these is:
;        /Users/aaronbreneman/Desktop/code/Aaron/datafiles/goldstein_pp_files/20140040000.ppa
;
; See call_get_distance_from_plasmapause_goldstein_boundary.pro for example of usage.
;
; OUTPUT: Returns a structure with the following values:
;         l, mlt --> all the L and MLT values of the PP for a single time (not
;         returned if more than one time is requested)
;         lpp, mltpp --> L and MLT of the PP position closest to the
;                spacecraft
;         ldiff, mltdiff --> difference b/t Lshell(MLT) of sc and Lshell(MLT)
;                    of nearest PP position. distance_from_pp is
;                    positive if sc is outside of plasmapause.
;
; HISTORY: Written by Aaron W Breneman, 2016
;-


function get_distance_from_plasmapause_goldstein_boundary,$
  time,$
  mltvals,$
  lvals,$
  name=name
;  path=path

  if ~keyword_set(mltvals) then mltvals = 0.
  if ~keyword_set(lvals) then lvals = 5.
  ;if ~keyword_set(path) then path = '/Users/aaronbreneman/Desktop/code/Aaron/datafiles/goldstein_pp_files/'
  





  time = time_string(time_double(time))
  year0 = strmid(time,0,4) + '-01-01'
  doy = 1 + floor(time_double(time)/86400 - time_double(year0)/86400)
  doyS = strarr(n_elements(doy))

  for i=0L,n_elements(doy)-1 do begin
    if doy[i] lt 10 then doyS[i] = '00'+strtrim(doy[i],2)
    if doy[i] ge 10 and doy[i] lt 100 then doyS[i] = '0'+strtrim(doy[i],2)
    if doy[i] ge 100 then doyS[i] = strtrim(doy[i],2)
  endfor
  datetime = strmid(time,0,4) + doyS + strmid(time,11,2) + strmid(time,14,2)


  ;Determine which Goldstein PP files are available for loading
  files = get_goldstein_file_list()
  file_to_load = ''



  

  ;------------------------------------------------------------------------------
  ;Load the Goldstein PP file closest to the current requested time,
  ;and find the MLT and Lshell values
  ;------------------------------------------------------------------------------


  lpp = fltarr(n_elements(datetime))
  mltpp = lpp
  ldiff = lpp
  mltdiff = lpp

  ;for each requested time
  for n=0L,n_elements(datetime)-1 do begin


    ;;find correct file to load
    goo = where(double(datetime[n]) le files)
    file_to_load2 = string(files[goo[0]],format='(i11)') + '.' + 'ppa'





    ;;load a new file if required
    if file_to_load2 ne file_to_load then begin
      file_to_load = file_to_load2
      l_mlt = load_goldstein_plasmasphere_file(file_to_load)
    endif ;;loading new file



    ;For each time requested, find L and MLT value of plasmapause closest to the input region
    mltall = l_mlt.mltpp
    lall = l_mlt.lpp
    diffv = abs(mltall - mltvals[n])

    ;;--------------------------------------------------
    ;;plot values
    ;; !p.multi = [0,0,2]
    ;; plot,24.*indgen(n_elements(mltall))/(n_elements(mltall)-1),mltall
    ;; oplot,[0,24],[mltvals,mltvals]
    ;; plot,24.*indgen(n_elements(mltall))/(n_elements(mltall)-1),diffv
    ;;--------------------------------------------------



    ;array location of plasmapause with same MLT as sc
    minv = min(diffv,loc)
    lpp[n] = lall[loc]
    mltpp[n] = mltall[loc]
    if keyword_set(lvals) then ldiff[n] = lvals[n] - lpp[n] else ldiff[n] = !values.f_nan
    mltdiff[n] = mltvals[n] - mltpp[n]


  endfor





;    if n_elements(mltvals) eq 1 then $
;    return,{$
;      l_nearest:lpp,$
;      mlt_nearest:mltpp,$
;      distance_from_pp:ldiff,$
;      mlt_offset:mltdiff} $
;    else return,{$
    return,{$
      l_nearest:lpp,$
      mlt_nearest:mltpp,$
      distance_from_pp:ldiff,$
      mlt_offset:mltdiff}

end
