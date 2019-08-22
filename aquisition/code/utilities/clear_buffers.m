function handles = clear_buffers(handles)

% Free SDK buffers
for bufferIdx = 1:handles.acqSettings.numBuffers
    errorCode = calllib('PCO_CAM_SDK','PCO_FreeBuffer',handles.out_ptr,handles.sBufNr(bufferIdx));
    pco_errdisp('PCO_FreeBuffer',errorCode); 
end

% Clear MATLAB variables
clear handles.imgStack
clear handles.sBufNr
clear handles.ev_ptr
clear handles.im_ptr