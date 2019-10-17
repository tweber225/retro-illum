function handles = open_camera(handles)

%% Check hardware and installed IMAQ adapters
hardwareInfo = imaqhwinfo;
if ~sum(strcmp(hardwareInfo.InstalledAdaptors,handles.acqSettings.adapterName))
    error('Could not find designated IMAQ adapter!')
end

% Check that there's a camera
adapterInfo = imaqhwinfo(handles.acqSettings.adapterName);
if isempty(adapterInfo.DeviceIDs)
    error('No camera devices found')
end

% Check that the camera has specified format
cameraInfo = imaqhwinfo(handles.acqSettings.adapterName, 1);
if ~sum(strcmp(cameraInfo.SupportedFormats,handles.acqSettings.pixelFormat))
    error('Camera does not support requested format')
end


%% Create video and objects
handles.vid = videoinput(handles.acqSettings.adapterName, 1, handles.acqSettings.pixelFormat);
handles.src = getselectedsource(handles.vid);

% Note the device info
handles.acqSettings.cameraVendorName = handles.src.DeviceVendorName;
handles.acqSettings.cameraModelName = handles.src.DeviceModelName;
handles.acqSettings.cameraSerialNumber = handles.src.DeviceSerialNumber;
handles.acqSettings.cameraName = [handles.acqSettings.cameraVendorName ' ' handles.acqSettings.cameraModelName ' (SN:' handles.acqSettings.cameraSerialNumber ')'];

% Set number of triggers to infinite
handles.vid.TriggerRepeat = Inf;
if handles.vid.TriggerRepeat ~= inf
    error('Failed to set trigger')
end

% Set trigger type to immediate
triggerconfig(handles.vid,'immediate');
if ~strcmp(handles.vid.TriggerType,'immediate')
    error('Failed to set trigger type')
end

% Report success
disp(['Camera ' handles.acqSettings.cameraName ' opened'])

