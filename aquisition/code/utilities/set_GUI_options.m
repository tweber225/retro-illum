function handles = set_GUI_options(handles)

% Set the number of frames to capture
set(handles.textNumCaptureFrames,'String',num2str(handles.acqSettings.numCaptureFrames));

% Set the frames to average
set(handles.textNumDisplayFrameAverage,'String',num2str(handles.acqSettings.displayFrameAverage));