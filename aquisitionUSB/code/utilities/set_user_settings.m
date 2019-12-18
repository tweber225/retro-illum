function handles = set_user_settings(handles)

% Set and then Get various parameters

% Set sensor size
handles.src.CenterX = handles.acqSettings.centerX;
handles.src.CenterY = handles.acqSettings.centerY;
handles.vid.ROIPosition = [handles.acqSettings.xOffset handles.acqSettings.yOffset handles.acqSettings.xSize handles.acqSettings.ySize];
handles.acqSettings.centerX = handles.src.CenterX;
handles.acqSettings.centerY = handles.src.CenterY;
updatedROI = handles.vid.ROIPosition;
handles.acqSettings.xOffset = updatedROI(1);
handles.acqSettings.yOffset = updatedROI(2);
handles.acqSettings.xSize = updatedROI(3);
handles.acqSettings.ySize = updatedROI(4);

% Set gain
handles.src.Gain = handles.acqSettings.gain;
handles.acqSettings.gain = handles.src.Gain;

% Set exposure
handles.src.ExposureTime = handles.acqSettings.exposureTime;
handles.acqSettings.exposureTime = handles.src.ExposureTime;

% Set GPIOs
handles.src.LineSelector = handles.acqSettings.GPIO1Name;
handles.src.LineMode = handles.acqSettings.GPIO1LineMode;
handles.src.LineSource = handles.acqSettings.GPIO1LineSource;
handles.src.LineInverter = handles.acqSettings.GPIO1LineInverter;
if ~strcmp(handles.src.LineMode,handles.acqSettings.GPIO1LineMode) || ~strcmp(handles.src.LineSource,handles.acqSettings.GPIO1LineSource) || ~strcmp(handles.src.LineInverter,handles.acqSettings.GPIO1LineInverter)
    error('Could not set GPIO 1 mode');
end

handles.src.LineSelector = handles.acqSettings.GPIO2Name;
handles.src.LineMode = handles.acqSettings.GPIO2LineMode;
handles.src.LineSource = handles.acqSettings.GPIO2LineSource;
handles.src.LineInverter = handles.acqSettings.GPIO2LineInverter;
if ~strcmp(handles.src.LineMode,handles.acqSettings.GPIO2LineMode) || ~strcmp(handles.src.LineSource,handles.acqSettings.GPIO2LineSource) || ~strcmp(handles.src.LineInverter,handles.acqSettings.GPIO2LineInverter)
    error('Could not set GPIO 2 mode');
end

% Turn off data throughput limit
handles.src.DeviceLinkThroughputLimitMode = 'Off';
if ~strcmp(handles.src.DeviceLinkThroughputLimitMode,'Off')
    error('Could not turn off data throughput limit mode')
end
