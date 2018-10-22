;+
; NAME: plot_plasmapause_goldstein_boundary
; SYNTAX:
; PURPOSE: Plots Jerry Goldstein's plasmapause boundary for a specific time,
;          Can overlayed a sc trajectory for nearby times.
;
; INPUT: time = '2014-01-06/20:00:00'
;        mltvals = 12   (mlt array for satellite trajectory)
;        lvals = 7      (L array for satellite trajectory)
;        s = plot_plasmapause_goldstein_boundary(time,mltvals,lvals)
;
;        Required Goldstein plasmapause files can be found at
;        http://enarc.space.swri.edu/PTP/
;        An example of one of these is:
;        /Users/aaronbreneman/Desktop/code/Aaron/datafiles/goldstein_pp_files/20140040000.ppa
;
;
; See call_plot_plasmapause_goldstein_boundary_for_rbsp.pro for example of usage.
;

; KEYWORDS: plot --> create a plot of the PS boundary
;           ps --> create a PS file
;           name --> Name of the output PS file
;           colorplot --> color for overlaid satellite trajectory
;
; HISTORY: Written by Aaron W Breneman, 2016
;-


pro plot_plasmapause_goldstein_boundary,$
    time,$
    mltvals,$
    lvals,$
    oplot=oplot,$
    colorplot=colorplot,$
    ps=ps,$
    name=name,$
    path=path,$
    extratitle=et,$
    xrange=xr,yrange=yr


if ~keyword_set(et) then et = ''
if ~keyword_set(mltvals) then mltvals = 0.
if ~keyword_set(lvals) then lvals = 5.
if ~KEYWORD_SET(colorplot) then colorplot = 0.
if ~keyword_set(name) then name = 'psphere_plot.ps'





;Format the input time string for input into get_goldstein_file_list.pro
time = time_string(time_double(time))
year0 = strmid(time,0,4) + '-01-01'
doy = 1 + floor(time_double(time)/86400 - time_double(year0)/86400)
doyS = strarr(n_elements(doy))
if doy lt 10 then doyS = '00'+strtrim(doy,2)
if doy ge 10 and doy lt 100 then doyS = '0'+strtrim(doy,2)
if doy ge 100 then doyS = strtrim(doy,2)
datetime = strmid(time,0,4) + doyS + strmid(time,11,2) + strmid(time,14,2)




;Load the appropriate Goldstein PP file and get L,MLT values to plot
files = get_goldstein_file_list()
file_to_load = ''
goo = where(double(datetime) le files)
file_to_load = string(files[goo[0]],format='(i11)') + '.ppa'
ppvals = load_goldstein_plasmasphere_file(file_to_load)



;Convert DOY format back to Unix format for better plot labeling
tmp = strmid(datetime,0,7)
frac = string(float(strmid(datetime,7,4))/2400.)
frac = strmid(strtrim(frac,2),1,4)
timeplot = date_conv(double(tmp+frac),'F') 




;Create the dial plot if the oplot keyword is not set
if ~KEYWORD_SET(oplot) then begin

    if keyword_set(ps) then popen,'~/Desktop/'+name



    ;Lshell lines, etc. 
    rad=findgen(101)
    rad=rad*2*!pi/100.0
    lval=findgen(7)
    lval=lval+3.0
    lshell1x=1.0*cos(rad) & lshell1y=1.0*sin(rad)
    lshell3x=lval[0]*cos(rad) & lshell3y=lval[0]*sin(rad)
    lshell5x=lval[2]*cos(rad) & lshell5y=lval[2]*sin(rad)
    lshell7x=lval[4]*cos(rad) & lshell7y=lval[4]*sin(rad)
    lshell9x=lval[6]*cos(rad) & lshell9y=lval[6]*sin(rad)
    !x.margin=[5,5]
    !y.margin=[5,5]
    if ~keyword_set(xr) then xr = [-12, 12]
    if ~keyword_set(yr) then yr = [-12, 12]



    ;Plot labeling 
    if !d.name eq 'X' then window,1, xsize = 600, ysize = 600
    plot, lshell3x, lshell3y, $
    xrange=xr, yrange=yr,$
    title='Goldstein PP at ' + timeplot + $
    '!C' + et + " !C(L vs MLT)!Cfrom plasmapause_goldstein_boundary.pro",$
    position=aspect(1.)



    ;x,y coordinates of Goldstein plasmapause
    x2 = abs(ppvals.lpp)*cos(ppvals.mltpp*360./24. *!dtor)
    y2 = abs(ppvals.lpp)*sin(ppvals.mltpp*360./24. *!dtor)
    polyfill,x2,y2,color=160,clip=[xr[0],yr[0],xr[1],yr[1]],noclip=0
    oplot, lshell1x, lshell1y
    oplot, lshell5x, lshell5y
    oplot, lshell7x, lshell7y
    oplot, lshell9x, lshell9y



    ;Earth
    rvals = replicate(1,360)
    thetavals = indgen(360)*!dtor
    xearth = rvals*cos(thetavals)
    yearth = rvals*sin(thetavals)
    good = where(xearth ge 0.)
    polyfill,xearth[good],yearth[good]


    xyouts, -10.5, -0.60, '12:00', /data
    xyouts, 9.75, -0.60, '0:00', /data
    xyouts, -7, -0.6, '7', /data
    xyouts, -3, -0.6, '3',/data
    xyouts, 7, -0.6, '7', /data
    xyouts, 3, -0.6,'3', /data
    xyouts, 0, 8, 'Square is start of sc trajectory',/data
    xyouts, 0, 7, 'Asterisk is sc location at time of plotted Goldstein PP'

endif  ;skip if oplot set



;overplot the payload position
xp = abs(lvals)*cos(mltvals*360./24. *!dtor)
yp = abs(lvals)*sin(mltvals*360./24. *!dtor)
for q=0,n_elements(xp)-1 do oplot,[xp[q],xp[q]],[yp[q],yp[q]],symsize=2,color=colorplot



;Square to label start of trajectory
boo = where(xp ne 0.)
oplot,[xp[boo[0]],xp[boo[0]]],[yp[boo[0]],yp[boo[0]]],psym=-6,symsize=1,color=colorplot

;Asterisk to label SC location at(near) time of plotted Goldstein plasmapause
midpt = n_elements(xp)/2.
oplot,[xp[midpt],xp[midpt]],[yp[midpt],yp[midpt]],psym=-2,symsize=1,color=50



if keyword_set(ps) then pclose
end
