function texto = MethodBlock(methodname, numconstructorargs, numinputs, numoutputs, classname, datapointers)
texto{1} = ['\t  if (!strcmp(', '"', methodname, '"', ', cmd)){'];
texto{2} = [' \t \t if (nlhs!=', num2str(numoutputs), '|| nrhs!=', num2str(numinputs+2)];
texto{3} = '\t \t \t mexErrMsgTxt("Unexpected Number of Arguments")';
j = 4;
outs = 0;
for i = 1:numel(datapointers)
    if strcmp(pointerdirection(i), 'in')
        texto{j} = [pointertype, '* inputarr=(*', pointertype, ')', 'mxGetData(prhs[', num2str(i+2), '])'];
    elseif strcmp(pointerdirection(i), 'out')
        texto{j} = [pointertype, '* outputarr=(*', pointertype, ')', 'mxGetData(prhs[', num2str(i+2), '])'];
    end
    j = j + 1;
end
if returnval > 0
    texto{j} = ['plhs[0]=instance->', methodname, '('];
    outs = outs + 1;
else
    texto{5} = ['instance->', methodname];
    outs = 2;
end
for i = 1:num_method_args

end
end
