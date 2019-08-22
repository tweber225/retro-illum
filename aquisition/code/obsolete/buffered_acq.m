% Trying to set up buffering with minimal code

% Set a few settings
settings.sensorFormat = 1; % 0 for standard (1392x1040), 1 for "extended" (800x600)
settings.pixelRate = 2; % 1 is 12 MHz and 2 is 24 MHz
settings.conversionFactor = 100; % 100 => 1.00 e-/ADU
settings.doubleImageMode = 1; % 1 is on, 0 is off
settings.IRSensitivity = 1; % 1 is on, 0 is off
settings.triggerMode = 0; % 0 is auto (ie freerun)
settings.hotPixelCorrectionMode = 0; % 0 is off
settings.exposureTime = 5; % see below for units
settings.exposureTimeBase = 2; % 2 for ms
settings.numBuffers = 4;

% Add PCO SDK-MATLAB folder to path
addpath(genpath('C:\Program Files\Digital Camera Toolbox\pco.matlab\scripts'))

% Make PCO SDK-MATLAB global variable
glvar=struct('do_libunload',0,'do_close',0,'camera_open',0,'out_ptr',[]);

% Load PCO definitions
pco_camera_load_defines();

% Try to open the camera
[errorCode,glvar] = pco_camera_open_close(glvar);
pco_errdisp('pco_camera_setup',errorCode); 
if(errorCode ~= PCO_NOERROR) % Return if camera open fails
    error('Could not open camera')
end 
out_ptr = glvar.out_ptr;

% Load subfunctions
subfunc = pco_camera_subfunction();

% Make sure the camera is stopped
subfunc.fh_stop_camera(out_ptr);

% Load camera description
cam_desc = libstruct('PCO_Description');
set(cam_desc,'wSize',cam_desc.structsize);
[errorCode,~,cam_desc] = calllib('PCO_CAM_SDK','PCO_GetCameraDescription',out_ptr,cam_desc);
pco_errdisp('PCO_GetCameraDescription',errorCode);

% Note the Bit Depth
settings.bitDepth = uint16(cam_desc.wDynResDESC);

% Set bit alignment to LSB
errorCode = calllib('PCO_CAM_SDK', 'PCO_SetBitAlignment', out_ptr,uint16(BIT_ALIGNMENT_LSB));
pco_errdisp('PCO_SetBitAlignment',errorCode);   

% Set recorder sub mode to ring buffer
errorCode = calllib('PCO_CAM_SDK', 'PCO_SetRecorderSubmode',out_ptr,RECORDER_SUBMODE_RINGBUFFER);
pco_errdisp('PCO_SetRecorderSubmode',errorCode); 

% Set parameters
errorCode = calllib('PCO_CAM_SDK','PCO_SetSensorFormat',out_ptr,settings.sensorFormat);
pco_errdisp('PCO_SetSensorFormat',errorCode);
subfunc.fh_set_pixelrate(out_ptr,settings.pixelRate);
errorCode = calllib('PCO_CAM_SDK','PCO_SetConversionFactor',out_ptr,settings.conversionFactor);
pco_errdisp('PCO_SetConversionFactor',errorCode);
errorCode = calllib('PCO_CAM_SDK','PCO_SetDoubleImageMode',out_ptr,settings.doubleImageMode);
pco_errdisp('PCO_SetDoubleImageMode',errorCode);
errorCode = calllib('PCO_CAM_SDK','PCO_SetIRSensitivity',out_ptr,settings.IRSensitivity);
pco_errdisp('PCO_SetIRSensitivity',errorCode);
subfunc.fh_set_triggermode(out_ptr,settings.triggerMode);
errorCode = calllib('PCO_CAM_SDK','PCO_SetHotPixelCorrectionMode',out_ptr,settings.hotPixelCorrectionMode);
pco_errdisp('PCO_SetHotPixelCorrectionMode',errorCode);
subfunc.fh_set_exposure_times(out_ptr,settings.exposureTime,settings.exposureTimeBase,0,2) % 2's indicate ms timebase

% Arm camera and check for errors
errorCode = calllib('PCO_CAM_SDK', 'PCO_ArmCamera', out_ptr);
pco_errdisp('PCO_ArmCamera',errorCode);   
if(errorCode~=PCO_NOERROR)
    error('Camera arming failed')
end 

