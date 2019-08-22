function handles = make_buffers(handles)

% Should be used when starting the program, and after changing the image
% size

% Allocate memory in MATLAB for display
handles.acqSettings.imgSizeBytes = 2*uint32(handles.acqSettings.xSize)*uint32(handles.acqSettings.ySize);
handles.imgStack = zeros(handles.acqSettings.xSize,handles.acqSettings.ySize,handles.acqSettings.numBuffers,'uint16');

% Allocate SDK buffers and set address of buffers from MATLAB buffer stack
handles.sBufNr = zeros(1,handles.acqSettings.numBuffers,'int16');
handles.ev_ptr(handles.acqSettings.numBuffers) = libpointer('voidPtr');
handles.im_ptr(handles.acqSettings.numBuffers) = libpointer('voidPtr');
for bufferIdx = 1:handles.acqSettings.numBuffers   
    sBufNri = int16(-1);
    
    handles.im_ptr(bufferIdx) = libpointer('uint16Ptr',handles.imgStack(:,:,bufferIdx));
    handles.ev_ptr(bufferIdx) = libpointer('voidPtr');

    [errorCode,~,sBufNri]  = calllib('PCO_CAM_SDK','PCO_AllocateBuffer',handles.out_ptr,sBufNri,handles.acqSettings.imgSizeBytes,handles.im_ptr(bufferIdx),handles.ev_ptr(bufferIdx));
    pco_errdisp('PCO_AllocateBuffer',errorCode); 
    
    handles.sBufNr(bufferIdx) = sBufNri;
end