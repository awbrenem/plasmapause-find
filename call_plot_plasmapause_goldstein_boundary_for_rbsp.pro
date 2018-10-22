;Plot the plasmapause locations over time based on RBSP inbound and outbound crossings
;Overplots this on a dial plot using plasmapause_goldstein_boundary.pro

pro call_plot_plasmapause_goldstein_boundary_for_rbsp

  date = '2014-01-04'

  rbsp_efw_init



  ;Load RBSP ephemeris data for day prior, day of, and day after
  prevdate = time_double(date)-86400.
  timespan,date,3,/days
  rbsp_efw_position_velocity_crib
  get_data,'rbspa_state_lshell',ttmp,la
  get_data,'rbspb_state_lshell',ttmp,lb
  get_data,'rbspa_state_mlt',ttmp,mlta
  get_data,'rbspb_state_mlt',ttmp,mltb
  times = ttmp






  ;Load the RBSP plasmapause crossing times/locations
  fn = '~/Desktop/code/Aaron/github.umn.edu/plasmapause-find/output/' + $
  'plasmasphere_rbspa_database_2014.txt'
  vals_rb = plasmasphere_crossing_load(fn)

  psi = vals_rb.ps_inboundT & psiday = psi
  pso = vals_rb.ps_outboundT & psoday = pso
  for i=0,n_elements(psi)-1 do psiday[i] = strmid(psi[i],0,10)
  for i=0,n_elements(pso)-1 do psoday[i] = strmid(pso[i],0,10)

  ;Find RBSP Inbound/Outbound crossings for day of interest
  goo = where(psiday eq date)
  for i=0,n_elements(goo)-1 do timesinboundi = time_double(psi[goo])
  timesinboundo = time_double(pso[goo])

 
 
  ;Extract RBSP times +/- n hrs 
  timeplot = time_double(date + '/23:59')
  n_pmhrs = 2.5
  goodindices = where((times ge time_double(timeplot)-n_pmhrs*3600.) and (times le time_double(timeplot)+n_pmhrs*3600.))

  ;extra title to indicate RBSP timerange 
  traj0 = time_string(times[goodindices[0]])
  traj1 = time_string(times[goodindices[n_elements(goodindices)-1]])

  et = 'RBSP trajectory from!C' + traj0 + ' to ' + traj1


  ;Find which of these times corresponds to RBSP inside and outside of PS
  ;Create a binary variable showing in/out as function of time 
  pp_in = replicate(0.,n_elements(times))
  for i=0,n_elements(timesinboundi)-1 do begin $
    boo = where((times ge timesinboundi[i]) and (times lt timesinboundo[i])) & $
    if boo[0] ne -1 then pp_in[boo] = 1.

  pp_out = (1-pp_in)


  ;plot times when RBSP is inside of PS
  plot_plasmapause_goldstein_boundary,timeplot,mlta[goodindices]*pp_out[goodindices],la[goodindices]*pp_out[goodindices],colorplot=0,extratitle=et,xrange=[-10,10],yrange=[-10,10] ;,plot=plotpp,ps=ps,name=name
  ;oplot times when RBSP is outside of PS
  plot_plasmapause_goldstein_boundary,timeplot,mlta[goodindices]*pp_in[goodindices],la[goodindices]*pp_in[goodindices],colorplot=250,/oplot ;,plot=plotpp,ps=ps,name=name



end
