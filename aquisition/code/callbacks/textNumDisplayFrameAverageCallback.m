function textNumDisplayFrameAverageCallback(hObject,handles)

% Get new value
newVal = round(str2double(get(handles.textNumDisplayFrameAverage,'String')));

% Check limits
if newVal < 1
    newVal = 1;
elseif newVal > 16
    newVal = 16;
end

% After passing limits, set the value
handles.acqSettings.displayFrameAverage = newVal;

% Set the value in GUI
set(handles.textNumDisplayFrameAverage,'String',num2str(handles.acqSettings.displayFrameAverage));


% Pass data to GUI
guidata(hObject,handles);


