function handles = start_up(handles)
% Run start-up related codes, including:
% - load default settings into settings structure
% - open camera


% Load default settings store in handles structure
default_settings
handles.acqSettings = acqSettings;

% Try to open the camera
handles = open_camera(handles);

% Set user-defined and necessary camera settings
handles = set_user_settings(handles);

% Set GUI options based on user-defined default settings
handles = set_GUI_options(handles);

% Get derived parameters
handles.acqSettings.resultingFrameRate = handles.src.ResultingFrameRate;
handles.acqSettings.sensorReadoutTime = handles.src.SensorReadoutTime;

% Update displays
handles = update_displays(handles);

% Render blank frame on image axes
blankFrame = zeros(handles.acqSettings.yDisplaySize,handles.acqSettings.xDisplaySize,'uint8');
axes(handles.imgAxes);
handles.imgHandle = imshow(blankFrame);
% Then update this with set(handles.imgHandle,'CData',YOUR8BITIMAGE)

% Make dummy frame for background
handles.background = ones(handles.acqSettings.ySize,handles.acqSettings.xSize,'double');

% Render histograms
handles.histogramBinEdges = linspace(0,2^double(handles.acqSettings.bitDepth),128+1);
handles.chan1Hist = histogram(handles.background,handles.histogramBinEdges,'Parent',handles.hist1Axes);
handles.hist1Axes.XLim = [handles.histogramBinEdges(1) handles.histogramBinEdges(end)];
handles.hist1Axes.YScale = 'log';
handles.hist1Axes.YLim = [1 10^5];





