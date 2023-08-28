function varargout = alpseqtool(varargin)
% ALPSEQTOOL M-file for alpseqtool.fig
%      ALPSEQTOOL, by itself, creates a new ALPSEQTOOL or raises the existing
%      singleton*.
%
%      H = ALPSEQTOOL returns the handle to a new ALPSEQTOOL or the handle to
%      the existing singleton*.
%
%      ALPSEQTOOL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ALPSEQTOOL.M with the given input arguments.
%
%      ALPSEQTOOL('Property','Value',...) creates a new ALPSEQTOOL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before alpseqtool_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to alpseqtool_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help alpseqtool

% Last Modified by GUIDE v2.5 20-Feb-2014 11:38:24

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name', mfilename, ...
    'gui_Singleton', gui_Singleton, ...
    'gui_OpeningFcn', @alpseqtool_OpeningFcn, ...
    'gui_OutputFcn', @alpseqtool_OutputFcn, ...
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

% --- Executes just before alpseqtool is made visible.
function alpseqtool_OpeningFcn(hObject, eventdata, handles, varargin) %#ok<*INUSL,*DEFNU,*INUSD>
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to alpseqtool (see VARARGIN)

% Choose default command line output for alpseqtool
handles.output = hObject;

% check parameter
if size(varargin, 2) >= 2 && isa(varargin{1}, 'alpdevice') && ...
        isa(varargin{2}, 'alpsequence')
    device = varargin{1};
    sequence = varargin{2};
else
    delete(hObject);
    return;
end

% store device in this figure's "deviceid" control
set(handles.deviceid, 'UserData', device);
set(handles.deviceid, 'String', sprintf('Device ID: %i', device.deviceid));
% store sequence in this figure's "deviceid" control
set(handles.sequenceid, 'UserData', sequence);
set(handles.sequenceid, 'String', sprintf('Sequence ID: %i', sequence.sequenceid));
set(handles.binarymode, 'String', {'Normal(D)', 'Uninterrupted'});
set(handles.binarymode, 'UserData', {device.api.DEFAULT, device.api.BIN_UNINTERRUPTED});
set(handles.dataformat, 'String', {'MSB(D)', 'LSB', 'TopDown', 'BottomUp'});
set(handles.dataformat, 'UserData', {device.api.DEFAULT, device.api.DATA_LSB_ALIGN, device.api.DATA_BINARY_TOPDOWN, device.api.DATA_BINARY_BOTTOMUP});

% Update handles structure
guidata(hObject, handles);

% inquire sequence settings
inquire_Callback(handles.inquire, eventdata, handles);
% set binary mode to "Uninterrupted"
set(handles.binarymode, 'Value', 2);
binarymode_Callback(handles.binarymode, eventdata, handles);

% UIWAIT makes alpseqtool wait for user response (see UIRESUME)
% uiwait(handles.alpseqtoolfigure);


% ========================================================================

% --- Executes when user attempts to close alpseqtoolfigure.
function alpseqtoolfigure_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to alpseqtoolfigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% device & sequence handle
device = get(handles.deviceid, 'UserData');
sequence = get(handles.sequenceid, 'UserData');

% remove sequence
retval = sequence.free();
if retval == device.api.SEQ_IN_USE
    answer = questdlg('Sequence is currently in use. Stop playback and delete sequence?', 'Please specify', 'Yes', 'No');
    if ~strcmp(answer, 'Yes')
        return;
    else
        device.stop();
        retval = sequence.free();
    end
end
if (retval == device.api.NOT_IDLE) || (retval == device.api.NOT_READY)
    answer = questdlg('ALP device is currently not idle/not ready. Stop playback and delete sequence?', 'Please specify', 'Yes', 'No');
    if ~strcmp(answer, 'Yes')
        return;
    else
        device.stop();
        retval = sequence.free();
    end
end
if retval ~= device.api.OK
    uiwait(msgbox(sprintf('Error freeing sequence, return value was %i.', retval)));
end

% Hint: delete(hObject) closes the figure
delete(hObject);


% ========================================================================

% --- Outputs from this function are returned to the command line.
function varargout = alpseqtool_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% ========================================================================

