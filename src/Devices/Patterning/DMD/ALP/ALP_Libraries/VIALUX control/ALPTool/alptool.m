function varargout = alptool(varargin)
% ALPTOOL M-file for alptool.fig
%      ALPTOOL, by itself, creates a new ALPTOOL or raises the existing
%      singleton*.
%
%      H = ALPTOOL returns the handle to a new ALPTOOL or the handle to
%      the existing singleton*.
%
%      ALPTOOL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ALPTOOL.M with the given input arguments.
%
%      ALPTOOL('Property','Value',...) creates a new ALPTOOL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before alptool_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to alptool_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help alptool

% Last Modified by GUIDE v2.5 19-Feb-2014 19:04:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name', mfilename, ...
    'gui_Singleton', gui_Singleton, ...
    'gui_OpeningFcn', @alptool_OpeningFcn, ...
    'gui_OutputFcn', @alptool_OutputFcn, ...
    'gui_LayoutFcn', [], ...
    'gui_Callback', []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% ========================================================================

% --- Executes just before alptool is made visible.
function alptool_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL,*DEFNU,*INUSD>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to alptool (see VARARGIN)

% Choose default command line output for alptool
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

if length(varargin) < 1
    % no API given, select one interactively
    api = alpload();
elseif ischar(varargin{1})
    if length(varargin) > 1 && islogical(varargin{2})
        api = alpload(varargin{1}, varargin{2});
    else
        api = alpload(varargin{1});
    end
end

if ~isa(api, 'alpapi')
    alptoolfigure_CloseRequestFcn(hObject, eventdata, handles);
    return;
end

set(hObject, 'UserData', api);

% set some control data
set(handles.triggerpolarity, 'String', {'High(D)', 'Low'});
set(handles.triggerpolarity, 'UserData', {api.LEVEL_HIGH, api.LEVEL_LOW});
set(handles.vdedge, 'String', {'Falling(D)', 'Raising'});
set(handles.vdedge, 'UserData', {api.EDGE_FALLING, api.EDGE_RISING});
set(handles.vdtimeout, 'String', {'Enable(D)', 'Disable'});
set(handles.vdtimeout, 'UserData', {api.TIME_OUT_ENABLE, api.TIME_OUT_DISABLE});
set(handles.projectionmode, 'String', {'Master(D)', 'Slave'});
set(handles.projectionmode, 'UserData', {api.MASTER, api.SLAVE_VD});
set(handles.inversion, 'String', {'None(D)', 'Inversion'});
set(handles.inversion, 'UserData', {api.DEFAULT, ~api.DEFAULT});
set(handles.imageflip, 'String', {'None(D)', 'Upside down'});
set(handles.imageflip, 'UserData', {api.DEFAULT, ~api.DEFAULT});

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes alptool wait for user response (see UIRESUME)
% uiwait(handles.alptoolfigure);


% ========================================================================

% --- Outputs from this function are returned to the command line.
function varargout = alptool_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
if isfield(handles, 'output')
    varargout{1} = handles.output;
else
    varargout{1} = [];
end


% ========================================================================

% --- Executes during object creation, after setting all properties.
function alptoolfigure_CreateFcn(hObject, eventdata, handles)
% hObject    handle to alptoolfigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% ========================================================================

% --- Executes during object deletion, before destroying properties.
function alptoolfigure_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to alptoolfigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isstruct(handles)
    device = get(handles.deviceid, 'UserData');
    if ~isempty(device)
        device.halt();
        device.free();
    end
end


% ========================================================================

% --- Executes when user attempts to close alptoolfigure.
function alptoolfigure_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to alptoolfigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
delete(hObject);


% ========================================================================

% --- Executes on button press in devalloc.
function devalloc_Callback(hObject, eventdata, handles)
% hObject    handle to devalloc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

devicenumber = str2double(get(handles.devicenumber, 'String'));
api = get(handles.alptoolfigure, 'UserData');

device = alpdevice(api);
[ret, deviceid] = device.alloc(devicenumber);

if ret ~= device.OK
    uiwait(msgbox(sprintf('ALP device #%i can not be allocated, return value was %i.', devicenumber, ret), ...
        'Error allocating device', 'modal'));
    return;
end

