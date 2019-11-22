function handles = set_GUI_options(handles)

% Set the number of frames to capture
set(handles.textNumCaptureFrames,'String',num2str(handles.acqSettings.numCaptureFrames));

% Set the frames to average
set(handles.textNumDisplayFrameAverage,'String',num2str(handles.acqSettings.displayFrameAverage));

% Set the frames to average
set(handles.textFilterSigma,'String',num2str(handles.acqSettings.filterSigma));

% Set exposure time
set(handles.textExposureTime,'String',num2str(handles.acqSettings.exposureTime));