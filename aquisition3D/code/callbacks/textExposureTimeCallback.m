function textExposureTimeCallback(hObject,handles)

% min/max values
maxExposure = 33000; % 33 ms
minExposure = 100; % 0.1 ms

% Get new value
newVal = round(str2double(get(handles.textExposureTime,'String')));

% Check limits
if newVal < minExposure
    newVal = minExposure;
elseif newVal > maxExposure
    newVal = maxExposure;
end

% Try to set new exposure time on camera, then get value
handles.baslerCam.Parameters.Item('ExposureTimeAbs').SetValue(newVal);
handles.acqSettings.exposureTime = handles.baslerCam.Parameters.Item('ExposureTimeAbs').GetValue; % get set value

% Set the value in GUI
set(handles.textExposureTime,'String',num2str(handles.acqSettings.exposureTime));

% Update timing display
handles.acqSettings.resultingFrameRate = handles.baslerCam.Parameters.Item('ResultingFrameRateAbs').GetValue;
handles.acqSettings.sensorReadoutTime = handles.baslerCam.Parameters.Item('ReadoutTimeAbs').GetValue;
handles.acqSettings.volumeRate = handles.acqSettings.resultingFrameRate/handles.acqSettings.numFramesPerVolume;
handles = update_displays(handles); 

% Update function generator with new frequency (to match volume rate)
update_function_generator(handles.fg,handles.acqSettings.volumeRate,handles.acqSettings.fgAmp);

% Pass data to GUI
guidata(hObject,handles);


