function notes = get_notes_js(app)
% returns a string
if exist(fullfile(app.datafolder, 'Session_Notes.txt'), 'file')
    notes = fileread(fullfile(app.datafolder, 'Session_Notes.txt'));
else
    notes = "";
end
end