% --- Executes on button press in inquire.
function inquire_Callback(hObject, eventdata, handles)
% hObject    handle to inquire (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% device & sequence handle
device = get(handles.deviceid, 'UserData');
sequence = get(handles.sequenceid, 'UserData');

% bit planes
[ret, uservar] = sequence.inquire(device.api.BITPLANES);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire bit planes of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error inquiring sequence', 'modal'));
    return;
else
    set(handles.bitplanes, 'String', sprintf('Bit Planes: %i', uservar));
    set(handles.bitplanes, 'UserData', uservar);
end

% frame number
[ret, uservar] = sequence.inquire(device.api.PICNUM);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire frame number of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error inquiring sequence', 'modal'));
    return;
else
    set(handles.framecount, 'String', sprintf('Frame Count: %i', uservar));
    set(handles.framecount, 'UserData', uservar);
end

% on time
[ret, uservar] = sequence.inquire(device.api.ON_TIME);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire on time of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error inquiring sequence', 'modal'));
    return;
else
    set(handles.ontime, 'String', sprintf('On Time: %i', uservar));
    set(handles.ontime, 'UserData', uservar);
end

% off time
[ret, uservar] = sequence.inquire(device.api.OFF_TIME);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire off time of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error inquiring sequence', 'modal'));
    return;
else
    set(handles.offtime, 'String', sprintf('Off Time: %i', uservar));
    set(handles.offtime, 'UserData', uservar);
end

% first frame
[ret, uservar] = sequence.inquire(device.api.FIRSTFRAME);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire first frame of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error inquiring sequence', 'modal'));
    return;
else
    set(handles.firstframe, 'String', sprintf('%i', uservar));
    set(handles.firstframe, 'UserData', uservar);
end

% last frame
[ret, uservar] = sequence.inquire(device.api.LASTFRAME);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire last frame of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error inquiring sequence', 'modal'));
    return;
else
    set(handles.lastframe, 'String', sprintf('%i', uservar));
    set(handles.lastframe, 'UserData', uservar);
end

% display bits
[ret, uservar] = sequence.inquire(device.api.BITNUM);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire bit depth for display of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error inquiring sequence', 'modal'));
    return;
else
    set(handles.displaybits, 'String', sprintf('%i', uservar));
    set(handles.displaybits, 'UserData', uservar);
end

% sequence repeat
[ret, uservar] = sequence.inquire(device.api.SEQ_REPEAT);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire repetition count of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error inquiring sequence', 'modal'));
    return;
else
    set(handles.repetitions, 'String', sprintf('%i', uservar));
    set(handles.repetitions, 'UserData', uservar);
end

% binary dark phase mode
[ret, uservar] = sequence.inquire(device.api.BIN_MODE);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire binary dark phase status of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error inquiring device', 'modal'));
    return;
else
    entries = get(handles.binarymode, 'UserData');
    for i = 1:size(entries, 2)
        if uservar == entries{i}
            set(handles.binarymode, 'Value', i);
        end
    end
end

% data format
[ret, uservar] = sequence.inquire(device.api.DATA_FORMAT);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire data format of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error inquiring device', 'modal'));
    return;
else
    entries = get(handles.dataformat, 'UserData');
    for i = 1:size(entries, 2)
        if uservar == entries{i}
            set(handles.dataformat, 'Value', i);
        end
    end
end

% picture(frame) time & min picture time
[ret, uservar] = sequence.inquire(device.api.PICTURE_TIME);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire frame time of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error inquiring sequence', 'modal'));
    return;
else
    set(handles.picturetime, 'String', sprintf('%i', uservar));
end
[ret, uservar] = sequence.inquire(device.api.MIN_PICTURE_TIME);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire minimum frame time of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error inquiring sequence', 'modal'));
    return;
else
    set(handles.minpicturetime, 'String', sprintf('(min %i us)', uservar));
end

% display(illumination) time & min display time
[ret, uservar] = sequence.inquire(device.api.ILLUMINATE_TIME);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire display time of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error inquiring sequence', 'modal'));
    return;
else
    set(handles.illuminatetime, 'String', sprintf('%i', uservar));
end
[ret, uservar] = sequence.inquire(device.api.MIN_ILLUMINATE_TIME);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire minimum display time of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error inquiring sequence', 'modal'));
    return;
else
    set(handles.minilluminatetime, 'String', sprintf('(min %i us)', uservar));
end

% trigger delay and max trigger delay
[ret, uservar] = sequence.inquire(device.api.TRIGGER_DELAY);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire trigger delay of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error inquiring sequence', 'modal'));
    return;
else
    set(handles.triggerdelay, 'String', sprintf('%i', uservar));
end
[ret, uservar] = sequence.inquire(device.api.MAX_TRIGGER_DELAY);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire maximum trigger delay of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error inquiring sequence', 'modal'));
    return;
else
    set(handles.maxtriggerdelay, 'String', sprintf('(max %i us)', uservar));
end

% VD trigger delay and max VD trigger delay
[ret, uservar] = sequence.inquire(device.api.VD_DELAY);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire VD trigger delay of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error inquiring sequence', 'modal'));
    return;
else
    set(handles.vddelay, 'String', sprintf('%i', uservar));
end
[ret, uservar] = sequence.inquire(device.api.MAX_VD_DELAY);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not inquire maximum VD trigger delay of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error inquiring sequence', 'modal'));
    return;
else
    set(handles.maxvddelay, 'String', sprintf('(max %i us)', uservar));
end

set(handles.set, 'Enable', 'on');


% ========================================================================

function firstframe_Callback(hObject, eventdata, handles)
% hObject    handle to firstframe (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of firstframe as text
%        str2double(get(hObject,'String')) returns contents of firstframe as a double

device = get(handles.deviceid, 'UserData');
sequence = get(handles.sequenceid, 'UserData');
try
    entry = str2double(get(hObject, 'String'));
catch
    entry = 0;
end
ret = sequence.control(device.api.FIRSTFRAME, entry);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set first frame of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error controlling sequence', 'modal'));
    return;
end


% ========================================================================

% --- Executes during object creation, after setting all properties.
function firstframe_CreateFcn(hObject, eventdata, handles)
% hObject    handle to firstframe (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

set(hObject, 'String', '0');


% ========================================================================

function lastframe_Callback(hObject, eventdata, handles)
% hObject    handle to lastframe (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lastframe as text
%        str2double(get(hObject,'String')) returns contents of lastframe as a double

device = get(handles.deviceid, 'UserData');
sequence = get(handles.sequenceid, 'UserData');
try
    entry = str2double(get(hObject, 'String'));
catch
    picnum = get(handles.framecount, 'UserData');
    if ~isempty(picnum)
        entry = picnum;
    else
        entry = 1;
    end
end
ret = sequence.control(device.api.LASTFRAME, entry);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set last frame of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error controlling sequence', 'modal'));
    return;
end


% ========================================================================

% --- Executes during object creation, after setting all properties.
function lastframe_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lastframe (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

set(hObject, 'String', '0');


% ========================================================================

function displaybits_Callback(hObject, eventdata, handles)
% hObject    handle to displaybits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of displaybits as text
%        str2double(get(hObject,'String')) returns contents of displaybits as a double

device = get(handles.deviceid, 'UserData');
sequence = get(handles.sequenceid, 'UserData');
try
    entry = str2double(get(hObject, 'String'));
catch
    bitplanes = get(handles.bitplanes, 'UserData');
    if ~isempty(picnum)
        entry = bitplanes;
    else
        entry = 1;
    end
end
ret = sequence.control(device.api.BITNUM, entry);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set display bit depth of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error controlling sequence', 'modal'));
    return;
end


% ========================================================================

% --- Executes during object creation, after setting all properties.
function displaybits_CreateFcn(hObject, eventdata, handles)
% hObject    handle to displaybits (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

set(hObject, 'String', '0');


% ========================================================================

function repetitions_Callback(hObject, eventdata, handles)
% hObject    handle to repetitions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of repetitions as text
%        str2double(get(hObject,'String')) returns contents of repetitions as a double

device = get(handles.deviceid, 'UserData');
sequence = get(handles.sequenceid, 'UserData');
try
    entry = str2double(get(hObject, 'String'));
catch
    entry = 1;
end
ret = sequence.control(device.api.SEQ_REPEAT, entry);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set sequence repetitions of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error controlling sequence', 'modal'));
    return;
end


% ========================================================================

% --- Executes during object creation, after setting all properties.
function repetitions_CreateFcn(hObject, eventdata, handles)
% hObject    handle to repetitions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

set(hObject, 'String', '0');


% ========================================================================

% --- Executes on selection change in binarymode.
function binarymode_Callback(hObject, eventdata, handles)
% hObject    handle to binarymode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns binarymode contents as cell array
%        contents{get(hObject,'Value')} returns selected item from binarymode

device = get(handles.deviceid, 'UserData');
sequence = get(handles.sequenceid, 'UserData');
entries = get(hObject, 'UserData');
entry = entries{get(hObject, 'Value')};
ret = sequence.control(device.api.BIN_MODE, entry);
if ret == device.api.NOT_IDLE
    uiwait(msgbox(sprintf('ALP device %i is not in IDLE state - abort setting parameters...', device.deviceid)));
    return;
elseif ret == device.api.SEQ_IN_USE
    uiwait(msgbox(sprintf('Sequence %i on ALP device %i is currently running. Stop playback and retry.', ...
        sequence.sequenceid, device.deviceid)));
    return;
elseif ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set binary dark phase mode of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error controlling sequence', 'modal'));
    return;
end


% ========================================================================

% --- Executes during object creation, after setting all properties.
function binarymode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to binarymode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end


% ========================================================================

% --- Executes on selection change in dataformat.
function dataformat_Callback(hObject, eventdata, handles)
% hObject    handle to dataformat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns dataformat contents as cell array
%        contents{get(hObject,'Value')} returns selected item from dataformat

device = get(handles.deviceid, 'UserData');
sequence = get(handles.sequenceid, 'UserData');
entries = get(hObject, 'UserData');
entry = entries{get(hObject, 'Value')};
ret = sequence.control(device.api.DATA_FORMAT, entry);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set data format of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error controlling sequence', 'modal'));
    return;
end


% ========================================================================

% --- Executes during object creation, after setting all properties.
function dataformat_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dataformat (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end


% ========================================================================

function picturetime_Callback(hObject, eventdata, handles)
% hObject    handle to picturetime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of picturetime as text
%        str2double(get(hObject,'String')) returns contents of picturetime as a double
setseqtiming(handles);


% ========================================================================

% --- Executes during object creation, after setting all properties.
function picturetime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to picturetime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

set(hObject, 'String', '0');


% ========================================================================

function triggerdelay_Callback(hObject, eventdata, handles)
% hObject    handle to triggerdelay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of triggerdelay as text
%        str2double(get(hObject,'String')) returns contents of triggerdelay as a double
setseqtiming(handles);


% ========================================================================

% --- Executes during object creation, after setting all properties.
function triggerdelay_CreateFcn(hObject, eventdata, handles)
% hObject    handle to triggerdelay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

set(hObject, 'String', '0');


% ========================================================================

function illuminatetime_Callback(hObject, eventdata, handles)
% hObject    handle to illuminatetime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of illuminatetime as text
%        str2double(get(hObject,'String')) returns contents of illuminatetime as a double
setseqtiming(handles);


% ========================================================================

% --- Executes during object creation, after setting all properties.
function illuminatetime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to illuminatetime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

set(hObject, 'String', '0');


% ========================================================================

function vddelay_Callback(hObject, eventdata, handles)
% hObject    handle to vddelay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of vddelay as text
%        str2double(get(hObject,'String')) returns contents of vddelay as a double
setseqtiming(handles);


% ========================================================================

% --- Executes during object creation, after setting all properties.
function vddelay_CreateFcn(hObject, eventdata, handles)
% hObject    handle to vddelay (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject, 'BackgroundColor', 'white');
end

set(hObject, 'String', '0');


% ========================================================================

function setseqtiming(handles)
device = get(handles.deviceid, 'UserData');
sequence = get(handles.sequenceid, 'UserData');
try
    illuminatetime = str2double(get(handles.illuminatetime, 'String'));
    picturetime = str2double(get(handles.picturetime, 'String'));
    triggerdelay = str2double(get(handles.triggerdelay, 'String'));
    vddelay = str2double(get(handles.vddelay, 'String'));
catch
    illuminatetime = device.api.DEFAULT;
    picturetime = device.api.DEFAULT;
    triggerdelay = device.api.DEFAULT;
    vddelay = device.api.DEFAULT;
end
triggerpulsewidth = triggerdelay + illuminatetime;

ret = sequence.timing(illuminatetime, picturetime, triggerdelay, triggerpulsewidth, vddelay);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set sequence timing parameters of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error controlling sequence', 'modal'));
    return;
end


% ========================================================================

% --- Executes on button press in set.
function set_Callback(hObject, eventdata, handles)
% hObject    handle to set (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% device and sequence handle
device = get(handles.deviceid, 'UserData');
sequence = get(handles.sequenceid, 'UserData');

% binary dark phase mode
entries = get(handles.binarymode, 'UserData');
entry = entries{get(handles.binarymode, 'Value')};
ret = sequence.control(device.api.BIN_MODE, entry);
if ret == device.api.NOT_IDLE
    uiwait(msgbox(sprintf('ALP device %i is not in IDLE state - abort setting parameters...', ...
        device.deviceid)));
    return;
elseif ret == device.api.SEQ_IN_USE
    uiwait(msgbox(sprintf('Sequence %i on ALP device %i is currently running. Stop playback and retry.', ...
        sequence.sequenceid, device.deviceid)));
    return;
elseif ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set binary dark phase mode of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error controlling sequence', 'modal'));
end

% data format
entries = get(handles.dataformat, 'UserData');
entry = entries{get(handles.dataformat, 'Value')};
ret = sequence.control(device.api.DATA_FORMAT, entry);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set data format of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error controlling sequence', 'modal'));
end

% first frame
try
    entry = str2double(get(handles.firstframe, 'String'));
catch
    entry = 0;
end
ret = sequence.control(device.api.FIRSTFRAME, entry);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set first frame of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error controlling sequence', 'modal'));
end

% last frame
try
    entry = str2double(get(handles.lastframe, 'String'));
catch
    picnum = get(handles.framecount, 'UserData');
    if ~isempty(picnum)
        entry = picnum;
    else
        entry = 1;
    end
end
ret = sequence.control(device.api.LASTFRAME, entry);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set last frame of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error controlling sequence', 'modal'));
end

% display bits
try
    entry = str2double(get(handles.displaybits, 'String'));
catch
    bitplanes = get(handles.bitplanes, 'UserData');
    if ~isempty(picnum)
        entry = bitplanes;
    else
        entry = 1;
    end
end
ret = sequence.control(device.api.BITNUM, entry);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set display bit depth of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error controlling sequence', 'modal'));
end

% sequence repeat
try
    entry = str2double(get(handles.repetitions, 'String'));
catch
    entry = 1;
end
ret = sequence.control(device.api.SEQ_REPEAT, entry);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set sequence repetitions of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error controlling sequence', 'modal'));
end

% timing data
try
    illuminatetime = str2double(get(handles.illuminatetime, 'String'));
    picturetime = str2double(get(handles.picturetime, 'String'));
    triggerdelay = str2double(get(handles.triggerdelay, 'String'));
    vddelay = str2double(get(handles.vddelay, 'String'));
catch
    illuminatetime = device.api.DEFAULT;
    picturetime = device.api.DEFAULT;
    triggerdelay = device.api.DEFAULT;
    vddelay = device.api.DEFAULT;
end
triggerpulsewidth = triggerdelay + illuminatetime;

ret = sequence.timing(illuminatetime, picturetime, triggerdelay, triggerpulsewidth, vddelay);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not set sequence timing parameters of device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Error controlling sequence', 'modal'));
end


% ========================================================================

% --- Executes during object creation, after setting all properties.
function set_CreateFcn(hObject, eventdata, handles)
% hObject    handle to set (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

set(hObject, 'Enable', 'off');
set(hObject, 'Visible', 'off');


% ========================================================================

% --- Executes on button press in startcont.
function startcont_Callback(hObject, eventdata, handles)
% hObject    handle to startcont (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% device and sequence handle
device = get(handles.deviceid, 'UserData');
sequence = get(handles.sequenceid, 'UserData');

ret = device.startcont(sequence);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not play back device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Playback error', 'modal'));
end


% ========================================================================

% --- Executes on button press in start.
function start_Callback(hObject, eventdata, handles)
% hObject    handle to start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% device and sequence handle
device = get(handles.deviceid, 'UserData');
sequence = get(handles.sequenceid, 'UserData');

ret = device.start(sequence);
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not play back device/sequence %i/%i, return value was %i', ...
        device.deviceid, sequence.sequenceid, ret), 'Playback error', 'modal'));
end


% ========================================================================

% --- Executes on button press in stop.
function stop_Callback(hObject, eventdata, handles)
% hObject    handle to stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% device and sequence handle
device = get(handles.deviceid, 'UserData');

ret = device.stop();
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not stop device %i, return value was %i', ...
        device.deviceid, ret), 'Stop error', 'modal'));
end
ret = device.halt();
if ret ~= device.api.OK
    uiwait(msgbox(sprintf('Can not stop device %i, return value was %i', ...
        device.deviceid, ret), 'Stop error', 'modal'));
end


% ========================================================================

% --- Executes on button press in close.
function close_Callback(hObject, eventdata, handles)
% hObject    handle to close (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close(handles.alpseqtoolfigure);


% ========================================================================


% --- Executes on button press in sequencetows.
function sequencetows_Callback(hObject, eventdata, handles)
% hObject    handle to sequencetows (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

sequence = get(handles.sequenceid, 'UserData');
seqvarname = sprintf('galpseq%i', sequence.sequenceid);
assignin('base', seqvarname, sequence);
