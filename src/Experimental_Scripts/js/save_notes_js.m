function save_notes_js(app, notes)
% check if notes is empty
if ~isempty(strip(notes))
    % notes is a string
    fid = fopen(fullfile(app.datafolder, 'Session_Notes.txt'), 'w');
    fprintf(fid, '%s\n', notes);
end
end