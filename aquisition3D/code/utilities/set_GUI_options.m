function handles = set_GUI_options(handles)

% Set the number of frames to capture
set(handles.textNumCaptureFrames,'String',num2str(handles.acqSettings.numCaptureFrames));

% Set the frames to average
set(handles.textNumDisplayFrameAverage,'String',num2str(handles.acqSettings.displayFrameAverage));

% Set frame number to display
set(handles.textDisplayFrame,'String',num2str(handles.acqSettings.displayFrame));

% Set the filtering sigma parameter
set(handles.textFilterSigma,'String',num2str(handles.acqSettings.filterSigma));

% (Re-)set exposure time
set(handles.textExposureTime,'String',num2str(handles.acqSettings.exposureTime));