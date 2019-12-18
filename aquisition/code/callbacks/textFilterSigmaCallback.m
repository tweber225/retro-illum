function textFilterSigmaCallback(hObject,handles)

% Min/max
maxVal = 256;
minVal = 1;

% Get new value
newVal = round(str2double(get(handles.textFilterSigma,'String')));

% Check limits
if newVal < minVal
    newVal = minVal;
elseif newVal > maxVal
    newVal = maxVal;
end

% After passing limits, set the value
handles.acqSettings.filterSigma = newVal;

% Set the value in GUI
set(handles.textFilterSigma,'String',num2str(handles.acqSettings.filterSigma));


% Pass data to GUI
guidata(hObject,handles);