set(handles.deviceid, 'UserData', device);
set(handles.deviceid, 'String', deviceid_makestr(deviceid));
set(handles.devalloc, 'Enable', 'off');
set(handles.devhalt, 'Enable', 'on');
set(handles.devfree, 'Enable', 'on');
set(handles.alpon, 'Enable', 'on');
set(handles.alpoff, 'Enable', 'on');
set(handles.alphon, 'Enable', 'on');
set(handles.alpqon, 'Enable', 'on');
set(handles.devinquire, 'Enable', 'on');
set(handles.usbreconnect, 'Enable', 'on');
set(handles.devcontrol, 'Enable', 'on');
set(handles.setdefault, 'Enable', 'on');
set(handles.setslave, 'Enable', 'on');
set(handles.filesequence, 'Enable', 'on');
set(handles.varsequence, 'Enable', 'on');
set(handles.devicetows, 'Enable', 'on');
set(handles.sequencetows, 'Enable', 'on');

% inquire current settings
devinquire_Callback(handles.devinquire, eventdata, handles);


% ========================================================================

% --- Executes during object creation, after setting all properties.
function deviceid_CreateFcn(hObject, eventdata, handles)
% hObject    handle to deviceid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

set(hObject, 'String', deviceid_makestr(0));


% ========================================================================

function str = deviceid_makestr(deviceid)
str = sprintf('DeviceID: %i', deviceid);


% ========================================================================

% --- Executes on button press in devhalt.
function devhalt_Callback(hObject, eventdata, handles)
% hObject    handle to devhalt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% halt the device
device = get(handles.deviceid, 'UserData');

ret = device.halt();
if ret ~= device.OK
    uiwait(msgbox(sprintf('ALP device id %i can not be halted, return value was %i.', device.deviceid, ret), ...
        'Error halting device', 'modal'));
    return;
end


% ========================================================================

% --- Executes during object creation, after setting all properties.
function devhalt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to devhalt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

set(hObject, 'Enable', 'off');


% ========================================================================

