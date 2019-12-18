function textExposureTimeCallback(hObject,handles)

% Get new value
newVal = round(str2double(get(handles.textExposureTime,'String')));

% Check limits
if newVal < 100
    newVal = 100;
elseif newVal > 33000
    newVal = 33000;
end

% Try to set new exposure time on camera
handles.src.ExposureTime = newVal;
handles.acqSettings.exposureTime = handles.src.ExposureTime; % get set value

% Set the value in GUI
set(handles.textExposureTime,'String',num2str(handles.acqSettings.exposureTime));

% Update timing display
handles.acqSettings.resultingFrameRate = handles.src.ResultingFrameRate;
handles.acqSettings.sensorReadoutTime = handles.src.SensorReadoutTime;
handles = update_displays(handles); 

% Pass data to GUI
guidata(hObject,handles);


