;Grabs for each time the closest distance to the plasmapause from the Goldstein model, and 
;saves various results in tplot variables. This includes variables that give the distance from the 
;plasmasphere calculated using three different methods: 
  ;;--first sorting method: values outside of the pp are referenced to
  ;;the closest measured pp value in time
  ;;--second sorting method: values outside of the pp are referenced to
  ;;the closest measured pp value in MLT
  ;;--third sorting method: Goldstein pp model


pro call_get_distance_from_plasmapause_goldstein_boundary


  date = '2014-01-04'
  timespan,date
  t0 = date + '/16:00'
  t1 = date + '/23:00'

  rbsp_efw_init



  ;Load the RBSP plasmapause crossing times
  fn = '~/Desktop/code/Aaron/github.umn.edu/plasmapause-find/output/' + $
  'plasmasphere_rbspa_database_2014.txt'
  vals_rb = plasmasphere_crossing_load(fn)



  ;Load RBSP ephemeris data
  rbsp_efw_position_velocity_crib
  get_data,'rbspa_state_lshell',ttmp,la
  get_data,'rbspb_state_lshell',ttmp,lb
  get_data,'rbspa_state_mlt',ttmp,mlta
  get_data,'rbspb_state_mlt',ttmp,mltb
  times = ttmp




  pp = get_distance_from_plasmapause_goldstein_boundary(times,mlta,la)

  l_nearest = pp.l_nearest
  mlt_nearest = pp.mlt_nearest
  goo = where(pp.distance_from_pp lt 0.)
  if goo[0] ne -1 then l_nearest[goo] = !values.f_nan
  if goo[0] ne -1 then mlt_nearest[goo] = !values.f_nan


  store_data,'gold_l_nearest',time_double(times),l_nearest
  store_data,'gold_mlt_nearest',time_double(times),mlt_nearest
  store_data,'gold_distance_from_pp',time_double(times),pp.distance_from_pp
  store_data,'gold_mlt_offset',time_double(times),pp.mlt_offset





  ;;----------------------------------------------------------------------------
  ;; Create distance from plasmapause variable


  ;;--first sorting method: values outside of the pp are referenced to
  ;;the closest measured pp value in time
  ;;--second sorting method: values outside of the pp are referenced to
  ;;the closest measured pp value in MLT
  ;;--third sorting method: Goldstein pp model




  psvals = fltarr(n_elements(times))
  lshell_ref = fltarr(n_elements(times))


  ;--first sorting method
  for i=0l,n_elements(vals_rb.ps_inboundt)-2 do begin
    tp0 = time_double(vals_rb.ps_inboundt[i])
    tp1 = time_double(vals_rb.ps_outboundt[i])

    tm0 = time_double(vals_rb.msphere_inboundt[i])
    tm1 = time_double(vals_rb.msphere_outboundt[i])
    print,'**********'
    print,'Plasmasphere: ' + time_string(tp0) + ' to ' + time_string(tp1)
    print,'Magsphere:    ' + time_string(tm0) + ' to ' + time_string(tm1)



    ;--chunk1
    tstart = tp0 < tm0
    tend = (tp1 - (tp1 - tp0)/2.) < (tm1 - (tm1 - tm0)/2.)
    tgoo = where((times ge tstart) and (times le tend))

    if tp0 lt tm0 then region = 'ps' else region = 'ms'
    if tgoo[0] ne -1 then begin
      if region eq 'ps' then lshell_ref[tgoo] = vals_rb.lshelli[i]
      if region eq 'ms' then lshell_ref[tgoo] = vals_rb.lshelli_ms[i]
    endif

    print,'...Chunk1: ' + region + ' ' + time_string(tstart) + ' to ' + $
      time_string(tend)
    ;; if region eq 'ps' then print,vals_rb.lshelli[i]
    ;; if region eq 'ms' then print,vals_rb.lshelli_ms[i]



    ;--chunk2
    tstart = tend
    tend = tp1 < tm1
    tgoo = where((times ge tstart) and (times le tend))

    if tp1 lt tm1 then region = 'ps' else region = 'ms'
    if tgoo[0] ne -1 then begin
      if region eq 'ps' then lshell_ref[tgoo] = vals_rb.lshello[i]
      if region eq 'ms' then lshell_ref[tgoo] = vals_rb.lshello_ms[i]
    endif

    print,'...Chunk2: ' + region + ' ' + time_string(tstart) + ' to ' + $
      time_string(tend)
    ;; if region eq 'ps' then print,vals_rb.lshello[i]
    ;; if region eq 'ms' then print,vals_rb.lshello_ms[i]

    ;stop
    ;--chunk3
    tstart = tp0 > tm0
    tend = (tp1 - (tp1 - tp0)/2.) > (tm1 - (tm1 - tm0)/2.)
    tgoo = where((times ge tstart) and (times le tend))

    if tp0 ge tm0 then region = 'ps' else region = 'ms'
    if tgoo[0] ne -1 then begin
      if region eq 'ps' then lshell_ref[tgoo] = vals_rb.lshelli[i]
      if region eq 'ms' then lshell_ref[tgoo] = vals_rb.lshelli_ms[i]
    endif

    print,'...Chunk3: ' + region + ' ' + time_string(tstart) + ' to ' + $
      time_string(tend)
    ;; if region eq 'ps' then print,vals_rb.lshelli[i]
    ;; if region eq 'ms' then print,vals_rb.lshelli_ms[i]

    ;stop
    ;--chunk4
    tstart = tend
    tend = tp1 > tm1
    tgoo = where((times ge tstart) and (times le tend))

    if tp1 ge tm1 then region = 'ps' else region = 'ms'
    if tgoo[0] ne -1 then begin
      if region eq 'ps' then lshell_ref[tgoo] = vals_rb.lshello[i]
      if region eq 'ms' then lshell_ref[tgoo] = vals_rb.lshello_ms[i]
    endif

    print,'...Chunk4: ' + region + ' ' + time_string(tstart) + ' to ' + $
      time_string(tend)
    ;; if region eq 'ps' then print,vals_rb.lshello[i]
    ;; if region eq 'ms' then print,vals_rb.lshello_ms[i]

    print,'**********'

  endfor


  store_data,'lshell_ref',time_double(times),lshell_ref
  store_data,'lshelli',time_double(vals_rb.ps_inboundT),vals_rb.lshelli
  store_data,'lshello',time_double(vals_rb.ps_outboundT),vals_rb.lshello
  dif_data,'rbspa_lshell','lshell_ref'


  ;tlimit,t0,t1
  ;  kyoto_load_dst
  ;  tplot,['rbspa_lshell','lshell_ref','lshelli','kyoto_dst']


  copy_data,'rbspa_lshell-lshell_ref','rbspa_distance_from_pp'

  store_data,'lcomb',data=['lshelli','lshell_ref','gold_l_nearest']
  options,'lcomb','colors',[0,50,250]
  options,'lcomb','ytitle','RBSPa nearest PP(black)!CRBSPa binned PP(blue)!CGoldstein PP(red)'
  options,['lshelli','lshello'],'thick',2
  options,['lshelli','lshello'],'psym',-4

  store_data,'pp_distance_comb',data=['rbspa_distance_from_pp','gold_distance_from_pp']
  options,'pp_distance_comb','colors',[0,250]

  ylim,['rbspa_distance_from_pp','gold_distance_from_pp','pp_distance_comb'],-6,4
  ylim,'lcomb',0,7

  tplot,['rbspa_lshell',$
  'lcomb',$
  'pp_distance_comb',$
  'kyoto_dst']



  stop






  ;;------------------------------------------------------------------------------
  ;;Load Thaller PP crossing files
  ;;------------------------------------------------------------------------------