% --- Executes on button press in devfree.
function devfree_Callback(hObject, eventdata, handles)
% hObject    handle to devfree (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% free the device
device = get(handles.deviceid, 'UserData');

ret = device.free();
if ret ~= device.OK
    uiwait(msgbox(sprintf('ALP device id %i can not be freed, return value was %i.', device.deviceid, ret), ...
        'Error freeing device', 'modal'));
    return;
end

set(handles.deviceid, 'UserData', []);
set(handles.deviceid, 'String', '0');
set(handles.devalloc, 'Enable', 'on');
set(handles.devhalt, 'Enable', 'off');
set(handles.devfree, 'Enable', 'off');
set(handles.alpon, 'Enable', 'off');
set(handles.alpoff, 'Enable', 'off');
set(handles.alphon, 'Enable', 'off');
set(handles.alpqon, 'Enable', 'off');
set(handles.devinquire, 'Enable', 'off');
set(handles.usbreconnect, 'Enable', 'off');
set(handles.devcontrol, 'Enable', 'off');
set(handles.setdefault, 'Enable', 'off');
set(handles.setslave, 'Enable', 'off');
set(handles.filesequence, 'Enable', 'off');
set(handles.varsequence, 'Enable', 'off');
set(handles.devicetows, 'Enable', 'off');
set(handles.sequencetows, 'Enable', 'off');


% ========================================================================

% --- Executes during object creation, after setting all properties.
function devfree_CreateFcn(hObject, eventdata, handles)
% hObject    handle to devfree (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

set(hObject, 'Enable', 'off');


% ========================================================================

% --- Executes on button press in alpon.
function alpon_Callback(hObject, eventdata, handles)
% hObject    handle to alpon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

device = get(handles.deviceid, 'UserData');
device.on();


% ========================================================================

% --- Executes during object creation, after setting all properties.
function alpon_CreateFcn(hObject, eventdata, handles)
% hObject    handle to alpon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

set(hObject, 'Enable', 'off');


% ========================================================================

% --- Executes on button press in alpoff.
function alpoff_Callback(hObject, eventdata, handles)
% hObject    handle to alpoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

device = get(handles.deviceid, 'UserData');
device.off();


% ========================================================================

% --- Executes during object creation, after setting all properties.
function alpoff_CreateFcn(hObject, eventdata, handles)
% hObject    handle to alpoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

set(hObject, 'Enable', 'off');


% ========================================================================

% --- Executes on button press in alphon.
function alphon_Callback(hObject, eventdata, handles)
% hObject    handle to alphon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

device = get(handles.deviceid, 'UserData');
half = get(handles.halves, 'Value');
device.half(half);


% ========================================================================

% --- Executes during object creation, after setting all properties.
function alphon_CreateFcn(hObject, eventdata, handles)
% hObject    handle to alphon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

set(hObject, 'Enable', 'off');


% ========================================================================

% --- Executes on button press in alpqon.
function alpqon_Callback(hObject, eventdata, handles)
% hObject    handle to alpqon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

device = get(handles.deviceid, 'UserData');
quarter = get(handles.quarters, 'Value');
device.quarter(quarter);


% ========================================================================

% --- Executes during object creation, after setting all properties.
function alpqon_CreateFcn(hObject, eventdata, handles)
% hObject    handle to alpqon (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

set(hObject, 'Enable', 'off');


% ========================================================================

% --- Executes during object creation, after setting all properties.
function halves_CreateFcn(hObject, eventdata, handles)
% hObject    handle to halves (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

set(hObject, 'String', {'bottom', 'top', 'left', 'right'});
set(hObject, 'Value', 1);


% ========================================================================

% --- Executes during object creation, after setting all properties.
function quarters_CreateFcn(hObject, eventdata, handles)
% hObject    handle to quarters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

set(hObject, 'String', {'left bottom', 'right bottom', 'left top', 'right top'});
set(hObject, 'Value', 1);


% ========================================================================

% --- Executes on button press in devinquire.
function devinquire_Callback(hObject, eventdata, handles)
% hObject    handle to devinquire (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% device handle
device = get(handles.deviceid, 'UserData');

% device number
[ret, uservar] = device.inquire(device.api.DEVICE_NUMBER);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire ALP device number of device id %i, return value was %i', device.deviceid, ret), ...
        'Error inquiring device', 'modal'));
    return;
else
    set(handles.devicenumber2, 'String', sprintf('Device Number: %i', uservar));
end

% version number
[ret, uservar] = device.inquire(device.api.VERSION);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire version number of device id %i, return value was %i', device.deviceid, ret), ...
        'Error inquiring device', 'modal'));
    return;
else
    set(handles.versionnumber, 'String', sprintf('Version Number: %i', uservar));
end

% device state
[ret, uservar] = device.inquire(device.api.DEV_STATE);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire state of device id %i, return value was %i', device.deviceid, ret), ...
        'Error inquiring device', 'modal'));
    return;
else
    switch (uservar)
        case device.api.DEV_BUSY
            state = 'ALP_DEV_BUSY';
        case device.api.DEV_READY
            state = 'ALP_DEV_READY';
        case device.api.DEV_IDLE
            state = 'ALP_DEV_IDLE';
        otherwise
            state = 'unknown';
    end
    set(handles.devicestate, 'String', sprintf('Device State: %s', state));
end

% memory
[ret, uservar] = device.inquire(device.api.AVAIL_MEMORY);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire memory of device id %i, return value was %i', device.deviceid, ret), ...
        'Error inquiring device', 'modal'));
    return;
else
    set(handles.availablememory, 'String', sprintf('Available Memory (binary images): %i', uservar));
end

% USB connection
[ret, uservar] = device.inquire(device.api.USB_CONNECTION); %#ok<NASGU>
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire USB status of device id %i, return value was %i', device.deviceid, ret), ...
        'Error inquiring device', 'modal'));
    return;
else
    if ret == device.api.OK
        set(handles.usbconnection, 'String', 'USB state: connected');
    else
        set(handles.usbconnection, 'String', 'USB state: device removed');
    end
end

% trigger polarity
[ret, uservar] = device.inquire(device.api.TRIGGER_POLARITY);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire trigger polarity state of device id %i, return value was %i', device.deviceid, ret), ...
        'Error inquiring device', 'modal'));
    return;
else
    entries = get(handles.triggerpolarity, 'UserData');
    for i = 1:size(entries, 2)
        if uservar == entries{i}
            set(handles.triggerpolarity, 'Value', i);
        end
    end
end

