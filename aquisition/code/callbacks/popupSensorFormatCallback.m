function popupSensorFormatCallback(hObject,handles)
% Executes when user switched between sensor formats on GUI
% This changes the resolution, so several things will need to be changed 

disp('Changing sensor format')

% Load PCO definitions
pco_camera_load_defines();

% Free old buffers
handles = clear_buffers(handles);

% Change in internal settings structure
newVal = get(handles.popupSensorFormat,'Value')-1; % minus 1 because it's a 0-indexed setting in SDK
handles.acqSettings.sensorFormat = newVal;

% Change sensor format in SDK
errorCode = calllib('PCO_CAM_SDK','PCO_SetSensorFormat',handles.out_ptr,handles.acqSettings.sensorFormat);
pco_errdisp('PCO_SetSensorFormat',errorCode);

% Arm camera and check for errors
errorCode = calllib('PCO_CAM_SDK', 'PCO_ArmCamera', handles.out_ptr);
pco_errdisp('PCO_ArmCamera',errorCode);   
if(errorCode~=PCO_NOERROR)
    error('Camera arming failed')
end 

% Get new frame period
handles.acqSettings.framePeriod = handles.subfunc.fh_get_frametime(handles.out_ptr);

% Get frame size
handles.acqSettings.xSize = uint16(0);
handles.acqSettings.ySize = uint16(0);
handles.acqSettings.xMaxSize = uint16(0);
handles.acqSettings.yMaxSize = uint16(0);
[errorCode,~,handles.acqSettings.xSize,handles.acqSettings.ySize,handles.acqSettings.xMaxSize,handles.acqSettings.yMaxSize]  = calllib('PCO_CAM_SDK','PCO_GetSizes',handles.out_ptr,handles.acqSettings.xSize,handles.acqSettings.ySize,handles.acqSettings.xMaxSize,handles.acqSettings.yMaxSize);
pco_errdisp('PCO_GetSizes',errorCode);
if handles.acqSettings.doubleImageMode == 1
    handles.acqSettings.actualYMaxSize = handles.acqSettings.yMaxSize/2;
    handles.acqSettings.actualYSize = handles.acqSettings.ySize/2;
else
    handles.acqSettings.actualYMaxSize = handles.acqSettings.yMaxSize;
    handles.acqSettings.actualYSize = handles.acqSettings.ySize;
end

% Update Number of Frames to Capture
textNumCaptureFramesCallback(hObject,handles); handles = guidata(hObject);

% Update displays
handles = update_displays(handles);

% Render blank frame on image axes
blankFrame = zeros(handles.acqSettings.actualYMaxSize,handles.acqSettings.xMaxSize,'uint8');
axes(handles.imgAxes);
handles.imgHandle = imshow(blankFrame);
% Then update this with set(handles.imgHandle,'CData',YOUR8BITIMAGE)

% Make dummy frame for background
handles.background = zeros(handles.acqSettings.ySize,handles.acqSettings.xSize,'uint16');

% Make new filter 
handles.filterFT = make_filter(handles.acqSettings.BPLow,handles.acqSettings.BPHigh,handles.acqSettings.xSize,handles.acqSettings.actualYSize);

% Render histograms
handles.histogramBinEdges = linspace(0,2^double(handles.acqSettings.bitDepth),128+1);
handles.chan1Hist = histogram(handles.background,handles.histogramBinEdges,'Parent',handles.hist1Axes);
handles.chan2Hist = histogram(handles.background,handles.histogramBinEdges,'Parent',handles.hist2Axes);
handles.hist1Axes.XLim = [handles.histogramBinEdges(1) handles.histogramBinEdges(end)];
handles.hist1Axes.YScale = 'log';
handles.hist1Axes.YLim = [1 10^5];
handles.hist2Axes.XLim = [handles.histogramBinEdges(1) handles.histogramBinEdges(end)];
handles.hist2Axes.YScale = 'log';
handles.hist2Axes.YLim = [1 10^5];

% Set up new buffers
handles = make_buffers(handles);

% Reset background collection button
set(handles.buttonCollectBackground,'String','Collect Background')
handles.acqSettings.backgroundAcquired = 0;

guidata(hObject,handles);