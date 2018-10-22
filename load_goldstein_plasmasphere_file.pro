;Load the requested Goldstein plasmapause file and return arrays of L vs MLT describing
;the PP location


function load_goldstein_plasmasphere_file,file

    path = '/Users/aaronbreneman/Desktop/code/Aaron/datafiles/goldstein_pp_files/'


    openr,1,path+file
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