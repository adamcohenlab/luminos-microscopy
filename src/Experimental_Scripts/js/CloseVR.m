function CloseVR(app)
app.VR_On = false;
if ~isempty(app.VRclient)
    delete(app.VRclient);
    app.VRclient = [];
end
end