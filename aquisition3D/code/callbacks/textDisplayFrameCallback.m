function textDisplayFrameCallback(hObject,handles)

% Get new value
newVal = round(str2double(get(handles.textDisplayFrame,'String')));

% Check limits
if newVal < 1
    newVal = 1;
end

if newVal > handles.acqSettings.numFramesPerVolume
    newVal = handles.acqSettings.numFramesPerVolume;
end


% After passing limits, set the value
handles.acqSettings.displayFrame = newVal;

% Set the value in GUI
set(handles.textDisplayFrame,'String',num2str(handles.acqSettings.displayFrame));

% Pass data to GUI
guidata(hObject,handles);