;;;************************************
;Test input for plasmasphere_crossing_load.pro
;;;************************************

date = '2013-01-01'
timespan,date
probe='a'
rbspx='rbspa'

  rbsp_read_ect_mag_ephem,probe

  rbsp_load_efw_waveform_l3,probe=probe
timespan,date
probe='a'
rbspx='rbspa'
  rbsp_load_efw_waveform_l3,probe=probe

  ylim,rbspx+'_efw_density',1,10000,1
  get_data,rbspx+'_efw_density',times,density

density[*] = 1.
goo = where((times ge time_double('2013-01-01/02:30:00')) and (times le time_double('2013-01-01/16:30:00')))
density[goo] = 200.



  get_data,rbspx+'_efw_mlt',ttmp,mlt
  get_data,rbspx+'_efw_lshell',ttmp,lshell
  get_data,rbspx+'_efw_mlat',ttmp,mlat
  get_data,rbspx+'_efw_pos_gse',ttmp,gse
  radius = sqrt(gse[*,0]^2 + gse[*,1]^2 + gse[*,2]^2)


;  tinterpol_mxn,'rbsp'+probe+'_ME_orbitnumber',times
  get_data,'rbsp'+probe+'_ME_orbitnumber',ttmp,orbit


  perigee_loc = where(orbit - shift(orbit,1) eq 1)
  perigeeT = ttmp[perigee_loc]

perigeeT = '2013-01-01/'+['01:55','04:00','06:00','08:00','10:00','12:00','14:00','16:10','18:00','20:00','22:00','24:00']
perigeeT = time_double(perigeeT)

print,time_string(perigeet)




;;;************************************
;;;************************************
;;;************************************
