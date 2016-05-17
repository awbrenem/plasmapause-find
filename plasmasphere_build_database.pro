;Build a database of times RBSP are in the plasmasphere.
;Includes Lshell (simple dipole), MLT, mlat and radius of entry and exits
;Meant to be called from plasmasphere_build_database_driver.py

;This is run a single day at a time, so day start and end can be
;artificially labeled as PP crossings. 


;Saves to a file called plasmasphere_rbspX_database.txt


pro plasmasphere_build_database,times,density,mlt,lshell

  ;; args = command_line_args()
  ;; print, args

  ;; date = args[0]
  ;; probe = args[1]

  date = '2013-02-14'
  probe = 'a'



  timespan,date
  rbspx = 'rbsp'+probe


  rbsp_read_ect_mag_ephem,probe


  rbsp_load_efw_waveform_l3,probe=probe
  split_vec,rbspx+'_efw_mlt_lshell_mlat'
  copy_data,rbspx+'_efw_mlt_lshell_mlat_x',rbspx+'_efw_mlt'
  copy_data,rbspx+'_efw_mlt_lshell_mlat_y',rbspx+'_efw_lshell'
  copy_data,rbspx+'_efw_mlt_lshell_mlat_z',rbspx+'_efw_mlat'

  ;; split_vec,rbspx+'_efw_flags_all'
  ;; copy_data,rbspx+'_efw_flags_all_0',rbspx+'_efw_flag_global'
  ;; copy_data,rbspx+'_efw_flags_all_1',rbspx+'_efw_flag_eclipse'
  ;; copy_data,rbspx+'_efw_flags_all_15',rbspx+'_efw_flag_charging'

  ylim,rbspx+'_efw_density',1,10000,1


  get_data,rbspx+'_efw_mlt',ttmp,mlt
  get_data,rbspx+'_efw_lshell',ttmp,lshell
;  get_data,rbspx+'_efw_mlat',ttmp,mlat
  get_data,rbspx+'_efw_pos_gse',ttmp,gse
  radius = sqrt(gse[*,0]^2 + gse[*,1]^2 + gse[*,2]^2)


;;------------------------------------------------------------------------------
;; FIND OUT TIMES WHEN WE ARE IN PLASMASPHERE
;;------------------------------------------------------------------------------


;;--------------------------------------------------
;; VERSION 1...using a density value of 100/cc
;; Find innermost crossings based on each perigee (from orbit number)
;;--------------------------------------------------

  get_data,rbspx+'_efw_density',data=dens

