;+
; NAME: plasmasphere_crossing_id
; PURPOSE: Identify times (SINGLE DAY) when a sc crosses into and out
; of the plasmasphere. The innermost inbound and outbound crossings
; are identified.
; INPUT: times -> array of unix times
;        density -> array of density values (cm-3) (set missing values
;        as NaN)
;        orbit -> sc orbit number (increments at perigee)
; OUTPUT: structure with the following:
;       psstart --> time of PS entry
;       psend   --> time of PS exit
;       where_start --> array location of PS entry
;       where_end   --> array location of PS exit
; KEYWORDS: dens_lim --> density value for PP crossing. Defaults to 100/cc
; HISTORY: Written by Aaron W Breneman, May 2016
; VERSION: 
;   $LastChangedBy: $
;   $LastChangedDate: $
;   $LastChangedRevision: $
;   $URL: $
;-

function plasmasphere_crossing_id,times,density,orbit,$
                                  dens_lim=dens_lim
  


  date = strmid(time_string(times[0]),0,10)

  if ~keyword_set(dens_lim) then dens_lim = 100.



;; Find how far from perigee (time, in either direction) you have to go to reach
;;100/cc

  perigeeT = where(orbit - shift(orbit,1) eq 1)
  perigeeT = times[perigeeT]    ;exact perigee times


;arrays with crossing times
  densinbound100 = fltarr(n_elements(perigeeT))
  densoutbound100 = fltarr(n_elements(perigeeT))
  psstart = dblarr(n_elements(perigeeT))
  psend = dblarr(n_elements(perigeeT))
;array index of crossings (used with density)
  wh_psstart = fltarr(n_elements(perigeeT))
  wh_psend = fltarr(n_elements(perigeeT))



  ;; For each perigee crossing in a day...
  for q=0,n_elements(perigeeT)-1 do begin

     goobefore = where(times le perigeeT[q]) ;Times before the perigee
     gooafter = where(times gt perigeeT[q])  ;Times after the perigee

     binbefore = density[goobefore] lt 100
     tmp = where(binbefore eq 1)

     if tmp[0] ne -1 then begin
                                ;print,density[goobefore[tmp]]


                                ;index of nearest 100/cc element before perigee
        gooinbound100 = tmp[n_elements(tmp)-1]
                                ;density of that element
        densinbound100[q] = density[goobefore[gooinbound100]]
                                ;time of that element
        psstart[q] = times[goobefore[gooinbound100]]
                                ;array element of that element in dens array
        wh_psstart[q] = goobefore[gooinbound100]
     endif else begin

        densinbound100[q] = density[0]
        psstart[q] = time_double(date + '/00:00:00')
        wh_psstart[q] = 0.

     endelse

     print,'Entry into PP at ' + time_string(psstart[q]) + $
           ' for perigee at  ' + time_string(perigeeT[q])

     binafter = density[gooafter] lt 100
     tmp = where(binafter eq 1)

     if tmp[0] ne -1 then begin

;print,density[gooafter[tmp]]
        goooutbound100 = tmp[0]
        densoutbound100[q] = density[gooafter[goooutbound100]]
        psend[q] = times[gooafter[goooutbound100]]
        wh_psend[q] = gooafter[goooutbound100]

     endif else begin

        densoutbound100[q] = density[n_elements(density)-1]
        psend[q] = time_double(date + '/23:59:59')
        wh_psend[q] = n_elements(times)-1

     endelse

     print,'Exit of PP at    ' + time_string(psend[q]) + $
           ' for perigee at  ' + time_string(perigeeT[q])

  endfor


;;------------------------------------------------------------------------------
  ;;Test day end boundary to see if we've reentered into
  ;;PS. Sometimes we can find ourselves back in PS and not know it
  ;;from above algorithm which relies on orbit boundaries
  ;;(perigee). If the perigee occurs nearly enough on the next day
  ;;we may be in PS and not know it.  
  ;;If so, then backtrack to see how long we've been in PS.


  ;;day end boundary
  densv = density[n_elements(density)-1]
  if densv ge 100. then begin
     goo = where(density le 100.,cnt)
     lastpp = goo[cnt-1]
     if times[lastpp] gt psend[n_elements(psend)-1] then begin
        psstart = [psstart, time_double(times[lastpp])]
        psend = [psend, time_double(date+'/23:59:59')]
     endif  
  endif

  ;; ;;day beginning boundary
  ;; densv = density[0]
  ;; if densv ge 100. then begin
  ;;    goo = where(density le 100.,cnt)
  ;;    firstpp = goo[0]
  ;;    if times[firstpp] lt psstart[0] then begin
  ;;       psstart = [time_double(date+'/00:00:00'), psstart]
  ;;       psend = [time_double(times[firstpp]), psend]
  ;;    endif  
  ;; endif



  vals = {psstart:psstart,$
          psend:psend,$
          where_start:wh_psstart,$
          where_end:wh_psend}

  return,vals


  
end





;; if type eq 'vsvy' then begin


;; ps = bytarr(n_elements(times))
;; if goo[0] ne -1 then ps[goo] = 1
;; times = times

;; store_data,'plasmasphere',data={x:times,y:ps}
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
