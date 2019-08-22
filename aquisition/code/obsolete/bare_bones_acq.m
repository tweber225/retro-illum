% First try at getting frame with PCO SDK. Implement with minimal code.

% Set a few parameters
params.sensorFormat = 1; % 0 for standard (1392x1040), 1 for "extended" (800x600)
params.pixelRate = 2; % 1 is 12 MHz and 2 is 24 MHz
params.conversionFactor = 100; % 100 => 1.00 e-/ADU
params.doubleImageMode = 0; % 1 is on, 0 is off
params.IRSensitivity = 1; % 1 is on, 0 is off
params.triggerMode = 0; % 0 is auto (ie freerun)
params.hotPixelCorrectionMode = 0; % 0 is off
params.exposureTime = 5; % ms
params.exposureTimeBase = 2; % 2=ms

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
params.bitDepth = uint16(cam_desc.wDynResDESC);

% Set parameters
errorCode = calllib('PCO_CAM_SDK','PCO_SetSensorFormat',out_ptr,params.sensorFormat);
pco_errdisp('PCO_SetSensorFormat',errorCode);
subfunc.fh_set_pixelrate(out_ptr,params.pixelRate);
errorCode = calllib('PCO_CAM_SDK','PCO_SetConversionFactor',out_ptr,params.conversionFactor);
pco_errdisp('PCO_SetConversionFactor',errorCode);
errorCode = calllib('PCO_CAM_SDK','PCO_SetDoubleImageMode',out_ptr,params.doubleImageMode);
pco_errdisp('PCO_SetDoubleImageMode',errorCode);
errorCode = calllib('PCO_CAM_SDK','PCO_SetIRSensitivity',out_ptr,params.IRSensitivity);
pco_errdisp('PCO_SetIRSensitivity',errorCode);
subfunc.fh_set_triggermode(out_ptr,params.triggerMode);
errorCode = calllib('PCO_CAM_SDK','PCO_SetHotPixelCorrectionMode',out_ptr,params.hotPixelCorrectionMode);
pco_errdisp('PCO_SetHotPixelCorrectionMode',errorCode);
subfunc.fh_set_exposure_times(out_ptr,params.exposureTime,params.exposureTimeBase,0,2) % 2's indicate ms timebase

% Arm camera and check for errors
errorCode = calllib('PCO_CAM_SDK', 'PCO_ArmCamera', out_ptr);
pco_errdisp('PCO_ArmCamera',errorCode);   
if(errorCode~=PCO_NOERROR)
    error('Camera arming failed')
end 

subfunc.fh_get_triggermode(out_ptr); % confirm trigger mode
subfunc.fh_show_frametime(out_ptr); % confirm frame period and rate

% Get a single image
[errorCode,ima,glvar] = pco_camera_stack(1,glvar);
if(errorCode==PCO_NOERROR) % If no error, show the single image
    m=max(max(ima(10:end-10,10:end-10)));
    imshow(ima,[0,m+100]);
    disp(['found max ',int2str(m)]);
end 

% Stop the camera
subfunc.fh_stop_camera(out_ptr);

% Close camera and exit library
if(glvar.camera_open==1)
    glvar.do_close=1;
    glvar.do_libunload=1;
    pco_camera_open_close(glvar);
end   
