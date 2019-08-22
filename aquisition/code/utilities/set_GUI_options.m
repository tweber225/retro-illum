function handles = set_GUI_options(handles)

% Set the sensor format popup menu to correct setting
set(handles.popupSensorFormat,'Value',handles.acqSettings.sensorFormat+1);

% Set the number of frames to capture
set(handles.textNumCaptureFrames,'String',num2str(handles.acqSettings.numCaptureFrames));