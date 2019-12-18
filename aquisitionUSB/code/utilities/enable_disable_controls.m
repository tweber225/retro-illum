function handles = enable_disable_controls(handles,modeCalled,onOff)
% Disable some of the controls during preview, capture, calibration
% collection modes


% Frames to capture can't be changed
set(handles.textNumCaptureFrames,'Enable',onOff);

switch modeCalled
    case 'capture'
        set(handles.buttonCollectCalibration,'Enable',onOff);
        set(handles.buttonPreview,'Enable',onOff);
        
    case 'preview'
        set(handles.buttonCollectCalibration,'Enable',onOff);
        
    case 'calibration'
        set(handles.buttonPreview,'Enable',onOff);
        set(handles.buttonCapture,'Enable',onOff);
        
end

drawnow;