;+
; NAME: plasmasphere_crossing_id
; PURPOSE: Identify times (SINGLE DAY) when a sc crosses into and out
; of the plasmasphere. The innermost inbound and outbound crossings
; are identified.
; INPUT: times -> array of unix times
;        density -> array of density values (cm-3) (set missing values
;        as NaN)
;        perigeeT -> array of times when sc reaches perigee
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

function plasmasphere_crossing_id,times,density,perigeeT,$
                                  dens_lim=dens_lim



test = 0
if test ne 1 then date = strmid(time_string(times[0]),0,10)


if test then begin
	date = '2013-02-10'
	timespan,date
	probe='a'
	rbspx='rbspa'

  rbsp_read_ect_mag_ephem,probe
  rbsp_load_efw_waveform_l3,probe=probe


  ylim,rbspx+'_efw_density',1,10000,1
  get_data,rbspx+'_efw_density',times,density

;density[*] = 1.
;goo = where((times ge time_double('2013-01-01/02:30:00')) and (times le time_double('2013-01-01/16:30:00')))
;density[goo] = 200.

  get_data,rbspx+'_efw_mlt',ttmp,mlt
  get_data,rbspx+'_efw_lshell',ttmp,lshell
  get_data,rbspx+'_efw_mlat',ttmp,mlat
  get_data,rbspx+'_efw_pos_gse',ttmp,gse
  radius = sqrt(gse[*,0]^2 + gse[*,1]^2 + gse[*,2]^2)


;  tinterpol_mxn,'rbsp'+probe+'_ME_orbitnumber',times
  get_data,'rbsp'+probe+'_ME_orbitnumber',ttmp,orbit


  perigee_loc = where(orbit - shift(orbit,1) eq 1)
  perigeeT = ttmp[perigee_loc]

;perigeeT = '2013-01-01/'+['01:55','04:00','06:00','08:00','10:00','12:00','14:00','16:10','18:00','20:00','22:00','24:00']
;perigeeT = time_double(perigeeT)

print,time_string(perigeet)


endif


if test then stop

  if ~keyword_set(dens_lim) then dens_lim = 100.



;arrays with crossing times
  densinbound100 = fltarr(n_elements(perigeeT))
  densoutbound100 = fltarr(n_elements(perigeeT))
  psstart = dblarr(n_elements(perigeeT))
  psend = dblarr(n_elements(perigeeT))
