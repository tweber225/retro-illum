function handles = open_camera(handles)

%% Check installed IMAQ adapters
hardwareInfo = imaqhwinfo;
if ~sum(strcmp(hardwareInfo.InstalledAdaptors,handles.acqSettings.adapterName))
    error('Could not find designated IMAQ adapter!')
end

%% Load Basler Pylon SDK
% initiate NET interface
NET.addAssembly('Basler.Pylon');
import Basler.Pylon.*

% Find camera and open it
handles.baslerCam = Camera(handles.acqSettings.cameraSerialNumber);
handles.baslerCam.Open();

% Note the device info
handles.acqSettings.cameraVendorName = char(handles.baslerCam.Parameters.Item('DeviceVendorName').GetValue());
handles.acqSettings.cameraModelName = char(handles.baslerCam.Parameters.Item('DeviceModelName').GetValue());
handles.acqSettings.cameraName = [handles.acqSettings.cameraVendorName ' ' handles.acqSettings.cameraModelName ' (SN:' handles.acqSettings.cameraSerialNumber ')'];


%% Create video and objects
handles.vid = videoinput('dalsa', 1, handles.acqSettings.saperaConfigFilePath);
handles.src = getselectedsource(handles.vid);

% Set number of triggers to infinite
handles.vid.TriggerRepeat = inf;
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

