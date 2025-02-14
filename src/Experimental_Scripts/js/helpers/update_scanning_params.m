% Process scanning parameters passed from Luminos Advanced imaging tab

function update_scanning_params(app, scanParameters, scanValues, currentIteration)
arguments
    app
    scanParameters struct
    scanValues
    currentIteration
end

i = currentIteration; 

for j = 1:numel(scanParameters)
    
    if ~strcmp(scanParameters(j).scanType, 'Autofocus') 
        % Handle parameter scans 
        if strcmp(scanParameters(j).scanParameter, 'Stage position')
            % Handle 2D or 3D positions for stage (e.g., x and y or x, y, z coordinates)
            stage = app.getDevice("Linear_Controller");
            if size(scanValues{j}, 2) == 2
                % Move to (x, y) position for 2D stage
                stage.Move_To_Position([scanValues{j}(i, 1), scanValues{j}(i, 2)]);
                pause(1);
            elseif size(scanValues{j}, 2) == 3
                % Move to (x, y, z) position for 3D stage
                stage.Move_To_Position([scanValues{j}(i, 1), scanValues{j}(i, 2), scanValues{j}(i, 3)]);
            else
                error("Stage position requires either 2D or 3D input (x, y or x, y, z).");
            end
        end
    
        if strcmp(scanParameters(j).scanParameter, 'z-Stage')
            % Handle 1D z-Stage movement with single z coordinate
            zstage = app.getDevice("Linear1D_Controller");
            zstage.Move_To_Position([0, 0, scanValues{j}(i)]);
        end

        if contains(scanParameters(j).scanParameter, 'patterns')
            dmd_name = strrep(scanParameters(j).scanParameter, " patterns", "");
            [dmd, ~] = select_devices(app, dmd_name, []);
            dmd.pattern_stack = dmd.all_patterns(:,:,scanValues{j}(i,:));
            dmd.Write_Stack("slave");
        end
    
        % Handle waveform parameters for scanning
        if contains(scanParameters(j).scanParameter, 'AO ') || contains(scanParameters(j).scanParameter, 'DO ')
            dq = app.getDevice("DAQ");
            waveform_number = regexp(scanParameters(j).scanParameter, '\d+', 'match');
            waveform_number = str2double(waveform_number);
        
            if contains(scanParameters(j).scanParameter, 'AO')
                dq.wfm_data.ao(waveform_number(end - 1)).params(waveform_number(end)) = scanValues{j}(i);
            elseif contains(scanParameters(j).scanParameter, 'DO')
                dq.wfm_data.do(waveform_number(end - 1)).params(waveform_number(end)) = scanValues{j}(i);
            else 
                error("Port must be AO or DO");
            end
    
            dq.Build_Waveforms();
        end
    else
        % Handle autofocus
        if strcmp(scanParameters(j).scanParameter, 'Stage position')
            stage = app.getDevice("Linear_Controller");
            if size(scanValues{j}, 2) < 3 % Assuming there's only xy or xyz stages 
                error("Cannot autofocus using stage without z-control.");
            end
            if isinteger(i/scanValues{j}(2))
                disp("Running autofocus.");
                Autofocus(app, scanValues{j}(1));
            end
        end
    
        if strcmp(scanParameters(j).scanParameter, 'z-Stage')
            % Handle 1D z-Stage movement with single z coordinate
            zstage = app.getDevice("Linear1D_Controller");
            % Autofocus once every scanValues{j}(2) (frequency) 
            if floor(i/scanValues{j}(2)) == i/scanValues{j}(2) 
                disp("Running autofocus.");
                Autofocus(app, scanValues{j}(1));
            end
        end
    end

end