function alp_returnvalue = put(obj, picoffset, picload, userarray)
%  Loads user supplied frame data to an ALP device
%
%  See also:
%     control, inquire
%
%  File information:
%     version 1.0 (feb 2014)
%     (c) Martin Vogel
%     email: matlab@martin-vogel.info
%
%  Revision history:
%     1.0 (feb 2014) initial release version

if nargin < 4

    alp_returnvalue = obj.MISSING_PARAMETERS;

else

    if ~isempty(obj.sequenceid) && ~isempty(obj.device.deviceid)

        if ~isnumeric(picoffset)
            picoffset = obj.device.api.DEFAULT;
        end
        if ~isnumeric(picload)
            picload = inf();
        end

        % cast userarray to unsigned int8
        switch (class(userarray))
            case 'uint8'
                % do nothing
            case 'logical'
                userarray = uint8(userarray) * intmax('uint8');
            otherwise
                userarray = uint8(userarray);
        end

        % query ALP_DATA_FORMAT for bitplane organization of data
        [alp_returnvalue, dataformat] = obj.inquire(obj.device.api.DATA_FORMAT);
        if alp_returnvalue ~= obj.device.api.OK
            return;
        end
        if ((dataformat == obj.device.api.DATA_BINARY_TOPDOWN) || ...
                (dataformat == obj.device.api.DATA_BINARY_BOTTOMUP))
            rowcount = ceil(obj.height/8);
        else
            rowcount = obj.height;
        end
        columncount = obj.width;

        % check array size, type and picload parameter
        if size(userarray, 4) > 1
            % reduce dimensionality to 3!
            userarray = userarray(:, :, :);
        end

        if size(userarray, 3) > 1

            % multiple frames present: 1st dimension = frame, 2nd dimension =
            % rows, 3rd dimension = columns

            columnsize = size(userarray, 3);
            if columnsize > columncount
                % delete surplus columns
                userarray(:, :, (columncount + 1):columnsize) = [];
            elseif columnsize < columncount
                % add additional columns with 0
                userarray(:, :, columncount) = 0;
            end

            rowsize = size(userarray, 2);
            if rowsize > rowcount
                % delete surplus rows
                userarray(:, (rowcount + 1):rowsize, :) = [];
            elseif rowsize < rowcount
                % add additional rows with 0
                userarray(:, rowcount, :) = 0;
            end

            % set picload to number of frames present in array (or less)
            picload = min(picload, size(userarray, 1));

            userarray = permute(userarray, [2, 3, 1]);

        else

            % only one frame present: 1st dimension = rows, 2nd dimension = columns

            columnsize = size(userarray, 2);
            if columnsize > columncount
                % delete surplus columns
                userarray(:, (columncount + 1):columnsize) = [];
            elseif columnsize < columncount
                % add additional columns with 0
                userarray(:, columncount) = 0;
            end

            rowsize = size(userarray, 1);
            if rowsize > rowcount
                % delete surplus rows
                userarray((rowcount + 1):rowsize, :) = [];
            elseif rowsize < rowcount
                % add additional rows with 0
                userarray(rowcount, :) = 0;
            end

            picload = 1;

        end

        alp_returnvalue = obj.device.api.seqput(obj.device.deviceid, ...
            obj.sequenceid, ...
            picoffset, ...
            picload, ...
            userarray);

    else

        alp_returnvalue = obj.INVALID_ID;

    end

end

end
