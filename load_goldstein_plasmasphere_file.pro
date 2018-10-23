;Load the Goldstein plasmapause file nearest the requested time 
;and return arrays of L vs MLT describing the PP location

;Example of how to call: see get_distance_from_plasmapause_goldstein.pro
;or call_get_distance_from_plasmapause_goldstein.pro

;        Required plasmapause files can be found at
;        http://enarc.space.swri.edu/PTP/
;        An example of one of these is:
;        /Users/aaronbreneman/Desktop/code/Aaron/datafiles/goldstein_pp_files/20140040000.ppa



function load_goldstein_plasmasphere_file,datetime,files=files


    path = '/Users/aaronbreneman/Desktop/code/Aaron/datafiles/goldstein_pp_files/'



    ;Typically you want to pass "files" into this function if you're
    ;calling this routine for "n" array elements. Reason is b/c it takes a
    ;few sec to grab the "files" list. 
    if ~keyword_set(files) then files = get_goldstein_file_list()


    datetime = time_string(time_double(datetime))
    year0 = strmid(datetime,0,4) + '-01-01'
    doy = 1 + floor(time_double(datetime)/86400 - time_double(year0)/86400)
    doyS = ''
    for i=0L,n_elements(doy)-1 do begin
    if doy[i] lt 10 then doyS[i] = '00'+strtrim(doy[i],2)
    if doy[i] ge 10 and doy[i] lt 100 then doyS[i] = '0'+strtrim(doy[i],2)
    if doy[i] ge 100 then doyS[i] = strtrim(doy[i],2)
    endfor
    datetime = strmid(datetime,0,4) + doyS + strmid(datetime,11,2) + strmid(datetime,14,2)




    ttmp = double(datetime)
    goo = where(ttmp le files)
    file_to_load = string(files[goo[0]],format='(i11)') + '.' + 'ppa'
    
    


    ;Read in the appropriate Goldstein PP file
    openr,1,path+file_to_load
    junk = ''
    readf,1,junk
    vals = ''

    while not eof(1) do begin
        readf,1,junk
        vals = [vals,junk]
    endwhile

    close,1
    free_lun,1



    ;;Remove last 11 lines in file
    vals = vals[1:n_elements(vals)-11]
    l = fltarr(n_elements(vals))
    phi = l


    ;Grab the L and phi values
    for i=0,n_elements(vals)-1 do begin
        tmp = strsplit(vals[i],' ',/extract)
        l[i] = tmp[0]
        phi[i] = tmp[1]
    endfor


    ;Change Phi to degrees and unwrap to 0-360
    deg = (phi + !pi)/!dtor
    nwrap = floor(min(deg)/360.)
    deg2 = deg - nwrap*360.

        ;--------------------------------------------------
        ; ;;Compare wrapped and unwrapped values to make sure I've done
        ; ;;unwrapping correctly
        ; x2 = abs(l)*cos(mlt*!dtor)
        ; y2 = abs(l)*sin(mlt*!dtor)
        ; r2 = sqrt(x^2 + y^2)

        ; x = abs(l)*cos(deg2*!dtor)
        ; y = abs(l)*sin(deg2*!dtor)
        ; r = sqrt(x^2 + y^2)

        ; ;;Test showing that the unwrapping was done correctly
        ; ;; print,x-x2
        ;--------------------------------------------------



    ;;Change to MLT values
    mlt = deg2 * (24./360.)
    goo = where(mlt ge 24)
    if goo[0] ne -1 then mlt[goo] = mlt[goo] - 24.

    return,{mltpp:mlt,lpp:l}


end
