function textNumDisplayFrameAverageCallback(hObject,handles)

% Min/max values
minVal = 1;
maxVal = 64;

% Get new value
newVal = round(str2double(get(handles.textNumDisplayFrameAverage,'String')));

% Check limits
if newVal < minVal
    newVal = minVal;
elseif newVal > maxVal
    newVal = maxVal;
end

% After passing limits, set the value
handles.acqSettings.displayFrameAverage = newVal;

% Set the value in GUI
set(handles.textNumDisplayFrameAverage,'String',num2str(handles.acqSettings.displayFrameAverage));


% Pass data to GUI
guidata(hObject,handles);


