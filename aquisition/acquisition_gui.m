function varargout = acquisition_gui(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @acquisition_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @acquisition_gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end % End initialization code - DO NOT EDIT

% --- Executes just before acquisition_gui is made visible.
function acquisition_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for acquisition_gui
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% Add paths
GUIPath = strsplit(mfilename('fullpath'),filesep); % Get full path
GUIPath = strjoin(GUIPath(1:(end-1)),filesep); % Strip this file's name
addpath(genpath(GUIPath)); % add subfolders

% Run start up function
handles = start_up(handles);

% Update handles structure
guidata(hObject, handles);

function varargout = acquisition_gui_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

%% CLOSING FUNCTION
function retroIllumAcqGUI_CloseRequestFcn(hObject, eventdata, handles)
try
    delete(handles.vid) % Close camera on frame grabbe
    handles.baslerCam.Close % Close camera on Basler SDK
    delete(handles.daq) % Close DAQ session
    clear handles.src handles.vid handles.baslerCam
    disp('Camera closed')
    delete(gcp('nocreate'))
    delete(hObject); % Close figure
    
catch
    disp('Error closing GUI')
    delete(gcp('nocreate'))
    delete(hObject); % Close figure
end


%% PREVIEW BUTTON
function buttonPreview_Callback(hObject, eventdata, handles)
if get(hObject,'Value') == 1 % If the button has been pressed on
    % Switch this button's label
    set(hObject,'String','Stop');
    
    % Start timer, Move pupil mirror
    tic;
    outputSingleScan(handles.daq,[true false]);
    
    % Disable controls
    handles = enable_disable_controls(handles,'preview','off');
       
    % Transfer cropped calibration frame to GPU
    cropCalibGPU = gpuArray(handles.calibFrame(handles.yCr,handles.xCr));
    
    % Make the "donut" cross-power spectrum filter
    donutFiltGPU = make_donut_filt(handles.acqSettings.xDisplaySize,handles.acqSettings.xDisplaySize,.01,.9);

    % Allocate refresh rate array
    refreshRateArray = 1024*ones(handles.acqSettings.refreshRateFrames,1,'uint32');
    
    % Store guidata
    guidata(hObject,handles);
    
    % Wait until mirror has flipped, Start the camera
    pause(handles.acqSettings.mirrorFlipTime - toc);
    start(handles.vid); disp('Starting Preview')
    
    % Loop until the button is no longer pressed
    while get(hObject,'Value')    
        % Wait for buffer
        framesAvail = handles.vid.FramesAvailable;
        if framesAvail < handles.acqSettings.displayFrameAverage
            continue % Continue (ie repeat from while) if not enough frames ready
        end

        % Take a peek at most recent data and flush the rest
        img = peekdata(handles.vid,handles.acqSettings.displayFrameAverage);
        flushdata(handles.vid);
        
        % Show image
        cropImgGPU = gpuArray(img(handles.yCr,handles.xCr,1,:));
        displayImg = reg_scale_img_8bit(cropImgGPU,cropCalibGPU,donutFiltGPU,handles.acqSettings.filterSigma,...
            handles.acqSettings.yDisplayActualSize,handles.acqSettings.xDisplayActualSize);
        set(handles.imgHandle,'CData',displayImg)

        % Update histograms
        handles.chan1Hist.Data = img(handles.yCr,handles.xCr,1,1); % only show first frame

        % Update frame stats
        refreshRateArray(1) = framesAvail;
        currentRefreshRate = handles.acqSettings.resultingFrameRate/mean(refreshRateArray,'double');
        refreshRateArray = circshift(refreshRateArray,[1 0]);
        str = ['Refresh rate: ' num2str(round(10*currentRefreshRate)/10) ' Hz'];
        set(handles.textDisplayFrameStats,'String',str);
        
        drawnow; % Interrupt point, necessary for img update & breaking loop
        handles = guidata(hObject); % Pass along GUI data
    end
    
    % If we reach here, the preview has ended: stop camera & flush buffer
    stop(handles.vid); flushdata(handles.vid);
    
    % Switch back label, re-enable controls
    set(hObject,'String','Preview')
    handles = enable_disable_controls(handles,'preview','on');
    guidata(hObject, handles);
    
    % Run capture (does nothing if "Capture" button not depressed)
    buttonCapture_Callback(handles.buttonCapture,eventdata,handles);
    
    % Move pupil mirror back into place for pupil alignment
    outputSingleScan(handles.daq,[false true]);
else
    disp('Stopping Preview')
end

%% COLLECT CALIBRATION BUTTON
function buttonCollectCalibration_Callback(hObject, ~, handles)
if get(hObject,'Value') == 1 % If the button has been pressed on
    % Switch this button's label
    set(hObject,'String','Abort'); 
    
    % Start timer, Move pupil mirror
    tic;
    outputSingleScan(handles.daq,[true false]);
    
    % Disable controls
    handles = enable_disable_controls(handles,'calibration','off');
    
    % Transfer cropped calibration frame to GPU
    cropCalibGPU = gpuArray(handles.calibFrame(handles.yCr,handles.xCr));
    
    % Allocate refresh rate array
    refreshRateArray = 255*ones(handles.acqSettings.refreshRateFrames,1,'uint32');
    
    % Make MATLAB variable to store calibration frames (each summed into)
    frameSumRegister = zeros(handles.acqSettings.ySize,handles.acqSettings.xSize,'uint32');
    
    % Reset background acquired flag
    handles.acqSettings.calibrationAcquired = false;
    
    % Store guidata
    guidata(hObject,handles);
    
    % Wait until mirror flips, Start the camera
    pause(handles.acqSettings.mirrorFlipTime - toc);
    start(handles.vid);
    disp('Starting Calibration Capture')
    
    % Run until number of background frames have been acquired
    frameIdx = 1;
    while frameIdx < handles.acqSettings.numBackgroundFrames
        % Wait for buffer
        framesAvail = handles.vid.FramesAvailable;
        if framesAvail < handles.acqSettings.displayFrameAverage
            continue % Continue if not enough frames ready
        end
        
        % Copy the available frames and sum into aray "frameSumRegister"
        % min() function to make sure we don't get too many frames
        lastFrameInSet = min(frameIdx+framesAvail-1,handles.acqSettings.numCaptureFrames);
        img = getdata(handles.vid,framesAvail);
        frameSumRegister = frameSumRegister + sum(uint32(img(:,:,1,1:(lastFrameInSet-frameIdx+1))),4,'native');
        
        % Show accumulated image
        cropImgGPU = gpuArray(frameSumRegister(handles.yCr,handles.xCr));
        displayImg = gather(scale_img_8bit(cropImgGPU,cropCalibGPU,handles.acqSettings.filterSigma)); 
        set(handles.imgHandle,'CData',displayImg(:,:));
        
        % Update button string with progress
        set(hObject,'String',['Abort (' num2str(frameIdx) '/' num2str(handles.acqSettings.numBackgroundFrames) ' acquired)']);
        
        % Update frame stats
        refreshRateArray(1) = framesAvail;
        currentRefreshRate = handles.acqSettings.resultingFrameRate/mean(refreshRateArray,'double');
        refreshRateArray = circshift(refreshRateArray,[1 0]);
        str = ['Refresh rate: ' num2str(round(10*currentRefreshRate)/10) ' Hz'];
        set(handles.textDisplayFrameStats,'String',str);
        
        % Advance frameIdx counter
        frameIdx = lastFrameInSet+1;
        
        drawnow % Interrupt point, necessary for img update & breaking loop
        
        handles = guidata(hObject);
        
        if get(hObject,'Value') == 0
            % Abort button has been pressed, clear register and break loop
            frameSumRegister = zeros(handles.acqSettings.ySize,handles.acqSettings.xSize,'uint32');
            break;             
        end

    end
    
    % Collection has ended: Stop the camera, flush buffer, move pupil mirror
    stop(handles.vid); flushdata(handles.vid);
    outputSingleScan(handles.daq,[false true]);
    
    % Average the frame sum register in single precision
    handles.calibFrame = single(frameSumRegister)./handles.acqSettings.numBackgroundFrames;
    
    % Switch back label
    if get(hObject,'Value') == 1 % Then we didn't abort
        set(hObject,'String','Calibration Acquired')
        handles.acqSettings.calibrationAcquired = true;
        set(hObject,'Value',0);
    else % Then we must have aborted
        set(hObject,'String','Calibration Aborted')
        handles.acqSettings.calibrationAcquired = false;
    end
    handles = enable_disable_controls(handles,'calibration','on');
    guidata(hObject, handles);
    
else
    disp('Aborting calibration collection')
    set(hObject,'Value',0);
    handles = enable_disable_controls(handles,'calibration','on');
    guidata(hObject, handles);
end


%% --- CAPTURE BUTTON ---
function buttonCapture_Callback(hObject, ~, handles)
if get(handles.buttonPreview,'Value') == 1 % If preview is on ...
    % Turn off the preview
    set(handles.buttonPreview,'Value',0); % Setting this to 0 will initiate termination of Preview loop
    disp('Ending Preview for Capture')
    guidata(hObject,handles);
    return
end

if get(hObject,'Value') == 1 % If the button has been pressed on...
    % Start timer, move pupil mirror, note start time, switch label, disable controls
    tic;
    outputSingleScan(handles.daq,[true false]);
    handles.acqSettings.captureStartTime = datestr(datetime);
    set(hObject,'String','Abort');
    handles = enable_disable_controls(handles,'capture','off');   
    
    % Transfer cropped calibration to GPU, make donut x-power spec filter
    cropCalibGPU = gpuArray(handles.calibFrame(handles.yCr,handles.xCr));
    donutFiltGPU = make_donut_filt(handles.acqSettings.xDisplaySize,handles.acqSettings.xDisplaySize,.05,.95);

    % Allocate refresh rate array
    refreshRateArray = ones(handles.acqSettings.refreshRateFrames,1,'uint32');
       
    % Store guidata, wait until mirror has moved, start the camera
    guidata(hObject,handles);
    pause(handles.acqSettings.mirrorFlipTime - toc);
    start(handles.vid); disp('Starting Capture')
    
    % Run until number of capture frames have been acquired
    while handles.vid.FramesAvailable < handles.acqSettings.numCaptureFrames
        % Check that enough frames are available
        frameIdx = handles.vid.FramesAvailable;
        if frameIdx < handles.acqSettings.displayFrameAverage
            continue
        end
        
        % Peek at the most recent frames up to display frame average #
        img = peekdata(handles.vid,handles.acqSettings.displayFrameAverage);

        % Show most recent images (registed and averaged on GPU)
        cropImgGPU = gpuArray(img(handles.yCr,handles.xCr,1,:));
        displayImg = reg_scale_img_8bit(cropImgGPU,cropCalibGPU,donutFiltGPU, handles.acqSettings.filterSigma, ...
            handles.acqSettings.yDisplayActualSize,handles.acqSettings.xDisplayActualSize);
        set(handles.imgHandle,'CData',displayImg(:,:));
        
        % Update histograms
        handles.chan1Hist.Data = img(handles.yCr,handles.xCr,1,1); % only most recent frame
        
        % Update button string with progress
        set(hObject,'String',['Abort (' num2str(frameIdx) '/' num2str(handles.acqSettings.numCaptureFrames) ' acquired)']);
        
        % Update frame stats
        refreshRateArray(handles.acqSettings.refreshRateFrames) = frameIdx;
        currentRefreshRate = handles.acqSettings.resultingFrameRate/mean(diff(refreshRateArray),'double');
        refreshRateArray = circshift(refreshRateArray,-1);
        str = ['Refresh rate: ' num2str(round(10*currentRefreshRate)/10) ' Hz'];
        set(handles.textDisplayFrameStats,'String',str);
        
        drawnow % Interrupt point, necessary for img update & breaking loop
        handles = guidata(hObject);
        
        if get(hObject,'Value') == 0
            % Abort button has been pressed, break loop
            break;             
        end

    end
    
    % Collection has ended: stop the camera, move mirror
    stop(handles.vid); 
    outputSingleScan(handles.daq,[false true]);
    
    if get(hObject,'Value') == 1 % Save the capture data and metadata
        set(hObject,'String','Saving Data');drawnow
        % Retrieve data
        captureFrames = getdata(handles.vid,handles.acqSettings.numCaptureFrames);
        
        % Formulate datapath for this capture--saves as date in YYYYMMDD \
        % time in HHMMSS[ms][ms][ms]-- and make directory
        handles.acqSettings.captureDirectory = [handles.acqSettings.dataPath filesep datestr(now,'yyyymmdd') filesep datestr(now,'HHMMSSFFF')];
        mkdir(handles.acqSettings.captureDirectory);
        
        % Save raw stack, calibration, thumbnail preview       
        save_captured_image_stack(squeeze(captureFrames),handles.calibFrame,handles.acqSettings.captureDirectory,handles.thumbOpts);
        
        % Save settings used during capture
        save_settings(handles.acqSettings);
        
        set(hObject,'String','Capture (Last: Success)');drawnow;
        disp(['Successfully saved file at ' handles.acqSettings.captureDirectory])
    else
        % Don't do saving b/c the capture was aborted
        set(hObject,'String','Capture (Last: Aborted)')
    end
    
    % Flush any extra buffer
    flushdata(handles.vid);
    
    % Switch back value, re-enable controls, and store guidata
    set(hObject,'Value',0);
    handles = enable_disable_controls(handles,'capture','on');
    guidata(hObject, handles);
    
else

    guidata(hObject, handles);
end


%% SETTINGS FUNCTION CALLBACKS
function textNumCaptureFrames_Callback(hObject, eventdata, handles)
textNumCaptureFramesCallback(hObject,handles);

function textNumDisplayFrameAverage_Callback(hObject, eventdata, handles)
textNumDisplayFrameAverageCallback(hObject,handles);

function textFilterSigma_Callback(hObject, eventdata, handles)
textFilterSigmaCallback(hObject,handles);

function textExposureTime_Callback(hObject, eventdata, handles)
textExposureTimeCallback(hObject,handles);


%% CREATE FUNCTIONS -- ignore
function textNumCaptureFrames_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function textNumDisplayFrameAverage_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function textFilterSigma_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function textExposureTime_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



%% HOTKEYS
% supported: F1 (Preview),  F4 (Capture)
function hot_key_callback(eventdata,handles) % Main hot key button

% Key that was pressed is in eventdata.Key field
if strcmp(eventdata.Key,'f1') % Toggle Preview Button and run callback
    oldValue = get(handles.buttonPreview,'Value');
    set(handles.buttonPreview,'Value',~oldValue);
    buttonPreview_Callback(handles.buttonPreview, eventdata, handles);

elseif strcmp(eventdata.Key,'f4') % Toggle Capture button and run callback
    oldValue = get(handles.buttonCapture,'Value');
    set(handles.buttonCapture,'Value',~oldValue);
    buttonCapture_Callback(handles.buttonCapture, eventdata, handles);
    
end

% Individ. key press callback functions all call the main hot key function
function retroIllumAcqGUI_KeyPressFcn(hObject, eventdata, handles)
hot_key_callback(eventdata,handles)
function buttonPreview_KeyPressFcn(hObject, eventdata, handles)
hot_key_callback(eventdata,handles)
function buttonCapture_KeyPressFcn(hObject, eventdata, handles)
hot_key_callback(eventdata,handles)
function buttonCollectCalibration_KeyPressFcn(hObject, eventdata, handles)
hot_key_callback(eventdata,handles)
function textNumDisplayFrameAverage_KeyPressFcn(hObject, eventdata, handles)
hot_key_callback(eventdata,handles)
function textNumCaptureFrames_KeyPressFcn(hObject, eventdata, handles)
hot_key_callback(eventdata,handles)
function textFilterSigma_KeyPressFcn(hObject, eventdata, handles)
hot_key_callback(eventdata,handles)
function textExposureTime_KeyPressFcn(hObject, eventdata, handles)
hot_key_callback(eventdata,handles)
