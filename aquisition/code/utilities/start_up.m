function handles = start_up(handles)
% Run start-up related codes, including:
% - load default settings into settings structure
% - load PCO definitions
% - open camera


% Load default settings store in handles structure
default_settings
handles.acqSettings = acqSettings;

% Make PCO SDK-MATLAB global variable
handles.glvar = struct('do_libunload',0,'do_close',0,'camera_open',0,'out_ptr',[]);

% Load PCO definitions
pco_camera_load_defines();

% Try to open the camera
[errorCode,handles.glvar] = pco_camera_open_close(handles.glvar);
pco_errdisp('pco_camera_setup',errorCode); 
if(errorCode ~= PCO_NOERROR), error('Could not open camera'); end 
handles.out_ptr = handles.glvar.out_ptr;

% Load subfunctions
handles.subfunc = pco_camera_subfunction();

% Make sure the camera is stopped
handles.subfunc.fh_stop_camera(handles.out_ptr);

% Load camera description
handles.cam_desc = libstruct('PCO_Description');
set(handles.cam_desc,'wSize',handles.cam_desc.structsize);
[errorCode,~,handles.cam_desc] = calllib('PCO_CAM_SDK','PCO_GetCameraDescription',handles.out_ptr,handles.cam_desc);
pco_errdisp('PCO_GetCameraDescription',errorCode);

% Note the Bit Depth
handles.acqSettings.bitDepth = uint16(handles.cam_desc.wDynResDESC);

% Set bit alignment to LSB
errorCode = calllib('PCO_CAM_SDK','PCO_SetBitAlignment',handles.out_ptr,uint16(BIT_ALIGNMENT_LSB));
pco_errdisp('PCO_SetBitAlignment',errorCode);   

% Set recorder sub mode to ring buffer
errorCode = calllib('PCO_CAM_SDK', 'PCO_SetRecorderSubmode',handles.out_ptr,RECORDER_SUBMODE_RINGBUFFER);
pco_errdisp('PCO_SetRecorderSubmode',errorCode);

% Set user-defined and necessary camera settings
handles = set_user_settings(handles);

% Set GUI options based on user-defined default settings
handles = set_GUI_options(handles);

% Arm camera and check for errors
errorCode = calllib('PCO_CAM_SDK', 'PCO_ArmCamera', handles.out_ptr);
pco_errdisp('PCO_ArmCamera',errorCode);   
if(errorCode~=PCO_NOERROR)
    error('Camera arming failed')
end 

% Get frame period
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

% Update displays
handles = update_displays(handles);

% Render blank frame on image axes
blankFrame = zeros(handles.acqSettings.actualYMaxSize,handles.acqSettings.xMaxSize,'uint8');
axes(handles.imgAxes);
handles.imgHandle = imshow(blankFrame);
% Then update this with set(handles.imgHandle,'CData',YOUR8BITIMAGE)

% Make dummy frame for background
handles.background = zeros(handles.acqSettings.ySize,handles.acqSettings.xSize,'uint16');

% Make filter 
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

% Set up buffers
handles = make_buffers(handles);