;array index of crossings (used with density)
  wh_psstart = fltarr(n_elements(perigeeT))
  wh_psend = fltarr(n_elements(perigeeT))


	q=0
  ;; For each perigee crossing in a day...
  while q le n_elements(perigeeT)-1 do begin

     skip_fac = 0.

     goobefore = where(times le perigeeT[q]) ;Times before the perigee
     gooafter = where(times gt perigeeT[q])  ;Times after the perigee

     binbefore = density[goobefore] lt 100
     tmp = where(binbefore eq 1)

	 ;-----
	 ;Case 1(entry): We're in PS at time of perigee
     if tmp[0] ne -1 and binbefore[n_elements(binbefore)-1] ne 1 then begin
        ;print,density[goobefore[tmp]]

                                ;index of nearest 100/cc element before perigee
        gooinbound100 = tmp[n_elements(tmp)-1]
                                ;density of that element
        densinbound100[q] = density[goobefore[gooinbound100]]
                                ;time of that element
        psstart[q] = times[goobefore[gooinbound100]]
                                ;array element of that element in dens array
        wh_psstart[q] = goobefore[gooinbound100]

        if test then stop
     endif

	 ;-----
	 ;Case 2(entry): We're outside of PS at time of perigee
     if tmp[0] ne -1 and binbefore[n_elements(binbefore)-1] eq 1 then begin
        psstart[q] = 0.
                                ;array element of that element in dens array
        wh_psstart[q] = -1

		if test then stop
     endif



	 ;-----
     ;Case 3(entry): day starts in PS
     if tmp[0] eq -1 then begin
		;manually set entry time to first time of day
        densinbound100[q] = density[0]
        psstart[q] = time_double(date + '/00:00:00')
        wh_psstart[q] = 0.

		if test then stop
     endif

     print,'Entry into PP at ' + time_string(psstart[q]) + $
           ' for perigee at  ' + time_string(perigeeT[q])


     binafter = density[gooafter] lt 100
     tmp = where(binafter eq 1)

	 ;Now find the PS exit time
	 ;-----
	 ;Case 1(exit): We're in PS at time of perigee
     if tmp[0] ne -1 and psstart[q] ne 0. then begin

		;print,density[gooafter[tmp]]
        goooutbound100 = tmp[0]
        densoutbound100[q] = density[gooafter[goooutbound100]]
        psend[q] = times[gooafter[goooutbound100]]
        wh_psend[q] = gooafter[goooutbound100]


		;Check to see that exit from PS is not after the next perigee time.
		;Corresponds to situation where sc never leaves PS during an orbit

		;get remaining perigee times
		if n_elements(perigeeT)-1 ge q+1 then begin
			perigeeT_goo = perigeeT[q+1:n_elements(perigeeT)-1]
			skip_fac = psend[q] gt perigeeT_goo
		endif else skip_fac = 0.

		if test then stop
     endif


	 ;-----
     ;Case 2(exit): We're outside of PS at time of perigee
     if psstart[q] eq 0. then begin
     	psend[q] = 0.
		wh_psend[q] = -1.

		if test then stop
     endif


	 ;-----
     ;Case 3(exit): still in PS at day end boundary
     if tmp[0] eq -1 then begin
		;manually set exit time to last time of day
        densoutbound100[q] = density[n_elements(density)-1]
        psend[q] = time_double(date + '/23:59:59')
        wh_psend[q] = n_elements(times)-1

		if test then stop
     endif


	     print,'Exit of PP at    ' + time_string(psend[q]) + $
           ' for perigee at  ' + time_string(perigeeT[q])

		if test then stop
	print,skip_fac
	q = q + 1 + total(skip_fac)
  endwhile

print,time_string(psstart)
print,time_string(psend)


;get rid of non-crossings
goo = where(psstart ne 0.)
if goo[0] ne -1 then psstart = psstart[goo]
if goo[0] ne -1 then psend = psend[goo]
if goo[0] ne -1 then wh_psstart = wh_psstart[goo]
if goo[0] ne -1 then wh_psend = wh_psend[goo]

;stop

;;------------------------------------------------------------------------------
  ;;Test first and last times in day to see if we start or end in the plasmasphere.
  ;;This is different than case(enter) and case3(exit) from above.

;;Sometimes we can find ourselves back in PS and not know it
  ;;from above algorithm which relies on orbit boundaries
  ;;(perigee). If the perigee occurs nearly enough on the next day
  ;;we may be in PS and not know it.
  ;;If so, then backtrack to see how long we've been in PS.



    ;find first non NaN value of density
   boop = where(finite(density) ne 0)
   densv = density[boop[0]]

   if densv ge 100. then begin
      goo = where(density le 100.,cnt)
      firstpp = goo[0]
      if times[firstpp] lt psstart[0] then begin
         psstart = [time_double(date+'/00:00:00'), psstart]
         psend = [time_double(times[firstpp]), psend]
         wh_psstart = [0, wh_psstart]
         wh_psend =   [firstpp, wh_psend]

		if test then stop
      endif
   endif

   ;find last non NaN value of density
  boop = where(finite(density) ne 0)
  densv = density[boop[n_elements(boop)-1]]
  if densv ge 100. then begin
     goo = where(density le 100.,cnt)
     lastpp = goo[cnt-1]
     if times[lastpp] gt psend[n_elements(psend)-1] then begin
        psstart = [psstart, time_double(times[lastpp])]
        psend = [psend, time_double(date+'/23:59:59')]
        wh_psstart = [wh_psstart, lastpp]
;        wh_psend =   [wh_psend,   n_elements(times)-1]
        wh_psend =   [wh_psend,   boop[n_elements(boop)-1]]

;boop[n_elements(boop)-1]

		if test then stop
     endif
  endif


;stop

  vals = {psstart:psstart,$
          psend:psend,$
          where_start:wh_psstart,$
          where_end:wh_psend}

  return,vals



end
