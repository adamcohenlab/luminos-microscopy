load('Required_Toolboxes.mat');
v = ver;
fprintf("-----------------------------------------\nChecking for required toolboxes as specified in 'Required_Toolboxes.mat'\n\n");
for i = 1:numel(plist)
    if ~any(strcmp(cellstr(char(v.Name)), plist{i}.Name))
        %Plist includes two products that aren't actually separate
        %toolboxes, so don't show up in v.
        if any(strcmp(plist{i}.Name, {'MATLAB Parallel Server', 'Polyspace Bug Finder'}))
            continue;
        elseif plist{i}.Certain
            fprintf("Required toolbox: %s missing. Please install this toolbox before proceeding\n", plist{i}.Name);
        else
            fprintf("Optional toolbox: %s may be required for proper function of some features. You may wish to install this toolbox to avoid possible errors\n", plist{i}.Name);
        end
    end
end
fprintf("\nAll toolboxes checked. See above for any missing toolboxes\n");