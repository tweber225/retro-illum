function textFilterSigmaCallback(hObject,handles)

% Get new value
newVal = round(str2double(get(handles.textFilterSigma,'String')));

% Check limits
if newVal < 1
    newVal = 1;
elseif newVal > 1024
    newVal = 1024;
end

% After passing limits, set the value
handles.acqSettings.filterSigma = newVal;

% Set the value in GUI
set(handles.textFilterSigma,'String',num2str(handles.acqSettings.filterSigma));


% Pass data to GUI
guidata(hObject,handles);


