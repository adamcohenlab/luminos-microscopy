function Prepare_Mex_Wrapper(classname, file)
x = fopen(file, 'r');
output = textscan(x, '%s', 'delimiter', '\n');
cnamelen = numel(classname);
lines = output{1};
entry = find(strcmp(lines, '//START METHOD LIST'));
exit = find(strcmp(lines, '//END METHOD LIST'));
fid = fopen('test.txt', 'wt');

for i = (entry + 1):(exit - 1)

end
end