;;since density is not continuous (it's removed at perigee), I
;;need to find how far away from perigee you have to go to reach
;;100/cc

  get_data,'rbsp'+probe+'_ME_orbitnumber',data=orbit
  perigeeT = where(orbit.y - shift(orbit.y,1) eq 1)
  perigeeT = orbit.x[perigeeT]  ;exact perigee times

;arrays with crossing times
  densinbound100 = fltarr(n_elements(perigeeT))
  densoutbound100 = fltarr(n_elements(perigeeT))
  psstart = dblarr(n_elements(perigeeT))
  psend = dblarr(n_elements(perigeeT))
;array index of crossings (used with dens.y)
  wh_psstart = fltarr(n_elements(perigeeT))
  wh_psend = fltarr(n_elements(perigeeT))

;  print,time_string(perigeeT)


  for q=0,n_elements(perigeeT)-1 do begin

     goobefore = where(dens.x le perigeeT[q])  ;Times before the perigee
     gooafter = where(dens.x gt perigeeT[q])   ;Times after the perigee

     binbefore = dens.y[goobefore] lt 100
     tmp = where(binbefore eq 1)

     if tmp[0] ne -1 then begin
        ;print,dens.y[goobefore[tmp]]

        ;index of nearest 100/cc element before perigee
        gooinbound100 = tmp[n_elements(tmp)-1]
        ;density of that element
        densinbound100[q] = dens.y[goobefore[gooinbound100]]
        ;time of that element
        psstart[q] = dens.x[goobefore[gooinbound100]]
        ;array element of that element in dens array
        wh_psstart[q] = goobefore[gooinbound100]
     endif else begin
        densinbound100[q] = dens.y[0]   ;!values.f_nan
        psstart[q] = time_double(date + '/00:00:00')
        wh_psstart[q] = 0.
     endelse
     print,'Entry into PP at ' + time_string(psstart[q]) + ' for perigee at  ' + time_string(perigeeT[q])

     binafter = dens.y[gooafter] lt 100
     tmp = where(binafter eq 1)

     if tmp[0] ne -1 then begin
;   print,dens.y[gooafter[tmp]]
        goooutbound100 = tmp[0]
        densoutbound100[q] = dens.y[gooafter[goooutbound100]]
        psend[q] = dens.x[gooafter[goooutbound100]]
        wh_psend[q] = gooafter[goooutbound100]
     endif else begin
        densoutbound100[q] = dens.y[n_elements(dens.y)-1]
        psend[q] = time_double(date + '/23:59:59')
        wh_psend[q] = n_elements(dens.x)-1
     endelse
     print,'Exit of PP at    ' + time_string(psend[q]) + ' for perigee at  ' + time_string(perigeeT[q])

  endfor


  ;;Test day end boundary to see if we've reentered into
  ;;PS. Sometimes we can find ourselves back in PS and not know it
  ;;from above algorithm which relies on orbit boundaries
  ;;(perigee). If the perigee occurs nearly enough on the next day
  ;;we may be in PS and not know it.  
  ;;If so, then backtrack to see how long we've been in PS.


  ;;day end boundary
  densv = dens.y[n_elements(dens.y)-1]
  if densv ge 100. then begin
     goo = where(dens.y le 100.,cnt)
     lastpp = goo[cnt-1]
     if dens.x[lastpp] gt psend[n_elements(psend)-1] then begin
        psstart = [psstart, time_double(dens.x[lastpp])]
        psend = [psend, time_double(date+'/23:59:59')]

     endif  
  endif

  ;; ;;day beginning boundary
  ;; densv = dens.y[0]
  ;; if densv ge 100. then begin
  ;;    goo = where(dens.y le 100.,cnt)
  ;;    firstpp = goo[0]
  ;;    if dens.x[firstpp] lt psstart[0] then begin
  ;;       psstart = [time_double(date+'/00:00:00'), psstart]
  ;;       psend = [time_double(dens.x[firstpp]), psend]
  ;;    endif  
  ;; endif


stop


  lshellstart = lshell[wh_psstart]
  lshellend = lshell[wh_psend]
  mltstart = mlt[wh_psstart]
  mltend = mlt[wh_psend]
  mlatstart = mlat[wh_psstart]
  mlatend = mlat[wh_psend]
  radiusstart = radius[wh_psstart]/6370.
  radiusend = radius[wh_psend]/6370.



  ;;check to make sure there are any PP crossings before trying to
  ;;save to file
  goo = where(psstart ne 0.)
  if goo[0] ne -1 then begin

     psstart = psstart[goo]
     psend = psend[goo]
     lshellstart = lshellstart[goo]
     lshellend = lshellend[goo]
     mltstart = mltstart[goo]
     mltend = mltend[goo]
     mlatstart = mlatstart[goo]
     mlatend = mlatend[goo]
     radiusstart = radiusstart[goo]
     radiusend = radiusend[goo]

     psdiff = psend - psstart



     path = '~/Desktop/code/Aaron/RBSP/survey_programs_hiss/'
     fn = 'plasmasphere_'+rbspx+'_database.txt'


     if not file_test(path+fn) then header = 1 else header = 0

     openw,lun,path+fn,/get_lun,/append
     
     if header then printf,lun,'PS enter              PS exit      Timeinside(s) Lenter Lexit MLTenter MLTexit mlatenter mlatexit Renter(RE) Rexit(RE)'
     for i=0L,n_elements(psstart)-1 do printf,lun,$
                                              time_string(psstart[i]),time_string(psend[i]),$
                                              psdiff[i],$
                                              lshellstart[i],lshellend[i],$
                                              mltstart[i],mltend[i],$
                                              mlatstart[i],mlatend[i],$
                                              radiusstart[i],radiusend[i],$
                                              format='(A19,2x,A19,2x,f6.0,2x,f6.3,2x,f6.3,2x,f6.3,2x,f6.3,2x,f7.3,2x,f7.3,2x,f6.3,2x,f6.3)'
     close,lun
     free_lun,lun


endif
  
end





;; if type eq 'vsvy' then begin


;; ps = bytarr(n_elements(dens.x))
;; if goo[0] ne -1 then ps[goo] = 1
;; times = dens.x

;; store_data,'plasmasphere',data={x:dens.x,y:ps}
;; ylim,'plasmasphere',0,1.5
;; ;VERSION 2...USING (V1+V2)/2
;;   get_data,rbspx+'_efw_Vavg',data=vavg
;;   goo = where((vavg.y ge -2.) and (vavg.y lt 0.))
;;   ps = bytarr(n_elements(vavg.x))
;;   if goo[0] ne -1 then ps[goo] = 1
;;   ;REMOVE THE GAP THAT USUALLY EXISTS AT PERIGEE B/C THE SC POTENTIAL IS
;;   ;TOO HIGH
;;   goo = where(lshell le 2.5)
;;   if goo[0] ne -1 then ps[goo] = 1
;;   times = vavg.x


;;   store_data,'plasmasphere2',data={x:times,y:ps}
;;   ylim,'plasmasphere2',0,1.5
;;   ylim,rbspx+'_efw_Vavg',-10,4,0



;; ;-1  = heading out of plasmasphere
;; ;1   = entering plasmsphere

;;   dif_bool = floor(float(ps) - shift(float(ps),1))
;;   store_data,'dif_bool',data={x:times,y:dif_bool}
;;   ylim,'dif_bool',-1.5,1.5
;; ;  tplot,'dif_bool'


;;   goo = where(dif_bool eq 1)
;;   if goo[0] ne -1 then psstart = times[goo] else psstart = time_double(date + '/00:00:00')
;;   if goo[0] ne -1 then lshellstart = lshell[goo]
;;   if goo[0] ne -1 then mltstart = mlt[goo]
;;   if goo[0] ne -1 then mlatstart = mlat[goo]
;;   if goo[0] ne -1 then radiusstart = radius[goo]/6370.

;;   goo = 0.
;;   goo = where(dif_bool eq -1)
;;   if goo[0] ne -1 then psend = times[goo-1] else psend = time_double(date + '/00:00:00')
;;   if goo[0] ne -1 then lshellend = lshell[goo]
;;   if goo[0] ne -1 then mltend = mlt[goo]
;;   if goo[0] ne -1 then mlatend = mlat[goo]
;;   if goo[0] ne -1 then radiusend = radius[goo]/6370.




;; ;do we start and/or end inside of PS?
;;   startinps = ps[0] eq 1        ; (psend[0] - psstart[0]) lt 0
;;   endinps = ps[n_elements(ps)-1] eq 1

;;   print,'start in ps = ',startinps
;;   print,'end in ps = ',endinps

;;   if startinps and (psend[0] - psstart[0]) lt 0 then psstart = [times[0],psstart]
;;   if endinps then psend = [psend,time_double(date+'/23:59:59')]
;;   if not startinps and endinps then psstart = [psend[0],psstart]


;; ;; help,psstart,psend
;; ;; for i=0,100 do print,time_string(psstart[i]) + ' to ' + time_string(psend[i])




;; ;Remove elements when the difference b/t ps start and ps end is too
;; ;small

;; stop
;;   psdiff = psend - psstart
;;   goo = 0.
;;   goo = where(psdiff ge minsep)


;; stop

;;   if goo[0] ne -1 then psstart = psstart[goo]
;;   if goo[0] ne -1 then psend = psend[goo]
;;   if goo[0] ne -1 then lshellstart = lshellstart[goo]
;;   if goo[0] ne -1 then lshellend = lshellend[goo]
;;   if goo[0] ne -1 then mltstart = mltstart[goo]
;;   if goo[0] ne -1 then mltend = mltend[goo]
;;   if goo[0] ne -1 then mlatstart = mlatstart[goo]
;;   if goo[0] ne -1 then mlatend = mlatend[goo]
;;   if goo[0] ne -1 then radiusstart = radiusstart[goo]
;;   if goo[0] ne -1 then radiusend = radiusend[goo]


;;   ;; tplot,'plasmasphere2'
;;   ;; timebar,psstart,color=250
;;   ;; timebar,psend,color=150

;;   psstartS = time_string(psstart)
;;   psendS = time_string(psend)

;;   for i=0,n_elements(psstartS)-1 do print,psstartS[i] + ' to ' + psendS[i]
;;   for i=0,n_elements(psstartS)-1 do print,psend[i] - psstart[i]

;; endif
;--------------------------------------------------
