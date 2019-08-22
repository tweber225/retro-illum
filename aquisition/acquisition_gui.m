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
addpath(genpath('C:\Users\tweber\Documents\GitHub\retro-illum\aquisition'));
addpath(genpath('C:\Program Files\Digital Camera Toolbox\pco.matlab\scripts'));

% Run start up function
handles = start_up(handles);

% Update handles structure
guidata(hObject, handles);



function varargout = acquisition_gui_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;


function retroIllumAcqGUI_CloseRequestFcn(hObject, eventdata, handles)
% Free buffers
handles = clear_buffers(handles);
% Close camera and exit library
if(handles.glvar.camera_open==1)
    handles.glvar.do_close=1;
    handles.glvar.do_libunload=1;
    pco_camera_open_close(handles.glvar);
end
% Close figure
delete(hObject);

%% PREVIEW BUTTON
function buttonPreview_Callback(hObject, eventdata, handles)
if get(hObject,'Value') == 1 % If the button has been pressed on
    
    bufferWaitTimes = zeros(4,1);
    
    % Switch this button's label
    set(hObject,'String','Stop'); 
    
    % Disable controls
    handles = enable_disable_controls(handles,'preview','off');
    
    % Start the camera
    handles.subfunc.fh_start_camera(handles.out_ptr);
    
    % Set up request loop
    for bufferIdx = 1:handles.acqSettings.numBuffers
        errorCode = calllib('PCO_CAM_SDK','PCO_AddBufferEx',handles.out_ptr,0,0,handles.sBufNr(bufferIdx),handles.acqSettings.xSize,handles.acqSettings.ySize,handles.acqSettings.bitDepth);
        pco_errdisp('PCO_AddBufferEx',errorCode);   
    end 
    
    % Make buffer list structure
    handles.bufferList = libstruct('PCO_Buflist');
    handles.bufferList.sBufNr = handles.sBufNr(1);
    bufferIdx = 1;
    
    % Store guidata
    guidata(hObject,handles);
    disp('Starting Preview')
    
    % Loop until the button is no longer pressed
    while get(hObject,'Value')    
        % Wait for buffer
        tic;
        handles.bufferList.sBufNr = handles.sBufNr(bufferIdx);
        [errorCode,~,handles.bufferList] = calllib('PCO_CAM_SDK','PCO_WaitforBuffer',handles.out_ptr,1,handles.bufferList,500);
        pco_errdisp('PCO_WaitforBuffer',errorCode); 
        bufferWaitTimes(bufferIdx) = toc;

        % Read image data, make sure to transpose
        img = get(handles.im_ptr(bufferIdx),'Value')'; 

        % Re-add buffer
        errorCode = calllib('PCO_CAM_SDK','PCO_AddBufferEx',handles.out_ptr,0,0,handles.sBufNr(bufferIdx),handles.acqSettings.xSize,handles.acqSettings.ySize,handles.acqSettings.bitDepth);
        pco_errdisp('PCO_AddBufferEx',errorCode); 
        
        % Compute next buffer index
        bufferIdx = mod(bufferIdx,handles.acqSettings.numBuffers)+1;
        
        % Slow down display rate a bit
        if rem(bufferIdx,2) == 1 
            
            % Show image
            if handles.acqSettings.doubleImageMode == 1
                [chan1,chan2,diffImg] = compute_diff_img(single(img)-single(handles.background));
                displayImg = scale_img_8bit(diffImg);
                set(handles.imgHandle,'CData',displayImg)
            else
                displayImg = scale_img_8bit(img);
                set(handles.imgHandle,'CData',displayImg)
            end

            % Update histograms
            if handles.acqSettings.doubleImageMode == 1
                handles.chan1Hist.Data = chan1;
                handles.chan2Hist.Data = chan2;
            else
                handles.chan1Hist.Data = img;
            end
            
            drawnow; % Interrupt point, necessary for img update & breaking loop
            if handles.acqSettings.dispBufferWaitTime
                disp(['Buffer wait time ' num2str(round(mean(bufferWaitTimes)*1000)) ' ms']);
            end
        end
        handles = guidata(hObject); 

    end
    
    % The preview has ended
    % Remove all pending buffers in the queue
    errorCode = calllib('PCO_CAM_SDK','PCO_CancelImages',handles.out_ptr);
    pco_errdisp('PCO_CancelImages',errorCode);   
    [errorCode,~,handles.bufferList] = calllib('PCO_CAM_SDK','PCO_WaitforBuffer',handles.out_ptr,1,handles.bufferList,1000);
    pco_errdisp('PCO_WaitforBuffer',errorCode);

    % Stop the camera
    handles.subfunc.fh_stop_camera(handles.out_ptr);
    
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
    
    % Make MATLAB variable to store background frames
    frameSumRegister = zeros(handles.acqSettings.ySize,handles.acqSettings.xSize,'uint32');
    
    % Start the camera
    handles.subfunc.fh_start_camera(handles.out_ptr);
    
    % Set up request loop
    for bufferIdx = 1:handles.acqSettings.numBuffers
        errorCode = calllib('PCO_CAM_SDK','PCO_AddBufferEx',handles.out_ptr,0,0,handles.sBufNr(bufferIdx),handles.acqSettings.xSize,handles.acqSettings.ySize,handles.acqSettings.bitDepth);
        pco_errdisp('PCO_AddBufferEx',errorCode);   
    end 
    
    % Make buffer list structure
    handles.bufferList = libstruct('PCO_Buflist');
    handles.bufferList.sBufNr = handles.sBufNr(1);
    bufferIdx = 1;
    
    % Store guidata
    guidata(hObject,handles);
    disp('Collecting Background')

    % Run until number of background frames have been acquired
    for frameIdx = 1:handles.acqSettings.numBackgroundFrames
        % Wait for buffer
        handles.bufferList.sBufNr = handles.sBufNr(bufferIdx);
        [errorCode,~,handles.bufferList] = calllib('PCO_CAM_SDK','PCO_WaitforBuffer',handles.out_ptr,1,handles.bufferList,500);
        pco_errdisp('PCO_WaitforBuffer',errorCode);

        % Read image data, make sure to transpose, add to register
        img = get(handles.im_ptr(bufferIdx),'Value')';
        frameSumRegister = frameSumRegister + uint32(img);
        
        % Re-add buffer
        errorCode = calllib('PCO_CAM_SDK','PCO_AddBufferEx',handles.out_ptr,0,0,handles.sBufNr(bufferIdx),handles.acqSettings.xSize,handles.acqSettings.ySize,handles.acqSettings.bitDepth);
        pco_errdisp('PCO_AddBufferEx',errorCode); 
        
        % Compute next buffer index
        bufferIdx = mod(bufferIdx,handles.acqSettings.numBuffers)+1;
        
        % Show average image
        if handles.acqSettings.doubleImageMode == 1
            [~,~,diffImg] = compute_diff_img(frameSumRegister);
            displayImg = scale_img_8bit(diffImg);
            set(handles.imgHandle,'CData',displayImg)
        else
            displayImg = scale_img_8bit(frameSumRegister);
            set(handles.imgHandle,'CData',displayImg)
        end
        
        % Update button string with progress
        set(hObject,'String',['Abort (' num2str(frameIdx) '/' num2str(handles.acqSettings.numBackgroundFrames) ' acquired)']);
        
        if rem(bufferIdx,2) == 1 % Slow down display rate a bit
            drawnow % Interrupt point, necessary for img update & breaking loop
        end
        handles = guidata(hObject);
        
        if get(hObject,'Value') == 0
            % Abort button has been pressed, clear register and break loop
            frameSumRegister = zeros(handles.acqSettings.ySize,handles.acqSettings.xSize,'uint32');
            break;             
        end

    end
    
    % Collection has ended
    % Remove all pending buffers in the queue
    errorCode = calllib('PCO_CAM_SDK','PCO_CancelImages',handles.out_ptr);
    pco_errdisp('PCO_CancelImages',errorCode);   
    [errorCode,~,handles.bufferList] = calllib('PCO_CAM_SDK','PCO_WaitforBuffer',handles.out_ptr,1,handles.bufferList,1000);
    pco_errdisp('PCO_WaitforBuffer',errorCode);

    % Stop the camera
    handles.subfunc.fh_stop_camera(handles.out_ptr);
    
    % Average the frame sum register
    handles.background = uint16(double(frameSumRegister)./handles.acqSettings.numBackgroundFrames);
    
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
    
    % Make MATLAB variable to store captured frames
    captureFrames = zeros(handles.acqSettings.ySize,handles.acqSettings.xSize,handles.acqSettings.numCaptureFrames,'uint16');
    
    % Start the camera
    handles.subfunc.fh_start_camera(handles.out_ptr);
    
    % Set up request loop
    for bufferIdx = 1:handles.acqSettings.numBuffers
        errorCode = calllib('PCO_CAM_SDK','PCO_AddBufferEx',handles.out_ptr,0,0,handles.sBufNr(bufferIdx),handles.acqSettings.xSize,handles.acqSettings.ySize,handles.acqSettings.bitDepth);
        pco_errdisp('PCO_AddBufferEx',errorCode);   
    end 
    
    % Make buffer list structure
    handles.bufferList = libstruct('PCO_Buflist');
    handles.bufferList.sBufNr = handles.sBufNr(1);
    bufferIdx = 1;
    
    % Store guidata
    guidata(hObject,handles);

    % Run until number of capture frames have been acquired
    for frameIdx = 1:handles.acqSettings.numCaptureFrames
        % Wait for buffer
        handles.bufferList.sBufNr = handles.sBufNr(bufferIdx);
        [errorCode,~,handles.bufferList] = calllib('PCO_CAM_SDK','PCO_WaitforBuffer',handles.out_ptr,1,handles.bufferList,500);
        pco_errdisp('PCO_WaitforBuffer',errorCode);

        % Read image data, make sure to transpose, insert into frame stack
        img = get(handles.im_ptr(bufferIdx),'Value')';
        captureFrames(:,:,frameIdx) = img;
        
        % Re-add buffer
        errorCode = calllib('PCO_CAM_SDK','PCO_AddBufferEx',handles.out_ptr,0,0,handles.sBufNr(bufferIdx),handles.acqSettings.xSize,handles.acqSettings.ySize,handles.acqSettings.bitDepth);
        pco_errdisp('PCO_AddBufferEx',errorCode); 
        
        % Compute next buffer index
        bufferIdx = mod(bufferIdx,handles.acqSettings.numBuffers)+1;
        
        % Show last image
        if handles.acqSettings.doubleImageMode == 1
            [chan1,chan2,diffImg] = compute_diff_img(single(img)-single(handles.background));
            displayImg = scale_img_8bit(diffImg);
            set(handles.imgHandle,'CData',displayImg)
        else
            displayImg = scale_img_8bit(single(img));
            set(handles.imgHandle,'CData',displayImg)
        end
        
        % Update histograms
        if handles.acqSettings.doubleImageMode == 1
            handles.chan1Hist.Data = uint16(chan1);
            handles.chan2Hist.Data = uint16(chan2);
        else
            handles.chan1Hist.Data = img;
        end
        
        % Update button string with progress
        set(hObject,'String',['Abort (' num2str(frameIdx) '/' num2str(handles.acqSettings.numCaptureFrames) ' acquired)']);
        
        if rem(bufferIdx,2) == 1 % Slow down display rate a bit
            drawnow % Interrupt point, necessary for img update & breaking loop
        end
        handles = guidata(hObject);
        
        if get(hObject,'Value') == 0
            % Abort button has been pressed, clear register and break loop
            clear captureFrames
            break;             
        end

    end
    
    % Collection has ended
    % Remove all pending buffers in the queue
    errorCode = calllib('PCO_CAM_SDK','PCO_CancelImages',handles.out_ptr);
    pco_errdisp('PCO_CancelImages',errorCode);   
    [errorCode,~,handles.bufferList] = calllib('PCO_CAM_SDK','PCO_WaitforBuffer',handles.out_ptr,1,handles.bufferList,1000);
    pco_errdisp('PCO_WaitforBuffer',errorCode);

    % Stop the camera
    handles.subfunc.fh_stop_camera(handles.out_ptr);
    
    if get(hObject,'Value') == 1
        % Make new directory for acquisition
        GUIPath = strsplit(mfilename('fullpath'),filesep);
        
        % Saves as date in YYYYMMDD \ time in HHMMSS[miliseconds] \(images)
        handles.acqSettings.captureDirectory = [strjoin(GUIPath(1:(end-2)),filesep) filesep 'data' filesep datestr(now,'yyyymmdd') filesep datestr(now,'HHMMSSFFF')];
        mkdir(handles.acqSettings.captureDirectory)
        
        % Save image raw stack, norm diff stack, background image
        set(hObject,'String','Saving Images');drawnow
        save_captured_double_image_stacks(captureFrames,handles.background,handles.acqSettings.captureDirectory);
        
        % Save settings used during capture
        set(hObject,'String','Saving Settings');drawnow
        handles = save_settings(handles);
        
        set(hObject,'String','Capture (Last: Success)');drawnow;
        
        disp(['Successfully saved file at ' handles.acqSettings.captureDirectory])
    else
        % Don't do saving stuff, capture was aborted
        set(hObject,'String','Capture (Last: Aborted)')
    end
    
    % Switch back value, re-enable controls, and store guidata
    set(hObject,'Value',0);
    handles = enable_disable_controls(handles,'capture','on');
    guidata(hObject, handles);
    
else

    guidata(hObject, handles);
end


function popupSensorFormat_Callback(hObject, eventdata, handles)
popupSensorFormatCallback(hObject,handles);

function textNumCaptureFrames_Callback(hObject, eventdata, handles)
textNumCaptureFramesCallback(hObject,handles);


% CREATE FUNCTIONS -- ignore
function popupSensorFormat_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function textNumCaptureFrames_CreateFcn(hObject, eventdata, handles)
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