% VD edge
[ret, uservar] = device.inquire(device.api.VD_EDGE);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire VD edge state of device id %i, return value was %i', device.deviceid, ret), ...
        'Error inquiring device', 'modal'));
    return;
else
    entries = get(handles.vdedge, 'UserData');
    for i = 1:size(entries, 2)
        if uservar == entries{i}
            set(handles.vdedge, 'Value', i);
        end
    end
end

% VD time out
[ret, uservar] = device.inquire(device.api.VD_TIME_OUT);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire VD time out state of device id %i, return value was %i', device.deviceid, ret), ...
        'Error inquiring device', 'modal'));
    return;
else
    entries = get(handles.vdtimeout, 'UserData');
    for i = 1:size(entries, 2)
        if uservar == entries{i}
            set(handles.vdtimeout, 'Value', i);
        end
    end
end

% projection mode
[ret, uservar] = device.projinquire(device.api.PROJ_MODE);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire projection mode state of device id %i, return value was %i', device.deviceid, ret), ...
        'Error inquiring device', 'modal'));
    return;
else
    entries = get(handles.projectionmode, 'UserData');
    for i = 1:size(entries, 2)
        if uservar == entries{i}
            set(handles.projectionmode, 'Value', i);
        end
    end
end

% projection state
[ret, uservar] = device.projinquire(device.api.PROJ_STATE);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire projection state of device id %i, return value was %i', device.deviceid, ret), ...
        'Error inquiring device', 'modal'));
    return;
else
    switch (uservar)
        case device.api.PROJ_ACTIVE
            state = 'Projection active';
        case device.api.PROJ_IDLE
            state = 'no active projection';
        otherwise
            state = 'state unknown';
    end
    set(handles.projectionstate, 'String', sprintf('Projection State: %s', state));
end

% inversion
[ret, uservar] = device.projinquire(device.api.PROJ_INVERSION);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire projection inversion status of device id %i, return value was %i', device.deviceid, ret), ...
        'Error inquiring device', 'modal'));
    return;
else
    entries = get(handles.inversion, 'UserData');
    for i = 1:size(entries, 2)
        if uservar == device.api.DEFAULT
            if uservar == entries{i}
                set(handles.inversion, 'Value', i);
            end
        else
            if entries{i} ~= device.api.DEFAULT
                set(handles.inversion, 'Value', i);
            end
        end
    end
end

% flip
[ret, uservar] = device.projinquire(device.api.PROJ_UPSIDE_DOWN);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire projection image flip status of device id %i, return value was %i', device.deviceid, ret), ...
        'Error inquiring device', 'modal'));
    return;
else
    entries = get(handles.imageflip, 'UserData');
    for i = 1:size(entries, 2)
        if uservar == device.api.DEFAULT
            if uservar == entries{i}
                set(handles.imageflip, 'Value', i);
            end
        else
            if entries{i} ~= device.api.DEFAULT
                set(handles.imageflip, 'Value', i);
            end
        end
    end
end


% ========================================================================

% --- Executes during object creation, after setting all properties.
function devinquire_CreateFcn(hObject, eventdata, handles)
% hObject    handle to devinquire (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

set(hObject, 'Enable', 'off');


% ========================================================================

% --- Executes on button press in usbreconnect.
function usbreconnect_Callback(hObject, eventdata, handles)
% hObject    handle to usbreconnect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% device handle
device = get(handles.deviceid, 'UserData');

ret = device.control(device.api.USB_CONNECTION, device.api.DEFAULT);

if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Could not reconnect to device %i, return value was %i', device.deviceid, ret), ...
        'Error reconnecting to device', 'modal'));
    return;
end


% ========================================================================

% --- Executes during object creation, after setting all properties.
function usbreconnect_CreateFcn(hObject, eventdata, handles)
% hObject    handle to usbreconnect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

set(hObject, 'Enable', 'off');


% ========================================================================

% --- Executes on selection change in triggerpolarity.
function triggerpolarity_Callback(hObject, eventdata, handles)
% hObject    handle to triggerpolarity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns triggerpolarity contents as cell array
%        contents{get(hObject,'Value')} returns selected item from triggerpolarity

device = get(handles.deviceid, 'UserData');

entries = get(hObject, 'UserData');
entry = entries{get(hObject, 'Value')};
ret = device.control(device.api.TRIGGER_POLARITY, entry);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set trigger polarity state of device id %i, return value was %i', device.deviceid, ret), ...
        'Error controlling device', 'modal'));
    return;