;  path2 = '~/Desktop/code/Aaron/datafiles/thaller_pp_files/'
  path2 = '/Users/aaronbreneman/Desktop/code/Aaron/github.umn.edu/plasmapause-find/output/'
;  fn = 'RBSPa_inbound_plasmapause_L_times_2013.txt'
;  fn2 = 'RBSPa_outbound_plasmapause_L_times_2013.txt'
  fn = 'RBSPb_inbound_plasmapause_L_times_2013_2016.txt'
  fn2 = 'RBSPb_outbound_plasmapause_L_times_2013_2016.txt'
  openr,lun,path2+fn,/get_lun
  openr,lun2,path2+fn2,/get_lun


  th_times = ''
  th_Lout = 0.
  th_Lin = 0.
  jnk = ''
  jnk2 = ''
  i = 0L
  while not eof(lun) do begin            ;$
    readf,lun,jnk                       ;& $
    readf,lun2,jnk2                     ;& $
    vals = strsplit(jnk,' ',/extract)   ;& $
    vals2 = strsplit(jnk2,' ',/extract) ;& $
    th_times = [th_times,vals[0]]       ;& $
    th_Lin = [th_Lin,vals[1]]           ;& $
    th_Lout = [th_Lout,vals2[1]]        ;& $
    i++
  endwhile


  close,lun,lun2
  free_lun,lun,lun2

  th_times = th_times[1:n_elements(th_times)-1]
  th_Lout = th_Lout[1:n_elements(th_times)-1]
  th_Lin = th_Lin[1:n_elements(th_times)-1]

  goo = where(th_times ne '0000-00-00/00:00:00')
  if goo[0] ne -1 then th_times = th_times[goo]
  if goo[0] ne -1 then th_Lout = th_Lout[goo]
  if goo[0] ne -1 then th_Lin = th_Lin[goo]

  store_data,'th_ppoutbound',time_double(th_times),th_Lout
  store_data,'th_ppinbound',time_double(th_times),th_Lin
  tplot,['th_ppoutbound','th_ppinbound']

  timespan,'2013-01-01',365,/days

  store_data,'lcomb2',data=['lshelli','lshell_ref','gold_l_nearest','th_ppinbound','th_ppoutbound']
  store_data,'lcomb2',data=['lshelli','gold_l_nearest','th_ppinbound']
  options,['th_ppoutbound','th_ppinbound'],'thick',2
  options,['th_ppoutbound','th_ppinbound'],'linestyle',2
  ;  options,'lcomb2','colors',[0,50,250,200,120]
  options,'lcomb2','colors',[0,250,200]
  options,'lcomb2','ytitle','RBSPa nearest PP(black)!CRBSPa binned PP(blue)!CGoldstein PP(red)'


  dif_data,'lshelli','th_ppinbound',newname='pp_diff'
  dif_data,'lshelli','gold_l_nearest',newname='pp_diff_gold'

  options,['pp_diff','pp_diff_gold'],constant=0
  ylim,['pp_diff','pp_diff_gold'],-3,3
  tplot,['rbspa_lshell',$
  'lcomb2',$
  'pp_distance_comb',$
  'pp_diff',$
  'pp_diff_gold']



stop

  rbsp_detrend,'gold_l_nearest',60.*360.

  options,'th_pp*','linestyle',0
  store_data,'tmpcomb',dat=['th_ppinbound','gold_l_nearest_smoothed']
  options,'tmpcomb','colors',[0,250]

  options,'tmpcomb','ytitle','thaller-inbound(black)!Cgoldstein-nearest(red)'
  options,'th_ppinbound','ytitle','thaller-inbound'
  options,'gold_l_nearest_smoothed','ytitle','goldstein-nearest'

  tplot,['tmpcomb','th_ppinbound','gold_l_nearest_smoothed']

  stop




end