subfunc.fh_get_triggermode(out_ptr); % confirm trigger mode
subfunc.fh_show_frametime(out_ptr); % confirm frame period and rate

% Get image size
settings.xSize = uint16(0);
settings.ySize = uint16(0);
settings.xMaxSize = uint16(0);
settings.yMaxSize = uint16(0);
[errorCode,~,settings.xSize,settings.ySize]  = calllib('PCO_CAM_SDK','PCO_GetSizes',out_ptr,settings.xSize,settings.ySize,settings.xMaxSize,settings.yMaxSize);
pco_errdisp('PCO_GetSizes',errorCode);   

% Allocate memory in MATLAB for display
imgSizeBytes = uint32(2*settings.xSize*settings.ySize);
imgStack = zeros(settings.xSize,settings.ySize,settings.numBuffers,'uint16');

% Allocate SDK buffers and set address of buffers from MATLAB buffer stack
sBufNr=zeros(1,settings.numBuffers,'int16');
ev_ptr(settings.numBuffers) = libpointer('voidPtr');
im_ptr(settings.numBuffers) = libpointer('voidPtr');
for bufferIdx = 1:settings.numBuffers   
    sBufNri=int16(-1);
    im_ptr(bufferIdx) = libpointer('uint16Ptr',imgStack(:,:,bufferIdx));
    ev_ptr(bufferIdx) = libpointer('voidPtr');

    [errorCode,~,sBufNri]  = calllib('PCO_CAM_SDK','PCO_AllocateBuffer', out_ptr,sBufNri,imgSizeBytes,im_ptr(bufferIdx),ev_ptr(bufferIdx));
    pco_errdisp('PCO_AllocateBuffer',errorCode);   
    sBufNr(bufferIdx) = sBufNri;
end

% Start the camera
subfunc.fh_start_camera(out_ptr);
tic;

% Set up request loop
for bufferIdx = 1:settings.numBuffers
    errorCode = calllib('PCO_CAM_SDK','PCO_AddBufferEx',out_ptr,0,0,sBufNr(bufferIdx),settings.xSize,settings.ySize,settings.bitDepth);
    pco_errdisp('PCO_AddBufferEx',errorCode);   
end 

% Make buffer list structure
bufferList = libstruct('PCO_Buflist');
bufferList.sBufNr = sBufNr(1);

% Acquire images
numImgsTotal = 100;
numImgsAcq=0;
while numImgsAcq < numImgsTotal
    % Wait for buffer
    for bufferIdx = 1:settings.numBuffers
        bufferList.sBufNr = sBufNr(bufferIdx);
        tic
        [errorCode,~,bufferList] = calllib('PCO_CAM_SDK','PCO_WaitforBuffer',out_ptr,1,bufferList,500);
        pco_errdisp('PCO_WaitforBuffer',errorCode);
        toc
    
        % Read image data
        img = get(im_ptr(bufferIdx),'Value');
        numImgsAcq = numImgsAcq+1;
        
        % Do some fake proccessing on the data
        F = fft2(single(img));
        F1 = F.*F;
        I = ifft2(F1);

        % Re-add buffer
        errorCode = calllib('PCO_CAM_SDK','PCO_AddBufferEx',out_ptr,0,0,sBufNr(bufferIdx),settings.xSize,settings.ySize,settings.bitDepth);
        pco_errdisp('PCO_AddBufferEx',errorCode);  
        
    end
    
end

% Remove all pending buffers in the queue
errorCode = calllib('PCO_CAM_SDK', 'PCO_CancelImages', out_ptr);
pco_errdisp('PCO_CancelImages',errorCode);   
[errorCode,~,bufferList] = calllib('PCO_CAM_SDK','PCO_WaitforBuffer', out_ptr,1,bufferList,100);
pco_errdisp('PCO_WaitforBuffer',errorCode);

% Stop the camera
subfunc.fh_stop_camera(out_ptr);

% Free buffers
for bufferIdx = 1:settings.numBuffers
    errorCode = calllib('PCO_CAM_SDK','PCO_FreeBuffer',out_ptr,sBufNr(bufferIdx));
    pco_errdisp('PCO_FreeBuffer',errorCode); 
end

% Close camera and exit library
if(glvar.camera_open==1)
    glvar.do_close=1;
    glvar.do_libunload=1;
    pco_camera_open_close(glvar);
end   