end


% ========================================================================

% --- Executes during object creation, after setting all properties.
function triggerpolarity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to triggerpolarity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end


% ========================================================================

% --- Executes on selection change in vdedge.
function vdedge_Callback(hObject, eventdata, handles)
% hObject    handle to vdedge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns vdedge contents as cell array
%        contents{get(hObject,'Value')} returns selected item from vdedge

device = get(handles.deviceid, 'UserData');

entries = get(hObject, 'UserData');
entry = entries{get(hObject, 'Value')};
ret = device.control(device.api.VD_EDGE, entry);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set VD edge state of device id %i, return value was %i', device.deviceid, ret), ...
        'Error controlling device', 'modal'));
    return;
end


% ========================================================================

% --- Executes during object creation, after setting all properties.
function vdedge_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vdedge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end


% ========================================================================

% --- Executes on selection change in vdtimeout.
function vdtimeout_Callback(hObject, eventdata, handles)
% hObject    handle to vdtimeout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns vdtimeout contents as cell array
%        contents{get(hObject,'Value')} returns selected item from vdtimeout

device = get(handles.deviceid, 'UserData');

entries = get(hObject, 'UserData');
entry = entries{get(hObject, 'Value')};
ret = device.control(device.api.VD_TIME_OUT, entry);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set VD time out state of device id %i, return value was %i', device.deviceid, ret), ...
        'Error controlling device', 'modal'));
    return;
end


% ========================================================================

% --- Executes during object creation, after setting all properties.
function vdtimeout_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vdtimeout (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end


% ========================================================================

% --- Executes on selection change in projectionmode.
function projectionmode_Callback(hObject, eventdata, handles)
% hObject    handle to projectionmode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns projectionmode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from projectionmode

device = get(handles.deviceid, 'UserData');

entries = get(hObject, 'UserData');
entry = entries{get(hObject, 'Value')};
ret = device.projcontrol(device.api.PROJ_MODE, entry);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set projection mode of device id %i, return value was %i', device.deviceid, ret), ...
        'Error controlling device', 'modal'));
    return;
end


% ========================================================================

% --- Executes during object creation, after setting all properties.
function projectionmode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to projectionmode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end


% ========================================================================

% --- Executes on selection change in inversion.
function inversion_Callback(hObject, eventdata, handles)
% hObject    handle to inversion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns inversion contents as cell array
%        contents{get(hObject,'Value')} returns selected item from inversion

device = get(handles.deviceid, 'UserData');

entries = get(hObject, 'UserData');
entry = entries{get(hObject, 'Value')};
ret = device.projcontrol(device.api.PROJ_INVERSION, entry);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set projection inversion state of device id %i, return value was %i', device.deviceid, ret), ...
        'Error controlling device', 'modal'));
    return;
end


% ========================================================================

% --- Executes during object creation, after setting all properties.
function inversion_CreateFcn(hObject, eventdata, handles)
% hObject    handle to inversion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end


% ========================================================================

% --- Executes on selection change in imageflip.
function imageflip_Callback(hObject, eventdata, handles)
% hObject    handle to imageflip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns imageflip contents as cell array
%        contents{get(hObject,'Value')} returns selected item from imageflip

device = get(handles.deviceid, 'UserData');

entries = get(hObject, 'UserData');
entry = entries{get(hObject, 'Value')};
ret = device.projcontrol(device.api.PROJ_UPSIDE_DOWN, entry);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set projection flip state of device id %i, return value was %i', device.deviceid, ret), ...
        'Error controlling device', 'modal'));
    return;
end


% ========================================================================

% --- Executes during object creation, after setting all properties.
function imageflip_CreateFcn(hObject, eventdata, handles)
% hObject    handle to imageflip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end


% ========================================================================

% --- Executes on button press in devcontrol.
function devcontrol_Callback(hObject, eventdata, handles)
% hObject    handle to devcontrol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% device handle
device = get(handles.deviceid, 'UserData');

% trigger polarity
entries = get(handles.triggerpolarity, 'UserData');
entry = entries{get(handles.triggerpolarity, 'Value')};
ret = device.control(device.api.TRIGGER_POLARITY, entry);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set trigger polarity state of device id %i, return value was %i', device.deviceid, ret), ...
        'Error controlling device', 'modal'));
