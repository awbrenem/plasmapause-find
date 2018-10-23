;+
; NAME: get_distance_from_plasmapause_goldstein_boundary
; SYNTAX:
; PURPOSE: returns distance from input sc coord (L,MLT) to nearest Goldstein plasmapause location, and the
;     L and MLT coord of that location for an array of times.
;     (for plotting the plasmapause see plot_plasmapause_goldstein_boundary.pro)
; INPUT: times = '2014-01-06/20:00:00'
;        mlt = 12
;        lshell = 7
;        s = get_distance_from_plasmapause_goldstein_boundary(times,mlt,lshell)
;
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
  times,$
  mltvals,$
  lvals,$
  name=name



  if ~keyword_set(mltvals) then mltvals = 0.
  if ~keyword_set(lvals) then lvals = 5.




  ;Determine which Goldstein PP files are available for loading. 
  ;This can be grabbed in load_goldstein_plasmasphere_file.pro, but it's faster if we 
  ;just grab the entire list here. 
  files = get_goldstein_file_list()

  

  ;Load the Goldstein PP file closest to the current requested time,
  ;and find the MLT and Lshell values
  lpp = fltarr(n_elements(times))
  mltpp = lpp
  ldiff = lpp
  mltdiff = lpp

  for n=0L,n_elements(times)-1 do begin

    l_mlt = load_goldstein_plasmasphere_file(times[n],files=files)


    ;For each time requested, find L and MLT value of plasmapause closest to the input region
    mltall = l_mlt.mltpp
    lall = l_mlt.lpp
    diffv = abs(mltall - mltvals[n])





    ;array location of plasmapause with same MLT as sc
    minv = min(diffv,loc)
    lpp[n] = lall[loc]
    mltpp[n] = mltall[loc]
    if keyword_set(lvals) then ldiff[n] = lvals[n] - lpp[n] else ldiff[n] = !values.f_nan
    mltdiff[n] = mltvals[n] - mltpp[n]

  endfor



  return,{$
    l_nearest:lpp,$
    mlt_nearest:mltpp,$
    distance_from_pp:ldiff,$
    mlt_offset:mltdiff}

end
