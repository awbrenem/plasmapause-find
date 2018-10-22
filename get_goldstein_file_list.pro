;Returns list of available Goldstein files 

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