end

% VD edge
entries = get(handles.vdedge, 'UserData');
entry = entries{get(handles.vdedge, 'Value')};
ret = device.control(device.api.VD_EDGE, entry);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set VD edge state of device id %i, return value was %i', device.deviceid, ret), ...
        'Error controlling device', 'modal'));
end

% VD time out
entries = get(handles.vdtimeout, 'UserData');
entry = entries{get(handles.vdtimeout, 'Value')};
ret = device.control(device.api.VD_TIME_OUT, entry);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set VD time out state of device id %i, return value was %i', device.deviceid, ret), ...
        'Error controlling device', 'modal'));
end

% projection mode
entries = get(handles.projectionmode, 'UserData');
entry = entries{get(handles.projectionmode, 'Value')};
ret = device.projcontrol(device.api.PROJ_MODE, entry);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set projection mode of device id %i, return value was %i', device.deviceid, ret), ...
        'Error controlling device', 'modal'));
end

% inversion
entries = get(handles.inversion, 'UserData');
entry = entries{get(handles.inversion, 'Value')};
ret = device.projcontrol(device.api.PROJ_INVERSION, entry);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set projection inversion state of device id %i, return value was %i', device.deviceid, ret), ...
        'Error controlling device', 'modal'));
end

% image flip
entries = get(handles.imageflip, 'UserData');
entry = entries{get(handles.imageflip, 'Value')};
ret = device.projcontrol(device.api.PROJ_UPSIDE_DOWN, entry);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set projection flip state of device id %i, return value was %i', device.deviceid, ret), ...
        'Error controlling device', 'modal'));
end


% ========================================================================

