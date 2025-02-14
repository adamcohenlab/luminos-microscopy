% Use to select dmd and camera when there are multiple options
function [dmd, cam] = select_devices(app, dmd_name, cam_name)
    arguments
        app
        dmd_name
        cam_name
    end

    if ~isempty(dmd_name)
        dmds = app.getDevice('DMD'); 
        for i = 1:size(dmds,2)
            % Using char comparison because direct strcmp behaves weirdly
            if strcmp(char(dmds(i).name), char(dmd_name))
                dmd = dmds(i);
            end
        end    
    else 
        dmd = [];
    end

    if ~isempty(cam_name)
        cams = app.getDevice('Camera'); 
        for i = 1:size(cams,2)
            % Using char comparison because direct strcmp behaves weirdly
            if strcmp(char(cams(i).name), char(cam_name))
                cam = cams(i);
            end
        end  
    else 
        cam = [];
    end 


end