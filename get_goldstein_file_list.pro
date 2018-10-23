;Returns list of available Goldstein files 
;Intended to be passed to a procedure like load_goldstein_plasmasphere_file.pro. 
;The reason this is separated is b/c it takes a few sec to grab this list. You don't 
;want to grab it n times, where n is the number of array time elements. 

;        Required plasmapause files can be found at
;        http://enarc.space.swri.edu/PTP/
;        An example of one of these is:
;        /Users/aaronbreneman/Desktop/code/Aaron/datafiles/goldstein_pp_files/20140040000.ppa


function get_goldstein_file_list,path=path


    extension = 'ppa'
    if ~keyword_set(path) then $
    path = '/Users/aaronbreneman/Desktop/code/Aaron/datafiles/goldstein_pp_files/'



    ;Determine which Goldstein PP files are available for loading
    files = FILE_SEARCH(path+'*.'+extension)
    for i=0L,n_elements(files)-1 do files[i] = strmid(files[i],14,/reverse_offset)
    files = double(strmid(files,0,11))
    file_to_load = ''


    return,files


end