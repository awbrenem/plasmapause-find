;Calls the general routine rbsp_plasmasphere_build_database.pro with
;input values for RBSP (Van Allen Probes)

;saves an array at end with values

;Called by plasmasphere_build_database_rbsp.py


pro plasmasphere_build_database_driver_rbsp

    args = command_line_args()
    print, args
    date = args[0]
    probe = args[1]



;  date = '2012-12-31'
;  probe = 'a'



  print,'**************'
  print,date
  print,probe
  print,'**************'

  timespan,date
  rbspx = 'rbsp'+probe


  rbsp_read_ect_mag_ephem,probe


  rbsp_load_efw_waveform_l3,probe=probe
  split_vec,rbspx+'_efw_mlt_lshell_mlat'
  copy_data,rbspx+'_efw_mlt_lshell_mlat_x',rbspx+'_efw_mlt'
  copy_data,rbspx+'_efw_mlt_lshell_mlat_y',rbspx+'_efw_lshell'
  copy_data,rbspx+'_efw_mlt_lshell_mlat_z',rbspx+'_efw_mlat'

  ylim,rbspx+'_efw_density',1,10000,1
  get_data,rbspx+'_efw_density',times,density


  get_data,rbspx+'_efw_mlt',ttmp,mlt
  get_data,rbspx+'_efw_lshell',ttmp,lshell
  get_data,rbspx+'_efw_mlat',ttmp,mlat
  get_data,rbspx+'_efw_pos_gse',ttmp,gse
  radius = sqrt(gse[*,0]^2 + gse[*,1]^2 + gse[*,2]^2)

  ;  tinterpol_mxn,'rbsp'+probe+'_ME_orbitnumber',times
  get_data,'rbsp'+probe+'_ME_orbitnumber',ttmp,orbit


  perigee_loc = where(orbit - shift(orbit,1) eq 1)
  perigeeT = ttmp[perigee_loc]


  ;  path = '~/Desktop/code/Aaron/RBSP/survey_programs_hiss/'
  path = '/Users/aaronbreneman/Desktop/Research/RBSP_FBK_first_results/datafiles/'
  fn = 'plasmasphere_'+rbspx+'_database.txt'
;  fn = 'plasmasphere_'+rbspx+'_database_' + d0 + '_' + d1 + '.txt'


  vals = plasmasphere_crossing_id(times,density,perigeeT)








  lshellstart = lshell[vals.where_start]
  lshellend = lshell[vals.where_end]
  mltstart = mlt[vals.where_start]
  mltend = mlt[vals.where_end]
  mlatstart = mlat[vals.where_start]
  mlatend = mlat[vals.where_end]
  radiusstart = radius[vals.where_start]/6370.
  radiusend = radius[vals.where_end]/6370.



  ;;check to make sure there are any PP crossings before trying to
  ;;save to file
  goo = where(vals.psstart ne 0.)
  if goo[0] ne -1 then begin

    psstart = vals.psstart[goo]
    psend = vals.psend[goo]
    lshellstart = lshellstart[goo]
    lshellend = lshellend[goo]
    mltstart = mltstart[goo]
    mltend = mltend[goo]
    mlatstart = mlatstart[goo]
    mlatend = mlatend[goo]
    radiusstart = radiusstart[goo]
    radiusend = radiusend[goo]

    psdiff = psend - psstart

  endif




  if not file_test(path+fn) then header = 1 else header = 0

  openw,lun,path+fn,/get_lun,/append

  if header then printf,lun,'PS enter              PS exit      Timeinside(s) Lenter Lexit MLTenter MLTexit mlatenter mlatexit Renter(RE) Rexit(RE)'
  for i=0L,n_elements(psstart)-1 do printf,lun,$
  time_string(psstart[i]),$
  time_string(psend[i]),$
  psdiff[i],$
  lshellstart[i],lshellend[i],$
  mltstart[i],mltend[i],$
  mlatstart[i],mlatend[i],$
  radiusstart[i],radiusend[i],$
  format='(A19,2x,A19,2x,f6.0,2x,f6.3,2x,f6.3,2x,f6.3,2x,f6.3,2x,f7.3,2x,f7.3,2x,f6.3,2x,f6.3)'


  close,lun
  free_lun,lun


end
