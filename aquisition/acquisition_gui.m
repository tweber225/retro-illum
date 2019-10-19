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
end
% End initialization code - DO NOT EDIT


% --- Executes just before acquisition_gui is made visible.
function acquisition_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for acquisition_gui
handles.output = hObject;
% Update handles structure
guidata(hObject, handles);

% Add paths
userPathSplit = regexp(userpath,filesep,'split');   
addpath(genpath(fullfile(userPathSplit{1},userPathSplit{2},userPathSplit{3},'retro-illum','aquisition')));

% Run start up function
handles = start_up(handles);

% Update handles structure
guidata(hObject, handles);



function varargout = acquisition_gui_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


function retroIllumAcqGUI_CloseRequestFcn(hObject, eventdata, handles)
try
    delete(handles.vid) % Close camera
    clear handles.src handles.vid
    disp('Camera closed')
    delete(hObject); % Close figure
catch
    disp('Error closing GUI')
    delete(hObject); % Close figure
end



%% PREVIEW BUTTON
function buttonPreview_Callback(hObject, eventdata, handles)
if get(hObject,'Value') == 1 % If the button has been pressed on
    % Switch this button's label
    set(hObject,'String','Stop'); 
    
    % Disable controls
    handles = enable_disable_controls(handles,'preview','off');
    
    % Derive frame cropping indices
    xCr = (-(handles.acqSettings.xDisplaySize/2 -1):(handles.acqSettings.xDisplaySize/2)) + (handles.acqSettings.xSize/2);
    yCr = (-(handles.acqSettings.yDisplaySize/2 -1):(handles.acqSettings.yDisplaySize/2)) + (handles.acqSettings.ySize/2);
    
    % Allocate refresh rate array
    refreshRateArray = 255*ones(handles.acqSettings.refreshRateFrames,1,'uint8');
    
    % Store guidata
    guidata(hObject,handles);
    
    % Start the camera
    start(handles.vid)
    disp('Starting Preview')
    
    % Loop until the button is no longer pressed
    while get(hObject,'Value')    
        % Wait for buffer
        framesAvail = handles.vid.FramesAvailable;
        if framesAvail < handles.acqSettings.displayFrameAverage
            continue % Continue if not enough frames ready
        end

        % Take a peek at most recent data and flush the rest
        img = peekdata(handles.vid,handles.acqSettings.displayFrameAverage);
        flushdata(handles.vid);
                   
        % Show image
        displayImg = scale_img_8bit(img(yCr,xCr,1,:),handles.background(yCr,xCr),handles.acqSettings.backgroundAcquired,handles.acqSettings.filterSigma);
        set(handles.imgHandle,'CData',displayImg(:,:))

        % Update histograms
        handles.chan1Hist.Data = img(yCr,xCr,1,1); % only show first frame

        % Update frame stats
        refreshRateArray(1) = framesAvail;
        currentRefreshRate = handles.acqSettings.resultingFrameRate/mean(refreshRateArray,'double');
        refreshRateArray = circshift(refreshRateArray,[1 0]);
        str = ['Refresh rate: ' num2str(round(10*currentRefreshRate)/10) ' Hz'];
        set(handles.textDisplayFrameStats,'String',str);
        
        drawnow; % Interrupt point, necessary for img update & breaking loop

        handles = guidata(hObject); 

    end
    
    % If we reach here, the preview has ended: stop camera
    stop(handles.vid);
    
    % Switch back label, re-enable controls
    set(hObject,'String','Preview')
    handles = enable_disable_controls(handles,'preview','on');
    guidata(hObject, handles);
    
    % Run capture callback (does nothing if button not depressed)
    buttonCapture_Callback(handles.buttonCapture,eventdata,handles);
    
else
    disp('Stopping Preview')
    
end

%% COLLECT BACKGROUND BUTTON
function buttonCollectBackground_Callback(hObject, eventdata, handles)
if get(hObject,'Value') == 1 % If the button has been pressed on
    
    % Switch this button's label
    set(hObject,'String','Abort'); 
    
    % Disable controls
    handles = enable_disable_controls(handles,'background','off');
    
    % Derive frame cropping indices
    xCr = (-(handles.acqSettings.xDisplaySize/2 -1):(handles.acqSettings.xDisplaySize/2)) + (handles.acqSettings.xSize/2);
    yCr = (-(handles.acqSettings.yDisplaySize/2 -1):(handles.acqSettings.yDisplaySize/2)) + (handles.acqSettings.ySize/2);
    
    % Allocate refresh rate array
    refreshRateArray = 255*ones(handles.acqSettings.refreshRateFrames,1,'uint8');
    
    % Make MATLAB variable to store background frames
    frameSumRegister = zeros(handles.acqSettings.ySize,handles.acqSettings.xSize,'uint32');
    
    % Reset background acquired flag
    handles.acqSettings.backgroundAcquired = 0;
    
    % Store guidata
    guidata(hObject,handles);
    
    % Start the camera
    start(handles.vid);
    disp('Starting Background Capture')
    
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
        displayImg = scale_img_8bit(frameSumRegister(yCr,xCr),[],handles.acqSettings.backgroundAcquired,handles.acqSettings.filterSigma); 
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
    
    % Collection has ended: Stop the camera
    stop(handles.vid);
    
    % Average the frame sum register in double precision
    handles.background = double(frameSumRegister)./handles.acqSettings.numBackgroundFrames;
    
    % Switch back label
    if get(hObject,'Value') == 1 % Then we didn't abort
        set(hObject,'String','Background Acquired')
        handles.acqSettings.backgroundAcquired = 1;
        set(hObject,'Value',0);
    else % Then we must have aborted
        set(hObject,'String','Background Aborted')
        handles.acqSettings.backgroundAcquired = 0;
    end
    handles = enable_disable_controls(handles,'background','on');
    guidata(hObject, handles);
    
