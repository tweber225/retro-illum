function textNumCaptureFramesCallback(hObject,handles)

% Get new value
newVal = round(str2double(get(handles.textNumCaptureFrames,'String')));

% Check limits
if newVal < 1
    newVal = 1;
end

% Check also that we're not going to allocating too much memory
frameMB = 2*double(handles.acqSettings.xSize)*double(handles.acqSettings.ySize)/2^20;
stackMB = newVal*frameMB;

if stackMB > handles.acqSettings.maxMemMB
    newVal = floor(handles.acqSettings.maxMemMB/frameMB);
end

% After passing limits, set the value
handles.acqSettings.numCaptureFrames = newVal;

% Set the value in GUI
set(handles.textNumCaptureFrames,'String',num2str(handles.acqSettings.numCaptureFrames));

% Update displays
handles = update_displays(handles);

% Pass data to GUI
guidata(hObject,handles);


