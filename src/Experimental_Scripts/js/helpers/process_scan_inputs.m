% Process scanning parameters passed from Luminos Advanced imaging tab

function scanValues = process_scan_inputs(num_burst, scanParameters)
arguments
    num_burst
    scanParameters struct
end

% Process scan parameters
for i = 1:numel(scanParameters)
    
    % Handle linear scans
    if strcmp(scanParameters(i).scanType, 'Linear scan')
        % Convert start and end values to numeric arrays
        startValue = str2double(split(scanParameters(i).startValue, ','));
        endValue = str2double(split(scanParameters(i).endValue, ','));

        % Ensure startValue and endValue have the same number of dimensions
        if numel(startValue) ~= numel(endValue)
            error('Start and end values must have the same dimensions');
        end

        % Generate interpolated values using linspace for each dimension
        for dim = 1:numel(startValue)
            scanValues{i}(dim, :) = linspace(startValue(dim), endValue(dim), num_burst)';
        end
        if numel(startValue) > 1
            scanValues{i} = scanValues{i}';
        end

    % Handle custom values input
    elseif strcmp(scanParameters(i).scanType, 'Custom')
        % Parse custom values as a 2D or 3D array by splitting rows and columns
        rows = split(scanParameters(i).customValues, ';'); % Separate rows by semicolon
        for r = 1:numel(rows)
            values = str2double(split(rows{r}, ',')); % Separate each row's elements by commas
            scanValues{i}(r, :) = values;
        end
        if numel(rows) == 1
            scanValues{i} = scanValues{i}';
        end

        scanValues{i} = scanValues{i}(~any(isnan(scanValues{i}), 2), :);

        % Repeat values if num_burst is larger than the provided custom values
        if size(scanValues{i}, 1) < num_burst
            scanValues{i} = repmat(scanValues{i}', 1, ceil(num_burst / size(scanValues{i}, 1)));
            scanValues{i} = scanValues{i}';
            scanValues{i} = scanValues{i}(1:num_burst, :); % Truncate to match num_burst
        end

    % Handle autofocus
    elseif strcmp(scanParameters(i).scanType, 'Autofocus')
            scanValues{i}(1) = str2double(scanParameters(i).autofocusParams.range);
            if ~isempty(scanParameters(i).autofocusParams.frequency)
                scanValues{i}(2) = str2double(scanParameters(i).autofocusParams.frequency);
            else
                scanValues{i}(2) = 1; % If no input given, focus once every round
            end
    else
        error("Scan type " + scanParameters(i).scanType + " not implemented.");
    end
end