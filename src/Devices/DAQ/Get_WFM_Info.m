% Read a file that looks like this:
% function outdata = awfm_doubleRamp_AOTF488(t,rest_time,ramp_time,minval,maxval)
%     % Take a V-response (e.g. AOTF output) calibration curve as the
%     % argument. The aim is to obtain linear output from a non-linear ramp
%     % curve_fit: the predetermined V-response fitting curve load as a cfit
%     % object

%     % [DEFAULTS] add default values and units below
%     % rest_time, 0.5, s
%     % ramp_time, 0.5, s
%     % minval, 0, AO val
%     % maxval, 1, AO val
%     % [END]

% and extract the [DEFAULTS] section into a struct
% in the example above, we'd get an args struct with fields:
% rest_time: { defaultVal: 0.5, units: 's' }
% ramp_time: { defaultVal: 0.5, units: 's' }
% maxval: { defaultVal: 1, units: 'AO val' }

% sometimes, there is no defaultVal or no units, in which case, we'd return { defaultVal: '', units: ''}

function out = Get_WFM_Info(file_name)
[~, wfm_name, ext] = fileparts(file_name);
if ext ~= ".m"
    file_name = wfm_name + ".m";
end
file = fileread(file_name);
try
    defaults = extractBetween(file, '[DEFAULTS]', '[END]');
    defaults = defaults{1};

    defaults = splitlines(defaults);
    defaults = defaults(2:end-1); % remove the first and last lines
    % now defaults is a list of lines that look like this:
    % rest_time, 0.5, s

    % set arg_info to be an empty list of length length(defaults)

    j = 1;
    for i = 1:length(defaults)
        % split the line into a cell array
        line = strsplit(defaults{i}, ',');
        % remove any extra whitespace
        line = cellfun(@strtrim, line, 'UniformOutput', false);
        % add the line to the arg_info struct
        if isempty(line)
            continue
        end
        name = strip(extractAfter(line{1}, '%'));
        if name == ""
            continue
        end
        if length(line) <= 1
            line{2} = '';
        end
        if length(line) <= 2
            line{3} = '';
        end
        arg_info(j).name = name;
        defaultVal = strip(line{2});

        % if we can't find a default value, set it to 'Default'
        if defaultVal == ""
            defaultVal = 'Default';
        end
        arg_info(j).defaultVal = defaultVal;
        arg_info(j).units = strip(line{3});
        j = j + 1;
    end
catch
    % no defaults section
    fcn_prototype = Get_WFM_Inputs(wfm_name+".m");
    inputs_list = strsplit(fcn_prototype, ',');
    inputs_list = inputs_list(2:end);
    inputs_list{end} = inputs_list{end}(1:end - 1); % remove the last ')'

    for i = 1:length(inputs_list)
        arg_info(i).name = inputs_list{i};
        arg_info(i).defaultVal = '';
        arg_info(i).units = '';
    end
end

% remove first 5 characters of wfm_name (e.g. awfm_ramp -> ramp)
name = extractAfter(wfm_name, 5);

out.name = name;
out.args = arg_info;

end