% --- Executes during object creation, after setting all properties.
function devcontrol_CreateFcn(hObject, eventdata, handles)
% hObject    handle to devcontrol (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

set(hObject, 'Enable', 'off');
set(hObject, 'Visible', 'off');


% ========================================================================

% --- Executes on button press in filesequence.
function filesequence_Callback(hObject, eventdata, handles)
% hObject    handle to filesequence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

device = get(handles.deviceid, 'UserData');

% read TIFF file
[stack, depth, height, width, bitdepth, filenames] = readstack(); %#ok<NASGU>

if bitdepth > 8
    uiwait(msgbox(sprintf('Device does not support a bit depth of %i, stack will be resampled to 8 bit.', bitdepth), ...
        'Image data problem', 'modal'));
    stack = uint8(stack/2^(bitdepth - 8));
    bitdepth = 8;
end

if bitdepth < 8
    % shift significant bits to left
    stack = bitshift(stack, 8-bitdepth);
end

sz = [depth, height, width];
orders = inputdlg({sprintf('Frame number index (default: 1, size: [%i, %i, %i])', sz), ...
    sprintf('Row number index (default: 2, size: [%i, %i, %i])', sz), ...
    sprintf('Column number index (default: 3, size: [%i, %i, %i])', sz)}, ...
    'Please enter...', 1, {'1', '2', '3'});

if isempty(orders)
    fi = 1; %#ok<NASGU>
    ri = 2; %#ok<NASGU>
    ci = 3; %#ok<NASGU>
else
    try
        fi = str2double(orders{1});
        ri = str2double(orders{2});
        ci = str2double(orders{3});
    catch
        fi = 1;
        ri = 2;
        ci = 3;
    end
    stack = permute(stack, [fi, ri, ci]);
    depth = size(stack, 1);
end

if depth ~= 0
    % allocate sequence
    sequence = alpsequence(device);
    [ret, sequenceid] = sequence.alloc(bitdepth, depth);
    if ret == device.api.MEMORY_FULL
        uiwait(msgbox('Not enough memory', 'Upload Error', 'modal'));
        delete(sequence);
    elseif ret ~= device.api.OK
        uiwait(msgbox(sprintf('Can not allocate memory for sequence on device id %i, return value was %i', device.deviceid, ret), ...
            'Upload Error', 'modal'));
        delete(sequence);
    else
        % upload file to ALP
        hw = waitbar(0, sprintf('Please wait... uploading data to sequence id %i...', sequenceid));
        ret = sequence.put(0, depth, stack);
        if ret ~= device.api.OK
            uiwait(msgbox(sprintf('Can not upload data to device/sequence id %i/%i, return value was %i', ...
                device.deviceid, sequence.sequenceid, ret), ...
                'Upload Error', 'modal'));
            delete(sequence);
        else
            alpseqtool(device, sequence);
        end
        close(hw);
    end
end

% ========================================================================

% --- Executes during object creation, after setting all properties.
function filesequence_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filesequence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

set(hObject, 'Enable', 'off');


% ========================================================================
% --- Executes on button press in varsequence.
function varsequence_Callback(hObject, eventdata, handles)
% hObject    handle to varsequence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

device = get(handles.deviceid, 'UserData');

% read variable name/expression
expression = inputdlg('Valid MATLAB expression in base WS:', 'Please enter...', 1);
if ~isempty(expression)
    try
        stack = evalin('base', expression{1});
    catch
        uiwait(msgbox(sprintf('Invalid MATLAB expression: %s', expression{1}), ...
            'EVAL error', 'modal'));
        return;
    end

    % convert to integer
    if ~isinteger(stack)
        uiwait(msgbox('Device does not support non integer data, stack will be resampled to 64 bit.', ...
            'Image data problem', 'modal'));
        stack = uint64(stack);
    end

    bitdepth = ceil(log2(double(intmax(class(stack)))));
    bitdepth = inputdlg({'Bit depth:'}, ...
        'Please enter...', 1, {sprintf('%i', bitdepth)});
    if ~isempty(bitdepth)
        bitdepth = str2double(bitdepth{1});
    else
        return;
    end

    if bitdepth > 8
        uiwait(msgbox(sprintf('Device does not support a bit depth of %i, stack will be resampled to 8 bit.', bitdepth), ...
            'Image data problem', 'modal'));
        stack = uint8(bitshift(stack, -(bitdepth - 8)));
        bitdepth = 8;
    end

    if bitdepth < 8
        % shift significant bits to left
        stack = bitshift(stack, 8-bitdepth);
    end

    sz = size(stack);
    orders = inputdlg({sprintf('Frame number index (default: 1, size: [%i, %i, %i])', sz), ...
        sprintf('Row number index (default: 2, size: [%i, %i, %i])', sz), ...
        sprintf('Column number index (default: 3, size: [%i, %i, %i])', sz)}, ...
        'Please enter...', 1, {'1', '2', '3'});

    if ~isempty(orders)
        try
            fi = str2double(orders{1});
            ri = str2double(orders{2});
            ci = str2double(orders{3});
        catch
            fi = 1;
            ri = 2;
            ci = 3;
        end
        stack = permute(stack, [fi, ri, ci]);
    else
        return;
    end

    depth = size(stack, 1);
    % allocate sequence
    sequence = alpsequence(device);
    [ret, sequenceid] = sequence.alloc(bitdepth, depth);
    if ret == device.api.MEMORY_FULL
        uiwait(msgbox('Not enough memory', 'Upload Error', 'modal'));
        delete(sequence);
    elseif ret ~= device.api.OK
        uiwait(msgbox(sprintf('Can not allocate memory for sequence on device id %i, return value was %i', device.deviceid, ret), ...
            'Upload Error', 'modal'));
        delete(sequence);
    else
        % upload file to ALP
        hw = waitbar(0, 'Please wait... uploading data...');
        ret = sequence.put(0, depth, stack);
        if ret ~= device.api.OK
            uiwait(msgbox(sprintf('Can not upload data to device/sequence id %i/%i, return value was %i', ...
                device.deviceid, sequenceid, ret), ...
                'Upload Error', 'modal'));
            delete(sequence);
        else
            alpseqtool(device, sequence);
        end
        close(hw);
    end
end


% ========================================================================

% --- Executes during object creation, after setting all properties.
function varsequence_CreateFcn(hObject, eventdata, handles)
% hObject    handle to varsequence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

set(hObject, 'Enable', 'off');


% ========================================================================


% --- Executes on button press in devicetows.
function devicetows_Callback(hObject, eventdata, handles)
% hObject    handle to devicetows (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

device = get(handles.deviceid, 'UserData');
assignin('base', 'galpdev', device);


% ========================================================================

% --- Executes during object creation, after setting all properties.
function devicetows_CreateFcn(hObject, eventdata, handles)
% hObject    handle to devicetows (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

set(hObject, 'Enable', 'off');


% ========================================================================

% --- Executes on button press in sequencetows.
function sequencetows_Callback(hObject, eventdata, handles)
% hObject    handle to sequencetows (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

device = get(handles.deviceid, 'UserData');
assignin('base', 'galpseq1', device.sequences(1));


% ========================================================================

% --- Executes during object creation, after setting all properties.
function sequencetows_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sequencetows (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

set(hObject, 'Enable', 'off');


% ========================================================================

% --- Executes on button press in setdefault.
function setdefault_Callback(hObject, eventdata, handles)
% hObject    handle to setdefault (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% set all controls to default value
set(handles.triggerpolarity, 'Value', 1);
set(handles.vdedge, 'Value', 1);
set(handles.vdtimeout, 'Value', 1);
set(handles.projectionmode, 'Value', 1);
set(handles.inversion, 'Value', 1);
set(handles.imageflip, 'Value', 1);

% call "set" button
devcontrol_Callback(handles.devcontrol, [], handles);


% ========================================================================

% --- Executes on button press in setslave.
function setslave_Callback(hObject, eventdata, handles)
% hObject    handle to setslave (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% set all controls to values needed for slave mode
set(handles.triggerpolarity, 'Value', 1);
set(handles.vdedge, 'Value', 2);
set(handles.vdtimeout, 'Value', 2);
set(handles.projectionmode, 'Value', 2);
set(handles.inversion, 'Value', 1);
set(handles.imageflip, 'Value', 1);

% call "set" button
devcontrol_Callback(handles.devcontrol, [], handles);


% ========================================================================

% --- read TIFF files
function [stack, stackdepth, stackwidth, stackheight, bitdepth, filenames] = readstack(filenames)

% ask for files
if ~exist('filenames', 'var') || isempty(filenames)
    [filenames, pathname, filterindex] = uigetfile({'*.tif', ['TIFF Files ', ...
        '(*.tif)']}, 'Please select', 'MultiSelect', 'on');

    if 0 == filterindex
        stack = 0;
        stackwidth = 0;
        stackheight = 0;
        stackdepth = 0;
        return;
    end

    if ischar(filenames)
        filenames = {filenames};
    end
    for i = 1:size(filenames, 2)
        filenames{i} = [pathname, filenames{i}];
    end
else
    % handle single file case
    if ischar(filenames)
        filenames = {filenames};
    end
end

% sort file names!
filenames = sort(filenames);

% read image files and combine to stack
filecount = size(filenames, 2);
framecount = 0;
framewidth = 0;
frameheight = 0;
bitdepth = 0;

% query number of frames and their size for preallocation
for filenumber = 1:filecount
    imagefileinfo = imfinfo(filenames{filenumber}, 'tif');

    % Multiple images in TIFF file?
    directorycount = length(imagefileinfo);
    framecount = framecount + directorycount;

    for directory = 1:directorycount
        if framewidth < imagefileinfo(directory).Width
            framewidth = imagefileinfo(directory).Width;
        end
        if frameheight < imagefileinfo(directory).Height
            frameheight = imagefileinfo(directory).Height;
        end
        if bitdepth < imagefileinfo(directory).BitDepth
            bitdepth = imagefileinfo(directory).BitDepth;
        end
    end
end

% get the necessary UINT* class
uintclass = sprintf('uint%i', ceil(bitdepth/8)*8);

% preallocate stack
stack = zeros(framecount, frameheight, framewidth, uintclass);

winhandle = waitbar(0, sprintf('Please wait... reading frame 0/%i', framecount));

frameindex = 0;
for filenumber = 1:filecount
    imagefileinfo = imfinfo(filenames{filenumber}, 'tif');

    % Multiple images in TIFF file?
    directorycount = length(imagefileinfo);

    for directory = 1:directorycount
        frameindex = frameindex + 1;
        prompt = sprintf('Please wait... reading frame %i/%i', frameindex, framecount);
        waitbar(frameindex/framecount, winhandle, prompt);
        stack(frameindex, :, :) = imread(filenames{filenumber}, directory);
    end

end

close(winhandle);

stackwidth = framewidth;
stackheight = frameheight;
stackdepth = framecount;
