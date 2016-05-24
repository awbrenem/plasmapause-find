;+
; NAME: plasmasphere_crossing_load
; SYNTAX:
; PURPOSE: Loads the output file from plasmasphere_build_database.pro
;          and removes the day boundaries.
; INPUT:
;
; OUTPUT:  Retuns a structure with the entry/exit times of the plasmasphere
;          and spacecraft ephemeris at those times
; KEYWORDS: print_output --> prints times inside and outside of PS
;
; HISTORY: Written by Aaron W Breneman, May, 2016
;-


function plasmasphere_crossing_load,fn,$
  print_output=print_output

  if ~keyword_set(print_output) then print_output = 0.

  openr,lun,fn,/get_lun
  psi = ''                      ;time of inbound plasmasphere entry
  pso = ''                      ;time of outbound plasmasphere exit
  deltaT = ''
  lshelli = ''
  lshello = ''
  mlti = ''
  mlto = ''
  mlati = ''
  mlato = ''
  radiusi = ''
  radiuso = ''
  jnk = ''
  header = ''
  cnt = 0.
  readf,lun,header              ;read header

  while not eof(lun) do begin
    readf,lun,jnk
    vals = strsplit(jnk,/extract)
    psi = [psi,vals[0]]
    pso = [pso,vals[1]]
    deltaT = [deltaT,vals[2]]
    lshelli = [lshelli,vals[3]]
    lshello = [lshello,vals[4]]
    mlti = [mlti,vals[5]]
    mlto = [mlto,vals[6]]
    mlati = [mlati,vals[7]]
    mlato = [mlato,vals[8]]
    radiusi = [radiusi,vals[9]]
    radiuso = [radiuso,vals[10]]

    cnt++
  endwhile

  close,lun
  free_lun,lun


  psi = time_double(psi[1:cnt])
  pso = time_double(pso[1:cnt])
  deltaT = deltaT[1:cnt]
  lshelli = lshelli[1:cnt]
  lshello = lshello[1:cnt]
  mlti = mlti[1:cnt]
  mlto = mlto[1:cnt]
  mlati = mlati[1:cnt]
  mlato = mlato[1:cnt]
  radiusi = radiusi[1:cnt]
  radiuso = radiuso[1:cnt]


  ;;--------------------------------------------------
  ;;Remove day boundaries in entry/exit times
  ;;--------------------------------------------------

  psiF = time_string(psi)
  psoF = time_string(pso)

  goo = where(strmid(psoF,11,8) eq '23:59:59')
  ;;Make sure goo doesn't refer to the very last element of the
  ;;database. It's OK for this element to be the last time of the day
  if goo[n_elements(goo)-1] eq n_elements(psoF)-1 then goo = goo[0:n_elements(goo)-2]
  if goo[0] ne -1 then psoF[goo] = 'xxxxxxxxxxxxxxxxxxx'
  if goo[0] ne -1 then psiF[goo+1] = 'xxxxxxxxxxxxxxxxxxx'
  ;for i=0,14 do print,psiF[i] + ' ' + psoF[i]



  goo = where(psiF ne 'xxxxxxxxxxxxxxxxxxx')
  if goo[0] ne -1 then begin
    psiF = psiF[goo]
    lshelliF = lshelli[goo]
    mltiF = mlti[goo]
    mlatiF = mlati[goo]
    radiusiF = radiusi[goo]
  endif
  goo = where(psoF ne 'xxxxxxxxxxxxxxxxxxx')
  if goo[0] ne -1 then begin
    psoF = psoF[goo]
    lshelloF = lshello[goo]
    mltoF = mlto[goo]
    mlatoF = mlato[goo]
    radiusoF = radiuso[goo]
  endif


  ;Find times when spacecraft is outside of the plasmasphere

  mspherei = psoF          ;entry time into low density magnetosphere (exit from PS)
  msphereo = shift(psiF,-1)     ;exit of low density magnetosphere
  lshelli_ms = lshelloF
  lshello_ms = shift(lshelliF,-1)

  mspherei = mspherei[0:n_elements(mspherei)-2]
  msphereo = msphereo[0:n_elements(msphereo)-2]



  ;;--------------------------------------------------
  ;;Pad either or both the psi/pso arrays and the msphere arrays
  ;;I do this b/c I have to account for all the possible times in a day
  ;;and, for example, if the first ps crossing starts at 01:00 then, at
  ;;this point, the msphere array won't have any values from 00:00-01:00.
  ;;I also want to ensure that the apogee and perigee arrays have the
  ;;same number of entries. This makes the looping easler later on.
  ;;--------------------------------------------------

  ;;see if we need to pad the apogee array with a single time
  ;;that's the start of the first day.
  tt0 = psiF[0]
  tt0t = strmid(tt0,0,10) + '/00:00:00'
  if time_double(tt0) - time_double(tt0t) gt 0 then begin
    mspherei = [tt0t,mspherei]
    msphereo = [tt0,msphereo]
    ;;do this so psi and pso arrays have same number of elements
    psiF = [tt0t,psiF]
    psoF = [tt0t,psoF]

    lshelliF = [lshelliF[0],lshelliF]
    lshelloF = [lshelloF[0],lshelloF]
  endif

  ;;see if we need to pad the apogee array with a single time
  ;;that's the end of the last day.
  tt0 = psoF[n_elements(psoF)-1]
  tt0t = strmid(tt0,0,10) + '/23:59:59'
  if time_double(tt0t) - time_double(tt0) ge 0 then begin
    mspherei = [mspherei,tt0]
    msphereo = [msphereo,tt0t]

    ;   lshelliF = [lshelliF,lshelliF[n_elements(lshelliF)-1]]
    ;   lshelloF = [lshelloF,lshelloF[n_elements(lshelloF)-1]]
  endif



  if print_output then begin
    print,'Plasmasphere entry/exit times          ||| Magnetosphere entry/exit times'
    for i=0,n_elements(psiF)-1 do print,psiF[i] + ' ' + psoF[i] + ' ||| ' + $
    mspherei[i] + ' ' + msphereo[i]
  endif



  vals = {$
  ps_inboundT:psiF,$
  ps_outboundT:psoF,$
  msphere_inboundT:mspherei,$
  msphere_outboundT:msphereo,$
  lshelli:lshelliF,$
  lshello:lshelloF,$
  mlti:mltiF,$
  mlto:mltoF,$
  mlati:mlatiF,$
  mlato:mlatoF,$
  radiusi:radiusiF,$
  radiuso:radiusoF}

  return,vals

end
