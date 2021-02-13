function handles = start_up(handles)
% Run start-up related codes, including:
% - load default settings into settings structure
% - open camera

% Load default settings store in handles structure
default_settings
handles.acqSettings = acqSettings;

% Move pupil-view mirror up, turn on pupil LED (ie logic level low,high)
handles.daq = initialize_DAQ(2); % 2 channels

% Try to open the camera
handles = open_camera(handles);

% Set user-defined and necessary camera-specific settings
handles = set_user_settings(handles);

% Set GUI options based on user-defined default settings
handles = set_GUI_options(handles);

% Get derived parameters
handles.acqSettings.resultingFrameRate = handles.baslerCam.Parameters.Item('ResultingFrameRateAbs').GetValue;
handles.acqSettings.sensorReadoutTime = handles.baslerCam.Parameters.Item('ReadoutTimeAbs').GetValue;
handles.acqSettings.volumeRate = handles.acqSettings.resultingFrameRate/acqSettings.numFramesPerVolume;
handles.xCr = (-(handles.acqSettings.xDisplaySize/2 -1):(handles.acqSettings.xDisplaySize/2)) + (handles.acqSettings.xSize/2); % Center the crop in X
handles.yCr = (handles.acqSettings.ySize-handles.acqSettings.yDisplaySize+1):(handles.acqSettings.ySize); % Crop to bottom in Y

% Update displays
handles = update_displays(handles);

% Initialize function generator (now that framerate is available)
handles.fg = set_up_function_generator(handles.acqSettings.fgComPort, ...
    handles.acqSettings.fgBaudRate, handles.acqSettings.volumeRate, ...
    handles.acqSettings.fgAmp);

% Render blank frame on image axes
blankFrame = zeros(handles.acqSettings.yDisplaySize,handles.acqSettings.xDisplaySize,'uint8');
smallBlankFrame = imresize(blankFrame,[handles.acqSettings.yDisplayActualSize, handles.acqSettings.xDisplayActualSize]);
axes(handles.imgAxes);
handles.imgHandle = imshow(smallBlankFrame);
% Then update this with set(handles.imgHandle,'CData',YOUR8BITIMAGE)

% Make dummy frame for background
handles.calibFrame = ones(handles.acqSettings.ySize,handles.acqSettings.xSize,'single');

% Render histograms
handles.histogramBinEdges = linspace(0,2^double(handles.acqSettings.bitDepth),128+1);
handles.chan1Hist = histogram(handles.calibFrame,handles.histogramBinEdges,'Parent',handles.hist1Axes);
handles.hist1Axes.XLim = [handles.histogramBinEdges(1) handles.histogramBinEdges(end)];
handles.hist1Axes.YScale = 'log';
handles.hist1Axes.YLim = [1 10^5];

% Note the directory
GUIPath = strsplit(mfilename('fullpath'),filesep);
GUIPath = strjoin(GUIPath(1:(end-3)),filesep);
handles.acqSettings.GUIPath = GUIPath; 






