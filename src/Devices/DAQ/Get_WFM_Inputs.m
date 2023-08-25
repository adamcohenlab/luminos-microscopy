function inargs = Get_WFM_Inputs(wfm_file)
str = fileread(wfm_file);
cstr = strsplit(str, '\n');
cstr = strsplit(cstr{1}, '=');
cstr = cstr{2};
inargs = cstr(1:end-1);
end