else
    disp('Aborting background collection')
    set(hObject,'Value',0);
    handles = enable_disable_controls(handles,'background','on');
    guidata(hObject, handles);
end


%% --- CAPTURE BUTTON ---
function buttonCapture_Callback(hObject, eventdata, handles)
if get(handles.buttonPreview,'Value') == 1 % If preview is on ...
    % Turn off the preview
    set(handles.buttonPreview,'Value',0); % Setting this to 0 will initiate termination of Preview loop
    disp('Ending Preview for Capture')
    guidata(hObject,handles);
    return
end

if get(hObject,'Value') == 1 % If the button has been pressed on...
    % Note start time
    handles.acqSettings.captureStartTime = datestr(datetime);
    
    % Switch this button's label
    set(hObject,'String','Abort');
    
    % Disable controls
    handles = enable_disable_controls(handles,'capture','off');
    
    % Derive frame cropping indices
    xCr = (-(handles.acqSettings.xDisplaySize/2 -1):(handles.acqSettings.xDisplaySize/2)) + (handles.acqSettings.xSize/2);
    yCr = (-(handles.acqSettings.yDisplaySize/2 -1):(handles.acqSettings.yDisplaySize/2)) + (handles.acqSettings.ySize/2);
    
    % Allocate refresh rate array
    refreshRateArray = 255*ones(handles.acqSettings.refreshRateFrames,1,'uint8');
    
    % Make MATLAB variable to store captured frames
    captureFrames = zeros(handles.acqSettings.ySize,handles.acqSettings.xSize,1,handles.acqSettings.numCaptureFrames,'uint8');
    
    % Store guidata
    guidata(hObject,handles);
    
    % Start the camera
    start(handles.vid);
    disp('Starting Capture')
    
    % Run until number of capture frames have been acquired
    frameIdx = 1;
    while frameIdx < handles.acqSettings.numCaptureFrames
        % Wait for buffer
        framesAvail = handles.vid.FramesAvailable;
        if framesAvail < handles.acqSettings.displayFrameAverage
            continue % Continue if not enough frames ready
        end

        % Copy the available frames into user array, "captureFrames"
        % min() function to make sure we don't overfill array with frames
        lastFrameInSet = min(frameIdx+framesAvail-1,handles.acqSettings.numCaptureFrames);
        img = getdata(handles.vid,framesAvail);
        captureFrames(:,:,1,frameIdx:lastFrameInSet) = img(:,:,1,1:(lastFrameInSet-frameIdx+1));
               
        % Show most recent image(s)
        displayImg = scale_img_8bit(img(yCr,xCr,1,(framesAvail-handles.acqSettings.displayFrameAverage+1):framesAvail),handles.background(yCr,xCr),handles.acqSettings.backgroundAcquired,handles.acqSettings.filterSigma);
        set(handles.imgHandle,'CData',displayImg(:,:));
        
        % Update histograms
        handles.chan1Hist.Data = img(yCr,xCr,1,1); % only most recent frame
        
        % Update button string with progress
        set(hObject,'String',['Abort (' num2str(frameIdx) '/' num2str(handles.acqSettings.numCaptureFrames) ' acquired)']);
        
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
            clear captureFrames
            break;             
        end

    end
    
    % Collection has ended: stop the camera
    stop(handles.vid);
    
    if get(hObject,'Value') == 1 % Save the capture data and metadata
        % Make new directory for acquisition
        GUIPath = strsplit(mfilename('fullpath'),filesep);
        
        % Saves as date in YYYYMMDD \ time in HHMMSS[miliseconds] \(images)
        handles.acqSettings.captureDirectory = [strjoin(GUIPath(1:(end-2)),filesep) filesep 'data' filesep datestr(now,'yyyymmdd') filesep datestr(now,'HHMMSSFFF')];
        mkdir(handles.acqSettings.captureDirectory)
        
        % Save image raw stack and background image
        set(hObject,'String','Saving Images');drawnow
        save_captured_image_stack(squeeze(captureFrames),handles.background,handles.acqSettings.captureDirectory);
        
        % Save settings used during capture
        set(hObject,'String','Saving Settings');drawnow
        handles = save_settings(handles);
        
        set(hObject,'String','Capture (Last: Success)');drawnow;
        
        disp(['Successfully saved file at ' handles.acqSettings.captureDirectory])
    else
        % Don't do saving b/c the capture was aborted
        set(hObject,'String','Capture (Last: Aborted)')
    end
    
    % Switch back value, re-enable controls, and store guidata
    set(hObject,'Value',0);
    handles = enable_disable_controls(handles,'capture','on');
    guidata(hObject, handles);
    
else

    guidata(hObject, handles);
end



function textNumCaptureFrames_Callback(hObject, eventdata, handles)
textNumCaptureFramesCallback(hObject,handles);

function textNumDisplayFrameAverage_Callback(hObject, eventdata, handles)
textNumDisplayFrameAverageCallback(hObject,handles);



% CREATE FUNCTIONS -- ignore
function textNumCaptureFrames_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function textNumDisplayFrameAverage_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



%% HOTKEYS
% supported: F1 (Preview),  F4 (Capture)

function retroIllumAcqGUI_KeyPressFcn(hObject, eventdata, handles)
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




